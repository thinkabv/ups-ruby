# frozen_string_literal: true

module UPS
  module Builders
    # Builds a PickupCreationRequest: a driver collecting parcels at an address
    # within a time window on a date, billed to the shipper account.
    #
    #   connection.pickup do |pickup|
    #     pickup.add_shipper_account "ACCOUNT_NUMBER", "NL"
    #     pickup.add_pickup_window Date.today, "0900", "1800"
    #     pickup.add_pickup_address company_name: "Example B.V.", address_line_1: "Dam 1",
    #       city: "Amsterdam", postal_code: "1012 JS", country: "NL", phone_number: "+31 20 123 4567"
    #     pickup.add_piece service_code: "011", quantity: 2, destination_country: "DE"
    #     pickup.add_total_weight 1.4, "KGS"
    #     pickup.add_notification_email "ops@example.com"
    #   end
    class PickupBuilder
      PACKAGE = "01" # ContainerCode
      BILL_SHIPPER = "01" # PaymentMethod

      attr_reader :root

      def initialize
        @root = {
          "Request" => {},
          "RatePickupIndicator" => "Y",
          "AlternateAddressIndicator" => "N",
          "PaymentMethod" => BILL_SHIPPER,
          "PickupPiece" => []
        }
        yield self if block_given?
      end

      def add_shipper_account(account_number, country_code)
        root["Shipper"] = {"Account" => {"AccountNumber" => account_number, "AccountCountryCode" => country_code}}
        self
      end

      # @param date [Date]
      # @param ready_time [String] "HHMM" from when the parcels can be collected
      # @param close_time [String] "HHMM" until when
      def add_pickup_window(date, ready_time, close_time)
        root["PickupDateInfo"] = {"PickupDate" => date.strftime("%Y%m%d"), "ReadyTime" => ready_time, "CloseTime" => close_time}
        self
      end

      def add_pickup_address(opts)
        root["PickupAddress"] = {
          "CompanyName" => opts[:company_name],
          "ContactName" => opts[:contact_name] || opts[:company_name],
          "AddressLine" => [opts[:address_line_1], opts[:address_line_2]].compact,
          "City" => opts[:city],
          "PostalCode" => opts[:postal_code].to_s.delete(" "),
          "CountryCode" => opts[:country],
          "ResidentialIndicator" => opts[:residential] ? "Y" : "N",
          "Phone" => {"Number" => opts[:phone_number].to_s.gsub(/\D/, "")}
        }
        self
      end

      # Pickup service codes are three digits ("011" for UPS Standard); a
      # two-digit rating code is padded.
      def add_piece(service_code:, destination_country:, quantity: 1, container_code: PACKAGE)
        root["PickupPiece"] << {
          "ServiceCode" => service_code.to_s.rjust(3, "0"),
          "Quantity" => quantity.to_s,
          "DestinationCountryCode" => destination_country,
          "ContainerCode" => container_code
        }
        self
      end

      def add_total_weight(weight, unit = "KGS")
        root["TotalWeight"] = {"Weight" => weight.to_s, "UnitOfMeasurement" => unit}
        self
      end

      def add_notification_email(email)
        root["Notification"] = {"ConfirmationEmailAddress" => email}
        self
      end

      def as_json
        {"PickupCreationRequest" => root}
      end
    end
  end
end
