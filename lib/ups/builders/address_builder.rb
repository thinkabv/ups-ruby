# frozen_string_literal: true

module UPS
  module Builders
    # The {AddressBuilder} class builds UPS JSON Address Objects.
    #
    # @author Paul Trippett
    # @since 0.1.0
    # @attr [Hash] opts The Address Parts
    class AddressBuilder < BuilderBase
      attr_accessor :opts

      # Initializes a new {AddressBuilder} object
      #
      # @param [Hash] opts The Address Parts
      # @option opts [String] :address_line_1 Address Line 1
      # @option opts [String] :city City
      # @option opts [String] :state State
      # @option opts [String] :postal_code Zip or Postal Code
      # @option opts [String] :country Country
      # @raise [InvalidAttributeError] If the passed :state is nil or an
      #   empty string and the :country is IE
      def initialize(opts = {})
        self.opts = opts
        validate
      end

      # Changes :state part of the address based on UPS requirements
      #
      # @raise [InvalidAttributeError] If the passed :state is nil or an
      #   empty string and the :country is IE
      # @return [void]
      def validate
        opts[:state] = case opts[:country].to_s.downcase
        when "us"
          normalize_us_state(opts[:state])
        when "ca"
          normalize_ca_state(opts[:state])
        when "ie"
          if opts[:skip_ireland_state_validation]
            "_" # UPS requires at least one character for Ireland
          else
            UPS::Data.ie_state_matcher(opts[:state])
          end
        else
          ""
        end
      end

      # Changes :state based on UPS requirements for US Addresses
      #
      # @param [String] state The US State to normalize
      # @return [String]
      def normalize_us_state(state)
        if state.to_str.length > 2
          UPS::Data::US_STATES[state] || state
        else
          state.upcase
        end
      end

      # Changes :state based on UPS requirements for CA Addresses
      #
      # @param [String] state The CA State to normalize
      # @return [String]
      def normalize_ca_state(state)
        if state.to_str.length > 2
          UPS::Data::CANADIAN_STATES[state] || state
        else
          state.upcase
        end
      end

      # Returns JSON representation of main address line
      #
      # @return [Hash] JSON representation of main address line
      def address_line_1
        opts[:address_line_1][0..34]
      end

      # Returns JSON representation of secondary address line
      #
      # @return [Hash] JSON representation of secondary address line
      def address_line_2
        opts[:address_line_2][0..34]
      end

      # Returns JSON representation of city
      #
      # @return [Hash] JSON representation of the city address part
      def city
        element_with_value("City", opts[:city][0..29])
      end

      # Returns JSON representation of state
      #
      # @return [Hash] JSON representation of the state address part
      def state
        element_with_value("StateProvinceCode", opts[:state][0..4])
      end

      # Returns JSON representation of postal code
      #
      # @return [Hash] JSON representation of the postal code address part
      def postal_code
        element_with_value("PostalCode", opts[:postal_code][0..8])
      end

      # Returns JSON representation of country
      #
      # @return [Hash] JSON representation of the country address part
      def country
        element_with_value("CountryCode", opts[:country][0..1])
      end

      # Returns JSON representation of the full address
      #
      # @return [Hash] JSON representation of the full address
      def as_json
        addr = element_with_value("Address", {})
        addr["Address"].merge!(city,
          country)

        addr_lines = []
        if opts[:address_line_1]
          addr_lines << address_line_1
        end
        if opts[:address_line_2]
          addr_lines << address_line_2
        end

        if addr_lines.any?
          addr["Address"].merge!(element_with_value("AddressLine", addr_lines))
        end

        if opts[:state]
          addr["Address"].merge!(state)
        end

        if opts[:postal_code]
          addr["Address"].merge!(postal_code)
        end

        addr
      end
    end
  end
end
