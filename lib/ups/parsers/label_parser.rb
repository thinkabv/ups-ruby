# frozen_string_literal: true

require "base64"
require "tempfile"

module UPS
  module Parsers
    class LabelParser < BaseParser
      def tracking_number
        labels[0].tracking_number
      end

      def label_graphic_extension
        labels[0].label_graphic_extension
      end

      def label_graphic_image
        labels[0].label_graphic_image
      end

      def label_html_image
        labels[0].label_html_image
      end

      alias_method :graphic_extension, :label_graphic_extension
      alias_method :graphic_image, :label_graphic_image
      alias_method :html_image, :label_html_image

      def labels
        if label_results.is_a?(Array)
          return label_results.map do |label_result|
                   UPS::Models::PackageResult.new(label_result, true)
                 end
        end

        [UPS::Models::PackageResult.new(label_results, true)]
      end

      private

      def label_results
        root_response[:LabelResults]
      end

      def root_response
        parsed_response[:LabelRecoveryResponse]
      end
    end
  end
end
