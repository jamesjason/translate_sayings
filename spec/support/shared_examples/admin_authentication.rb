RSpec.shared_examples 'requires authentication' do |path_helper, arg_name = nil|
  it 'redirects to sign in with Devise alert' do
    arg = arg_name ? send(arg_name) : nil
    get public_send(path_helper, arg)
    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:alert]).to eq('You need to sign in or sign up before continuing.')
  end
end

RSpec.shared_examples 'requires admin' do |path_helper, arg_name = nil|
  it 'redirects non-admin user to root with unauthorized message' do
    sign_in create(:user)
    arg = arg_name ? send(arg_name) : nil
    get public_send(path_helper, arg)
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq('Not authorized')
  end
end
