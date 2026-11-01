require_relative "lib/ups/version"

Gem::Specification.new do |gem|
  gem.name = "ups-ruby"
  gem.version = UPS::Version::STRING
  gem.authors = ["Thinka B.V."]
  gem.email = ["support@thinka.eu"]
  gem.homepage = "https://github.com/thinkabv/ups-ruby"
  gem.summary = "UPS REST API client"
  gem.description = "Rating, shipping, tracking, label recovery, paperless documents and pickups " \
    "through the UPS REST (OAuth, JSON) API. Thinka's fork of veeqo/ups-ruby."
  gem.license = "MIT"

  gem.required_ruby_version = ">= 3.2"

  gem.add_dependency "excon", ">= 0.100"
  gem.add_dependency "insensitive_hash", "~> 0.3.3"

  gem.files = Dir["lib/**/*.rb", "LICENSE.txt", "README.md"]
  gem.require_paths = ["lib"]
end
