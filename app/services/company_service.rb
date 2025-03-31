require 'securerandom'

class CompanyService
  class CompanyCreationValidationError < StandardError; end

  class CompanyUpdateValidationError < StandardError; end

  class CompanyDeletionValidationError < StandardError; end

  MAX_COMPANIES_PER_SIDE = 3.freeze

  MIN_POP_PER_PLATOON = 7.freeze
  MAX_POP_PER_PLATOON = 25.freeze

  def initialize(player)
    @player = player
  end

  def create_company(doctrine, name, ruleset_id)
    unless can_create_company(doctrine)
      raise CompanyCreationValidationError.new("Player #{@player.id} has too many #{doctrine.faction.side} companies, cannot create another one.")
    end

    unless name.length.between?(1, 50)
      raise CompanyCreationValidationError.new("Company name must be between 1 and 50 characters")
    end

    # Get ruleset
    ruleset = Ruleset.find_by!(id: ruleset_id)

    validate_active_ruleset(ruleset)

    # Starting vps
    vps = [@player.vps + ruleset.starting_vps, ruleset.max_vps].min

    ActiveRecord::Base.transaction do
      # Create Company entity
      new_company = ActiveCompany.create!(name: name,
                                          uuid: SecureRandom.uuid,
                                          player: @player,
                                          doctrine: doctrine,
                                          faction: doctrine.faction,
                                          vps_earned: vps,
                                          vps_current: vps,
                                          man: ruleset.starting_man,
                                          mun: ruleset.starting_mun,
                                          fuel: ruleset.starting_fuel,
                                          pop: 0,
                                          ruleset: ruleset
      )

      # Create AvailableUnits for the Company
      available_units_service = AvailableUnitService.new(new_company)
      available_units_service.build_new_company_available_units

      # Create AvailableOffmaps for the Company
      available_offmaps_service = AvailableOffmapService.new(new_company)
      available_offmaps_service.build_new_company_available_offmaps

      # Create AvailableUpgrades for the Company
      available_upgrade_service = AvailableUpgradeService.new(new_company)
      available_upgrade_service.build_new_company_available_upgrades

      # Create CompanyStats for the Company
      CompanyStats.create!(company: new_company)

      new_company
    end
  end

  # Takes the set of squads, validates that the company can upsert all of the squads, and persists them, overwriting old
  # squads as necessary. If an existing Squad is not in the new list of squads, it will be destroyed.
  #
  # If squads have transportUuids, must have a matching squad with those squads' uuids in its transportedSquadUuid list.
  # Construct TransportedSquad associating the transport to the embarked squads.
  # If the transportUuid does not match, persist the squads without a TransportedSquad association.
  #
  # Takes the input offmaps, validates that the company can upsert all of the offmaps, and persists them. Deletes any
  # existing company offmaps that are not in that set of offmaps.
  #
  # Takes the input squad upgrades, compares against existing squad upgrades to determine
  # 1. The set of existing squad upgrades that will remain
  # 2. The set of existing squad upgrades that will be destroyed
  # 3. The set of new squad upgrades to create
  #
  # Validates:
  # * The company belongs to the player, or an override is used
  # * The set of squad ids represent Squads belonging to the company
  # * The set of unit ids given in squads contain valid Unit ids
  # * The set of unit ids given in squads are a subset of the company's AvailableUnit unit ids
  # * The company has sufficient manpower, munitions, and fuel resources to afford all given squads
  # * Each platoon of squads (squads grouped by tab and index) has pop between the MIN and MAX allowed
  # * The company has sufficient availability in AvailableUnits for every unique unit in the given squads
  def update_company_squads(company, squads, offmaps, squad_upgrades, override = false)
    unless can_update_company(company, override)
      # Raise validation error if the company does not belong to the player
      raise CompanyUpdateValidationError.new("Player #{@player.id} cannot modify Company #{company.id}")
    end

    # Validate not in battle
    validate_company_not_in_battle(company)

    ## Squads
    existing_squads = company.squads
    existing_squad_ids = existing_squads.pluck(:id)
    payload_squad_ids = squads.select { |s| s[:squad_id].present? }.pluck(:squad_id)
    # Validates that all squad ids in the squads payload are unique and correspond to an existing squad id in the company
    validate_incoming_squad_ids(payload_squad_ids, existing_squad_ids, company.id)

    # Company Offmaps
    existing_company_offmaps = company.company_offmaps
    existing_co_offmap_ids = existing_company_offmaps.pluck(:id)
    payload_co_offmap_ids = offmaps.select { |o| o[:company_offmap_id].present? }.pluck(:company_offmap_id)
    # Validates that all company_offmap ids in the offmaps payload are unique and correspond to an existing company_offmap id in the company
    validate_incoming_company_offmap_ids(payload_co_offmap_ids, existing_co_offmap_ids, company.id)

    ## Squad Upgrades
    existing_squad_upgrades = existing_squads.map { |s| s.squad_upgrades }.flatten
    existing_squad_upgrade_ids = existing_squad_upgrades.pluck(:id)
    payload_squad_upgrade_ids = squad_upgrades.select { |su| su[:squad_upgrade_id].present? }.pluck(:squad_upgrade_id)
    # Validates that all squad upgrade ids in the squad_upgrades payload are unique and correspond to an existing squad_upgrade id in the company
    validate_incoming_squad_upgrade_ids(payload_squad_upgrade_ids, existing_squad_upgrade_ids, company.id)

    ### Price every squad, offmap, and squad upgrade, sum up and validate against ruleset totals
    ### Raise validation error if insufficient

    ## Squads
    # Get unique squad units
    uniq_unit_ids_new = squads.map { |s| s[:unit_id] }.uniq
    uniq_units_new_by_id = Unit.where(id: uniq_unit_ids_new).index_by(&:id)

    # Validates that all unit ids correspond to existing units
    validate_squad_units_exist(uniq_unit_ids_new, uniq_units_new_by_id)

    # Get available units for the company - cost is stored there
    available_units = company.available_units

    # Get unique squad available_unit_ids
    uniq_available_unit_ids_new = squads.map { |s| s[:available_unit_id] }.uniq
    # Validate that all available_unit_ids correspond to existing available_units
    validate_squad_available_units_exist(uniq_available_unit_ids_new, available_units, company.id)

    # Validates that all unit ids correspond to available units
    validate_squad_units_available(uniq_unit_ids_new, available_units, company.id)

    # Index available_units by id
    available_units_by_id = available_units.index_by(&:id)

    # Build hash of tab and index to pop
    platoon_pop_by_tab_and_index = build_empty_tab_index_pop

    # Get available upgrades for the company - cost is stored there
    available_upgrades = company.available_upgrades
    # Index available upgrades by id
    available_upgrades_by_id = available_upgrades.index_by(&:id)
    # Get unique squad_upgrades payload available_upgrade_ids
    uniq_available_upgrade_ids_new = squad_upgrades.map { |su| su[:available_upgrade_id] }.uniq
    # Validate that all uniq_available_upgrade_ids_new correspond to existing available_upgrades
    validate_payload_available_upgrades_exist(uniq_available_upgrade_ids_new, available_upgrades, company.id)
    # Attach each squad upgrade to corresponding squad hash. Validate there are no unattached squad upgrades
    squads = attach_squad_upgrades_to_squads(squads, squad_upgrades)

    # Calculate resources used by the input squads and upgrades
    man_new, mun_new, fuel_new, pop_new = calculate_squad_resources(squads, available_units_by_id, available_upgrades_by_id, platoon_pop_by_tab_and_index)

    ## Offmaps
    # Get available_offmaps for the company
    available_offmaps = company.available_offmaps
    # Get unique offmaps payload available_offmap_ids
    uniq_available_offmap_ids_new = offmaps.map { |o| o[:available_offmap_id] }.uniq
    # Validate that all uniq_available_offmap_ids_new correspond to existing available_offmaps
    validate_payload_available_offmaps_exist(uniq_available_offmap_ids_new, available_offmaps, company.id)
    # Index available_offmaps by id
    available_offmaps_by_id = available_offmaps.index_by(&:id)
    # Calculate resources used by the payload offmaps
    man_offmap, mun_offmap, fuel_offmap = calculate_offmap_resources(offmaps, available_offmaps_by_id)

    man_final = man_new + man_offmap
    mun_final = mun_new + mun_offmap
    fuel_final = fuel_new + fuel_offmap

    # Calculate resources remaining when subtracting the squad resources from the company's total starting resources
    # Raise validation error if the new squads' cost is greater in one or more resource than the company's total starting resources
    man_remaining, mun_remaining, fuel_remaining = calculate_remaining_resources(company.ruleset, company.company_resource_bonuses, man_final, mun_final, fuel_final)

    # Raise validation error if a platoon (squads within a tab and index) has either less pop than the minimum or
    # more pop than the maximum allowed
    validate_platoon_pop(platoon_pop_by_tab_and_index)

    ## Squads
    # Get all existing squads for the company
    existing_squads_by_available_unit_id = existing_squads.group_by(&:available_unit_id)

    # Get payload squads by available unit id
    payload_squads_by_available_unit_id = squads.group_by { |s| s[:available_unit_id] }

    # Calculate delta in number of each unit against the available number of that unit for the company
    # Raise validation error if insufficient
    available_changes = build_available_unit_deltas(company, payload_squads_by_available_unit_id, existing_squads_by_available_unit_id, available_units_by_id)

    # Check for any existing squads that have units which aren't in the payload squads list. These represent squads we
    # will be destroying and units that will give their availability back as the unit is not included at all in the new
    # squads list
    add_existing_squads_to_remove(existing_squads_by_available_unit_id, available_changes)

    ## Offmaps
    # Get all existing company_offmaps for the company by available_offmap_id
    existing_company_offmaps_by_available_offmap_id = existing_company_offmaps.group_by(&:available_offmap_id)
    # Get payload offmaps by available_offmap_id
    payload_offmaps_by_available_offmap_id = offmaps.group_by { |o| o[:available_offmap_id] }
    ## Calculate delta in number of each offmap against the available number of that offmap
    # Raise a validation error if insufficient
    available_offmap_changes = build_available_offmap_deltas(company, payload_offmaps_by_available_offmap_id,
                                                             existing_company_offmaps_by_available_offmap_id,
                                                             available_offmaps_by_id)
    # Check for any existing company offmaps that have offmaps that aren't in the payload offmaps list. These represent company_offmaps
    # we will be destroying and offmaps that will give their availability back
    add_existing_offmaps_to_remove(existing_company_offmaps_by_available_offmap_id, available_offmap_changes)

    ## Squad Upgrades
    # Validate for each squad that upgrades fit max, slots, unitwide slots
    validate_squad_upgrade_max_and_slots(squads, existing_squads, available_upgrades_by_id, available_units_by_id, company.id)

    ##### At this point, we know the company can have the new squads, offmaps, and upgrades as they are within price and availability

    # Build transport mappings
    uuid_to_transported_uuids, transport_related_uuids = build_transport_mappings(squads, uniq_units_new_by_id)

    ActiveRecord::Base.transaction do
      existing_squads_by_id = existing_squads.index_by(&:id)

      new_squads = []
      new_squad_upgrades = []
      squads.each do |s|
        if s[:squad_id].blank?
          ## Create new Squad records for squads without squad id
          available_unit = available_units_by_id[s[:available_unit_id]]
          squad = Squad.new(company: company, vet: s[:vet], tab_category: s[:tab], uuid: s[:uuid],
                            category_position: s[:index], available_unit: available_unit,
                            total_model_count: s[:totalModelCount], pop: s[:pop])
          new_squad_upgrades.concat(build_recursive_squad_upgrades(s, squad))
          new_squads << squad
        else
          ## Update existing Squads
          existing_squad = existing_squads_by_id[s[:squad_id]]
          existing_squad.update!(tab_category: s[:tab], category_position: s[:index], name: s[:name],
                                 total_model_count: s[:totalModelCount], pop: s[:pop])
          new_squad_upgrades.concat(build_recursive_squad_upgrades(s, existing_squad))
        end
      end
      Squad.import!(new_squads)
      SquadUpgrade.import!(new_squad_upgrades)

      ## Determine set of existing Squads with squad id not in the new list of squads. Delete these
      squad_ids_to_delete = existing_squad_ids - payload_squad_ids
      Squad.where(id: [squad_ids_to_delete]).destroy_all if squad_ids_to_delete.present?

      ## Update unit available number for every squad operation above
      available_changes.each do |available_unit_id, delta|
        available_unit = available_units_by_id[available_unit_id]
        new_available_number = available_unit.available + delta
        available_unit.update!(available: [new_available_number, 0].max)
      end

      ## Construct TransportedSquads based on transportSquadUuid to uuid relationships
      transported_squads = []
      transport_related_squads = Squad.where(company: company, uuid: transport_related_uuids)
      transport_related_squads_by_uuid = transport_related_squads.index_by(&:uuid)
      uuid_to_transported_uuids.each do |transport_uuid, transported_uuids|
        transport_squad = transport_related_squads_by_uuid[transport_uuid]
        next unless transport_squad.present?

        transported_uuids.each do |t_uuid|
          passenger = transport_related_squads_by_uuid[t_uuid]
          next unless passenger.present?
          next unless transport_squad.category_position == passenger.category_position && transport_squad.tab_category == passenger.tab_category

          # Established these squads exist and are in the same platoon
          transported_squads << TransportedSquad.new(transport_squad: transport_squad, embarked_squad: passenger)
        end
      end
      # First select all existing TransportedSquads from the create list
      ts_to_keep = transported_squads.map do |ts|
        TransportedSquad.where(transport_squad: ts.transport_squad, embarked_squad: ts.embarked_squad)
      end.reduce(&:or)
      # Destroy all TransportedSquads which are not in the list of ids to keep
      TransportedSquad.joins(:transport_squad).where(transport_squad: { company_id: company.id }).where.not(id: ts_to_keep&.pluck(:id)).destroy_all
      if transported_squads.present?
        TransportedSquad.import!(transported_squads, on_duplicate_key_ignore: { conflict_target: [:transport_squad_id, :embarked_squad_id] })
      end

      ## Offmaps
      new_company_offmaps = []
      offmaps.each do |offmap|
        if offmap[:company_offmap_id].blank?
          # Create a new CompanyOffmap record for offmaps without company_offmap_id
          available_offmap = available_offmaps_by_id[offmap[:available_offmap_id]]
          new_company_offmaps << CompanyOffmap.new(company: company, available_offmap: available_offmap)

          # Nothing to update for existing company_offmaps
        end
      end
      CompanyOffmap.import!(new_company_offmaps)

      # Determine set of existing CompanyOffmaps with id not in the new list of company offmaps. Delete these
      company_offmap_ids_to_delete = existing_co_offmap_ids - payload_co_offmap_ids
      CompanyOffmap.where(id: [company_offmap_ids_to_delete]).destroy_all if company_offmap_ids_to_delete.present?

      # Update offmap available number
      available_offmap_changes.each do |available_offmap_id, delta|
        available_offmap = available_offmaps_by_id[available_offmap_id]
        new_available_number = available_offmap.available + delta
        available_offmap.update!(available: [new_available_number, 0].max)
      end

      ## Squad Upgrades
      ## Determine set of existing SquadUpgrades with squad_upgrade_id not in the payload list of squad_upgrades. Delete these
      squad_upgrade_ids_to_delete = existing_squad_upgrade_ids - payload_squad_upgrade_ids
      SquadUpgrade.where(id: [squad_upgrade_ids_to_delete]).destroy_all if squad_upgrade_ids_to_delete.present?

      company.update!(pop: pop_new, man: man_remaining, mun: mun_remaining, fuel: fuel_remaining)
    end
  end

  def delete_company(company, override = false)
    unless can_update_company(company, override)
      raise CompanyUpdateValidationError.new("Player #{@player.id} cannot update Company #{company.id}")
    end

    # Validate not in battle
    validate_company_not_in_battle(company)

    company.destroy!
  end

  # Recalculates resources remaining for the company based on squads and availability, AND updates the company
  def recalculate_and_update_resources(company, force_update = false)
    man, mun, fuel, pop = recalculate_resources(company, force_update)
    company.update!(man: man, mun: mun, fuel: fuel, pop: pop)
  end

  # Based on squads of the company and ruleset starting resources, determine what resources are left
  # TODO refactor with similar block in #update_company_squads
  def recalculate_resources(company, force_update = false)
    # Index available units by id
    available_units_by_id = company.reload.available_units.index_by(&:id)
    # Index available upgrades by id
    available_upgrades_by_id = company.available_upgrades.index_by(&:id)

    # Build hash of tab and index to pop
    platoon_pop_by_tab_and_index = build_empty_tab_index_pop

    squads = company.squads.map do |s|
      squad_upgrades = s.squad_upgrades.map { |su| { id: su.id, available_upgrade_id: su.available_upgrade_id, is_free: su.is_free } }
      { tab: s.tab_category, index: s.category_position, available_unit_id: s.available_unit_id, upgrades: squad_upgrades }
    end

    # Calculate resources used by the input squads
    man_new, mun_new, fuel_new, pop_new = calculate_squad_resources(squads, available_units_by_id, available_upgrades_by_id, platoon_pop_by_tab_and_index)

    offmaps = company.company_offmaps.map { |co| { available_offmap_id: co.available_offmap_id } }
    available_offmaps_by_id = company.available_offmaps.index_by(&:id)
    man_offmap, mun_offmap, fuel_offmap = calculate_offmap_resources(offmaps, available_offmaps_by_id)

    man_final = man_new + man_offmap
    mun_final = mun_new + mun_offmap
    fuel_final = fuel_new + fuel_offmap

    # Calculate resources remaining when subtracting the squad resources from the company's total starting resources
    # Raise validation error if the new squads' cost is greater in one or more resource than the company's total starting resources
    man_remaining, mun_remaining, fuel_remaining = calculate_remaining_resources(company.ruleset, company.company_resource_bonuses,
                                                                                 man_final, mun_final, fuel_final,
                                                                                 force_update)

    [man_remaining, mun_remaining, fuel_remaining, pop_new]
  end

  private

  def validate_active_ruleset(ruleset)
    unless ruleset.is_active?
      raise CompanyCreationValidationError.new("Ruleset #{ruleset.name} with id #{ruleset.id} is not active")
    end
  end

  # A company can be created for a player if they have fewer than the limit of companies for the doctrine's side
  def can_create_company(doctrine)
    side = doctrine.faction.side
    factions_for_side = Faction.where(side: side)

    ActiveCompany.where(player: @player, faction: factions_for_side).size < MAX_COMPANIES_PER_SIDE
  end

  def can_update_company(company, override)
    company.player == @player || override
  end

  def validate_company_not_in_battle(company)
    if company.active_battle_id.present?
      raise CompanyUpdateValidationError.new("Company #{company.id} is in an active battle and cannot be updated")
    end
  end

  # Validates that all squad ids in the squads payload are unique and correspond to an existing squad id in the company
  def validate_incoming_squad_ids(payload_squad_ids, existing_squad_ids, company_id)
    uniq_payload_squad_ids = payload_squad_ids.uniq
    unless uniq_payload_squad_ids.size == payload_squad_ids.size
      # Raise validation error if one or more given squad ids are duplicated
      raise CompanyUpdateValidationError.new("Duplicate squad ids found in payload squad ids: " \
                                               "#{payload_squad_ids.group_by { |e| e }.select { |_, v| v.size > 1 }.map(&:first)}")
    end

    unless (payload_squad_ids - existing_squad_ids).size == 0
      # Raise validation error if one or more given squad ids do not belong to the company
      raise CompanyUpdateValidationError.new("Given squad ids #{payload_squad_ids - existing_squad_ids}" \
                                               " that don't exist for the company #{company_id}")
    end
  end

  # Validates that all company offmap ids in the payload are unique and correspond to an existing company offmap id in the company
  def validate_incoming_company_offmap_ids(payload_co_offmap_ids, existing_co_offmap_ids, company_id)
    uniq_payload_co_offmap_ids = payload_co_offmap_ids.uniq
    unless uniq_payload_co_offmap_ids.size == payload_co_offmap_ids.size
      # Raise validation error if one or more company offmap ids are duplicated
      raise CompanyUpdateValidationError.new("Duplicate company offmap ids found in payload company offmap ids: " \
                                               "#{payload_co_offmap_ids.group_by { |e| e }.select { |_, v| v.size > 1 }.map(&:first)}")
    end

    unless (payload_co_offmap_ids - existing_co_offmap_ids).size == 0
      # Raise validation error if one or more given company offmap ids do not belong to the company
      raise CompanyUpdateValidationError.new("Given company offmap ids #{payload_co_offmap_ids - existing_co_offmap_ids}" \
                                               " that don't exist for the company #{company_id}")
    end
  end

  # Validates that all squad_upgrade ids in the payload are unique and correspond to an existing squad_upgrade id in the company
  def validate_incoming_squad_upgrade_ids(payload_squad_upgrade_ids, existing_squad_upgrade_ids, company_id)
    uniq_payload_squad_upgrade_ids = payload_squad_upgrade_ids.uniq
    unless uniq_payload_squad_upgrade_ids.size == payload_squad_upgrade_ids.size
      # Raise validation error if one or more squad upgrade ids are duplicated
      raise CompanyUpdateValidationError.new("Duplicate squad upgrade ids found in payload squad upgrade ids: " \
                                               "#{payload_squad_upgrade_ids.group_by { |e| e }.select { |_, v| v.size > 1 }.map(&:first)}")
    end

    unless (payload_squad_upgrade_ids - existing_squad_upgrade_ids).size == 0
      # Raise validation error if one or more given squad upgrades ids do not belong to the company
      raise CompanyUpdateValidationError.new("Given squad upgrade ids #{payload_squad_upgrade_ids - existing_squad_upgrade_ids}" \
                                               " that don't exist for the company #{company_id}")
    end
  end

  # Validates that all unit ids correspond to existing units
  def validate_squad_units_exist(uniq_unit_ids_new, uniq_units_new_by_id)
    unless uniq_unit_ids_new.size == uniq_units_new_by_id.size
      # Raise validation error if some of the given unit ids for the new squads don't match a Unit record
      raise CompanyUpdateValidationError.new("Invalid unit id(s) given in company squad update: #{uniq_unit_ids_new - uniq_units_new_by_id.keys}")
    end
  end

  def validate_squad_available_units_exist(uniq_available_unit_ids_new, available_units, company_id)
    diff = uniq_available_unit_ids_new - available_units.pluck(:id).uniq
    unless diff.empty?
      raise CompanyUpdateValidationError.new("Invalid available_unit_id(s) given in company #{company_id} squad update: #{diff}")
    end
  end

  def validate_payload_available_offmaps_exist(uniq_available_offmap_ids_new, available_offmaps, company_id)
    diff = uniq_available_offmap_ids_new - available_offmaps.pluck(:id).uniq
    unless diff.empty?
      raise CompanyUpdateValidationError.new("Invalid available_offmap_id(s) given in company #{company_id} squad update: #{diff}")
    end
  end

  def validate_payload_available_upgrades_exist(uniq_available_upgrade_ids_new, available_upgrades, company_id)
    diff = uniq_available_upgrade_ids_new - available_upgrades.pluck(:id).uniq
    unless diff.empty?
      raise CompanyUpdateValidationError.new("Invalid available_upgrade_id(s) given in company #{company_id} squad update: #{diff}")
    end
  end

  def attach_squad_upgrades_to_squads(squads, squad_upgrades)
    squad_upgrades_grouped_by_squad_uuid = squad_upgrades.deep_dup.group_by { |su| su[:squad_uuid] }
    squads.each do |squad|
      next unless squad_upgrades_grouped_by_squad_uuid.include? squad[:uuid]

      squad[:upgrades] = squad_upgrades_grouped_by_squad_uuid[squad[:uuid]]
      squad_upgrades_grouped_by_squad_uuid.delete(squad[:uuid])
    end

    unless squad_upgrades_grouped_by_squad_uuid.empty?
      raise CompanyUpdateValidationError.new("Found squad upgrades not associated with a squad uuid: #{squad_upgrades_grouped_by_squad_uuid}")
    end

    squads
  end

  # Validates that all unit ids correspond to available units
  def validate_squad_units_available(uniq_unit_ids_new, available_units, company_id)
    uniq_available_unit_ids = available_units.pluck(:unit_id).uniq
    if (uniq_unit_ids_new - uniq_available_unit_ids).size > 0
      # Raise validation error if some of the given unit ids are not in the set of AvailableUnits for the company
      raise CompanyUpdateValidationError.new("Found unavailable unit ids #{uniq_unit_ids_new - uniq_available_unit_ids} for the company #{company_id}")
    end
  end

  # Build hash of tab and index to pop
  def build_empty_tab_index_pop
    tab_categories = Squad.tab_categories
    Hash[
      tab_categories[:core], Array.new(8, 0),
      tab_categories[:assault], Array.new(8, 0),
      tab_categories[:infantry], Array.new(8, 0),
      tab_categories[:armour], Array.new(8, 0),
      tab_categories[:anti_armour], Array.new(8, 0),
      tab_categories[:support], Array.new(8, 0),
      tab_categories[:holding], Array.new(1, 0)
    ].with_indifferent_access
  end

  # Calculates manpower, munitions, fuel, and pop used by the input squads, based on costs of the corresponding
  # AvailableUnit for the squad's unit id. Also increments the pop of the platoon_pop_by_tab_and_index value for the
  # tab and index the squad is in.
  def calculate_squad_resources(squads, available_units_by_id, available_upgrades_by_id, platoon_pop_by_tab_and_index)
    man_new = 0
    mun_new = 0
    fuel_new = 0
    pop_new = 0

    squads.each do |squad|
      available_unit = available_units_by_id[squad[:available_unit_id]]
      man_new += available_unit.man
      mun_new += available_unit.mun
      fuel_new += available_unit.fuel

      squad_pop = available_unit.pop
      squad[:upgrades]&.each do |su|
        available_upgrade = available_upgrades_by_id[su[:available_upgrade_id]]
        man_new += available_upgrade.man
        mun_new += available_upgrade.mun
        fuel_new += available_upgrade.fuel
        squad_pop += available_upgrade.pop
      end

      squad[:pop] = squad_pop
      platoon_pop_by_tab_and_index[squad[:tab]][squad[:index]] += squad_pop
      pop_new += squad_pop
    end
    [man_new, mun_new, fuel_new, pop_new]
  end

  # Calculates manpower, munitions, fuel used by the input offmaps, based on costs of the corresponding AvailableOffmap
  def calculate_offmap_resources(offmaps, available_offmaps_by_id)
    man_offmap = 0
    mun_offmap = 0
    fuel_offmap = 0

    offmaps.each do |offmap|
      available_offmap = available_offmaps_by_id[offmap[:available_offmap_id]]
      mun_offmap += available_offmap.mun
    end
    [man_offmap, mun_offmap, fuel_offmap]
  end

  # Calculate a company's total starting resources, including:
  # * Ruleset starting man, mun, fuel
  def get_total_available_resources(ruleset, company_resource_bonuses)
    available_man = ruleset.starting_man
    available_mun = ruleset.starting_mun
    available_fuel = ruleset.starting_fuel

    company_resource_bonuses.each do |crb|
      resource_bonus = crb.resource_bonus
      available_man += resource_bonus.man
      available_mun += resource_bonus.mun
      available_fuel += resource_bonus.fuel
    end

    [available_man, available_mun, available_fuel]
  end

  # Calculate resources remaining after subtracting the used resources from the company's total starting resources
  def calculate_remaining_resources(ruleset, company_resource_bonuses, man_new, mun_new, fuel_new, force_update = false)
    available_man, available_mun, available_fuel = get_total_available_resources(ruleset, company_resource_bonuses)
    man_remaining = available_man - man_new
    mun_remaining = available_mun - mun_new
    fuel_remaining = available_fuel - fuel_new

    unless (man_remaining >= 0 && mun_remaining >= 0 && fuel_remaining >= 0) || force_update
      # Raise validation error if the new squads' cost is greater in one or more resource than the ruleset's starting resources
      # Skip validation error if we are forcing the update even with negative resource amounts. Currently used for resource bonuses
      raise CompanyUpdateValidationError.new("Invalid squad update, negative resource balance found: #{man_remaining} manpower" \
                                               ", #{mun_remaining} munitions, #{fuel_remaining} fuel")
    end
    [man_remaining, mun_remaining, fuel_remaining]
  end

  # Validates that every tab/index in the company has pop that is either 0 or a value between the MIN_POP_PER_PLATOON
  # and MAX_POP_PER_PLATOON
  def validate_platoon_pop(platoon_pop_by_tab_and_index)
    platoon_pop_by_tab_and_index.each do |tab, indices|
      next if tab == Squad.tab_categories[:holding]
      indices.each_with_index do |pop, index|
        unless pop == 0 || (MIN_POP_PER_PLATOON <= pop && pop <= MAX_POP_PER_PLATOON)
          # Raise validation error if a platoon (squads within a tab and index) has either less pop than the minimum or
          # more pop than the maximum allowed
          raise CompanyUpdateValidationError.new("Platoon at [#{tab} #{index}] has #{pop} pop, " \
                                                   "must be between #{MIN_POP_PER_PLATOON} and #{MAX_POP_PER_PLATOON}, inclusive")
        end
      end
    end
  end

  # Calculate delta in number of each unit against the available number of that unit for the company
  # Take into account the difference between the existing number of squads of that unit and the number of squads of that unit in the payload
  # Raise validation error if insufficient
  def build_available_unit_deltas(company, payload_squads_by_available_unit_id, existing_squads_by_available_unit_id, available_units_by_id)
    available_changes = {}
    payload_squads_by_available_unit_id.each do |available_unit_id, payload_unit_squads|
      if existing_squads_by_available_unit_id.include? available_unit_id
        existing_count = existing_squads_by_available_unit_id[available_unit_id].size
      else
        existing_count = 0
      end
      payload_unit_count = payload_unit_squads.size
      availability_delta = existing_count - payload_unit_count
      available_number = available_units_by_id[available_unit_id].available

      # Inverse of the availability delta as the availability delta is how much we are changing down the available number
      # so the inverse is how much net the available number must compare against
      # Ex, 0 existing, 2 payload count, 2 available, then the availability delta is -2 as we are going to adjust down available by 2.
      #   To validate, we take the inverse (2), and compare against the available number as that 2 is what we are net adding to the company for the unit
      # Ex, 2 existing, 1 payload count, 0 available, then the availability delta is 1 as we are adjusting up by 1, as we are making 1 more available
      #   To validate we take the inverse, -1, and compare against the available number. For cases like this where the payload count is < existing, we should
      #   always pass the validation as we are adding to the available number for the unit
      unless -availability_delta <= available_number
        raise CompanyUpdateValidationError.new("Insufficient availability to create squads for available unit #{available_unit_id} in company" \
                                                 " #{company.id}: Existing count #{existing_count}, payload count #{payload_unit_count}, available number #{available_number}")
      end

      # Save the delta so we can update it later after we finish validating availability
      available_changes[available_unit_id] = availability_delta
    end
    available_changes
  end

  # Check for any existing squads that have units which aren't in the payload squads list. These represent squads we
  # will be destroying and units that will give their availability back as the unit is not included at all in the new
  # squads list
  def add_existing_squads_to_remove(existing_squads_by_available_unit_id, available_changes)
    existing_squads_by_available_unit_id.each do |available_unit_id, existing_unit_squads|
      next if available_changes.include? available_unit_id

      available_changes[available_unit_id] = existing_unit_squads.size
    end
  end

  ## Calculate delta in number of each offmap against the available number of that offmap
  # Raise a validation error if insufficient
  def build_available_offmap_deltas(company, payload_offmaps_by_available_offmap_id, existing_company_offmaps_by_available_offmap_id, available_offmaps_by_id)
    available_changes = {}
    payload_offmaps_by_available_offmap_id.each do |available_offmap_id, payload_offmaps|
      if existing_company_offmaps_by_available_offmap_id.include? available_offmap_id
        existing_count = existing_company_offmaps_by_available_offmap_id[available_offmap_id].size
      else
        existing_count = 0
      end
      payload_offmap_count = payload_offmaps.size
      availability_delta = existing_count - payload_offmap_count
      available_number = available_offmaps_by_id[available_offmap_id].available

      unless -availability_delta <= available_number
        raise CompanyUpdateValidationError.new("Insufficient availability to create squads for available offmap #{available_offmap_id} in company" \
                                                 " #{company.id}: Existing count #{existing_count}, payload count #{payload_offmap_count}, available number #{available_number}")
      end

      # save the delta to update later
      available_changes[available_offmap_id] = availability_delta
    end
    available_changes
  end

  # Check for any existing company offmaps that have offmaps that aren't in the payload offmaps list.
  # These represent company_offmaps we will be destroying and offmaps that will give their availability back.
  # We need this step as build_available_offmap_deltas only looks at offmaps in the payload
  def add_existing_offmaps_to_remove(existing_company_offmaps_by_available_offmap_id, available_offmap_changes)
    existing_company_offmaps_by_available_offmap_id.each do |available_offmap_id, existing_company_offmaps|
      next if available_offmap_changes.include? available_offmap_id

      available_offmap_changes[available_offmap_id] = existing_company_offmaps.size
    end
  end

  # Validate max, slots and unitwide slots for squad upgrades by squad
  def validate_squad_upgrade_max_and_slots(payload_squads, existing_squads, available_upgrades_by_id, available_units_by_id, company_id)
    existing_squads_by_id = existing_squads.index_by(&:id)

    # For each payload squad
    payload_squads.each do |payload_squad|
      # validate each squad upgrade against max, calculate slot cost against squad unit slots/unitwide slots
      check_squad_unit_max_upgrades_and_slots(payload_squad, available_upgrades_by_id, available_units_by_id[payload_squad[:available_unit_id]], company_id)
    end
  end

  def check_squad_unit_max_upgrades_and_slots(payload_squad, available_upgrades_by_id, available_unit, company_id)
    return unless payload_squad.include? :upgrades
    return unless payload_squad[:upgrades].size.positive?

    slots_used = 0
    unitwide_slots_used = 0
    upgrade_id_to_count = Hash.new { |h, k| h[k] = 0 }
    unit = available_unit.unit

    payload_squad[:upgrades].each do |squad_upgrade|
      available_upgrade_id = squad_upgrade[:available_upgrade_id]
      available_upgrade = available_upgrades_by_id[available_upgrade_id]
      upgrade = available_upgrade.upgrade

      slots_used += available_upgrade.upgrade_slots || 0
      unitwide_slots_used += available_upgrade.unitwide_upgrade_slots || 0
      upgrade_id_to_count[upgrade.id] += 1

      unless available_upgrade.max.blank? || upgrade_id_to_count[upgrade.id] <= available_upgrade.max
        raise CompanyUpdateValidationError.new("Found #{upgrade_id_to_count[upgrade.id]} uses of available upgrade " \
                                                 "#{available_upgrade_id} with max #{available_upgrade.max}, for company #{company_id} update and squad " \
                                                 "available unit id #{payload_squad[:available_unit_id]}")
      end

      unless slots_used <= unit.upgrade_slots
        raise CompanyUpdateValidationError.new("Found #{slots_used} upgrade slots used for unit #{unit.id} with " \
                                                 "#{unit.upgrade_slots} upgrade slots, for company #{company_id} update and squad " \
                                                 "available unit id #{payload_squad[:available_unit_id]}")
      end

      unless unitwide_slots_used <= unit.unitwide_upgrade_slots
        raise CompanyUpdateValidationError.new("Found #{unitwide_slots_used} unitwide upgrade slots used for unit " \
                                                 "#{unit.id} with #{unit.unitwide_upgrade_slots} unitwide upgrade slots, for company #{company_id} update and" \
                                                 " squad available unit id #{payload_squad[:available_unit_id]}")
      end
    end
  end

  def build_transport_mappings(squads, uniq_units_new_by_id)
    squads_by_uuid = squads.index_by { |s| s[:uuid] }
    transport_allowed_unit_ids_by_transport_id = TransportAllowedUnit.relationship_map
    uuid_to_transported_uuids = {}
    transport_related_uuids = []
    squads.each do |s|
      next unless s[:transportedSquadUuids].present?

      # Validate the relationship of transportUuid on passenger to transportedSquadUuids on transport are 2 way matching
      # Validate the transport unit is allowed to transport the potential passenger unit
      # Validate the transport squad has sufficient squad slots for the potential passenger squad
      # Validate the transport squad has sufficient model slots for the potential passenger squad's model count
      #
      # If validation fails on any case, skip creating a transport link. The potential passenger squad will still be upserted into the platoon
      #
      # NOTE: Platoon pop has already been validated, do not need to do it per transport
      s_unit = uniq_units_new_by_id[s[:unit_id]]
      remaining_squad_slots = s_unit.transport_squad_slots
      remaining_model_slots = s_unit.transport_model_slots
      matching_transport_uuid = s[:transportedSquadUuids].select do |uuid|
        potential_passenger = squads_by_uuid[uuid]
        potential_passenger_unit_id = potential_passenger[:unit_id]
        potential_pass_unit = uniq_units_new_by_id[potential_passenger_unit_id]
        valid_passenger_relationship = potential_passenger[:transportUuid] == s[:uuid]
        valid_transport_allowed_unit = transport_allowed_unit_ids_by_transport_id[s[:unit_id]].include? potential_passenger_unit_id
        valid_squad_slots = (remaining_squad_slots -= 1) >= 0
        valid_model_slots = (remaining_model_slots -= potential_pass_unit.model_count) >= 0

        valid_passenger_relationship && valid_transport_allowed_unit && valid_squad_slots && valid_model_slots
      end
      if matching_transport_uuid.present?
        uuid_to_transported_uuids[s[:uuid]] = matching_transport_uuid
        transport_related_uuids << s[:uuid]
        transport_related_uuids.concat(s[:transportedSquadUuids])
      end
    end
    [uuid_to_transported_uuids, transport_related_uuids]
  end

  def build_recursive_squad_upgrades(payload_squad, squad_record)
    return [] unless payload_squad.include? :upgrades

    new_squad_upgrades = []
    payload_squad[:upgrades].each do |su|
      next unless su[:squad_upgrade_id].blank?

      new_squad_upgrades << SquadUpgrade.new(squad: squad_record, available_upgrade_id: su[:available_upgrade_id])
    end
    new_squad_upgrades
  end
end
