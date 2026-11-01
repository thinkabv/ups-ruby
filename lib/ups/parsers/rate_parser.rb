# frozen_string_literal: true

require "uri"

module UPS
  module Parsers
    class RateParser
      attr_reader :rate

      def initialize(rate)
        @rate = rate
      end

      def as_json
        {
          service_code: rate_service_code,
          service_name: rate_service_name,
          total: rate_total
        }
      end

      def rate_service_name
        UPS::SERVICES[rate_service_code]
      end

      def rate_service_code
        rate_service[:Code]
      end

      private

      def rate_total
        unless negotiated_rates
          return {
            currency: total_charges[:CurrencyCode],
            amount: total_charges[:MonetaryValue]
          }
        end

        {
          currency: negotiated_rates[:TotalCharge][:CurrencyCode],
          amount: negotiated_rates[:TotalCharge][:MonetaryValue]
        }
      end

      def rate_service
        rate[:Service]
      end

      def total_charges
        rate[:TotalCharges]
      end

      def negotiated_rates
        rate[:NegotiatedRateCharges]
      end
    end
  end
end
