OmniAuth.config.test_mode = true

RSpec.configure do |config|
  config.before do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end

def mock_google_oauth(email: 'test@example.com')
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
    provider: 'google_oauth2',
    uid: '1234567890',
    info: {
      email: email,
      first_name: 'Test',
      last_name: 'User'
    }
  )
end
