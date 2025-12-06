class SayingsController < ApplicationController
  def autocomplete
    sayings = Saying.search(
      language: source_language,
      term: autocomplete_params[:term]
    )

    render json: sayings.map { |saying| { id: saying.id, text: saying.text } }
  end

  def show
    @saying = Saying.find_canonical_by(slug: params[:slug])

    @translations =
      SayingTranslation
      .for_saying(source_saying: @saying)
      .includes(:translation_votes, :saying_a, :saying_b)
      .sort_by { |t| -t.accuracy_score }

    set_meta_tags_for_saying
  end

  private

  def autocomplete_params
    params.permit(:source_language, :term)
  end

  def source_language
    return @source_language if defined?(@source_language)

    @source_language = Language.find_by(
      code: autocomplete_params[:source_language].to_s.downcase.presence || Language::DEFAULT_SOURCE_LANGUAGE
    )
  end

  def set_meta_tags_for_saying
    priority_codes = %w[es fr fa]

    equivalents_by_lang = {}

    priority_codes.each do |code|
      equivalents_by_lang[code] = @translations.map do |translation|
        other = translation.saying_a_id == @saying.id ? translation.saying_b : translation.saying_a
        other if other.language.code == code
      end.compact.first
    end

    text_equivalents = equivalents_by_lang.values.compact.map(&:text)

    description_text =
      if text_equivalents.any?
        "Equivalent sayings: #{text_equivalents.join(', ')}."
      else
        'Explore equivalent sayings across languages.'
      end

    set_meta_tags(
      title: @saying.text,
      description: description_text,
      keywords: [
        @saying.text,
        'proverb', 'saying', 'translation'
      ].join(', '),
      canonical: saying_url(@saying.slug),
      og: {
        title: @saying.text,
        description: description_text,
        type: 'article',
        url: saying_url(@saying.slug),
        image: view_context.image_url('logo.png')
      },
      twitter: {
        card: 'summary',
        title: @saying.text,
        description: description_text
      }
    )
  end
end
