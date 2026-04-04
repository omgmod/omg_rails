# == Schema Information
#
# Table name: battles
#
#  id                                                                   :bigint           not null, primary key
#  elo_diff(Elo difference between most balanced teams, absolute value) :integer
#  last_notified(Last time a notification was sent to players)          :datetime
#  map(Map name)                                                        :string
#  name(Optional battle name)                                           :string
#  size(Size of each team)                                              :integer          not null
#  state(Battle status)                                                 :string           not null
#  winner(Winning side)                                                 :string
#  created_at                                                           :datetime         not null
#  updated_at                                                           :datetime         not null
#  ruleset_id                                                           :bigint           not null
#
# Indexes
#
#  index_battles_on_ruleset_id  (ruleset_id)
#  index_battles_on_state       (state)
#
class Battle < ApplicationRecord
  belongs_to :ruleset
  has_many :battle_players, dependent: :destroy, inverse_of: :battle
  has_many :players, through: :battle_players
  has_many :player_ratings, through: :players, class_name: "PlayerRating"
  has_many :companies, through: :battle_players
  has_many :squads, through: :companies

  has_one_attached :sga_file
  has_one_attached :ucs_file
  has_one_attached :zip_file
  has_one_attached :report_file

  enum winner: {
    allied: "allied",
    axis: "axis"
  }

  BATTLE_SIZES = [1,2,3,4].freeze

  validates_presence_of :ruleset
  validates_presence_of :size
  validates_numericality_of :size

  state_machine :state, initial: :open do
    event :full do
      transition :open => :full
    end

    event :not_full do
      transition :full => :open
    end

    event :ready do
      transition :full => :generating
    end

    event :generated do
      transition :generating => :ingame
    end

    event :reporting do
      transition :ingame => :reporting
    end

    event :revert_reporting do
      transition :reporting => :ingame
    end

    event :finalize do
      transition :reporting => :final
    end

    event :abandoned do
      transition [:generating, :ingame, :reporting] => :abandoned
    end
  end

  def total_size
    size * 2
  end

  def players_full?
    battle_players.size == total_size
  end

  def any_players_ready?
    battle_players.any? { |bp| bp.ready }
  end

  def all_players_ready?
    battle_players.all? { |bp| bp.ready }
  end

  def both_sides_abandoned?
    allied_abandoned? && axis_abandoned?
  end

  def allied_abandoned?
    allied_battle_players.any? { |bp| bp.abandoned }
  end

  def axis_abandoned?
    axis_battle_players.any? { |bp| bp.abandoned }
  end

  def joinable?
    state == "open"
  end

  def leavable?
    %w[open full].include? state
  end

  def abandonable?
    %w[generating ingame reporting].include? state
  end

  def allied_battle_players
    battle_players.filter { |bp| bp.side == BattlePlayer::sides[:allied] }
  end

  def axis_battle_players
    battle_players.filter { |bp| bp.side == BattlePlayer::sides[:axis] }
  end

  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :id
    expose :name
    expose :size
    expose :state
    expose :ruleset_id, as: :rulesetId
    expose :winner
    expose :map
    expose :updated_at, as: :updatedAt
    expose :created_at, as: :createdAt

    expose :battle_players, as: :battlePlayers, using: BattlePlayer::Entity, if: { type: :include_players }
    expose :elo_diff, as: :eloDifference, if: { type: :include_players }
  end
end
