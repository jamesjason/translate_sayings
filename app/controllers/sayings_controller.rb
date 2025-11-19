class SayingsController < ApplicationController
  def autocomplete
    sayings = Saying.search(
      language: source_language,
      term: autocomplete_params[:term]
    )

    render json: sayings.map { |saying| { id: saying.id, text: saying.text } }
  end

  private

  def autocomplete_params
    params.permit(:source_language, :term)
  end

  def source_language
    return @source_language if defined?(@source_language)

    @source_language = Language.find_by(
      code: autocomplete_params[:source_language].to_s.downcase.presence || 'en'
    )
  end
end
