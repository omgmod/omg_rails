# == Schema Information
#
# Table name: companies
#
#  id                                       :bigint           not null, primary key
#  fuel(Fuel available to this company)     :integer          default(0), not null
#  man(Manpower available to this company)  :integer          default(0), not null
#  mun(Munitions available to this company) :integer          default(0), not null
#  name(Company name)                       :string
#  pop(Population cost of this company)     :integer          default(0), not null
#  type(Company type)                       :string           not null
#  uuid(Uuid)                               :string           not null
#  vps_current(VPs available to spend)      :integer          default(0), not null
#  vps_earned(VPs earned by this company)   :integer          default(0), not null
#  created_at                               :datetime         not null
#  updated_at                               :datetime         not null
#  doctrine_id                              :bigint           not null
#  faction_id                               :bigint           not null
#  player_id                                :bigint           not null
#  ruleset_id                               :bigint           not null
#
# Indexes
#
#  index_companies_on_doctrine_id  (doctrine_id)
#  index_companies_on_faction_id   (faction_id)
#  index_companies_on_player_id    (player_id)
#  index_companies_on_ruleset_id   (ruleset_id)
#  index_companies_on_uuid         (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (doctrine_id => doctrines.id)
#  fk_rails_...  (faction_id => factions.id)
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (ruleset_id => rulesets.id)
#
class Company < ApplicationRecord
  belongs_to :player
  belongs_to :doctrine
  belongs_to :faction
  belongs_to :ruleset

  has_many :available_units, dependent: :destroy
  has_many :available_offmaps, dependent: :destroy
  has_many :available_upgrades, dependent: :destroy

  has_many :active_units, -> { unit_active },  class_name: "AvailableUnit"
  has_many :active_offmaps, -> { offmap_active }, class_name: "AvailableOffmap"
  has_many :active_upgrades, -> { unit_active.upgrade_active }, class_name: "AvailableUpgrade"

  has_many :squads, dependent: :destroy
  has_many :squad_upgrades, through: :squads
  has_many :company_unlocks, dependent: :destroy
  has_many :doctrine_unlocks, through: :company_unlocks
  has_many :unlocks, through: :doctrine_unlocks
  has_many :company_offmaps, dependent: :destroy
  has_many :offmaps, -> { distinct }, through: :available_offmaps
  has_many :company_callin_modifiers, dependent: :destroy
  has_many :callin_modifiers, -> { distinct }, through: :company_callin_modifiers
  has_many :upgrades, -> { distinct }, through: :available_upgrades
  has_many :company_resource_bonuses, dependent: :destroy
  has_many :map_vetoes, dependent: :destroy
  has_many :vetoed_maps, through: :map_vetoes, source: :map
  has_many :battle_players, dependent: nil # Don't change the battle player
  has_many :transporting_transported_squads, through: :squads
  has_one :company_stats, dependent: :destroy

  validates_presence_of :faction
  validates_presence_of :doctrine
  validates_presence_of :player
  validates_presence_of :ruleset

  def resources_valid?
    !man.negative? && !mun.negative? && !fuel.negative?
  end

  def doctrine_name
    doctrine.name
  end

  def doctrine_display_name
    doctrine.display_name
  end

  def faction_name
    faction.name
  end

  def side
    faction.side
  end

  def active_battle_id
    battle_players.in_active_battle.first&.id # TODO Improve this
  end

  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :id
    expose :name
    expose :player_id, as: :playerId
    expose :doctrine_id, as: :doctrineId
    expose :faction_id, as: :factionId
    expose :man, :mun, :fuel, :pop
    expose :vps_earned, as: :vpsEarned
    expose :vps_current, as: :vpsCurrent
    expose :side
    expose :faction_name, as: :factionName
    expose :doctrine_name, as: :doctrineName
    expose :doctrine_display_name, as: :doctrineDisplayName
    expose :active_battle_id, as: :activeBattleId, if: { type: :full }
    expose :active_battle_id, as: :activeBattleId, if: { type: :with_active_battle }
    expose :type
    expose :ruleset_id, as: :rulesetId

    expose :available_units, as: :availableUnits, using: AvailableUnit::Entity, if: { type: :full }
    expose :squads, using: Squad::Entity, if: { type: :full }
    expose :company_unlocks, as: :unlocks, using: CompanyUnlock::Entity
    # TODO offmaps
    # TODO resource bonuses

    expose :company_stats, as: :companyStats, using: CompanyStats::Entity, if: { type: :with_stats }
    expose :company_stats, as: :companyStats, using: CompanyStats::Entity, if: { type: :full }
  end
end
