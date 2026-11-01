# frozen_string_literal: true

module UPS
  module Builders
    # The {LabelRecoveryRequest} class builds UPS JSON LabelRecoveryRequest Objects.
    #
    # @author Ed Phillips
    # @since 0.17.1
    class LabelRecoveryRequestBuilder < BuilderBase
      # Initializes a new {LabelRecoveryRequestBuilder} object
      #
      def initialize
        super("LabelRecoveryRequest")

        add_request "LabelRecovery"
      end

      # Adds a LabelImageFormat to the JSON body being built
      # according to user inputs
      #
      # @param [String] image_format_code Customer supplied image format.
      # @return [void]
      def add_label_specification(image_format_code)
        root.merge!(multi_valued("LabelSpecification",
          multi_valued("LabelImageFormat", "Code" => image_format_code.upcase)))
      end

      # Adds a TrackingNumber to the JSON body being built
      # according to user inputs
      #
      # @return [void]
      def add_tracking_number(number)
        root.merge!(element_with_value("TrackingNumber", number))
      end

      # Adds a ReferenceNumber to the JSON body being built
      # according to user inputs
      #
      # @param [String] value Customer supplied reference number.
      # @return [void]
      def add_reference_number(value)
        if !root.key? "ReferenceValues"
          root.merge!(element_with_value("ReferenceValues", {}))
        end

        root["ReferenceValues"].merge!(multi_valued("ReferenceNumber", "Value" => value))
      end

      # Adds a ShipperNumber to the JSON body being built
      # according to user inputs
      #
      # @param [String] shipper_number Shipper's six digit account number
      # @return [void]
      def add_shipper_number(shipper_number)
        if !root.key? "ReferenceValues"
          root.merge!(element_with_value("ReferenceValues", {}))
        end

        root["ReferenceValues"].merge!(element_with_value("ShipperNumber", shipper_number))
      end
    end
  end
end
