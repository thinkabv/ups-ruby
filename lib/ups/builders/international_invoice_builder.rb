# frozen_string_literal: true

module UPS
  module Builders
    # The {InternationalInvoiceBuilder} class builds UPS JSON International invoice Objects.
    #
    # @author Calvin Hughes
    # @since 0.9.3
    # @attr [String] name The Containing Element Name
    # @attr [Hash] opts The international invoice parts
    class InternationalInvoiceBuilder < BuilderBase
      attr_accessor :name, :opts

      def initialize(name, opts = {})
        self.name = name
        self.opts = opts
      end

      def form_type
        element_with_value('FormType', opts[:form_type] || '01')
      end

      def user_created_form
        element_with_value('UserCreatedForm', 'DocumentID' => Array(opts[:document_id]))
      end

      def invoice_number
        element_with_value('InvoiceNumber', opts[:invoice_number][0..34])
      end

      def invoice_date
        element_with_value('InvoiceDate', opts[:invoice_date][0..7])
      end

      def terms_of_shipment
        element_with_value('TermsOfShipment', opts[:terms_of_shipment][0..2])
      end

      def reason_for_export
        element_with_value('ReasonForExport', opts[:reason_for_export][0..19])
      end

      def currency_code
        element_with_value('CurrencyCode', opts[:currency_code][0..2])
      end

      def freight_charge
        multi_valued('FreightCharges',
                     'MonetaryValue' => opts[:freight_charge].to_s)
      end

      def discount
        multi_valued('Discount', 'MonetaryValue' => opts[:discount].to_s)
      end

      def product_details
        opts[:products].map do |product_opts|
          product_container(product_opts)
        end
      end

      def product_container(opts = {})
        InternationalInvoiceProductBuilder.new(opts).as_json
      end

      # Returns a JSON representation of the current object
      #
      # @return [Hash] JSON representation of the current object
      def as_json
        international_form = element_with_value(name, {})
        international_form[name].merge!(form_type,
                                        invoice_date,
                                        reason_for_export,
                                        currency_code)

        international_form[name].merge!(freight_charge) if opts[:freight_charge]
        international_form[name].merge!(discount) if opts[:discount]
        international_form[name].merge!(invoice_number) if opts[:invoice_number]
        international_form[name].merge!(terms_of_shipment) if opts[:terms_of_shipment]
        international_form[name].merge!(user_created_form) if opts[:document_id]

        international_form[name]['Product'] = product_details
        international_form
      end
    end
  end
end
