class TranslationsController < ApplicationController
  before_action :set_languages_and_query

  def index
    if @query.present?
      @source_saying = Saying.find_by(
        language: @source_language,
        text: normalized_query
      )
    end

    @equivalent_sayings =
      @source_saying&.equivalents_in(language: @target_language) || []
  end

  private

  def set_languages_and_query
    @query = query
    source_language
    target_language
  end

  def translations_params
    params.permit(:source_language, :target_language, :q)
  end

  def query
    translations_params[:q].to_s.strip
  end

  def normalized_query
    return @normalized_query if defined?(@normalized_query)

    @normalized_query = query.downcase.gsub(/\s+/, ' ')
  end

  def source_language
    return @source_language if defined?(@source_language)

    @source_language = Language.find_by(
      code: (translations_params[:source_language].presence || Language::DEFAULT_SOURCE_LANGUAGE).downcase
    )
  end

  def target_language
    return @target_language if defined?(@target_language)

    @target_language = Language.find_by(
      code: (translations_params[:target_language].presence || Language::DEFAULT_TARGET_LANGUAGE).downcase
    )
  end
end
