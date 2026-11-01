# frozen_string_literal: true

module UPS
  module Parsers
    class RatesParser < BaseParser
      def rated_shipments
        array(root_response&.dig(:RatedShipment)).map do |rated_shipment|
          RateParser.new(rated_shipment).as_json
        end
      end

      private

      def root_response
        parsed_response[:RateResponse]
      end
    end
  end
end
