# frozen_string_literal: true

module UPS
  module Utils
    def self.base64_to_file(contents, extension)
      file_config = ["ups", extension]
      Tempfile.new(file_config, nil, encoding: "ascii-8bit").tap do |file|
        file.write Base64.decode64(contents)
      ensure
        file.rewind
      end
    end
  end
end
