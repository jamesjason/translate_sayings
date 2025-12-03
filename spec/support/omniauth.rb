OmniAuth.config.test_mode = true

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
