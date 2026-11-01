# frozen_string_literal: true

require "json"

module UPS
  module Parsers
    # Reads a UPS JSON response. Subclasses name the root element
    # (RateResponse, ShipmentResponse, ...) through #root_response.
    #
    # UPS reports failure in two shapes: an HTTP-level `response.errors` list,
    # and an API-level `Response.ResponseStatus` code 0 with `Response.Alert`
    # entries. Both surface through #errors and #error_description.
    class BaseParser
      SUCCESS = "1"

      Error = Struct.new(:code, :description)

      attr_reader :response

      def initialize(response)
        @response = response
      end

      def success?
        errors.empty? && status_code == SUCCESS
      end

      def errors
        http_errors + ((status_code == SUCCESS) ? [] : alerts)
      end

      def error_description
        errors.map(&:description).join("; ")
      end

      # "1" on success, "0" on failure. A response without a ResponseStatus
      # (tracking, paperless) counts as "1"; its errors tell otherwise.
      def status_code
        status = response_status
        return SUCCESS if status.nil?

        (status[:Code] || status[:StatusCode]).to_s
      end

      def status_description
        status = response_status
        return "" if status.nil?

        (status[:Description] || status[:StatusDescription]).to_s
      end

      def parsed_response
        @parsed_response ||= JSON.parse(response, symbolize_names: true)
      rescue JSON::ParserError
        raise Exceptions::ResponseError.new(nil, response)
      end

      private

      # The element under which this response's data lives; nil when absent.
      def root_response
        nil
      end

      def response_status
        root = root_response
        root.dig(:Response, :ResponseStatus) if root.is_a?(Hash)
      end

      def http_errors
        body = parsed_response
        list = body.is_a?(Hash) ? body.dig(:response, :errors) : nil
        Array(list).map { |error| Error.new(error[:code], error[:message]) }
      end

      def alerts
        root = root_response
        list = root.is_a?(Hash) ? root.dig(:Response, :Alert) : nil
        Array(list).map { |alert| Error.new(alert[:Code], alert[:Description]) }
      end

      # UPS sends one element as an object and several as an array.
      def array(node)
        [node].flatten.compact
      end
    end
  end
end
