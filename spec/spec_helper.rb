require "simplecov"
SimpleCov.start

path = File.expand_path("../../", __FILE__)
require "#{path}/lib/ups.rb"

# Set default env parameters to prevent CI failing on pull requests
ENV["UPS_LICENSE_NUMBER"] = "" unless ENV.key? "UPS_LICENSE_NUMBER"
ENV["UPS_USER_ID"] = "" unless ENV.key? "UPS_USER_ID"
ENV["UPS_PASSWORD"] = "" unless ENV.key? "UPS_PASSWORD"
ENV["UPS_ACCOUNT_NUMBER"] = "" unless ENV.key? "UPS_ACCOUNT_NUMBER"
ENV["UPS_CLIENT_ID"] = "" unless ENV.key? "UPS_CLIENT_ID"
ENV["UPS_CLIENT_SECRET"] = "" unless ENV.key? "UPS_CLIENT_SECRET"

require "minitest/autorun"

require "support/shipping_options"
