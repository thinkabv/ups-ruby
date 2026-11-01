require "spec_helper"
require "date"

describe UPS::Connection do
  before { Excon.defaults[:mock] = true }
  after { Excon.stubs.clear }

  let(:stub_path) { File.expand_path("../../stubs", __dir__) }
  let(:connection) do
    UPS::Connection.new(test_mode: true).tap { |connection| connection.authorize("ACCOUNT", "CLIENT", "SECRET", true) }
  end

  def schedule
    connection.pickup do |pickup|
      pickup.add_shipper_account "ACCOUNT", "NL"
      pickup.add_pickup_window Date.new(2026, 2, 6), "0900", "1800"
      pickup.add_pickup_address company_name: "Example B.V.", address_line_1: "Dam 1", city: "Amsterdam",
        postal_code: "1012 JS", country: "NL", phone_number: "+31 20 123 4567"
      pickup.add_piece service_code: "11", quantity: 2, destination_country: "DE"
      pickup.add_total_weight 1.4
      pickup.add_notification_email "ops@example.com"
    end
  end

  describe "a scheduled pickup" do
    let(:requests) { [] }

    before do
      Excon.stub({method: :post, path: UPS::Connection::PICKUP_PATH}, lambda { |params|
        requests << JSON.parse(params[:body])
        {status: 200, body: File.read("#{stub_path}/pickup_success.json")}
      })
    end

    it "returns the pickup request number" do
      response = schedule

      expect(response.success?).must_equal true
      expect(response.reference).must_equal "GPE58AB041C"
      expect(response.rate_status_description).must_equal "Rate available"
    end

    it "sends the request UPS documents" do
      schedule

      body = requests.first.fetch("PickupCreationRequest")
      expect(body["Request"]).must_equal({})
      expect(body["RatePickupIndicator"]).must_equal "Y"
      expect(body["PaymentMethod"]).must_equal "01"
      expect(body["Shipper"]).must_equal("Account" => {"AccountNumber" => "ACCOUNT", "AccountCountryCode" => "NL"})
      expect(body["PickupDateInfo"]).must_equal("PickupDate" => "20260206", "ReadyTime" => "0900", "CloseTime" => "1800")
      expect(body["PickupAddress"]["CompanyName"]).must_equal "Example B.V."
      expect(body["PickupAddress"]["ContactName"]).must_equal "Example B.V."
      expect(body["PickupAddress"]["AddressLine"]).must_equal ["Dam 1"]
      expect(body["PickupAddress"]["PostalCode"]).must_equal "1012JS"
      expect(body["PickupAddress"]["ResidentialIndicator"]).must_equal "N"
      expect(body["PickupAddress"]["Phone"]).must_equal("Number" => "31201234567")
      expect(body["PickupPiece"]).must_equal [{"ServiceCode" => "011", "Quantity" => "2", "DestinationCountryCode" => "DE", "ContainerCode" => "01"}]
      expect(body["TotalWeight"]).must_equal("Weight" => "1.4", "UnitOfMeasurement" => "KGS")
      expect(body["Notification"]).must_equal("ConfirmationEmailAddress" => "ops@example.com")
    end
  end

  describe "a refused pickup" do
    before do
      Excon.stub({method: :post, path: UPS::Connection::PICKUP_PATH}, {status: 400, body: File.read("#{stub_path}/pickup_failure.json")})
    end

    it "reports the error" do
      response = schedule

      expect(response.success?).must_equal false
      expect(response.reference).must_be_nil
      expect(response.errors.map(&:code)).must_equal ["9510124"]
      expect(response.error_description).must_equal "Missing or invalid pickup date."
    end
  end
end
