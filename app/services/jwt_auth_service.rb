class JwtAuthService
  SECRET_KEY = ENV["DEVISE_JWT_SECRET_KEY"]
  ALGORITHM = "HS256"
  EXPIRATION = 24.hours

  def self.encode(player)
    expires_at = EXPIRATION.from_now
    payload = {
      player_id: player.id,
      exp: expires_at.to_i
    }
    token = JWT.encode(payload, SECRET_KEY, ALGORITHM)
    { jwt: token, expires_at: expires_at.iso8601, user: { id: player.id, name: player.name } }
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: ALGORITHM)
    decoded.first
  rescue JWT::DecodeError
    nil
  end
end