require "spec_helper"

describe UPS::Builders::InternationalInvoiceBuilder do
  let(:opts) do
    {
      form_type: "07",
      invoice_number: "202405-123",
      invoice_date: "20260717",
      reason_for_export: "SALE",
      currency_code: "EUR",
      document_id: "1Z2345678901234567890ABCDE",
      products: [
        {
          description: "Thinka for KNX",
          number: 1,
          value: "789.00",
          dimensions_unit: "PCS",
          commodity_code: "84714100",
          origin_country_code: "NL"
        }
      ]
    }
  end

  subject { UPS::Builders::InternationalInvoiceBuilder.new("InternationalForms", opts).as_json["InternationalForms"] }

  it "uses the given form type" do
    expect(subject["FormType"]).must_equal "07"
  end

  it "attaches the uploaded document id" do
    expect(subject["UserCreatedForm"]).must_equal({ "DocumentID" => ["1Z2345678901234567890ABCDE"] })
  end

  it "includes the product commodity code" do
    expect(subject["Product"].first["CommodityCode"]).must_equal "84714100"
  end

  it "omits freight and discount when not provided" do
    expect(subject.key?("FreightCharges")).must_equal false
    expect(subject.key?("Discount")).must_equal false
  end

  describe "without a form type or document id" do
    before do
      opts.delete(:form_type)
      opts.delete(:document_id)
    end

    it "defaults to an invoice (01) with no user created form" do
      expect(subject["FormType"]).must_equal "01"
      expect(subject.key?("UserCreatedForm")).must_equal false
    end
  end
end
