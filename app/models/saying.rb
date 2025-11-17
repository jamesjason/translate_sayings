class Saying < ApplicationRecord
  MINIMUM_TEXT_LENGTH = 3

  belongs_to :language

  before_validation :normalize_text

  validates :language, presence: true
  validates :text,
            presence: true,
            length: { minimum: MINIMUM_TEXT_LENGTH },
            uniqueness: { case_sensitive: false }

  private

  def normalize_text
    return if text.blank?

    normalized = text.downcase.strip
    normalized = normalized.gsub(/\s+/, " ")

    self.text = normalized
  end
end
