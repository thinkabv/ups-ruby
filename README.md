# ups-ruby

Ruby client for the UPS REST API (OAuth client credentials, JSON). It covers
what a web shop needs to ship with UPS:

- **Rating**: shop the available services and their prices
- **Shipping**: book a shipment and get its label and tracking number
- **Tracking**: the latest activity of a package
- **Label recovery**: a copy of an earlier label
- **Paperless documents**: upload customs documents to attach to a shipment
- **Pickup**: book a driver to collect parcels

This is Thinka's fork of [veeqo/ups-ruby](https://github.com/veeqo/ups-ruby),
which stopped at the XML API in 2021. The fork moved to the REST API in 2024
and is maintained for [thinka-server](https://github.com/thinkabv/thinka-server).

## Installation

```ruby
gem "ups-ruby", git: "https://github.com/thinkabv/ups-ruby", branch: "main"
```

Requires Ruby 3.2 or newer.

## Usage

```ruby
require "ups-ruby"

connection = UPS::Connection.new(test_mode: true, transaction_source: "my-app")
connection.authorize "ACCOUNT_NUMBER", "CLIENT_ID", "CLIENT_SECRET"
```

Keep one `Connection` per process: it requests an OAuth token on the first
call and a fresh one once the token expires (UPS tokens live four hours).
`test_mode` talks to UPS's Customer Integration Environment.

Every call returns a parser with `success?`, `errors` and `error_description`.
UPS reports failures in the body with an HTTP 4xx, so check `success?`; only a
response that is not an API response at all (a 5xx error page) raises
`UPS::Exceptions::ResponseError`.

### Rates

```ruby
rates = connection.rates do |rate|
  rate.add_shipper company_name: "Example B.V.", phone_number: "0031201234567",
    address_line_1: "Dam 1", city: "Amsterdam", postal_code: "1012 JS", country: "NL",
    shipper_number: "ACCOUNT_NUMBER"
  rate.add_ship_from company_name: "Example B.V.", phone_number: "0031201234567",
    address_line_1: "Dam 1", city: "Amsterdam", postal_code: "1012 JS", country: "NL"
  rate.add_ship_to company_name: "Customer", attention_name: "Jane Doe", phone_number: "0049301234567",
    address_line_1: "Unter den Linden 1", city: "Berlin", postal_code: "10117", country: "DE"
  rate.add_package weight: "0.7", unit: "KGS", dimensions: {length: 30, width: 16, height: 8, unit: "CM"}
end

rates.rated_shipments
# => [{service_code: "11", service_name: "UPS Standard", total: {currency: "EUR", amount: "12.34"}}, ...]
```

### Shipments

```ruby
shipment = connection.ship do |ship|
  ship.add_shipper ...
  ship.add_ship_from ...
  ship.add_ship_to ...
  ship.add_package weight: "0.7", unit: "KGS", dimensions: {...}
  ship.add_description "Home automation device"
  ship.add_reference_number code: "IK", value: "INV-2026-001"
  ship.add_payment_information "ACCOUNT_NUMBER"
  ship.add_service "11" # a service_code from the rates response
  ship.add_shipment_direct_delivery_only
  ship.add_shipment_delivery_confirmation "1" # signature required
end

shipment.tracking_number      # => "1Z..."
shipment.label_graphic_image  # => Tempfile with the GIF label
shipment.packages             # one PackageResult per package
```

For a return label add `ship.add_return_service "9"` (UPS prints the label);
for customs paperwork add `ship.add_international_invoice(...)`, optionally
with `document_id:` from a paperless upload (see below).

### Tracking

```ruby
track = connection.track "1Z12345E6692804405"
track.found?                   # false while UPS has no activity yet
track.delivered?
track.status_type_description  # => "DELIVERED"
track.status_date              # => Date
```

### Label recovery

```ruby
label = connection.label do |recovery|
  recovery.add_tracking_number "1Z12345E6692804405"
  recovery.add_label_specification "PDF"
end
label.label_graphic_image # => Tempfile
```

### Paperless documents

```ruby
upload = connection.paperless_document_upload do |documents|
  documents.add_shipper_number "ACCOUNT_NUMBER"
  documents.add_file file: File.binread("invoice.pdf"), file_name: "invoice.pdf", document_type: "002"
end
upload.document_ids # attach with ship.add_international_invoice(document_id: ids, form_type: "07", ...)
```

### Pickups

```ruby
pickup = connection.pickup do |pickup|
  pickup.add_shipper_account "ACCOUNT_NUMBER", "NL"
  pickup.add_pickup_window Date.today, "0900", "1800"
  pickup.add_pickup_address company_name: "Example B.V.", address_line_1: "Dam 1",
    city: "Amsterdam", postal_code: "1012 JS", country: "NL", phone_number: "0031201234567"
  pickup.add_piece service_code: "11", quantity: 2, destination_country: "DE"
  pickup.add_total_weight 1.4
  pickup.add_notification_email "ops@example.com"
end
pickup.reference # => the Pickup Request Number
```

## API versions

The paths follow the versions UPS lists in
[UPS-API/api-documentation](https://github.com/UPS-API/api-documentation):
rating, shipping and pickup `v2409`, tracking and label recovery `v1`,
paperless `v2`. The token endpoint is `/security/v1/oauth/token`.

## Development

```sh
bundle install
bundle exec rake        # tests (minitest, HTTP stubbed with Excon)
bundle exec standardrb  # style
```

## License

MIT, see [LICENSE.txt](LICENSE.txt). Originally written by Paul Trippett and
maintained by Veeqo until 2021.
