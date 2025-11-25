class SuggestedTranslationsController < ApplicationController
  before_action :authenticate_user!, except: [:new]

  def new
    store_location_for(:user, request.fullpath)

    @suggested_translation = SuggestedTranslation.new(source_language:, target_language:)
  end

  def create
    @suggested_translation =
      current_user.suggested_translations.new(suggested_translation_params)

    if @suggested_translation.save
      flash[:inline_flash] = true
      redirect_to contribute_path(anchor: 'form')
    else
      @suggested_translation.source_language ||= source_language
      @suggested_translation.target_language ||= target_language

      render :new, status: :unprocessable_entity
    end
  end

  private

  def raw_suggested_translation_params
    params.require(:suggested_translation).permit(
      :source_language_code,
      :target_language_code,
      :source_saying_text,
      :target_saying_text
    )
  end

  def suggested_translation_params
    raw_params = raw_suggested_translation_params

    {
      source_language_id: language_id_from(code: raw_params[:source_language_code]),
      target_language_id: language_id_from(code: raw_params[:target_language_code]),
      source_saying_text: raw_params[:source_saying_text],
      target_saying_text: raw_params[:target_saying_text]
    }
  end

  def source_language
    @source_language ||= begin
      code = params[:source_language].presence || Language::DEFAULT_SOURCE_LANGUAGE
      Language.find_by(code:)
    end
  end

  def target_language
    @target_language ||= begin
      code = params[:target_language].presence || Language::DEFAULT_TARGET_LANGUAGE
      Language.find_by(code:)
    end
  end

  def language_id_from(code:)
    Language.find_by(code: code)&.id
  end
end
