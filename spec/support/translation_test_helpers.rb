module TranslationTestHelpers
  def create_translation(language1:, language2:, text1: nil, text2: nil)
    saying_a = if text1
                 create(:saying, language: language1, text: text1)
               else
                 create(:saying, language: language1)
               end

    saying_b = if text2
                 create(:saying, language: language2, text: text2)
               else
                 create(:saying, language: language2)
               end

    create(:saying_translation, saying_a:, saying_b:)
  end
end
