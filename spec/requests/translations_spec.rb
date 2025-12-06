require 'rails_helper'

RSpec.describe 'TranslationsController', type: :request do
  let!(:languages) do
    create_default_languages
    Language.where(code: %w[en fa])
            .index_by(&:code)
            .values_at('en', 'fa')
  end

  let(:english) { languages[0] }
  let(:farsi)   { languages[1] }

  describe 'GET /translations' do
    context 'when the query matches an existing saying' do
      let!(:source_saying)   { create(:saying, language: english, text: 'hello world') }
      let!(:target_saying1)  { create(:saying, language: farsi) }
      let!(:target_saying2)  { create(:saying, language: farsi) }
      let!(:target_saying3)  { create(:saying, language: farsi) }

      let!(:translation1) { create(:saying_translation, saying_a: source_saying, saying_b: target_saying1) }
      let!(:translation2) { create(:saying_translation, saying_a: source_saying, saying_b: target_saying2) }
      let!(:translation3) { create(:saying_translation, saying_a: source_saying, saying_b: target_saying3) }

      before do
        create(:translation_vote, saying_translation: translation1, vote: 1)
        3.times { create(:translation_vote, saying_translation: translation2, vote: -1) }
        4.times { create(:translation_vote, saying_translation: translation3, vote: 1) }
      end

      it 'returns the source saying and sorts translations by accuracy_score descending' do
        get translations_path, params: { q: '  HELLO   world  ', target_language: farsi.code }

        translations = assigns(:translations)
        accuracy_scores = translations.map(&:accuracy_score)
        expect(response).to have_http_status(:ok)
        expect(assigns(:source_saying)).to eq(source_saying)
        expect(accuracy_scores).to eq(accuracy_scores.sort.reverse)
        expect(translations.first).to eq(translation3)
        expect(translations.second).to eq(translation1)
        expect(translations.third).to eq(translation2)
      end
    end

    context 'when the query is present but no saying matches' do
      it 'returns an empty translation list' do
        get translations_path, params: {
          q: 'hello',
          source_language: english.code,
          target_language: farsi.code
        }

        expect(response).to have_http_status(:ok)
        expect(assigns(:source_saying)).to be_nil
        expect(assigns(:translations)).to eq([])
      end
    end

    context 'when the query is blank' do
      it 'returns empty translations and default languages' do
        get translations_path, params: { q: '' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:translations)).to eq([])
        expect(assigns(:source_saying)).to be_nil
      end
    end

    context 'language selection' do
      it 'uses values from params when provided' do
        get translations_path, params: {
          q: 'test',
          source_language: farsi.code,
          target_language: english.code
        }

        expect(response).to have_http_status(:ok)
        expect(assigns(:source_language)).to eq(farsi)
        expect(assigns(:target_language)).to eq(english)
      end

      it 'falls back to defaults when params are missing' do
        get translations_path, params: { q: 'test' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:source_language).code).to eq(Language::DEFAULT_SOURCE_LANGUAGE)
        expect(assigns(:target_language).code).to eq(Language::DEFAULT_TARGET_LANGUAGE)
      end
    end

    context 'query normalization' do
      it 'normalizes by trimming, lowercasing, and collapsing interior whitespace' do
        get translations_path, params: { q: '   Hello   WORLD   ' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:query)).to eq('Hello   WORLD')
        expect(assigns(:normalized_query)).to eq('hello world')
      end
    end

    context 'when the language code is invalid' do
      it 'falls back to default languages' do
        get translations_path, params: { q: 'x', source_language: 'zzz' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:source_language).code).to eq(Language::DEFAULT_SOURCE_LANGUAGE)
      end
    end

    context 'when translations exist but not for the selected language pair' do
      it 'returns an empty list' do
        spanish = create(:language, :es)
        create_translation(language1: english, language2: spanish, text1: 'hello')

        get translations_path, params: {
          q: 'hello',
          source_language: english.code,
          target_language: farsi.code
        }

        expect(response).to have_http_status(:ok)
        expect(assigns(:translations)).to eq([])
      end
    end
  end
end
