# frozen_string_literal: true

require "uri"
require "excon"
require "json"
require "base64"
require "securerandom"

module UPS
  # Entry point to the UPS REST API: holds the OAuth client-credentials token
  # and performs the rate, ship, track, label, paperless and pickup calls.
  #
  #   connection = UPS::Connection.new(test_mode: true, transaction_source: "my-app")
  #   connection.authorize("ACCOUNT_NUMBER", "CLIENT_ID", "CLIENT_SECRET")
  #   rates = connection.rates { |builder| ... }
  #
  # The token is requested on the first call and requested again once it has
  # expired, so one Connection can serve a process for its whole lifetime.
  class Connection
    TEST_URL = "https://wwwcie.ups.com"
    LIVE_URL = "https://onlinetools.ups.com"

    TOKEN_PATH = "/security/v1/oauth/token"
    # v2409 is the only version UPS lists for rating, shipping and pickup
    # (UPS-API/api-documentation, October 2026); the others are fixed at v1/v2.
    RATE_PATH = "/api/rating/v2409/Shop"
    SHIP_PATH = "/api/shipments/v2409/ship"
    TRACK_PATH = "/api/track/v1/details"
    LABEL_PATH = "/api/labels/v1/recovery"
    PAPERLESS_UPLOAD_PATH = "/api/paperlessdocuments/v2/upload"
    PICKUP_PATH = "/api/pickupcreation/v2409/pickup"

    # Seconds before the reported expiry at which a token counts as expired,
    # so a request never leaves with a token that dies in flight.
    TOKEN_EXPIRY_MARGIN = 60

    Token = Struct.new(:access_token, :expires_at) do
      def expired?(now) = now >= expires_at
    end

    attr_reader :url, :account_number, :client_id, :client_secret, :transaction_source

    # @param test_mode [Boolean] use the UPS customer integration environment
    # @param transaction_source [String] the `transactionSrc` header UPS asks
    #   every client to send, identifying the calling application
    # @param clock [#call] returns the current Time; injectable for tests
    def initialize(test_mode: false, transaction_source: "ups-ruby", clock: Time.method(:now))
      @url = test_mode ? TEST_URL : LIVE_URL
      @transaction_source = transaction_source
      @clock = clock
      @token = nil
    end

    # Stores the credentials. The token itself is requested on the first call
    # that needs it. With `mock` no token is ever requested (for tests).
    def authorize(account_number, client_id, client_secret, mock = false)
      if !mock && [account_number, client_id, client_secret].any? { |value| value.nil? || value.empty? }
        raise Exceptions::AuthorizationError, "Missing account_number, client_id, or client_secret"
      end

      @account_number = account_number
      @client_id = client_id
      @client_secret = client_secret
      @token = Token.new("test_token", @clock.call + 6 * 365 * 24 * 3600) if mock
      nil
    end

    def authorized? = !@token.nil? || !client_id.nil?

    # Shops rates for a shipment. Yields a {Builders::RateBuilder} unless one is given.
    def rates(builder = nil, &block)
      Parsers::RatesParser.new(post(RATE_PATH, build(Builders::RateBuilder, builder, &block).as_json))
    end

    # Books a shipment and returns its labels. Yields a {Builders::ShipBuilder} unless one is given.
    def ship(builder = nil, &block)
      Parsers::ShipParser.new(post(SHIP_PATH, build(Builders::ShipBuilder, builder, &block).as_json))
    end

    # Fetches the activity of a package by tracking number.
    def track(number)
      raise Exceptions::InvalidAttributeError, "Tracking number is required" if number.nil? || number.empty?

      Parsers::TrackParser.new(get("#{TRACK_PATH}/#{number}"))
    end

    # Recovers the label of an earlier shipment. Yields a {Builders::LabelRecoveryRequestBuilder} unless one is given.
    def label(builder = nil, &block)
      Parsers::LabelParser.new(post(LABEL_PATH, build(Builders::LabelRecoveryRequestBuilder, builder, &block).as_json))
    end

    # Uploads customs documents to UPS Paperless. Yields a {Builders::PaperlessDocumentBuilder} unless one is given.
    def paperless_document_upload(builder = nil, &block)
      builder = build(Builders::PaperlessDocumentBuilder, builder, &block)
      Parsers::PaperlessDocumentParser.new(post(PAPERLESS_UPLOAD_PATH, builder.as_json, "ShipperNumber" => builder.shipper_number))
    end

    # Books a driver to collect parcels. Yields a {Builders::PickupBuilder} unless one is given.
    def pickup(builder = nil, &block)
      Parsers::PickupParser.new(post(PICKUP_PATH, build(Builders::PickupBuilder, builder, &block).as_json))
    end

    # The current access token, requesting a new one when there is none yet or
    # the previous one expired.
    def access_token
      raise Exceptions::AuthorizationError, "No credentials, call authorize first" unless authorized?

      @token = request_token if @token.nil? || @token.expired?(@clock.call)
      @token.access_token
    end
    alias_method :get_access_token, :access_token

    private

    def build(builder_class, builder)
      return builder unless builder.nil?

      builder_class.new.tap { |fresh| yield fresh if block_given? }
    end

    def post(path, body, extra_headers = {})
      body_of Excon.post(url + path, headers: headers.merge(extra_headers), body: body.to_json)
    end

    def get(path)
      body_of Excon.get(url + path, headers: headers)
    end

    # UPS answers API failures with a JSON body which the parsers report through
    # #success? and #error_description. Only a response that cannot carry such a
    # body (a gateway error page, say) is raised here.
    def body_of(response)
      raise Exceptions::ResponseError.new(response.status, response.body) if response.status >= 500

      response.body
    end

    def headers
      {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{access_token}",
        "transId" => SecureRandom.hex(16),
        "transactionSrc" => transaction_source
      }
    end

    def request_token
      response = Excon.post(
        url + TOKEN_PATH,
        body: URI.encode_www_form(grant_type: "client_credentials"),
        headers: {
          "Content-Type" => "application/x-www-form-urlencoded",
          "x-merchant-id" => account_number,
          "Authorization" => "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
        }
      )
      unless response.status == 200
        raise Exceptions::AuthorizationError, "Token request failed with HTTP #{response.status}: #{response.body.to_s[0, 200]}"
      end

      data = JSON.parse(response.body)
      Token.new(data.fetch("access_token"), @clock.call + data.fetch("expires_in").to_i - TOKEN_EXPIRY_MARGIN)
    rescue Excon::Error, JSON::ParserError, KeyError => e
      raise Exceptions::AuthorizationError, "Token request failed: #{e.message}"
    end
  end
end
