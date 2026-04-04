# == Schema Information
#
# Table name: players
#
#  id                                                 :bigint           not null, primary key
#  avatar(Player avatar url)                          :text
#  current_sign_in_at                                 :datetime
#  current_sign_in_ip                                 :string
#  last_sign_in_at                                    :datetime
#  last_sign_in_ip                                    :string
#  name(Player screen name)                           :string           not null
#  provider(Omniauth provider)                        :string
#  remember_created_at                                :datetime
#  role(Player role for permissions)                  :string           not null
#  sign_in_count                                      :integer          default(0), not null
#  total_vps_earned(Total WAR VPs earned, not capped) :integer          default(0), not null
#  uid(Omniauth uid)                                  :string
#  vps(WAR VPs earned up to ruleset max)              :integer          default(0), not null
#  created_at                                         :datetime         not null
#  updated_at                                         :datetime         not null
#  discord_id(Discord id)                             :string
#
# Indexes
#
#  index_players_on_provider_and_uid  (provider,uid) UNIQUE
#
require "rails_helper"

RSpec.describe Player, type: :model do
  let!(:player) { create :player }

  describe 'associations' do
    it { should have_many(:companies) }
    it { should have_many(:factions) }
    it { should have_many(:doctrines) }
    it { should have_one(:player_rating) }
    it { should have_many(:historical_player_ratings) }
  end

  describe "#from_omniauth" do
    let!(:player) { create :player }
    let(:nickname) { "nickname" }
    let(:image) { "www.image.com" }
    let(:info_double) { double("info", nickname: nickname, image: image) }
    let(:provider) { "provider" }
    let(:uid) { "1234" }
    let(:auth_double) { double("auth", info: info_double, provider: provider, uid: uid) }

    subject { described_class.from_omniauth(auth_double) }

    context "when there is no player for the provider and uid values" do
      it "creates a Player" do
        expect { subject }.to change { Player.count }.by 1

        p = Player.last
        expect(p.name).to eq nickname
        expect(p.avatar).to eq image
        expect(p.provider).to eq provider
        expect(p.uid).to eq uid
        expect(p.discord_id).to be nil
        expect(p.player?).to be true
      end

      context "when there is a matching player name in PlayerDiscordTemp" do
        let!(:pdt) { create :player_discord_temp, player_name: nickname, discord_id: 123456 }

        it 'creates a Player with discord_id populated' do
          expect { subject }.to change { Player.count }.by 1

          p = Player.last
          expect(p.name).to eq nickname
          expect(p.discord_id).to eq pdt.discord_id
        end
      end

      context "when there is no historical player rating" do
        it "creates a PlayerRating with default values" do
          expect { subject }.to change { PlayerRating.count }.by 1
          pr = PlayerRating.last

          expect(pr.player).to eq Player.last
          expect(pr.player.provider).to eq provider
          expect(pr.player.uid).to eq uid
          expect(pr.elo).to eq PlayerRating::DEFAULT_ELO
          expect(pr.mu).to eq PlayerRating::DEFAULT_MU
          expect(pr.sigma).to eq PlayerRating::DEFAULT_SIGMA
          expect(pr.last_played).to be nil
        end
      end

      context "when there is no matching historical player rating with the same name" do
        let!(:hpr) { create :historical_player_rating, player_name: "some other name",
                            player: nil, elo: 1233, mu: 21.2, sigma: 3.2312, last_played: Date.parse("2023-01-01") }

        it "creates a PlayerRating with default values" do
          expect { subject }.to change { PlayerRating.count }.by 1
          pr = PlayerRating.last

          expect(pr.player).to eq Player.last
          expect(pr.player.provider).to eq provider
          expect(pr.player.uid).to eq uid
          expect(pr.elo).to eq PlayerRating::DEFAULT_ELO
          expect(pr.mu).to eq PlayerRating::DEFAULT_MU
          expect(pr.sigma).to eq PlayerRating::DEFAULT_SIGMA
          expect(pr.last_played).to be nil
        end
      end

      context "when there is a matching historical player rating" do
        let(:elo) { 1400 }
        let(:mu) { 24.3484584 }
        let(:sigma) { 4.294785963 }
        let(:last_played) { "2023-04-01" }
        let!(:hpr) { create :historical_player_rating, player_name: nickname.upcase, player: nil, elo: elo, mu: mu, sigma: sigma, last_played: last_played }

        it "creates a PlayerRating with historical player rating values" do
          expect { subject }.to change { PlayerRating.count }.by 1
          pr = PlayerRating.last

          expect(pr.player).to eq Player.last
          expect(pr.player.provider).to eq provider
          expect(pr.player.uid).to eq uid
          expect(pr.elo).to eq elo
          expect(pr.mu).to eq mu
          expect(pr.sigma).to eq sigma
          expect(pr.last_played).to eq Date.parse(last_played)
        end
      end
    end

    context "when there is an existing player for the provider and uid values" do
      let!(:player) { create :player, provider: provider, uid: uid }

      it "updates the existing player" do
        expect { subject }.not_to change { Player.count }
        expect(player.reload.name).to eq nickname
        expect(player.avatar).to eq image
        expect(player.provider).to eq provider
        expect(player.uid).to eq uid
      end

      it "does not create a PlayerRating" do
        expect { subject }.not_to change { PlayerRating.count }
      end
    end
  end
end
