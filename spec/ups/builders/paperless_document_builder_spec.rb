require "spec_helper"
require "base64"

describe UPS::Builders::PaperlessDocumentBuilder do
  subject do
    UPS::Builders::PaperlessDocumentBuilder.new.tap do |builder|
      builder.add_shipper_number("8Y7F40")
      builder.add_file(file: "PDF-BYTES", file_name: "invoice-1.pdf")
    end
  end

  let(:upload) { subject.as_json["UploadRequest"] }

  it "sets the shipper number" do
    expect(subject.shipper_number).must_equal "8Y7F40"
    expect(upload["ShipperNumber"]).must_equal "8Y7F40"
  end

  it "base64 encodes the file as a commercial invoice" do
    form = upload["UserCreatedForm"].first
    expect(form["UserCreatedFormFileName"]).must_equal "invoice-1.pdf"
    expect(form["UserCreatedFormFileFormat"]).must_equal "pdf"
    expect(form["UserCreatedFormDocumentType"]).must_equal "002"
    expect(Base64.strict_decode64(form["UserCreatedFormFile"])).must_equal "PDF-BYTES"
  end
end
