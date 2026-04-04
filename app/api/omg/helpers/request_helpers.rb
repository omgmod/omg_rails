module OMG
  module Helpers
    module RequestHelpers
      extend Grape::API::Helpers

      def declared_params
        @declared_params = declared(params)
      end

      def current_player
        @current_player ||= player_from_jwt || player_from_warden
      end

      def player_from_warden
        warden = env["warden"]
        warden.authenticate
      end

      def player_from_jwt
        header = headers["Authorization"] || env["HTTP_AUTHORIZATION"]
        return nil unless header&.start_with?("Bearer ")

        token = header.split(" ", 2).last
        payload = JwtAuthService.decode(token)
        return nil unless payload

        Player.find_by(id: payload["player_id"])
      end

      def authenticate!
        error!("401 Unauthorized", 401) unless current_player
        current_player.try :touch # Update player updated_at for online list
      end
    end
  end
end
