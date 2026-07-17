# frozen_string_literal: true

require 'uri'
require 'excon'
require 'digest/md5'
require 'ox'
require 'base64'
require 'json'

module UPS
  # The {Connection} class acts as the main entry point to performing rate and
  # ship operations against the UPS API.
  #
  # @author Paul Trippett
  # @abstract
  # @since 0.1.0
  # @attr [String] url The base url to use either TEST_URL or LIVE_URL
  class Connection
    attr_accessor :url,
                  :account_number,
                  :client_id,
                  :client_secret

    TEST_URL = 'https://wwwcie.ups.com'
    LIVE_URL = 'https://onlinetools.ups.com'

    RATE_VERSION = 'v2403'
    SHIP_VERSION = 'v2403'
    TRACK_VERSION = 'v1'
    LABEL_VERSION = 'v1'
    PAPERLESS_VERSION = 'v2'

    RATE_PATH = "/api/rating/#{RATE_VERSION}/Shop"
    SHIP_PATH = "/api/shipments/#{SHIP_VERSION}/ship"
    TRACK_PATH = "/api/track/#{TRACK_VERSION}/details"
    LABEL_PATH = "/api/labels/#{LABEL_VERSION}/recovery"
    PAPERLESS_UPLOAD_PATH = "/api/paperlessdocuments/#{PAPERLESS_VERSION}/upload"

    DEFAULT_PARAMS = {
      test_mode: false
    }

    # Initializes a new {Connection} object
    #
    # @param [Hash] params The initialization options
    # @option params [Boolean] :test_mode If TEST_URL should be used for
    #   requests to the UPS URL
    def initialize(params = {})
      params = DEFAULT_PARAMS.merge(params)
      self.url = params[:test_mode] ? TEST_URL : LIVE_URL

      @token_data = nil
    end

    # Makes a request to fetch Rates for a shipment.
    #
    # A pre-configured {Builders::RateBuilder} object can be passed as the first
    # option or a block yielded to configure a new {Builders::RateBuilder}
    # object.
    #
    # @param [Builders::RateBuilder] rate_builder A pre-configured
    #   {Builders::RateBuilder} object to use
    # @yield [rate_builder] A RateBuilder object for configuring
    #   the shipment information sent
    def rates(rate_builder = nil)
      if rate_builder.nil? && block_given?
        rate_builder = UPS::Builders::RateBuilder.new
        yield rate_builder
      end

      response = get_response(RATE_PATH, rate_builder.as_json)
      UPS::Parsers::RatesParser.new(response.body)
    end

    # Makes a request to ship a package
    #
    # A pre-configured {Builders::ShipBuilder} object can be passed as
    # the first option or a block yielded to configure a new
    # {Builders::ShipBuilder} object.
    #
    # @param [Builders::ShipBuilder] confirm_builder A pre-configured
    #   {Builders::ShipBuilder} object to use
    # @yield [ship_builder] A ShipBuilder object for configuring
    #   the shipment information sent
    def ship(confirm_builder = nil)
      if confirm_builder.nil? && block_given?
        confirm_builder = Builders::ShipBuilder.new
        yield confirm_builder
      end

      make_confirm_request(confirm_builder)
    end

    # Makes a request to Track the status for a shipment.
    #
    # @param [String] number Tracking number to request status for
    def track(number)
      if number.empty?
        fail Exceptions::InvalidAttributeError, 'Tracking number is required'
      end

      response = get_response(TRACK_PATH + "/#{number}", {}, 'GET')
      UPS::Parsers::TrackParser.new(response.body)
    end

    # Makes a request for a label of a shipment.
    #
    # A pre-configured {Builders::LabelRecoveryRequestBuilder} object can be passed as the first
    # option or a block yielded to configure a new {Builders::LabelRecoveryRequestBuilder}
    # object.
    #
    # @param [Builders::LabelRecoveryRequestBuilder] label_builder A pre-configured
    #   {Builders::LabelRecoveryRequestBuilder} object to use
    # @yield [label_builder] A LabelRecoveryRequestBuilder object for configuring
    #   the label request information sent
    def label(label_builder = nil)
      if label_builder.nil? && block_given?
        label_builder = UPS::Builders::LabelRecoveryRequestBuilder.new
        yield label_builder
      end

      response = get_response(LABEL_PATH, label_builder.as_json)
      UPS::Parsers::LabelParser.new(response.body)
    end

    # Uploads a document (e.g. a commercial invoice) to the UPS Paperless
    # Document API and returns a parser exposing the created DocumentID.
    #
    # A pre-configured {Builders::PaperlessDocumentBuilder} object can be passed
    # as the first option or a block yielded to configure a new one.
    #
    # @param [Builders::PaperlessDocumentBuilder] builder A pre-configured builder
    # @yield [builder] A PaperlessDocumentBuilder for configuring the upload
    def paperless_document_upload(builder = nil)
      if builder.nil? && block_given?
        builder = UPS::Builders::PaperlessDocumentBuilder.new
        yield builder
      end

      response = get_response(PAPERLESS_UPLOAD_PATH, builder.as_json, 'post',
                              'ShipperNumber' => builder.shipper_number)
      UPS::Parsers::PaperlessDocumentParser.new(response.body)
    end

    # Authorizes the connection with the UPS API
    #
    # @param [String] account_number Account number to use for the request
    # @param [String] client_id Client ID to use
    # @param [String] client_secret Client secret to use
    # @param [Boolean] mock If the request should be mocked
    # @return [void]
    def authorize(account_number = '', client_id = '', client_secret = '', mock = false)
      if @token_data && !@token_data.nil? && !@token_data.empty?
        return nil
      end

      if mock
        self.account_number = account_number
        self.client_id = client_id
        self.client_secret = client_secret

        @token_data = {
          'access_token' => 'test_token',
          'expires_in' => 189200000, # 6 years
          'issued_at' => Time.now.to_i,
          'refresh_token' => 'test_refresh_token'
        }

        return nil
      end

      # Make sure we were given credentials for OAuth
      if account_number.nil? || account_number.empty? || client_id.nil? || client_id.empty? || client_id.nil? || client_secret.empty?
        fail Exceptions::AuthorizationError,
             'Missing account_number, client_id, or client_secret'
      end

      self.account_number = account_number
      self.client_id = client_id
      self.client_secret = client_secret

      create_token
    end

    # Retrieves the access token, or refreshes it if it has expired
    #
    # @return [String] The access token
    def get_access_token
      if @token_data.nil?
        fail Exceptions::AuthorizationError,
             'No token data found, please call authorize first'
      end

      issued_at = @token_data['issued_at'].to_i
      expires_in = @token_data['expires_in'].to_i
      current_time = Time.now.to_i

      # Token is expired, refresh it
      if issued_at + expires_in <= current_time
        refresh_token(@token_data['refresh_token'])
      end

      @token_data['access_token']
    end

    private

    def build_url(path)
      "#{url}#{path}"
    end

    # Makes a request to the UPS API
    #
    # @param [String] path The path to make the request to
    # @param [Optional, Hash] body The body to send with the request
    # @param [Optional, String] method The method type to use for the request
    # @return [Excon::Response] The response from the request
    def get_response(path, body = {}, method = 'post', extra_headers = {})
      access_token = get_access_token

      headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{access_token}",
        'transId' => SecureRandom.hex(16), # Unique identifier for this request
        'transactionSrc' => 'testing' # Identifies client/source app that is calling, UPS has default of 'testing' (sometimes)
      }.merge(extra_headers)

      if method.downcase == 'get'
        Excon.get(
          build_url(path),
          headers: headers
        )
      else
        Excon.post(
          build_url(path),
          headers: headers,
          body: body.to_json
        )
      end
    end

    def make_confirm_request(confirm_builder)
      make_ship_request(confirm_builder, SHIP_PATH, Parsers::ShipParser)
    end

    def make_ship_request(builder, path, ship_parser)
      response = get_response(path, builder.as_json)
      ship_parser.new(response.body)
    end

    # Creates a new access token
    #
    # @return [void]
    def create_token
      full_url = "#{url}/security/v1/oauth/token"
      auth = "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"

      params = {
        'grant_type' => 'client_credentials'
      }

      begin
        response = Excon.post(
          full_url,
          body: URI.encode_www_form(params),
          headers: {
            'Content-Type' => 'application/x-www-form-urlencoded',
            'x-merchant-id' => account_number,
            'Authorization' => auth
          }
        )

        if response.status == 200
          @token_data = JSON.parse(response.body)
        else
          raise "Unexpected response status: #{response.status}"
        end
      rescue Excon::Errors::Timeout
        fail Exceptions::AuthorizationError, 'Token creation request timed out'
      rescue Excon::Errors::SocketError
        fail Exceptions::AuthorizationError,
             'Token creation request failed due to socket error'
      rescue StandardError => e
        fail Exceptions::AuthorizationError,
             "Token creation request failed: #{e.message}"
      end
    end

    # Refreshes the access token once it has expired
    #
    # @param [String] refresh_token Refresh token to use for the request
    # @return [void]
    def refresh_token(refresh_token)
      full_url = "#{url}/security/v1/oauth/refresh"
      auth = "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"

      params = {
        'grant_type' => 'refresh_token',
        'refresh_token' => refresh_token
      }

      begin
        response = Excon.post(
          full_url,
          body: URI.encode_www_form(params),
          headers: {
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Authorization' => auth
          }
        )

        if response.status == 200
          @token_data = JSON.parse(response.body)
        else
          raise "Unexpected response status: #{response.status}"
        end
      rescue Excon::Errors::Timeout
        fail Exceptions::AuthorizationError, 'Token refresh request timed out'
      rescue Excon::Errors::SocketError
        fail Exceptions::AuthorizationError,
             'Token refresh request failed due to socket error'
      rescue StandardError => e
        fail Exceptions::AuthorizationError,
             "Token refresh request failed: #{e.message}"
      end
    end
  end
end
