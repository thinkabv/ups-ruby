# frozen_string_literal: true

module UPS
  module Parsers
    class PickupParser < BaseParser
      # The Pickup Request Number: what UPS calls the pickup from here on.
      def reference
        root_response&.dig(:PRN) || root_response&.dig(:PickupConfirmationNumber)
      end

      def rate_status_description
        root_response&.dig(:RateStatus, :Description)
      end

      private

      def root_response
        parsed_response[:PickupCreationResponse]
      end
    end
  end
end
