class SayingTranslation < ApplicationRecord
  belongs_to :saying_a, class_name: 'Saying'
  belongs_to :saying_b, class_name: 'Saying'

  validate :saying_a_and_saying_b_must_be_different
  validate :unique_translation_pair

  def saying_a_and_saying_b_must_be_different
    return if saying_a_id.blank? || saying_b_id.blank?

    return unless saying_a_id == saying_b_id

    errors.add(:base, 'saying_a and saying_b must be different')
  end

  def unique_translation_pair
    return if saying_a_id.blank? || saying_b_id.blank?

    a_id, b_id = [saying_a_id, saying_b_id].minmax

    existing = SayingTranslation.where(
      saying_a_id: a_id,
      saying_b_id: b_id
    )
    existing = existing.where.not(id: id) if persisted?

    return unless existing.exists?

    errors.add(:base, 'This translation pair already exists')
  end
end
