require "spec_helper"
require "tempfile"
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

  describe "if requesting a shipment" do
    describe "single package shipment" do
      before do
        Excon.stub(method: :post) do |params|
          case params[:path]
          when UPS::Connection::SHIP_PATH
            {
              body: File.read("#{stub_path}/ship_single_success.json"), status: 200
            }
          end
        end
      end

      subject do
        server.authorize ENV["UPS_ACCOUNT_NUMBER"], ENV["UPS_CLIENT_ID"], ENV["UPS_CLIENT_SECRET"], true
        server.ship do |shipment_builder|
          shipment_builder.add_shipper shipper
          shipment_builder.add_ship_from shipper
          shipment_builder.add_ship_to ship_to
          shipment_builder.add_package package
          shipment_builder.add_payment_information ENV["UPS_ACCOUNT_NUMBER"]
          shipment_builder.add_service "07"
        end
      end

      it "does what ever it takes to get that shipment shipped" do
        expect(subject).wont_equal false
        expect(subject.success?).must_equal true
        expect(subject.status_description).must_equal "Success"
      end

      it "returns the packages data" do
        expect(subject.packages).must_be_kind_of Array
        expect(subject.packages.size).must_equal 1
      end

      it "returns the label data" do
        expect(subject.label_graphic_image).must_be_kind_of Tempfile
        expect(subject.label_graphic_image.path.end_with?(".png")).must_equal true
        expect(subject.label_graphic_extension).must_equal ".png"

        expect(subject.graphic_image).must_be_kind_of Tempfile
        expect(subject.graphic_image.path.end_with?(".png")).must_equal true
        expect(subject.graphic_extension).must_equal ".png"

        expect(subject.html_image).must_be_kind_of Tempfile
        expect(subject.html_image.path.end_with?(".png")).must_equal true

        expect(subject.label_html_image).must_be_kind_of Tempfile
        expect(subject.label_html_image.path.end_with?(".png")).must_equal true
      end

      it "should return the requested customs form data" do
        expect(subject.form_graphic_image).must_be_kind_of Tempfile
        expect(subject.form_graphic_image.path.end_with?(".pdf")).must_equal true
        expect(subject.form_graphic_extension).must_equal ".pdf"
      end

      it "should return the tracking number" do
        expect(subject.tracking_number).must_equal "1Z2220060292353829"
      end
    end

    describe "when packaging type is specified" do
      before do
        Excon.stub(method: :post) do |params|
          case params[:path]
          when UPS::Connection::SHIP_PATH
            {
              body: File.read("#{stub_path}/ship_success_with_packaging_type.json"), status: 200
            }
          end
        end
      end

      subject do
        server.authorize ENV["UPS_ACCOUNT_NUMBER"], ENV["UPS_CLIENT_ID"], ENV["UPS_CLIENT_SECRET"], true
        server.ship do |shipment_builder|
          shipment_builder.add_shipper shipper
          shipment_builder.add_ship_from shipper
          shipment_builder.add_ship_to ship_to
          shipment_builder.add_package package_with_carrier_packaging_and_dimensions
          shipment_builder.add_payment_information ENV["UPS_ACCOUNT_NUMBER"]
          shipment_builder.add_service "07"
        end
      end

      let(:supplied_package) { package_with_carrier_packaging }

      it "should return the tracking number" do
        expect(subject.tracking_number).must_equal "1Z2R466A6790676189"
      end
    end

    describe "multi package shipment" do
      before do
        Excon.stub(method: :post) do |params|
          case params[:path]
          when UPS::Connection::SHIP_PATH
            {
              body: File.read("#{stub_path}/ship_multiple_success.json"), status: 200
            }
          end
        end
      end

      let(:first_package) { subject.packages[0] }
      let(:second_package) { subject.packages[1] }

      subject do
        server.authorize ENV["UPS_ACCOUNT_NUMBER"], ENV["UPS_CLIENT_ID"], ENV["UPS_CLIENT_SECRET"], true
        server.ship do |shipment_builder|
          shipment_builder.add_shipper shipper
          shipment_builder.add_ship_from shipper
          shipment_builder.add_ship_to ship_to
          shipment_builder.add_package package
          shipment_builder.add_package large_package
          shipment_builder.add_payment_information ENV["UPS_ACCOUNT_NUMBER"]
          shipment_builder.add_service "07"
        end
      end

      describe "legacy methods for first package" do
        it "returns the label data for the first package" do
          expect(subject.label_graphic_image).must_be_kind_of Tempfile
          expect(subject.label_graphic_image.path.end_with?(".png")).must_equal true
          expect(subject.label_graphic_extension).must_equal ".png"

          expect(subject.graphic_image).must_be_kind_of Tempfile
          expect(subject.graphic_image.path.end_with?(".png")).must_equal true
          expect(subject.graphic_extension).must_equal ".png"

          expect(subject.html_image).must_be_kind_of Tempfile
          expect(subject.html_image.path.end_with?(".png")).must_equal true

          expect(subject.label_html_image).must_be_kind_of Tempfile
          expect(subject.label_html_image.path.end_with?(".png")).must_equal true
        end

        it "returns the tracking number of the first package" do
          expect(subject.tracking_number).must_equal "1Z2220060292353829"
        end
      end

      it "returns the packages data" do
        expect(subject.packages).must_be_kind_of Array
        expect(subject.packages.size).must_equal 2
      end

      describe "data per package" do
        describe "package #1" do
          it "returns the correct label data" do
            expect(first_package.label_graphic_image).must_be_kind_of Tempfile
            expect(first_package.label_graphic_image.path.end_with?(".png")).must_equal true
            expect(first_package.label_html_image).must_be_kind_of Tempfile
            expect(first_package.label_html_image.path.end_with?(".png")).must_equal true
            expect(first_package.label_graphic_extension).must_equal ".png"
          end

          it "returns the correct tracking number" do
            expect(first_package.tracking_number).must_equal "1Z2220060292353829"
          end
        end

        describe "package #2" do
          it "returns the correct label data" do
            expect(second_package.label_graphic_image).must_be_kind_of Tempfile
            expect(second_package.label_graphic_image.path.end_with?(".png")).must_equal true
            expect(second_package.label_html_image).must_be_kind_of Tempfile
            expect(second_package.label_html_image.path.end_with?(".png")).must_equal true
            expect(second_package.label_graphic_extension).must_equal ".png"
          end

          it "returns the correct tracking_number" do
            expect(second_package.tracking_number).must_equal "1Z2R466A6894635437"
          end
        end
      end
    end
  end

  describe "ups returns an error during shipping" do
    before do
      Excon.stub(method: :post) do |params|
        case params[:path]
        when UPS::Connection::SHIP_PATH
          {body: File.read("#{stub_path}/ship_failure.json"), status: 200}
        end
      end
    end

    subject do
      server.authorize ENV["UPS_ACCOUNT_NUMBER"], ENV["UPS_CLIENT_ID"], ENV["UPS_CLIENT_SECRET"], true
      server.ship do |shipment_builder|
        shipment_builder.add_shipper shipper
        shipment_builder.add_ship_from shipper
        shipment_builder.add_ship_to ship_to
        shipment_builder.add_package package
        shipment_builder.add_payment_information ENV["UPS_ACCOUNT_NUMBER"]
        shipment_builder.add_service "07"
      end
    end

    it "should return a response with an error code and error description" do
      expect(subject).wont_equal false
      expect(subject.success?).must_equal false
      expect(subject.error_description).must_equal "Missing or invalid shipper number."
    end
  end
end
