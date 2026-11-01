# frozen_string_literal: true

module UPS
  module Builders
    # The {ShipperBuilder} class builds UPS Organization Objects.
    #
    # @author Paul Trippett
    # @since 0.1.0
    # @attr [String] name The Containing Element Name
    # @attr [Hash] opts The Shipper and Address Parts
    class ShipperBuilder < BuilderBase
      attr_accessor :name, :opts

      # Initializes a new {ShipperBuilder} object
      #
      # @param [Hash] opts The Shipper and Address Parts
      # @option opts [String] :company_name Company Name
      # @option opts [String] :phone_number Phone Number
      # @option opts [String] :address_line_1 Address Line 1
      # @option opts [String] :city City
      # @option opts [String] :state State
      # @option opts [String] :postal_code Zip or Postal Code
      # @option opts [String] :country Country
      def initialize(opts = {})
        self.name = name
        self.opts = opts
      end

      # Returns JSON representation of shipper name
      #
      # @return [Hash] JSON representation for shipper name
      def shipper_name
        element_with_value("Name", opts[:company_name][0..34])
      end

      # Returns JSON representation of shipper phone number
      #
      # @return [Hash] JSON representation of shipper phone number
      def phone_number
        multi_valued("Phone", "Number" => opts[:phone_number][0..14])
      end

      # Returns JSON representation of shipper account number
      #
      # @return [Hash] JSON representation of shipper account number
      def shipper_number
        element_with_value("ShipperNumber", opts[:shipper_number] || "")
      end

      # Returns JSON representation of shipper address
      #
      # @return [Hash] JSON representation of shipper address
      def address
        AddressBuilder.new(opts).as_json
      end

      # Returns JSON representation of shipper attention name
      #
      # @return [Hash] JSON representation of shipper attention name
      def attention_name
        element_with_value("AttentionName", opts[:attention_name] || "")
      end

      # Returns JSON representation of shipper tax identification number
      #
      # @return [Hash] JSON representation of shipper tax identification number
      def tax_identification_number
        element_with_value("TaxIdentificationNumber", opts[:sender_tax_number] || "")
      end

      # Returns JSON representation of email address
      #
      # @return [Hash] JSON representation of email address
      def email_address
        element_with_value("EMailAddress", opts[:email_address][0..49])
      end

      # Returns JSON representation of the shipper object
      #
      # @return [Hash] JSON representation of the shipper object
      def as_json
        sh = element_with_value("Shipper", {})
        sh["Shipper"].merge!(shipper_name,
          phone_number,
          shipper_number,
          address,
          attention_name,
          tax_identification_number)

        if opts[:email_address]
          sh["Shipper"].merge!(email_address)
        end

        sh
      end
    end
  end
end
