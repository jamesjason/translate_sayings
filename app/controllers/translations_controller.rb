class TranslationsController < ApplicationController
  before_action :set_query, :set_languages

  def index
    return @translations = [] if @query.blank?

    @source_saying = Saying.find_by(
      language: source_language,
      normalized_text: @normalized_query
    )

    @translations = fetch_translations
  end

  private

  def translations_params
    params.permit(:source_language, :target_language, :q)
  end

  def set_query
    raw = translations_params[:q].to_s.strip
    @query = raw
    @normalized_query = TextNormalizer.new(text: raw).call
  end

  def set_languages
    source_language
    target_language
  end

  def source_language
    @source_language ||= Language.find_by(code: translations_params[:source_language].presence) ||
                         Language.find_by!(code: Language::DEFAULT_SOURCE_LANGUAGE)
  end

  def target_language
    @target_language ||= Language.find_by(code: translations_params[:target_language].presence) ||
                         Language.find_by!(code: Language::DEFAULT_TARGET_LANGUAGE)
  end

  def fetch_translations
    return [] unless @source_saying

    SayingTranslation
      .for_saying(source_saying: @source_saying)
      .between_languages(
        language_a: source_language,
        language_b: target_language
      )
      .includes(:translation_votes, :saying_a, :saying_b)
      .sort_by { |translation| -translation.accuracy_score }
  end
end
