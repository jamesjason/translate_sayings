class Language < ApplicationRecord
  LANGUAGE_CODE_TO_NAME_MAP = {
    'en' => 'English',
    'fa' => 'Persian'
  }.freeze
  SUPPORTED_LANGUAGES = LANGUAGE_CODE_TO_NAME_MAP.keys.freeze
  DEFAULT_SOURCE_LANGUAGE = 'en'.freeze
  DEFAULT_TARGET_LANGUAGE = 'fa'.freeze

  before_validation :normalize_code

  validates :code,
            presence: true,
            uniqueness: { case_sensitive: false },
            inclusion: { in: SUPPORTED_LANGUAGES }

  validates :name, presence: true

  def self.name_for(code:)
    LANGUAGE_CODE_TO_NAME_MAP[code.to_s.strip.downcase]
  end

  private

  def normalize_code
    return if code.blank?

    self.code = code.to_s.strip.downcase.gsub(/\s+/, '')
  end
end
