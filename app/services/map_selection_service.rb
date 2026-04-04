class MapSelectionService
  def initialize(battle)
    @battle = battle
  end

  def select_map
    return if Map.enabled.none?

    size_prefix = "#{@battle.total_size}p_%"
    size_maps = Map.enabled.where("name LIKE ?", size_prefix)
    return if size_maps.none?

    company_ids = @battle.battle_players.pluck(:company_id)
    vetoed_map_ids = MapVeto.where(company_id: company_ids).pluck(:map_id).uniq

    eligible = size_maps.where.not(id: vetoed_map_ids)
    eligible = size_maps if eligible.empty?

    selected = eligible.order("RANDOM()").first
    @battle.update!(map: selected.name)
    selected
  end
end
