class AuthenticationController < Devise::OmniauthCallbacksController
  # We must disable CSRF check when Steam issues the callback request.
  skip_before_action :verify_authenticity_token

  def steam
    auth = request.env["omniauth.auth"]

    if auth.info.nickname.blank?
      msg = "[AuthenticationController] Received steam omniauth response with null nickname: #{auth}"
      Rails.logger.error(msg)
      Sentry.capture_message(msg)
      # error scenario with Steam OpenID, retry
      redirect_to after_omniauth_failure_path_for(resource_name)
    else
      @player = Player.from_omniauth(auth)
      sign_in_and_redirect @player
    end
  end

  protected

  def after_omniauth_failure_path_for(scope)
    "/players/auth/steam"
  end
end
