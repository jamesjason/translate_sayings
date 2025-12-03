require 'rails_helper'

RSpec.describe 'TranslationReviews', type: :request do
  let!(:english) { create(:language) }
  let!(:farsi)   { create(:language, :fa) }

  describe 'GET /translation_reviews' do
    it 'returns correctly structured JSON with all required fields' do
      translation = create_translation(
        language1: english, text1: 'hello',
        language2: farsi,   text2: 'salam'
      )
      create(:translation_vote, saying_translation: translation, vote: 1)
      create(:translation_vote, saying_translation: translation, vote: 1)

      get translation_reviews_path, params: {
        language_a_code: english.code,
        language_b_code: farsi.code
      }

      json = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json).to have_key('translations')
      expect(json['translations']).to be_an(Array)
      expect(json['translations'].size).to eq(1)

      expect(json['translations'].first).to match(
        'id' => translation.id,
        'saying_a' => 'hello',
        'saying_b' => 'salam',
        'upvotes' => 2,
        'downvotes' => 0,
        'user_vote' => 0
      )
    end

    it 'returns empty array when no translations match' do
      get translation_reviews_path, params: {
        language_a_code: english.code,
        language_b_code: farsi.code
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['translations']).to eq([])
    end

    it 'falls back to default languages if invalid codes are passed' do
      create_translation(language1: english, language2: farsi)

      get translation_reviews_path, params: {
        language_a_code: 'INVALID',
        language_b_code: 'WRONG'
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['translations']).to be_an(Array)
    end
  end

  describe 'POST /translation_reviews/vote' do
    let(:user)        { create(:user) }
    let(:translation) { create_translation(language1: english, language2: farsi) }

    context 'when authenticated' do
      before { sign_in user }

      it 'registers a valid vote and returns updated counts' do
        post vote_translation_reviews_path, params: { id: translation.id, vote: 1 }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          'upvotes' => 1,
          'downvotes' => 0,
          'user_vote' => 1
        )
      end

      it 'toggles vote when the same value is submitted again' do
        create(:translation_vote, user:, saying_translation: translation, vote: 1)

        post vote_translation_reviews_path, params: { id: translation.id, vote: 1 }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          'upvotes' => 0,
          'downvotes' => 0,
          'user_vote' => 0
        )
      end

      it 'returns 404 when translation is not found' do
        invalid_id = SayingTranslation.maximum(:id).to_i + 1

        post vote_translation_reviews_path, params: { id: invalid_id, vote: 1 }

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['error']).to eq('Translation not found')
      end

      it 'returns errors for invalid vote value' do
        post vote_translation_reviews_path, params: { id: translation.id, vote: 2 }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['errors']).to include(
          'Vote must be -1 (downvote), 0 (neutral), or 1 (upvote)'
        )
      end
    end

    context 'when not authenticated' do
      it 'redirects to the sign-in page' do
        post vote_translation_reviews_path, params: { id: translation.id, vote: 1 }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
