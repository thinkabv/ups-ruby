# frozen_string_literal: true

module UPS
  module Parsers
    # Parses the response of a UPS Paperless Document API upload and exposes
    # the returned Forms History DocumentID.
    class PaperlessDocumentParser < BaseParser
      def success?
        !document_id.nil?
      end

      # @return [String, nil] the 26-character Forms History DocumentID
      def document_id
        id = parsed_response.dig(:UploadResponse, :FormsHistoryDocumentID, :DocumentID)
        id.is_a?(Array) ? id.first : id
      end
    end
  end
end
