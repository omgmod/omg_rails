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
class SnapshotCompany < Company
  LIMIT = 12.freeze

  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :id
    expose :name
    expose :uuid
    expose :player_id, as: :playerId
    expose :doctrine_id, as: :doctrineId
    expose :faction_id, as: :factionId
    expose :faction_name, as: :factionName
    expose :doctrine_name, as: :doctrineName
    expose :doctrine_display_name, as: :doctrineDisplayName
    expose :side
    expose :type
    expose :man, :mun, :fuel, :pop
    expose :vps_earned, as: :vpsEarned
    expose :vps_current, as: :vpsCurrent

    expose :company_unlocks, as: :unlocks, using: CompanyUnlock::Entity

    # expose :available_units, as: :availableUnits, using: AvailableUnit::Entity, if: { type: :full }
    # expose :squads, using: Squad::Entity, if: { type: :full }
    # expose :company_unlocks, as: :companyUnlocks, using: CompanyUnlock::Entity, if: { type: :full }
    # expose :company_offmaps, as: :companyOffmaps, using: CompanyOffmap::Entity, if: { type: :full }
    # # expose :company_resource_bonuses, as: :companyResourceBonuses, using: CompanyResourceBonus::Entity, if: { type: :full }
    # expose :company_stats, as: :companyStats, using: CompanyStats::Entity, if: { type: :full }
  end
end
