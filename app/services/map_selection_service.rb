class MapSelectionService
  def initialize(battle)
    @battle = battle
  end

  def select_map
    return if Map.enabled.none?

    company_ids = @battle.battle_players.pluck(:company_id)
    vetoed_map_ids = MapVeto.where(company_id: company_ids).pluck(:map_id).uniq

    eligible = Map.enabled.where.not(id: vetoed_map_ids)
    eligible = Map.enabled if eligible.empty?

    selected = eligible.order("RANDOM()").first
    @battle.update!(map: selected.name)
    selected
  end
end
