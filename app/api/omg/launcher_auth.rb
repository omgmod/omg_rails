module OMG
  class LauncherAuth < Grape::API
    resource :auth do
      desc 'Exchange authorization code for JWT after browser OAuth flow'
      params do
        requires :code, type: String, desc: 'Authorization code from OAuth callback'
      end
      post :oauth_callback do
        code = declared(params)[:code]

        # The code is the player's Steam UID that was set during the browser OAuth flow
        player = Player.find_by(uid: code, provider: "steam")
        unless player
          error!("Invalid authorization code", 401)
        end

        # Verify the code hasn't expired (must be used within 5 minutes of last sign in)
        if player.current_sign_in_at.nil? || player.current_sign_in_at < 5.minutes.ago
          error!("Authorization code expired", 401)
        end

        present JwtAuthService.encode(player)
      end

      desc 'Authenticate via Steam session ticket'
      params do
        requires :ticket, type: String, desc: 'Steam encrypted application ticket (hex-encoded)'
      end
      post :steam_ticket do
        ticket = declared(params)[:ticket]

        steam_api_key = ENV["STEAM_WEB_API_KEY"]
        error!("Steam API key not configured", 500) unless steam_api_key.present?

        # Validate the ticket with Steam Web API
        response = HTTP.get(
          "https://api.steampowered.com/ISteamUserAuth/AuthenticateUserTicket/v1/",
          params: {
            key: steam_api_key,
            appid: ENV["STEAM_APP_ID"],
            ticket: ticket
          }
        )

        result = JSON.parse(response.body.to_s)
        auth_response = result.dig("response", "params")

        unless auth_response && auth_response["result"] == "OK"
          Rails.logger.error("[LauncherAuth] Steam ticket validation failed: #{result}")
          error!("Steam ticket validation failed", 401)
        end

        steam_id = auth_response["steamid"]

        # Find or create the player
        player = Player.find_by(uid: steam_id, provider: "steam")
        unless player
          # Fetch player info from Steam
          profile_response = HTTP.get(
            "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/",
            params: { key: steam_api_key, steamids: steam_id }
          )
          profile_result = JSON.parse(profile_response.body.to_s)
          profile = profile_result.dig("response", "players")&.first

          unless profile
            Rails.logger.error("[LauncherAuth] Failed to fetch Steam profile for #{steam_id}")
            error!("Failed to fetch Steam profile", 500)
          end

          nickname = profile["personaname"]
          avatar = profile["avatarfull"]

          if nickname.blank?
            error!("Steam profile has no display name", 422)
          end

          pdt = PlayerDiscordTemp.find_by(player_name: nickname)
          player = Player.create!(
            provider: "steam",
            uid: steam_id,
            name: nickname,
            avatar: avatar,
            discord_id: pdt&.discord_id,
            role: Player.roles[:player]
          )

          hpr = HistoricalPlayerRating.find_by(player_name: player.name.upcase, player_id: nil)
          if hpr.present?
            PlayerRating.create!(player: player, elo: hpr.elo, mu: hpr.mu, sigma: hpr.sigma, last_played: hpr.last_played)
            hpr.update!(player_id: player.id)
          else
            PlayerRating.for_new_player(player)
          end
        end

        present JwtAuthService.encode(player)
      end
    end
  end
end