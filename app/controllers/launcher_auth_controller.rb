class LauncherAuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:login]

  ALLOWED_REDIRECT_HOST = "127.0.0.1"
  ALLOWED_REDIRECT_PORT = 23847

  def login
    redirect_uri = params[:redirect_uri]

    unless valid_launcher_redirect?(redirect_uri)
      render plain: "Invalid redirect_uri", status: :bad_request
      return
    end

    session[:launcher_redirect_uri] = redirect_uri
    redirect_to "/players/auth/steam", allow_other_host: true
  end

  private

  def valid_launcher_redirect?(uri)
    return false if uri.blank?

    parsed = URI.parse(uri)
    parsed.host == ALLOWED_REDIRECT_HOST && parsed.port == ALLOWED_REDIRECT_PORT
  rescue URI::InvalidURIError
    false
  end
end