class SayingTranslation < ApplicationRecord
  REVIEW_BATCH_SIZE = 10

  belongs_to :saying_a, class_name: 'Saying'
  belongs_to :saying_b, class_name: 'Saying'
  has_many :translation_votes, dependent: :destroy

  validate :saying_a_and_saying_b_must_be_different
  validate :unique_translation_pair

  scope :for_saying, lambda { |source_saying:|
    where(saying_a: source_saying).or(
      where(saying_b: source_saying)
    )
  }

  scope :between_languages, lambda { |language_a:, language_b:|
    sql = <<~SQL.squish
      (
        sayings.language_id = :language_a_id
        AND saying_bs_saying_translations.language_id = :language_b_id
      )
      OR
      (
        sayings.language_id = :language_b_id
        AND saying_bs_saying_translations.language_id = :language_a_id
      )
    SQL

    joins(:saying_a, :saying_b)
      .where(
        sql,
        language_a_id: language_a.id,
        language_b_id: language_b.id
      )
  }

  scope :unreviewed_by, lambda { |user|
    return all unless user

    where.not(id: user.translation_votes.select(:saying_translation_id))
  }

  scope :random_batch, lambda {
    order('RANDOM()').limit(REVIEW_BATCH_SIZE)
  }

  def user_vote_value(user)
    return 0 unless user

    translation_votes.find_by(user_id: user.id)&.vote || 0
  end

  def upvotes_count
    @upvotes_count ||= translation_votes.count { |translation_vote| translation_vote.vote == 1 }
  end

  def downvotes_count
    @downvotes_count ||= translation_votes.count { |translation_vote| translation_vote.vote == -1 }
  end

  def accuracy_score
    return 0.0 if total_votes.zero?

    wilson_lower_bound_score
  end

  def register_vote(user:, value:)
    translation_vote = translation_votes.find_or_initialize_by(user:)
    translation_vote.vote = (translation_vote.vote == value ? 0 : value)
    translation_vote.save
    translation_vote
  end

  private

  def saying_a_and_saying_b_must_be_different
    return unless saying_a_id && saying_b_id
    return unless saying_a_id == saying_b_id

    errors.add(:base, 'saying_a and saying_b must be different')
  end

  def unique_translation_pair
    return unless saying_a_id && saying_b_id

    a_id, b_id = [saying_a_id, saying_b_id].minmax
    existing = SayingTranslation.where(saying_a_id: a_id, saying_b_id: b_id)
    existing = existing.where.not(id: id) if persisted?

    errors.add(:base, 'This translation pair already exists') if existing.exists?
  end

  def total_votes
    @total_votes ||= upvotes_count + downvotes_count
  end

  def wilson_lower_bound_score
    z = 1.96
    proportion = upvotes_count.to_f / total_votes

    numerator =
      proportion +
      ((z**2) / (2 * total_votes)) -
      (z * Math.sqrt(((proportion * (1 - proportion)) + ((z**2) / (4 * total_votes))) / total_votes))

    denominator = 1 + ((z**2) / total_votes)

    numerator / denominator
  end
end
