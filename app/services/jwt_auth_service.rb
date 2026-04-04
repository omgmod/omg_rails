class JwtAuthService
  ALGORITHM = "HS256"
  EXPIRATION = 24.hours

  def self.secret_key
    ENV["DEVISE_JWT_SECRET_KEY"]
  end

  def self.encode(player)
    expires_at = EXPIRATION.from_now
    payload = {
      player_id: player.id,
      exp: expires_at.to_i
    }
    token = JWT.encode(payload, secret_key, ALGORITHM)
    { jwt: token, expires_at: expires_at.iso8601, user: { id: player.id, name: player.name } }
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret_key, true, algorithms: [ALGORITHM])
    decoded.first
  rescue JWT::DecodeError
    nil
  end
end