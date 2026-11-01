require "spec_helper"

describe UPS::Builders::OrganisationBuilder do
  subject { UPS::Builders::OrganisationBuilder.new(builder_name, options) }

  describe "when the name is anything" do
    let(:builder_name) { "Hamburger" }
    let(:options) { {} }

    it "disables option to skip Ireland state validation" do
      expect(subject.opts[:skip_ireland_state_validation]).must_equal false
    end
  end

  describe "when given options" do
    let(:builder_name) { "Google Inc." }
    let(:options) {
      {
        company_name: "Google Inc.",
        attention_name: "Sergie Bryn",
        phone_number: "0207 031 3000",
        address_line_1: "1 St Giles High Street",
        address_line_2: "Parktown House",
        city: "London",
        state: "England",
        postal_code: "WC2H 8AG",
        country: "GB",
        sender_tax_number: "123456"
      }
    }

    it "returns correct company name" do
      expect(subject.company_name).must_equal({"Name" => "Google Inc."})
    end

    it "returns correct attention name" do
      expect(subject.attention_name).must_equal({"AttentionName" => "Sergie Bryn"})
    end

    it "returns correct tax number" do
      expect(subject.tax_identification_number).must_equal({"TaxIdentificationNumber" => "123456"})
    end

    it "returns correct phone number" do
      expect(subject.phone_number).must_equal({"Phone" => {"Number" => "0207 031 3000"}})
    end

    it "returns correct address" do
      expect(subject.address).must_equal({
        "Address" => {
          "AddressLine" => [
            "1 St Giles High Street",
            "Parktown House"
          ],
          "City" => "London",
          "StateProvinceCode" => "",
          "PostalCode" => "WC2H 8AG",
          "CountryCode" => "GB"
        }
      })
    end
  end
end
