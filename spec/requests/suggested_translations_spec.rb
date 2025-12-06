require 'rails_helper'

RSpec.describe 'SuggestedTranslations', type: :request do
  before do
    create_default_languages
  end

  describe 'GET /contribute' do
    it 'returns OK' do
      get contribute_path
      expect(response).to have_http_status(:ok)
    end

    it 'stores return location for after login' do
      get contribute_path
      expect(session['user_return_to']).to eq(contribute_path)
    end

    it 'renders the suggested translation form' do
      get contribute_path

      expect(response.body).to include(%(action="/suggested_translations"))
      expect(response.body).to include(%(name="suggested_translation[source_language_code]"))
      expect(response.body).to include(%(value="en"))
      expect(response.body).to include(%(name="suggested_translation[target_language_code]"))
      expect(response.body).to include(%(value="es"))
      expect(response.body).to include(%(name="suggested_translation[source_saying_text]"))
      expect(response.body).to include(%(name="suggested_translation[target_saying_text]"))

      expect(response.body).to include('Add Translation')
    end
  end

  describe 'POST /suggested_translations' do
    let(:user) { create(:user) }
    let(:valid_params) do
      {
        suggested_translation: {
          source_language_code: 'en',
          target_language_code: 'fa',
          source_saying_text: 'hello world',
          target_saying_text: 'salam'
        }
      }
    end

    context 'when user is not authenticated' do
      it 'redirects to the sign in page' do
        post suggested_translations_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      it 'creates a suggested translation' do
        english, persian = Language.where(code: %w[en fa]).index_by(&:code).values_at('en', 'fa')

        expect do
          post suggested_translations_path, params: valid_params
        end.to change(SuggestedTranslation, :count).by(1)

        translation = SuggestedTranslation.last
        expect(translation.user).to eq(user)
        expect(translation.source_language).to eq(english)
        expect(translation.target_language).to eq(persian)
        expect(translation.source_saying_text).to eq('hello world')
        expect(translation.target_saying_text).to eq('salam')
      end

      it 'sets inline flash' do
        post suggested_translations_path, params: valid_params
        expect(flash[:inline_flash]).to be(true)
      end

      it 'redirects to contribute with form anchor' do
        post suggested_translations_path, params: valid_params
        expect(response).to redirect_to(contribute_path(anchor: 'form'))
      end

      it 're-renders the form when language code cannot be resolved' do
        bad_params = valid_params.deep_merge(
          suggested_translation: { source_language_code: 'INVALID' }
        )

        post suggested_translations_path, params: bad_params

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(%(action="/suggested_translations"))
      end

      it 're-renders the form when validations fail' do
        invalid_params = {
          suggested_translation: {
            source_language_code: 'en',
            target_language_code: 'fa',
            source_saying_text: '',
            target_saying_text: ''
          }
        }

        post suggested_translations_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)

        expect(response.body).to include(%(action="/suggested_translations"))
        expect(response.body).to include('data-test="error-messages"')
      end
    end
  end
end
