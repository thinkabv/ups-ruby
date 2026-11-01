require "spec_helper"

class UPS::Builders::TestShipBuilder < Minitest::Test
  include ShippingOptions

  def setup
    @ship_builder = UPS::Builders::ShipBuilder.new do |builder|
      builder.add_shipper shipper
      builder.add_ship_to ship_to
      builder.add_ship_from shipper
      builder.add_package package
      builder.add_label_specification "gif", {height: "100", width: "100"}
      builder.add_international_invoice invoice_form
      builder.add_description "Los Pollo Hermanos"
      builder.add_reference_number reference_number
      builder.add_return_service "10"
      builder.add_usps_endorsement "1"
      builder.add_package_id "1234"
      builder.add_shipment_delivery_confirmation "2"
      builder.add_shipment_direct_delivery_only
      builder.add_invoice_line_total("12", "GBP")
    end
  end

  def test_has_correct_shipper_name
    assert_equal shipper[:company_name], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["Shipper"]["Name"]
  end

  def test_has_correct_shipper_number
    assert_equal shipper[:shipper_number], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["Shipper"]["ShipperNumber"]
  end

  def test_has_correct_shipper_tax_number
    assert_equal shipper[:sender_tax_number], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["Shipper"]["TaxIdentificationNumber"]
  end

  def test_has_correct_ship_to_name
    assert_equal ship_to[:company_name], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ShipTo"]["Name"]
  end

  def test_has_correct_ship_from_name
    assert_equal shipper[:company_name], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ShipFrom"]["Name"]
  end

  def test_has_correct_package_weight
    assert_equal package[:weight], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["Package"][0]["PackageWeight"]["Weight"]
  end

  def test_has_correct_packaging_type
    assert_equal "02", @ship_builder.as_json["ShipmentRequest"]["Shipment"]["Package"][0]["Packaging"]["Code"]
  end

  def test_has_correct_label_specification
    assert_equal "GIF", @ship_builder.as_json["ShipmentRequest"]["LabelSpecification"]["LabelImageFormat"]["Code"]
    assert_equal "100", @ship_builder.as_json["ShipmentRequest"]["LabelSpecification"]["LabelStockSize"]["Height"]
    assert_equal "100", @ship_builder.as_json["ShipmentRequest"]["LabelSpecification"]["LabelStockSize"]["Width"]
  end

  def test_has_correct_international_invoice
    assert_equal invoice_form[:invoice_number], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ShipmentServiceOptions"]["InternationalForms"]["InvoiceNumber"]
    assert_equal invoice_form[:invoice_date], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ShipmentServiceOptions"]["InternationalForms"]["InvoiceDate"]
    assert_equal invoice_form[:reason_for_export], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ShipmentServiceOptions"]["InternationalForms"]["ReasonForExport"]
    assert_equal invoice_form[:currency_code], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ShipmentServiceOptions"]["InternationalForms"]["CurrencyCode"]
    assert_equal invoice_form[:terms_of_shipment], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ShipmentServiceOptions"]["InternationalForms"]["TermsOfShipment"]
    assert_equal invoice_form[:discount], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ShipmentServiceOptions"]["InternationalForms"]["Discount"]["MonetaryValue"]
  end

  def test_has_correct_description
    assert_equal "Los Pollo Hermanos", @ship_builder.as_json["ShipmentRequest"]["Shipment"]["Description"]
  end

  def test_has_correct_reference_number
    assert_equal reference_number[:code], @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ReferenceNumber"]["Code"]
  end

  def test_has_correct_return_service
    assert_equal "10", @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ReturnService"]["Code"]
  end

  def test_has_correct_usps_endorsement
    assert_equal "1", @ship_builder.as_json["ShipmentRequest"]["Shipment"]["USPSEndorsement"]
  end

  def test_has_correct_package_id
    assert_equal "1234", @ship_builder.as_json["ShipmentRequest"]["Shipment"]["PackageID"]
  end

  def test_has_correct_delivery_confirmation
    assert_equal "2", @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ShipmentServiceOptions"]["DeliveryConfirmation"]["DCISType"]
  end

  def test_has_correct_direct_delivery_only_flag
    assert_equal "", @ship_builder.as_json["ShipmentRequest"]["Shipment"]["ShipmentServiceOptions"]["DirectDeliveryOnlyIndicator"]
  end

  def test_has_correct_invoice_line_total
    assert_equal "12", @ship_builder.as_json["ShipmentRequest"]["Shipment"]["InvoiceLineTotal"]["MonetaryValue"]
    assert_equal "GBP", @ship_builder.as_json["ShipmentRequest"]["Shipment"]["InvoiceLineTotal"]["CurrencyCode"]
  end
end
