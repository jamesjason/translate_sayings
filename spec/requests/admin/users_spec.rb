require 'rails_helper'

RSpec.describe 'Admin::Users', type: :request do
  let(:user)  { create(:user) }
  let(:admin) { create(:user, :admin) }

  describe 'GET /admin/users' do
    context 'when logged in as admin' do
      before { sign_in admin }

      it 'returns success' do
        get admin_users_path
        expect(response).to have_http_status(:ok)
      end

      it 'lists admin users' do
        get admin_users_path
        expect(response.body).to include('Admin – Users')
        expect(response.body).to include(admin.email)
      end
    end

    context 'when not logged in' do
      it_behaves_like 'requires authentication', :admin_users_path
    end

    context 'when logged in as normal user' do
      it_behaves_like 'requires admin', :admin_users_path
    end
  end

  describe 'GET /admin/users/:id' do
    let!(:suggested_translation) { create(:suggested_translation, user: user) }

    context 'when logged in as admin' do
      before { sign_in admin }

      it 'returns success' do
        get admin_user_path(user)
        expect(response).to have_http_status(:ok)
      end

      it 'shows suggested translations' do
        get admin_user_path(user)
        expect(response.body).to include(suggested_translation.source_saying_text)
        expect(response.body).to include(suggested_translation.target_saying_text)
      end
    end

    context 'when not logged in' do
      it_behaves_like 'requires authentication', :admin_user_path, :user
    end

    context 'when logged in as normal user' do
      it_behaves_like 'requires admin', :admin_user_path, :user
    end
  end
end
