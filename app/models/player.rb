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
class Player < ApplicationRecord
  include ActiveModel::Serializers::JSON
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :rememberable, :trackable, :timeoutable, :omniauthable, omniauth_providers: %i[steam]

  def self.from_omniauth(auth)
    player = find_by(provider: auth.provider, uid: auth.uid)
    if player.present?
      # Rails.logger.info("Player found from omniauth: #{player.name}")
      player.name = auth.info.nickname
      player.avatar = auth.info.image
      player.save!
    else
      pdt = PlayerDiscordTemp.find_by(player_name: auth.info.nickname)
      player = create!(provider: auth.provider, uid: auth.uid, name: auth.info.nickname, avatar: auth.info.image, discord_id: pdt&.discord_id, role: roles[:player])
      # Rails.logger.info("Player created from omniauth: #{player.name}")

      # try to match nickname to historical player rating with nil player_id
      hpr = HistoricalPlayerRating.find_by(player_name: player.name.upcase, player_id: nil)
      if hpr.present?
        # Rails.logger.info("Found historical player rating for player #{player.name}")
        PlayerRating.create!(player: player, elo: hpr.elo, mu: hpr.mu, sigma: hpr.sigma, last_played: hpr.last_played)
        hpr.update!(player_id: player.id)
      else
        # Rails.logger.info("Created default PlayerRating for player #{player.name}")
        PlayerRating.for_new_player(player)
      end
    end

    player.remember_me!
    player
  end

  enum role: {
    player: "player",
    admin: "admin"
  }

  has_many :companies, inverse_of: :player
  has_many :doctrines, through: :companies
  has_many :factions, through: :companies
  has_one :player_rating, inverse_of: :player
  has_many :historical_player_ratings, inverse_of: :player
  has_many :historical_battle_players, inverse_of: :player

  scope :online, -> { where("updated_at > ? ", 10.minutes.ago) }

  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :id
    expose :name
    expose :avatar
    expose :role
  end
end
