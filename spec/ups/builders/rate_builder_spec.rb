require "spec_helper"

class UPS::Builders::TestRateBuilder < Minitest::Test
  include ShippingOptions

  def setup
    @rate_builder = UPS::Builders::RateBuilder.new do |builder|
      builder.add_shipper shipper
      builder.add_ship_to ship_to
      builder.add_ship_from shipper
      builder.add_package package
      builder.add_return_service "10"
      builder.add_shipment_delivery_confirmation "2"
      builder.add_shipment_direct_delivery_only
    end
  end

  def test_has_correct_shipper_name
    assert_equal shipper[:company_name], @rate_builder.as_json["RateRequest"]["Shipment"]["Shipper"]["Name"]
  end

  def test_has_correct_shipper_number
    assert_equal shipper[:shipper_number], @rate_builder.as_json["RateRequest"]["Shipment"]["Shipper"]["ShipperNumber"]
  end

  def test_has_correct_shipper_tax_number
    assert_equal shipper[:sender_tax_number], @rate_builder.as_json["RateRequest"]["Shipment"]["Shipper"]["TaxIdentificationNumber"]
  end

  def test_has_correct_ship_to_name
    assert_equal ship_to[:company_name], @rate_builder.as_json["RateRequest"]["Shipment"]["ShipTo"]["Name"]
  end

  def test_has_correct_ship_from_name
    assert_equal shipper[:company_name], @rate_builder.as_json["RateRequest"]["Shipment"]["ShipFrom"]["Name"]
  end

  def test_has_correct_package_weight
    assert_equal package[:weight], @rate_builder.as_json["RateRequest"]["Shipment"]["Package"][0]["PackageWeight"]["Weight"]
  end

  def test_has_correct_packaging_type
    assert_equal "02", @rate_builder.as_json["RateRequest"]["Shipment"]["Package"][0]["PackagingType"]["Code"]
  end

  def test_has_correct_return_service
    assert_equal "10", @rate_builder.as_json["RateRequest"]["Shipment"]["ShipmentServiceOptions"]["ReturnService"]["Code"]
  end

  def test_has_correct_delivery_confirmation
    assert_equal "2", @rate_builder.as_json["RateRequest"]["Shipment"]["ShipmentServiceOptions"]["DeliveryConfirmation"]["DCISType"]
  end

  def test_has_correct_direct_delivery_only_flag
    assert_equal "", @rate_builder.as_json["RateRequest"]["Shipment"]["ShipmentServiceOptions"]["DirectDeliveryOnlyIndicator"]
  end
end
