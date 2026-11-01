# frozen_string_literal: true

module UPS
  module Parsers
    class PaperlessDocumentParser < BaseParser
      def success?
        super && document_ids.any?
      end

      def document_ids
        Array(root_response&.dig(:FormsHistoryDocumentID, :DocumentID))
      end

      def document_id
        document_ids.first
      end

      private

      def root_response
        parsed_response[:UploadResponse]
      end
    end
  end
end
