# frozen_string_literal: true

require "base64"
require "tempfile"

module UPS
  module Parsers
    class ShipParser < BaseParser
      def tracking_number
        packages[0].tracking_number
      end

      def label_graphic_extension
        packages[0].label_graphic_extension
      end

      def label_graphic_image
        packages[0].label_graphic_image
      end

      def label_html_image
        packages[0].label_html_image
      end

      def has_form_graphic?
        packages[0].form != nil
      end

      def form_graphic
        packages[0].form
      end

      alias_method :graphic_extension, :label_graphic_extension
      alias_method :graphic_image, :label_graphic_image
      alias_method :html_image, :label_html_image

      def form_graphic_extension
        return unless has_form_graphic?

        ".#{form_graphic[:Image][:ImageFormat][:Code].downcase}"
      end

      def form_graphic_image
        return unless has_form_graphic?

        Utils.base64_to_file(form_graphic[:Image][:GraphicImage],
          form_graphic_extension)
      end

      def packages
        package_results.map do |package_result|
          UPS::Models::PackageResult.new(package_result)
        end
      end

      private

      def package_results
        shipment_results[:PackageResults]
      end

      def shipment_results
        root_response[:ShipmentResults]
      end

      def root_response
        parsed_response[:ShipmentResponse]
      end
    end
  end
end
