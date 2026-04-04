require "rails_helper"

RSpec.describe "Launcher Auth", type: :request do
  describe "GET /auth/login" do
    it "renders a form that POSTs to Steam auth when redirect_uri is valid" do
      get "/auth/login", params: { redirect_uri: "http://127.0.0.1:23847/callback" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="/players/auth/steam"')
      expect(response.body).to include('method="post"')
    end

    it "returns 400 for missing redirect_uri" do
      get "/auth/login"
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 400 for invalid redirect_uri host" do
      get "/auth/login", params: { redirect_uri: "http://evil.com/callback" }
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 400 for invalid redirect_uri port" do
      get "/auth/login", params: { redirect_uri: "http://127.0.0.1:9999/callback" }
      expect(response).to have_http_status(:bad_request)
    end

    it "stores launcher_redirect_uri in session" do
      get "/auth/login", params: { redirect_uri: "http://127.0.0.1:23847/callback" }
      expect(session[:launcher_redirect_uri]).to eq("http://127.0.0.1:23847/callback")
    end
  end

  describe "POST /api/auth/oauth_callback" do
    let!(:player) { create :player, uid: "12345", provider: "steam", current_sign_in_at: Time.current }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("DEVISE_JWT_SECRET_KEY").and_return("test-secret-key")
    end

    it "returns JWT for valid authorization code" do
      post "/api/auth/oauth_callback", params: { code: "12345" }
      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body["jwt"]).to be_present
      expect(body["expires_at"]).to be_present
      expect(body["user"]["id"]).to eq(player.id)
      expect(body["user"]["name"]).to eq(player.name)
    end

    it "returns 401 for invalid authorization code" do
      post "/api/auth/oauth_callback", params: { code: "invalid" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for expired authorization code" do
      player.update!(current_sign_in_at: 10.minutes.ago)
      post "/api/auth/oauth_callback", params: { code: "12345" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/auth/steam_ticket" do
    let(:steam_id) { "76561198000000001" }
    let(:ticket) { "abc123hex" }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("DEVISE_JWT_SECRET_KEY").and_return("test-secret-key")
      allow(ENV).to receive(:[]).with("STEAM_WEB_API_KEY").and_return("fake-steam-key")
      allow(ENV).to receive(:[]).with("STEAM_APP_ID").and_return("12345")
    end

    context "when Steam validates the ticket and player exists" do
      let!(:player) { create :player, uid: steam_id, provider: "steam" }

      before do
        auth_response = double(body: double(to_s: {
          response: { params: { result: "OK", steamid: steam_id } }
        }.to_json))
        allow(HTTP).to receive(:get)
          .with("https://api.steampowered.com/ISteamUserAuth/AuthenticateUserTicket/v1/", anything)
          .and_return(auth_response)
      end

      it "returns JWT for existing player" do
        post "/api/auth/steam_ticket", params: { ticket: ticket }
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body["jwt"]).to be_present
        expect(body["user"]["id"]).to eq(player.id)
      end
    end

    context "when Steam validates the ticket and player does not exist" do
      before do
        auth_response = double(body: double(to_s: {
          response: { params: { result: "OK", steamid: steam_id } }
        }.to_json))
        allow(HTTP).to receive(:get)
          .with("https://api.steampowered.com/ISteamUserAuth/AuthenticateUserTicket/v1/", anything)
          .and_return(auth_response)

        profile_response = double(body: double(to_s: {
          response: { players: [{ "personaname" => "NewPlayer", "avatarfull" => "http://avatar.url" }] }
        }.to_json))
        allow(HTTP).to receive(:get)
          .with("https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/", anything)
          .and_return(profile_response)
      end

      it "creates a new player and returns JWT" do
        expect { post "/api/auth/steam_ticket", params: { ticket: ticket } }.to change { Player.count }.by(1)
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body["jwt"]).to be_present
        expect(body["user"]["name"]).to eq("NewPlayer")
      end
    end

    context "when Steam rejects the ticket" do
      before do
        auth_response = double(body: double(to_s: {
          response: { error: { errorcode: 101, errordesc: "Invalid ticket" } }
        }.to_json))
        allow(HTTP).to receive(:get)
          .with("https://api.steampowered.com/ISteamUserAuth/AuthenticateUserTicket/v1/", anything)
          .and_return(auth_response)
      end

      it "returns 401" do
        post "/api/auth/steam_ticket", params: { ticket: ticket }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end