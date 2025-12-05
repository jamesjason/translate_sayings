class BrowseController < ApplicationController
  before_action :set_language, :set_letter

  ALPHABET = ('A'..'Z').to_a.freeze

  def index
    @languages = Language.order(:name)
    @letters   = ALPHABET
    @sayings = filtered_sayings
               .order(:text)
               .page(browse_params[:page])
               .per(50)
  end

  private

  def browse_params
    params.permit(:code, :letter, :page)
  end

  def set_language
    @language = Language.find_by!(code: browse_params[:code])
  end

  def set_letter
    raw = browse_params[:letter].to_s.strip.upcase
    @letter = ALPHABET.include?(raw) ? raw : nil
  end

  def filtered_sayings
    scope = @language.sayings

    return scope unless english_with_letter?

    scope.where('text ILIKE ?', "#{@letter}%")
  end

  def english_with_letter?
    @language.code == 'en' && @letter.present?
  end
end
