# frozen_string_literal: true

module UPS
  module Version
    MAJOR = 0
    MINOR = 17
    PATCH = 1
    BUILD = nil

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join(".")
  end
end
