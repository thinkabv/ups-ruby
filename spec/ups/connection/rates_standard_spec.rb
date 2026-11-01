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

  describe "if requesting rates" do
    subject do
      server.authorize ENV["UPS_ACCOUNT_NUMBER"], ENV["UPS_CLIENT_ID"], ENV["UPS_CLIENT_SECRET"], true
      server.rates do |rate_builder|
        rate_builder.add_shipper shipper
        rate_builder.add_ship_from shipper
        rate_builder.add_ship_to ship_to
        rate_builder.add_package supplied_package
      end
    end

    describe "successful rates response" do
      before do
        Excon.stub(method: :post) do |params|
          case params[:path]
          when UPS::Connection::RATE_PATH
            {body: File.read("#{stub_path}/rates_success.json"), status: 200}
          end
        end
      end

      it "returns standard rates" do
        expect(subject.rated_shipments).wont_be_empty
        expect(subject.rated_shipments).must_equal [
          {
            service_code: "11",
            service_name: "UPS Standard",
            total: {
              currency: "GBP",
              amount: "25.03"
            }
          },
          {
            service_code: "65",
            service_name: "UPS Saver",
            total: {
              currency: "GBP",
              amount: "45.82"
            }
          },
          {
            service_code: "54",
            service_name: "Express Plus",
            total: {
              currency: "GBP",
              amount: "82.08"
            }
          },
          {
            service_code: "07",
            service_name: "Express",
            total: {
              currency: "GBP",
              amount: "47.77"
            }
          }
        ]
      end

      describe "when API responds with a single rate" do
        before do
          Excon.stub(method: :post) do |params|
            case params[:path]
            when UPS::Connection::RATE_PATH
              {body: File.read("#{stub_path}/rates_success_single_rate.json"), status: 200}
            end
          end
        end

        it "returns rates" do
          expect(subject.rated_shipments).wont_be_empty
          expect(subject.rated_shipments).must_equal [
            {
              service_code: "11",
              service_name: "UPS Standard",
              total: {
                currency: "GBP",
                amount: "25.03"
              }
            }
          ]
        end
      end
    end

    describe "when ups packaging type is specified" do
      let(:supplied_package) { package_with_carrier_packaging }

      before do
        Excon.stub(method: :post) do |params|
          case params[:path]
          when UPS::Connection::RATE_PATH
            {body: File.read("#{stub_path}/rates_success_with_packaging_type.json"), status: 200}
          end
        end
      end

      it "returns rates" do
        expect(subject.rated_shipments).wont_be_empty
        expect(subject.rated_shipments).must_equal [
          {
            service_code: "07",
            service_name: "Express",
            total: {
              currency: "GBP",
              amount: "172.77"
            }
          },
          {
            service_code: "65",
            service_name: "UPS Saver",
            total: {
              currency: "GBP",
              amount: "162.38"
            }
          },
          {
            service_code: "54",
            service_name: "Express Plus",
            total: {
              currency: "GBP",
              amount: "229.18"
            }
          }
        ]
      end
    end

    describe "error rates response" do
      describe "with single error response" do
        before do
          Excon.stub(method: :post) do |params|
            case params[:path]
            when UPS::Connection::RATE_PATH
              {body: File.read("#{stub_path}/rates_error_single_error.json"), status: 200}
            end
          end
        end

        it "returns error" do
          expect(subject).wont_equal false
          expect(subject.success?).must_equal false
          expect(subject.error_description).must_equal "Missing or invalid shipper number."
        end
      end

      describe "with multi error response" do
        before do
          Excon.stub(method: :post) do |params|
            case params[:path]
            when UPS::Connection::RATE_PATH
              {body: File.read("#{stub_path}/rates_error_multi_error.json"), status: 200}
            end
          end
        end

        it "returns error" do
          expect(subject).wont_equal false
          expect(subject.success?).must_equal false
          expect(subject.error_description).must_equal "Packages must weigh more than zero kg."
        end
      end
    end
  end
end
