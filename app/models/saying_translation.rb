class SayingTranslation < ApplicationRecord
  belongs_to :saying_a, class_name: "Saying", foreign_key: :saying_a_id
  belongs_to :saying_b, class_name: "Saying", foreign_key: :saying_b_id

  validates :saying_a, presence: true
  validates :saying_b, presence: true

  validate :saying_a_and_saying_b_must_be_different
  validate :unique_translation_pair

  def saying_a_and_saying_b_must_be_different
    return if saying_a_id.blank? || saying_b_id.blank?

    if saying_a_id == saying_b_id
      errors.add(:base, "saying_a and saying_b must be different")
    end
  end

  def unique_translation_pair
    return if saying_a_id.blank? || saying_b_id.blank?

    a_id, b_id = [ saying_a_id, saying_b_id ].minmax

    existing = SayingTranslation.where(
      saying_a_id: a_id,
      saying_b_id: b_id
    )
    existing = existing.where.not(id: id) if persisted?

    if existing.exists?
      errors.add(:base, "This translation pair already exists")
    end
  end
end
