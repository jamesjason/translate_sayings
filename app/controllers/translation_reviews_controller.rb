class TranslationReviewsController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    translations = FetchTranslationsForReview.new(
      user: current_user,
      language_a:,
      language_b:
    ).call

    render json: { translations: }
  end

  def vote
    translation = SayingTranslation.find_by(id: vote_params[:id])

    if translation.nil?
      render json: { error: 'Translation not found' }, status: :not_found
      return
    end

    translation_vote = translation.register_vote(
      user: current_user,
      value: vote_params[:vote].to_i
    )

    if translation_vote.errors.none?
      render json: {
        upvotes: translation.upvotes_count,
        downvotes: translation.downvotes_count,
        user_vote: translation_vote.vote
      }
    else
      render json: { errors: translation_vote.errors.full_messages },
             status: :unprocessable_content
    end
  end

  private

  def review_params
    params.permit(:language_a_code, :language_b_code)
  end

  def vote_params
    params.permit(:id, :vote)
  end

  def language_a
    @language_a ||= Language.find_by(code: review_params[:language_a_code]) ||
                    Language.find_by!(code: Language::DEFAULT_SOURCE_LANGUAGE)
  end

  def language_b
    @language_b ||= Language.find_by(code: review_params[:language_b_code]) ||
                    Language.find_by!(code: Language::DEFAULT_TARGET_LANGUAGE)
  end
end
