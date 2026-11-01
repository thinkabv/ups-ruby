require "simplecov"
SimpleCov.start

require_relative "../lib/ups"

# The connection specs authorize with mock = true, so these only need to exist.
ENV["UPS_ACCOUNT_NUMBER"] ||= ""
ENV["UPS_CLIENT_ID"] ||= ""
ENV["UPS_CLIENT_SECRET"] ||= ""

require "minitest/autorun"
require "support/shipping_options"
