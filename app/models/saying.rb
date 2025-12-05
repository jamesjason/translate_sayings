class Saying < ApplicationRecord
  MINIMUM_TEXT_LENGTH = 1
  MAXIMUM_TEXT_LENGTH = 300

  include WhitespaceNormalization

  belongs_to :language

  has_many :outgoing_translations,
           class_name: 'SayingTranslation',
           foreign_key: :saying_a_id,
           inverse_of: :saying_a,
           dependent: :destroy

  has_many :incoming_translations,
           class_name: 'SayingTranslation',
           foreign_key: :saying_b_id,
           inverse_of: :saying_b,
           dependent: :destroy

  before_validation :normalize_text_fields

  validates :text,
            presence: true,
            length: {
              minimum: MINIMUM_TEXT_LENGTH,
              maximum: MAXIMUM_TEXT_LENGTH
            },
            uniqueness: { case_sensitive: true, scope: :language_id }

  def self.search(language:, term:)
    return none unless language

    normalized_term = TextNormalizer.new(text: term).call
    return none if normalized_term.length < 2

    select(:id, :text)
      .where(language:)
      .where('normalized_text ILIKE ?', "%#{normalized_term}%")
      .order(:normalized_text)
      .limit(10)
  end

  def self.find_canonical_by(slug:)
    english = Language.find_by!(code: Language::DEFAULT_SOURCE_LANGUAGE)

    canonical = find_by(slug:, language: english)
    return canonical if canonical

    find_by(slug:)
  end

  def equivalents_in(language:)
    return [] unless language

    linked_sayings.select { |saying| saying.language_id == language.id }
  end

  def to_param
    slug
  end

  def linked_sayings
    (incoming_translations.map(&:saying_a) +
     outgoing_translations.map(&:saying_b)).uniq
  end

  private

  def normalize_text_fields
    return if text.blank?

    whitespace_normalized_text = normalize_whitespace(string: text)
    self.text = whitespace_normalized_text
    self.normalized_text = TextNormalizer.new(text: whitespace_normalized_text).call
  end
end
