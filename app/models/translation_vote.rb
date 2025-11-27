class TranslationVote < ApplicationRecord
  belongs_to :user
  belongs_to :saying_translation

  validates :vote,
            inclusion: { in: [-1, 0, 1], message: :invalid_vote }

  validates :user_id, uniqueness: {
    scope: :saying_translation_id,
    message: :already_voted
  }

  def upvote!
    update!(vote: 1)
  end

  def downvote!
    update!(vote: -1)
  end

  def clear_vote!
    update!(vote: 0)
  end

  def upvoted?
    vote == 1
  end

  def downvoted?
    vote == -1
  end

  def neutral?
    vote.zero?
  end
end
