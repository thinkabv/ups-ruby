def levenshtein_distance(str1, str2)
  # Create a 2D array to hold distances
  rows = str1.length + 1
  cols = str2.length + 1
  dp = Array.new(rows) { Array.new(cols, 0) }

  # Initialize base cases
  (0...rows).each { |i| dp[i][0] = i }
  (0...cols).each { |j| dp[0][j] = j }

  # Fill the matrix
  (1...rows).each do |i|
    (1...cols).each do |j|
      dp[i][j] = if str1[i - 1] == str2[j - 1]
        dp[i - 1][j - 1] # No cost if characters are the same
      else
        [
          dp[i - 1][j],    # Deletion
          dp[i][j - 1],    # Insertion
          dp[i - 1][j - 1] # Substitution
        ].min + 1
      end
    end
  end

  # The bottom-right cell contains the result
  dp[rows - 1][cols - 1]
end
