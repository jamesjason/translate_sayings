module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      auth = request.env['omniauth.auth']
      user = User.authenticate_via_google(
        provider: auth.provider,
        uid: auth.uid,
        email: auth.info.email,
        name: auth.info.name
      )

      if user.present?
        set_flash_message!(:notice, :signed_in, scope: 'devise.sessions')
        sign_in_and_redirect user, event: :authentication
      else
        redirect_to new_user_session_path, alert: t('devise.oauth.google_failure')
      end
    end

    def failure
      redirect_to new_user_session_path
    end
  end
end
