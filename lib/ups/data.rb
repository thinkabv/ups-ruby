# frozen_string_literal: true

module UPS
  module Data
    class << self
      EMPTY_STATE_MESSAGE = "Invalid Address State [:state]"

      # Normalizes Irish states as per UPS requirements
      #
      # @param [String] string The Irish State to normalize
      # @return [String] The normalized Irish state name
      def ie_state_normalizer(string)
        IE_COUNTY_PREFIXES.reduce(string) do |target, prefix|
          target.sub(/^#{Regexp.escape(prefix.downcase)} /i, "")
        end
      end

      # Returns the closest matching Irish state name. Uses Levenshtein
      # distance to correct any possible spelling errors.
      #
      # @param [String] match_string The Irish State to match
      # @raise [InvalidAttributeError] If the passed match_String is nil or
      #   empty
      # @return [String] The closest matching irish state with the specified
      #   name
      def ie_state_matcher(match_string)
        if match_string.nil? || match_string.empty?
          raise Exceptions::InvalidAttributeError, EMPTY_STATE_MESSAGE
        end

        normalized_string = ie_state_normalizer string_normalizer match_string
        IE_COUNTIES.min_by { |county| levenshtein_distance(county.downcase, normalized_string) }
      end

      # Removes extra characters from a string
      #
      # @param [String] string The string to normalize and remove special
      #   characters
      # @return [String] The normalized string
      def string_normalizer(string)
        string.downcase.gsub(/[^0-9a-z ]/i, "")
      end

      private

      # Edit distance between two strings.
      def levenshtein_distance(from, to)
        previous = (0..to.length).to_a
        from.each_char.with_index(1) do |char, row|
          current = [row]
          to.each_char.with_index(1) do |other, column|
            current << [previous[column] + 1, current[column - 1] + 1, previous[column - 1] + ((char == other) ? 0 : 1)].min
          end
          previous = current
        end
        previous.last
      end
    end
  end
end
