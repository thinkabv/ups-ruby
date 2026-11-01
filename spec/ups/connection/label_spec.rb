require "spec_helper"
require "support/shipping_options"

describe UPS::Connection do
  before do
    Excon.defaults[:mock] = true
  end

  after do
    Excon.stubs.clear
  end

  let(:stub_path) { File.expand_path("../../../stubs", __FILE__) }
  let(:server) { UPS::Connection.new(test_mode: true) }

  describe "label request" do
    subject do
      server.authorize ENV["UPS_ACCOUNT_NUMBER"], ENV["UPS_CLIENT_ID"], ENV["UPS_CLIENT_SECRET"], true
      server.label do |label_builder|
        label_builder.add_tracking_number "1Z1107YY8567985294"
        label_builder.add_label_specification "PNG"
      end
    end

    describe "successful single label response" do
      before do
        Excon.stub(method: :post) do |params|
          case params[:path]
          when UPS::Connection::LABEL_PATH
            {body: File.read("#{stub_path}/label_single_success.json"), status: 200}
          end
        end
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

      it "returns the tracking number" do
        expect(subject.tracking_number).must_equal "1Z1107YY8567985294"
      end
    end

    describe "successful multi label response" do
      before do
        Excon.stub(method: :post) do |params|
          case params[:path]
          when UPS::Connection::LABEL_PATH
            {body: File.read("#{stub_path}/label_multi_success.json"), status: 200}
          end
        end
      end

      let(:first_label) { subject.labels[0] }
      let(:second_label) { subject.labels[1] }

      it "returns the first label data" do
        expect(first_label.label_graphic_image).must_be_kind_of Tempfile
        expect(first_label.label_graphic_image.path.end_with?(".png")).must_equal true
        expect(first_label.label_graphic_extension).must_equal ".png"

        expect(first_label.label_html_image).must_be_kind_of Tempfile
        expect(first_label.label_html_image.path.end_with?(".png")).must_equal true
      end

      it "returns the first label tracking number" do
        expect(first_label.tracking_number).must_equal "1Z1107YY8567985294"
      end

      it "returns the second label data" do
        expect(second_label.label_graphic_image).must_be_kind_of Tempfile
        expect(second_label.label_graphic_image.path.end_with?(".png")).must_equal true
        expect(second_label.label_graphic_extension).must_equal ".png"

        expect(second_label.label_html_image).must_be_kind_of Tempfile
        expect(second_label.label_html_image.path.end_with?(".png")).must_equal true
      end

      it "returns the second label tracking number" do
        expect(second_label.tracking_number).must_equal "1Z1907YZ8567783482"
      end
    end
  end
end
