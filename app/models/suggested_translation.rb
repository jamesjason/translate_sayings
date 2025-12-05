class SuggestedTranslation < ApplicationRecord
  belongs_to :user
  belongs_to :source_language, class_name: 'Language'
  belongs_to :target_language, class_name: 'Language'

  enum :status, {
    pending_review: 'pending_review',
    approved: 'approved',
    rejected: 'rejected'
  }

  before_validation :normalize_fields

  validates :source_saying_text,
            presence: true,
            length: {
              minimum: Saying::MINIMUM_TEXT_LENGTH,
              maximum: Saying::MAXIMUM_TEXT_LENGTH
            }
  validates :target_saying_text,
            presence: true,
            length: {
              minimum: Saying::MINIMUM_TEXT_LENGTH,
              maximum: Saying::MAXIMUM_TEXT_LENGTH
            }
  validates :status, presence: true

  private

  def normalize_fields
    self.source_saying_text = source_saying_text.to_s.strip.downcase.gsub(/\s+/, ' ')
    self.target_saying_text = target_saying_text.to_s.strip.downcase.gsub(/\s+/, ' ')
  end
end
