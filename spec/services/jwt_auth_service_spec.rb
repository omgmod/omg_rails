require "rails_helper"

RSpec.describe JwtAuthService do
  let!(:player) { create :player, name: "TestPlayer" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("DEVISE_JWT_SECRET_KEY").and_return("test-secret-key")
  end

  describe ".encode" do
    subject { described_class.encode(player) }

    it "returns a hash with jwt, expires_at, and user" do
      result = subject
      expect(result[:jwt]).to be_a(String)
      expect(result[:expires_at]).to be_a(String)
      expect(result[:user][:id]).to eq(player.id)
      expect(result[:user][:name]).to eq(player.name)
    end

    it "sets expires_at to 24 hours from now" do
      result = subject
      expires_at = Time.parse(result[:expires_at])
      expect(expires_at).to be_within(5.seconds).of(24.hours.from_now)
    end
  end

  describe ".decode" do
    it "decodes a valid token" do
      token = described_class.encode(player)[:jwt]
      payload = described_class.decode(token)
      expect(payload["player_id"]).to eq(player.id)
    end

    it "returns nil for an invalid token" do
      expect(described_class.decode("invalid-token")).to be_nil
    end

    it "returns nil for an expired token" do
      allow(described_class).to receive(:const_get).with(:EXPIRATION).and_return(-1.hour)
      expired_payload = { player_id: player.id, exp: 1.hour.ago.to_i }
      token = JWT.encode(expired_payload, "test-secret-key", "HS256")
      expect(described_class.decode(token)).to be_nil
    end
  end
end