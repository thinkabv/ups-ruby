require "spec_helper"

describe UPS::Parsers::PaperlessDocumentParser do
  subject { UPS::Parsers::PaperlessDocumentParser.new(response) }

  describe "with a single DocumentID" do
    let(:response) do
      { UploadResponse: { FormsHistoryDocumentID: { DocumentID: ["1Z2345678901234567890ABCDE"] } } }.to_json
    end

    it "extracts the DocumentID" do
      expect(subject.document_id).must_equal "1Z2345678901234567890ABCDE"
      expect(subject.document_ids).must_equal ["1Z2345678901234567890ABCDE"]
    end

    it "is successful" do
      expect(subject.success?).must_equal true
    end
  end

  describe "with multiple DocumentIDs" do
    let(:response) do
      { UploadResponse: { FormsHistoryDocumentID: { DocumentID: %w[AAA BBB] } } }.to_json
    end

    it "returns all DocumentIDs" do
      expect(subject.document_ids).must_equal %w[AAA BBB]
      expect(subject.document_id).must_equal "AAA"
    end
  end

  describe "without a DocumentID" do
    let(:response) { { UploadResponse: {} }.to_json }

    it "is not successful and has no DocumentID" do
      expect(subject.success?).must_equal false
      expect(subject.document_ids).must_equal []
      expect(subject.document_id).must_be_nil
    end
  end
end
