module TextNormalizer
  extend ActiveSupport::Concern

  def normalize_text_field(value)
    value.to_s.strip.downcase.gsub(/\s+/, ' ')
  end
end
