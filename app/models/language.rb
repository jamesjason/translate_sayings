class Language < ApplicationRecord
  SUPPORTED_LANGUAGES = {
    'en' => 'English',
    'fa' => 'Farsi'
  }.freeze

  before_validation :normalize_code
  validates :code, presence: true, uniqueness: { case_sensitive: false }, inclusion: { in: SUPPORTED_LANGUAGES.keys }
  validates :name, presence: true

  private

  def normalize_code
    return if code.blank?

    self.code = code.to_s.strip.downcase.gsub(/\s+/, '')
  end
end
