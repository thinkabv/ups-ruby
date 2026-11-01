# frozen_string_literal: true

module UPS
  module Builders
    # The {RateBuilder} class builds UPS Rate Objects.
    #
    # @author Paul Trippett
    # @since 0.1.0
    class RateBuilder < BuilderBase
      # Initializes a new {RateBuilder} object
      #
      def initialize
        super("RateRequest")

        add_request "Shop"
      end

      # Adds a Package section to the JSON body being built
      #
      # @param [Hash] opts A Hash of data to build the requested section
      # @return [void]
      def add_package(opts = {})
        if shipment_root["Package"].nil?
          shipment_root["Package"] = []
        end

        item = {}
        item.merge!(packaging_type(opts[:packaging_type] || customer_supplied_packaging))
        item.merge!(package_weight(opts[:weight], opts[:unit]))

        if opts[:dimensions]
          item.merge!(package_dimensions(opts[:dimensions]))
        end

        shipment_root["Package"] << item
      end

      # Adds ReturnService to JSON body being built
      #
      # @param [String] service_code The code for Return Service type
      # @return [void]
      def add_return_service(service_code, service_description = "")
        shipment_service_options.merge!(code_description("ReturnService",
          service_code,
          service_description))
      end

      private

      def packaging_type(packaging_options_hash)
        code_description "PackagingType", packaging_options_hash[:code],
          packaging_options_hash[:description]
      end
    end
  end
end
