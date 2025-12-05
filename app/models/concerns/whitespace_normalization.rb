module WhitespaceNormalization
  extend ActiveSupport::Concern

  def normalize_whitespace(string:)
    return nil if string.nil?

    string.strip.gsub(/\s+/, ' ')
  end
end
