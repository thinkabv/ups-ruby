# frozen_string_literal: true

module UPS
  module Models
    class PackageResult
      attr_reader :package_result

      def initialize(package_result, is_label = false)
        @package_result = package_result
        @is_label = is_label
      end

      def tracking_number
        package_result[:TrackingNumber]
      end

      def label_graphic_extension
        if @is_label
          return ".#{package_result[:LabelImage][:LabelImageFormat][:Code].downcase}"
        end

        ".#{package_result[:ShippingLabel][:ImageFormat][:Code].downcase}"
      end

      def label_graphic_image
        if @is_label
          return Utils.base64_to_file(package_result[:LabelImage][:GraphicImage],
            label_graphic_extension)
        end

        Utils.base64_to_file(package_result[:ShippingLabel][:GraphicImage],
          label_graphic_extension)
      end

      def label_html_image
        if @is_label
          return Utils.base64_to_file(package_result[:LabelImage][:HTMLImage],
            label_graphic_extension)
        end

        Utils.base64_to_file(package_result[:ShippingLabel][:HTMLImage],
          label_graphic_extension)
      end

      def form
        package_result[:Form]
      end
    end
  end
end
