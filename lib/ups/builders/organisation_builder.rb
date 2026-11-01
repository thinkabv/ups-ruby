# frozen_string_literal: true

module UPS
  module Builders
    # The {OrganisationBuilder} class builds UPS JSON Organization Objects.
    #
    # @author Paul Trippett
    # @since 0.1.0
    # @attr [String] name The Containing Element Name
    # @attr [Hash] opts The Organization and Address Parts
    class OrganisationBuilder < BuilderBase
      attr_accessor :name, :opts

      # Initializes a new {OrganisationBuilder} object
      #
      # @param [Hash] opts The Organization and Address Parts
      # @option opts [String] :company_name Company Name
      # @option opts [String] :phone_number Phone Number
      # @option opts [String] :address_line_1 Address Line 1
      # @option opts [String] :city City
      # @option opts [String] :state State
      # @option opts [String] :postal_code Zip or Postal Code
      # @option opts [String] :country Country
      def initialize(name, opts = {})
        self.name = name
        self.opts = opts
        self.opts[:skip_ireland_state_validation] = false
      end

      # Returns JSON representation of company name
      #
      # @return [Hash] JSON representation of company name
      def company_name
        element_with_value("Name", opts[:company_name][0..34])
      end

      # Returns JSON representation of phone number
      #
      # @return [Hash] JSON representation of phone number
      def phone_number
        multi_valued("Phone", "Number" => opts[:phone_number][0..14])
      end

      # Returns JSON representation of attention name
      #
      # @return [Hash] JSON representation of attention name
      def attention_name
        element_with_value("AttentionName", opts[:attention_name][0..34])
      end

      # Returns JSON representation of tax identification number of the company
      #
      # @return [Hash] JSON representation of tax identification number
      def tax_identification_number
        element_with_value("TaxIdentificationNumber",
          opts[:sender_tax_number] || "")
      end

      # Returns an JSON representation of address
      #
      # @return [Hash] An instance of {AddressBuilder} containing the
      #   address
      def address
        AddressBuilder.new(opts).as_json
      end

      def as_json
        org = element_with_value(name, {})
        org[name].merge!(company_name,
          phone_number,
          attention_name,
          tax_identification_number,
          address)

        org
      end
    end
  end
end
