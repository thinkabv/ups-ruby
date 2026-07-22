# frozen_string_literal: true

module UPS
  module Parsers
    # Parses the response of a UPS Paperless Document API upload and exposes
    # the returned Forms History DocumentID(s).
    class PaperlessDocumentParser < BaseParser
      def success?
        document_ids.any?
      end

      # @return [Array<String>] all returned Forms History DocumentIDs
      def document_ids
        Array(parsed_response.dig(:UploadResponse, :FormsHistoryDocumentID, :DocumentID))
      end

      # @return [String, nil] the first DocumentID (convenience for single-file uploads)
      def document_id
        document_ids.first
      end
    end
  end
end
