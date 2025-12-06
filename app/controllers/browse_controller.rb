class BrowseController < ApplicationController
  before_action :set_language, :set_letter
  before_action :set_browse_meta_tags, only: [:index]

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

  def set_browse_meta_tags
    page_num = browse_params[:page].presence&.to_i
    is_paginated = page_num && page_num > 1

    if @letter.present?
      base_title = "#{@language.name} Sayings Starting With #{@letter}"
      base_desc  = "Discover #{@language.name} sayings and proverbs beginning with #{@letter}. Browse 50 per page."

    else
      base_title = "Browse #{@language.name} Sayings — A–Z Collection"
      base_desc  = "Explore a curated list of #{@language.name} sayings and proverbs. Browse all " \
                   'sayings alphabetically.'
    end

    if is_paginated
      base_title = "#{base_title} (Page #{page_num})"
      base_desc  = "#{base_desc} Page #{page_num}."
    end

    set_meta_tags(
      title: base_title,
      description: base_desc,
      keywords: [
        "#{@language.name} sayings",
        "#{@language.name} proverbs",
        'browse sayings',
        'alphabetical sayings'
      ].join(', '),
      canonical: request.original_url,
      og: {
        title: base_title,
        description: base_desc,
        type: 'website',
        url: request.original_url,
        image: view_context.image_url('logo.png')
      },
      twitter: {
        card: 'summary_large_image',
        title: base_title,
        description: base_desc
      }
    )
  end
end
