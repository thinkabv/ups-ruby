# frozen_string_literal: true

module UPS
  autoload :SERVICES, "ups/services"
  autoload :PACKAGING, "ups/packaging"

  autoload :Version, "ups/version"
  autoload :Connection, "ups/connection"
  autoload :Exceptions, "ups/exceptions"

  autoload :Utils, "ups/utils"

  autoload :Data, "ups/data"
  module Data
    autoload :US_STATES, "ups/data/us_states"
    autoload :CANADIAN_STATES, "ups/data/canadian_states"
    autoload :IE_COUNTIES, "ups/data/ie_counties"
    autoload :IE_COUNTY_PREFIXES, "ups/data/ie_county_prefixes"
  end

  module Models
    autoload :PackageResult, "ups/models/package_result"
  end

  module Parsers
    autoload :BaseParser, "ups/parsers/base_parser"
    autoload :ParserBase, "ups/parsers/parser_base"
    autoload :RatesParser, "ups/parsers/rates_parser"
    autoload :RateParser, "ups/parsers/rate_parser"
    autoload :ShipParser, "ups/parsers/ship_parser"
    autoload :TrackParser, "ups/parsers/track_parser"
    autoload :LabelParser, "ups/parsers/label_parser"
    autoload :PaperlessDocumentParser, "ups/parsers/paperless_document_parser"
  end

  module Builders
    autoload :BuilderBase, "ups/builders/builder_base"
    autoload :RateBuilder, "ups/builders/rate_builder"
    autoload :AddressBuilder, "ups/builders/address_builder"
    autoload :ShipBuilder, "ups/builders/ship_builder"
    autoload :InternationalInvoiceBuilder, "ups/builders/international_invoice_builder"
    autoload :InternationalInvoiceProductBuilder, "ups/builders/international_invoice_product_builder"
    autoload :OrganisationBuilder, "ups/builders/organisation_builder"
    autoload :ShipperBuilder, "ups/builders/shipper_builder"
    autoload :LabelRecoveryRequestBuilder, "ups/builders/label_recovery_request_builder"
    autoload :PaperlessDocumentBuilder, "ups/builders/paperless_document_builder"
  end
end
