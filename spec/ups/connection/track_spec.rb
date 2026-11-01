require "spec_helper"
require "support/shipping_options"

describe UPS::Connection do
  include ShippingOptions

  before do
    Excon.defaults[:mock] = true
  end

  after do
    Excon.stubs.clear
  end

  let(:stub_path) { File.expand_path("../../../stubs", __FILE__) }
  let(:server) { UPS::Connection.new(test_mode: true) }
  let(:supplied_package) { package }

  describe "if tracking shipment" do
    subject do
      server.authorize ENV["UPS_ACCOUNT_NUMBER"], ENV["UPS_CLIENT_ID"], ENV["UPS_CLIENT_SECRET"], true
      server.track "1Z12345E6692804405"
    end

    describe "successful track response" do
      before do
        Excon.stub({method: :get}, lambda { |params|
          {body: File.read("#{stub_path}/track_success.json"), status: 200}
        })
      end

      it "returns the tracking status" do
        expect(subject.as_json).wont_be_empty
        expect(subject.as_json).must_equal(
          status_date: Date.parse("2010-06-10"),
          status_type_description: "DELIVERED",
          status_type_code: "D"
        )
      end
    end
  end

  describe "if tracking shipment with no tracking number" do
    subject do
      server.authorize ENV["UPS_ACCOUNT_NUMBER"], ENV["UPS_CLIENT_ID"], ENV["UPS_CLIENT_SECRET"], true
      server.track ""
    end

    it "raises an error" do
      assert_raises UPS::Exceptions::InvalidAttributeError do
        subject
      end
    end
  end
end
