# frozen_string_literal: true

module UPS
  module Builders
    # The {InternationalProductInvoiceBuilder} class builds UPS International invoice Produt Objects.
    #
    # @author Calvin Hughes
    # @since 0.9.3
    # @attr [Hash] opts The international invoice product parts
    class InternationalInvoiceProductBuilder < BuilderBase
      attr_accessor :opts

      def initialize(opts = {})
        self.opts = opts
      end

      def description
        element_with_value("Description", opts[:description])
      end

      def number
        element_with_value("Number", opts[:number].to_s)
      end

      def value
        element_with_value("Value", opts[:value].to_s)
      end

      def dimensions_unit
        unit_of_measurement(opts[:dimensions_unit])
      end

      def part_number
        element_with_value("PartNumber", opts[:part_number][0..9])
      end

      def commodity_code
        element_with_value("CommodityCode", opts[:commodity_code][0..14])
      end

      def origin_country_code
        element_with_value("OriginCountryCode", opts[:origin_country_code][0..2])
      end

      def product_unit
        unit = element_with_value("Unit", {})
        unit["Unit"].merge!(number, value, dimensions_unit)

        unit
      end

      # Returns a JSON representation of the current object
      #
      # @return [Hash] JSON representation of the current object
      def as_json
        product = {}
        product.merge!(description,
          origin_country_code,
          product_unit)

        if opts[:commodity_code]
          product.merge!(commodity_code)
        end
        if opts[:part_number]
          product.merge!(part_number)
        end

        product
      end
    end
  end
end
