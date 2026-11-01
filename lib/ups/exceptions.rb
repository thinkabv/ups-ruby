# frozen_string_literal: true

module UPS
  module Exceptions
    class InvalidUrlException < StandardError; end

    class InvalidAttributeError < StandardError; end

    class AuthenticationRequiredException < StandardError; end

    class AuthorizationError < StandardError; end

    # UPS answered with something that is not a JSON API response, such as a
    # gateway error page.
    class ResponseError < StandardError
      attr_reader :status, :body

      def initialize(status, body)
        @status = status
        @body = body
        super("UPS responded with #{status ? "HTTP #{status}" : "an unreadable body"}: #{body.to_s[0, 200]}")
      end
    end
  end
end
