# frozen_string_literal: true

require "date"

module UPS
  module Parsers
    # The latest activity of a tracked package.
    class TrackParser < BaseParser
      DELIVERED = "D"

      def initialize(response)
        # The track endpoint has been seen returning its body with escaped
        # quotes and newlines; undo that before parsing.
        super(response.gsub('\\"', '"').gsub("\\n", "\n"))
      end

      # False when UPS has no activity for the number (yet).
      def found?
        !latest_activity.nil?
      end

      def delivered?
        status_type_code == DELIVERED
      end

      def status_date
        date = latest_activity&.dig(:date)
        Date.parse(date) if date
      end

      def status_type_description
        latest_activity&.dig(:status, :description)
      end

      def status_type_code
        latest_activity&.dig(:status, :type)
      end

      def as_json
        {
          status_date: status_date,
          status_type_description: status_type_description,
          status_type_code: status_type_code
        }
      end

      def latest_activity
        activities.max_by { |activity| [activity[:gmtDate], activity[:gmtTime]] }
      end

      def activities
        array(parsed_response.dig(:trackResponse, :shipment, 0, :package, 0, :activity))
      end

      private

      def root_response
        parsed_response[:trackResponse]
      end
    end
  end
end
