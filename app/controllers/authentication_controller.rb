class AuthenticationController < Devise::OmniauthCallbacksController
  # We must disable CSRF check when Steam issues the callback request.
  skip_before_action :verify_authenticity_token

  def steam
    auth = request.env["omniauth.auth"]

    if auth.info.nickname.blank?
      msg = "[AuthenticationController] Received steam omniauth response with null nickname: #{auth.to_hash}"
      msg_info = "[AuthenticationController] AuthHash valid?: #{auth.valid?}, Auth info hash valid?: #{auth.info.valid?}, Auth info hash name: #{auth.info.name}, Auth info hash nickname: #{auth.info.nickname}"
      Rails.logger.error(msg)
      Sentry.capture_message(msg)
      Rails.logger.error(msg_info)
      Sentry.capture_message(msg_info)
      # error scenario with Steam OpenID, retry
      redirect_to after_omniauth_failure_path_for(resource_name), method: :post
    else
      @player = Player.from_omniauth(auth)

      if session[:launcher_redirect_uri].present?
        launcher_redirect_uri = session.delete(:launcher_redirect_uri)
        sign_in @player
        @player.update!(current_sign_in_at: Time.current)
        # Redirect to the launcher's local callback with the player's UID as the authorization code
        redirect_uri = URI.parse(launcher_redirect_uri)
        redirect_uri.query = URI.encode_www_form(code: @player.uid)
        redirect_to redirect_uri.to_s, allow_other_host: true
      else
        sign_in_and_redirect @player
      end
    end
  end

  protected

  def after_omniauth_failure_path_for(scope)
    "/players/auth/steam"
  end
end
