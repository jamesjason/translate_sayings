class FetchTranslationsForReview
  def initialize(user:, language_a:, language_b:)
    @user       = user
    @language_a = language_a
    @language_b = language_b
  end

  def call
    SayingTranslation
      .between_languages(language_a:, language_b:)
      .unreviewed_by(user)
      .includes(:translation_votes, saying_a: :language, saying_b: :language)
      .random_batch
      .map { |translation| build_review_item(translation) }
  end

  private

  attr_reader :user, :language_a, :language_b

  def build_review_item(translation)
    first_saying, second_saying = ordered_pair(translation)

    {
      id: translation.id,
      saying_a: first_saying.text,
      saying_b: second_saying.text,
      upvotes: translation.upvotes_count,
      downvotes: translation.downvotes_count,
      user_vote: translation.user_vote_value(user)
    }
  end

  def ordered_pair(translation)
    saying_a = translation.saying_a
    saying_b = translation.saying_b

    return [saying_a, saying_b] if saying_a.language.code == Language::DEFAULT_SOURCE_LANGUAGE
    return [saying_b, saying_a] if saying_b.language.code == Language::DEFAULT_SOURCE_LANGUAGE

    saying_a.language.id == language_a.id ? [saying_a, saying_b] : [saying_b, saying_a]
  end
end
