# frozen_string_literal: true

require "base64"

module UPS
  module Builders
    # The {PaperlessDocumentBuilder} class builds the UploadRequest JSON body
    # for the UPS Paperless Document API (uploading e.g. a commercial invoice
    # PDF to Forms History).
    #
    # @author Thinka
    class PaperlessDocumentBuilder
      # UserCreatedFormDocumentType: 002 = Commercial Invoice
      COMMERCIAL_INVOICE = "002"

      attr_reader :shipper_number

      def initialize
        @documents = []
      end

      # Sets the UPS account number (also sent as the ShipperNumber header).
      #
      # @param [String] shipper_number UPS account number
      # @return [void]
      def add_shipper_number(shipper_number)
        @shipper_number = shipper_number
      end

      # Adds a document to be uploaded.
      #
      # @param [String] file The raw file bytes (will be base64 encoded)
      # @param [String] file_name The file name
      # @param [String] file_format The file extension (default 'pdf')
      # @param [String] document_type The UPS document type code (default '002')
      # @return [self]
      def add_file(file:, file_name:, file_format: "pdf", document_type: COMMERCIAL_INVOICE)
        @documents << {
          "UserCreatedFormFileName" => file_name,
          "UserCreatedFormFile" => Base64.strict_encode64(file),
          "UserCreatedFormFileFormat" => file_format,
          "UserCreatedFormDocumentType" => document_type
        }
        self
      end

      # Returns a JSON representation of the upload request.
      #
      # @return [Hash]
      def as_json
        {
          "UploadRequest" => {
            "Request" => {},
            "ShipperNumber" => shipper_number,
            "UserCreatedForm" => @documents
          }
        }
      end
    end
  end
end
