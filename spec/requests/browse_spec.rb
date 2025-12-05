require 'rails_helper'

RSpec.describe 'BrowseController', type: :request do
  let!(:english) { create(:language) }

  describe 'GET /browse/:code' do
    it 'returns 200 for a valid language' do
      get browse_path(english.code)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'letter filtering for English' do
    before do
      create(:saying, language: english, text: 'apple pie', slug: 'apple-pie')
      create(:saying, language: english, text: 'banana bread', slug: 'banana-bread')
    end

    it 'filters by first letter when letter is valid' do
      get browse_path(english.code, letter: 'A')
      expect(response.body).to include('apple pie')
      expect(response.body).not_to include('banana bread')
    end

    it 'ignores invalid letters' do
      get browse_path(english.code, letter: '9')
      expect(response.body).to include('apple pie')
      expect(response.body).to include('banana bread')
    end
  end
end
