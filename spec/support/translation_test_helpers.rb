module TranslationTestHelpers
  def create_translation(language1:, language2:, text1: nil, text2: nil)
    saying_a = if text1
                 Saying.find_by(text: text1, language: language1) || create(:saying, language: language1, text: text1)
               else
                 create(:saying, language: language1)
               end

    saying_b = if text2
                 Saying.find_by(text: text2, language: language2) || create(:saying, language: language2, text: text2)
               else
                 create(:saying, language: language2)
               end

    create(:saying_translation, saying_a:, saying_b:)
  end

  def create_default_languages
    english = create(:language)
    persian = create(:language, :fa)

    [english, persian]
  end

  def create_sample_translations
    english, persian = create_default_languages
    spanish = create(:language, :es)

    create_translation(
      language1: english,
      language2: persian,
      text1: 'too many cooks spoil the broth',
      text2: 'آشپز که دو تا شد آش یا شور میشه یا بی‌نمک'
    )

    create_translation(
      language1: english,
      language2: persian,
      text1: 'better late than never',
      text2: 'دیر رسیدن بهتر از هرگز نرسیدن است'
    )

    create_translation(
      language1: english,
      language2: persian,
      text1: 'a stitch in time saves nine',
      text2: 'پیشگیری بهتر از درمان است'
    )

    create_translation(
      language1: spanish,
      language2: english,
      text1: 'más vale tarde que nunca',
      text2: 'better late than never'
    )
  end
end
