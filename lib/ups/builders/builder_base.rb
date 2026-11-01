# frozen_string_literal: true

module UPS
  module Builders
    # The {BuilderBase} class builds UPS JSON Objects.
    #
    # @author Paul Trippett
    # @since 0.1.0
    # @abstract
    # @attr [Hash] root The JSON Root
    # @attr [Hash] shipment_root The JSON Shipment Element
    # @attr [Hash] shipment_service_options The JSON Shipment Services Element
    class BuilderBase
      include Exceptions

      attr_accessor :name,
        :root,
        :shipment_root,
        :shipment_service_options

      # Initializes a new {BuilderBase} object
      #
      # @param [String] request_name The name of the request
      # @return [void]
      def initialize(request_name)
        self.name = request_name
        self.root = {}
        self.shipment_root = {}
        self.shipment_service_options = {}

        yield self if block_given?
      end

      # Adds a Request section to JSON body being built
      #
      # @param [String] option The UPS API Option
      # @return [void]
      def add_request(option)
        root.merge!(multi_valued("Request", "RequestOption" => option))
      end

      # Adds payment information for the shipment
      #
      # @param [String] ship_number The UPS Shipper Number
      # @return [void]
      def add_payment_information(ship_number)
        shipment_root.merge!({
          "PaymentInformation" => {
            "ShipmentCharge" => {
              "Type" => "01",
              "BillShipper" => {
                "AccountNumber" => ship_number
              }
            }
          }
        })
      end

      # Adds a Shipper section to the JSON body being built
      #
      # @param [Hash] opts A Hash of data to build the requested section
      # @option opts [String] :company_name Company Name
      # @option opts [String] :phone_number Phone Number
      # @option opts [String] :address_line_1 Address Line 1
      # @option opts [String] :city City
      # @option opts [String] :state State
      # @option opts [String] :postal_code Zip or Postal Code
      # @option opts [String] :country Country
      # @option opts [String] :shipper_number UPS Account Number
      # @return [void]
      def add_shipper(opts = {})
        shipment_root.merge!(ShipperBuilder.new(opts).as_json)
      end

      # Adds a ShipTo section to the JSON body being built
      #
      # @param [Hash] opts A Hash of data to build the requested section
      # @option opts [String] :company_name Company Name
      # @option opts [String] :phone_number Phone Number
      # @option opts [String] :address_line_1 Address Line 1
      # @option opts [String] :city City
      # @option opts [String] :state State
      # @option opts [String] :postal_code Zip or Postal Code
      # @option opts [String] :country Country
      # @return [void]
      def add_ship_to(opts = {})
        shipment_root.merge!(OrganisationBuilder.new("ShipTo", opts).as_json)
      end

      # Adds a ShipFrom section to the JSON body being built
      #
      # @param [Hash] opts A Hash of data to build the requested section
      # @option opts [String] :company_name Company Name
      # @option opts [String] :phone_number Phone Number
      # @option opts [String] :address_line_1 Address Line 1
      # @option opts [String] :city City
      # @option opts [String] :state State
      # @option opts [String] :postal_code Zip or Postal Code
      # @option opts [String] :country Country
      # @option opts [String] :shipper_number UPS Account Number
      # @return [void]
      def add_ship_from(opts = {})
        shipment_root.merge!(OrganisationBuilder.new("ShipFrom", opts).as_json)
      end

      # Adds a specific packaging type to the shipment
      #
      def customer_supplied_packaging
        {code: "02", description: "Customer Supplied Package"}
      end

      # Adds a RateInformation/NegotiatedRatesIndicator section to the JSON
      # body being built
      #
      # @return [void]
      def add_rate_information
        shipment_root.merge!(multi_valued("ShipmentRatingOptions",
          "NegotiatedRatesIndicator" => "1"))
      end

      # Adds a Delivery Confirmation DCIS Type to the shipment service options
      #
      # @param [String] dcis_type DCIS type
      # @return [void]
      def add_shipment_delivery_confirmation(dcis_type)
        shipment_service_options.merge!(multi_valued("DeliveryConfirmation",
          "DCISType" => dcis_type))
      end

      # Adds Direct Delivery Only indicator to the shipment service options
      #
      # @return [void]
      def add_shipment_direct_delivery_only
        shipment_service_options.merge!(element_with_value(
          "DirectDeliveryOnlyIndicator", ""
        ))
      end

      # Returns JSON representation of the object
      #
      # @return [Hash] JSON representation of the object
      def as_json
        all = element_with_value(name, {})
        all[name].merge!(root)

        if shipment_service_options.size > 0
          shipment_root.merge!({"ShipmentServiceOptions" => shipment_service_options})
        end

        all[name]["Shipment"] = shipment_root
        all
      end

      private

      def package_weight(weight, unit)
        pkg_weight = element_with_value("PackageWeight", {})
        pkg_weight["PackageWeight"].merge!(unit_of_measurement(unit),
          element_with_value("Weight",
            weight.to_s))

        pkg_weight
      end

      def package_dimensions(dimensions)
        dim = element_with_value("Dimensions", {})
        dim["Dimensions"].merge!(unit_of_measurement(dimensions[:unit]),
          element_with_value("Length",
            dimensions[:length].to_s[0..3]),
          element_with_value("Width",
            dimensions[:width].to_s[0..3]),
          element_with_value("Height",
            dimensions[:height].to_s[0..3]))

        dim
      end

      def unit_of_measurement(unit)
        multi_valued("UnitOfMeasurement", "Code" => unit.to_s, "Description" => unit.to_s)
      end

      def element_with_value(name, value)
        {
          name => value
        }
      end

      def code_description(name, code, description)
        multi_valued(name, "Code" => code, "Description" => description)
      end

      def multi_valued(name, params)
        {
          name => params.each { |key, value| element_with_value(key, value) }
        }
      end
    end
  end
end
