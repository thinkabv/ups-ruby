require "spec_helper"

describe UPS::Builders::LabelRecoveryRequestBuilder do
  describe "when adding only necessary items" do
    subject {
      UPS::Builders::LabelRecoveryRequestBuilder.new do |builder|
        builder.add_tracking_number "1Z12345E0205271688"
        builder.add_label_specification "gif"
      end
    }

    it "returns the correct tracking number" do
      expect(subject.as_json["LabelRecoveryRequest"]["TrackingNumber"]).must_equal "1Z12345E0205271688"
    end

    it "returns the correct label specification" do
      expect(subject.as_json["LabelRecoveryRequest"]["LabelSpecification"]["LabelImageFormat"]["Code"]).must_equal "GIF"
    end
  end

  describe "when adding only shipper number extra" do
    subject {
      UPS::Builders::LabelRecoveryRequestBuilder.new do |builder|
        builder.add_tracking_number "1Z12345E0205271688"
        builder.add_shipper_number "123456"
        builder.add_label_specification "gif"
      end
    }

    it "returns the correct tracking number" do
      expect(subject.as_json["LabelRecoveryRequest"]["TrackingNumber"]).must_equal "1Z12345E0205271688"
    end

    it "returns the correct shipper number" do
      expect(subject.as_json["LabelRecoveryRequest"]["ReferenceValues"]["ShipperNumber"]).must_equal "123456"
    end

    it "returns the correct label specification" do
      expect(subject.as_json["LabelRecoveryRequest"]["LabelSpecification"]["LabelImageFormat"]["Code"]).must_equal "GIF"
    end
  end

  describe "when adding only reference number extra" do
    subject {
      UPS::Builders::LabelRecoveryRequestBuilder.new do |builder|
        builder.add_tracking_number "1Z12345E0205271688"
        builder.add_reference_number "rf1294"
        builder.add_label_specification "gif"
      end
    }

    it "returns the correct tracking number" do
      expect(subject.as_json["LabelRecoveryRequest"]["TrackingNumber"]).must_equal "1Z12345E0205271688"
    end

    it "returns the correct reference number" do
      expect(subject.as_json["LabelRecoveryRequest"]["ReferenceValues"]["ReferenceNumber"]["Value"]).must_equal "rf1294"
    end

    it "returns the correct label specification" do
      expect(subject.as_json["LabelRecoveryRequest"]["LabelSpecification"]["LabelImageFormat"]["Code"]).must_equal "GIF"
    end
  end

  describe "when adding shipper number before reference number" do
    subject {
      UPS::Builders::LabelRecoveryRequestBuilder.new do |builder|
        builder.add_tracking_number "1Z12345E0205271688"
        builder.add_shipper_number "123456"
        builder.add_reference_number "rf1294"
        builder.add_label_specification "gif"
      end
    }

    it "returns the correct tracking number" do
      expect(subject.as_json["LabelRecoveryRequest"]["TrackingNumber"]).must_equal "1Z12345E0205271688"
    end

    it "returns the correct reference number" do
      expect(subject.as_json["LabelRecoveryRequest"]["ReferenceValues"]["ReferenceNumber"]["Value"]).must_equal "rf1294"
    end

    it "returns the correct shipper number" do
      expect(subject.as_json["LabelRecoveryRequest"]["ReferenceValues"]["ShipperNumber"]).must_equal "123456"
    end

    it "returns the correct label specification" do
      expect(subject.as_json["LabelRecoveryRequest"]["LabelSpecification"]["LabelImageFormat"]["Code"]).must_equal "GIF"
    end
  end

  describe "when adding reference number before shipper number" do
    subject {
      UPS::Builders::LabelRecoveryRequestBuilder.new do |builder|
        builder.add_tracking_number "1Z12345E0205271688"
        builder.add_reference_number "rf1294"
        builder.add_shipper_number "123456"
        builder.add_label_specification "gif"
      end
    }

    it "returns the correct tracking number" do
      expect(subject.as_json["LabelRecoveryRequest"]["TrackingNumber"]).must_equal "1Z12345E0205271688"
    end

    it "returns the correct reference number" do
      expect(subject.as_json["LabelRecoveryRequest"]["ReferenceValues"]["ReferenceNumber"]["Value"]).must_equal "rf1294"
    end

    it "returns the correct shipper number" do
      expect(subject.as_json["LabelRecoveryRequest"]["ReferenceValues"]["ShipperNumber"]).must_equal "123456"
    end

    it "returns the correct label specification" do
      expect(subject.as_json["LabelRecoveryRequest"]["LabelSpecification"]["LabelImageFormat"]["Code"]).must_equal "GIF"
    end
  end
end
