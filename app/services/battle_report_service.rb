class BattleReportService < ApplicationService
  class BattleReportValidationError < StandardError; end

  MINIMUM_ELAPSED = 300.freeze
  MINIMUM_RANKED_ELAPSED = 1200.freeze
  RUBBERBAND_VET = 5.freeze

  FINAL = 1.freeze
  NOT_FINAL = 0.freeze

  def initialize(battle_id)
    @battle = Battle.includes(:ruleset, players: :companies, companies: [:squads, available_units: :unit, company_resource_bonuses: :resource_bonus]).find_by!(id: battle_id)
    @ruleset = @battle.ruleset
  end

  def self.enqueue_report(battle_id, is_final, reporting_player_name, time_elapsed, race_winner, map_name,
                          dead_squads, surviving_squads, dropped_players, battle_stats)
    # Rails.logger.info("[#{self.class.name}] Enqueuing BattleReportJob for battle #{battle_id} with params:")
    # Rails.logger.info("[#{self.class.name}] is_final #{is_final}, reporting player #{reporting_player_name}, time_elapsed #{time_elapsed}, winner #{race_winner}")
    # Rails.logger.info("[#{self.class.name}] dead_squads #{dead_squads}, surviving_squads #{surviving_squads}")
    BattleReportJob.perform_async(battle_id, is_final, reporting_player_name, time_elapsed, race_winner, map_name,
                                  dead_squads, surviving_squads, dropped_players, battle_stats)
  end

  def process_report(battle_id, is_final, reporting_player_name, time_elapsed, race_winner, map_name,
                     dead_squads, surviving_squads, dropped_players, battle_stats)
    # Get lock on battle to prevent duplicate updates to associated companies
    # Just lock the read of the battle's state and update of the battle's state to reporting
    info_logger("Starting processing of battle report for Battle #{battle_id}")
    @battle.with_lock do
      if @battle.reporting? || @battle.final?
        info_logger("Battle #{battle_id} is already in '#{@battle.state}' state, skipping battle report processing")
      else
        validate_battle_ingame

        # Look for dropped players
        handle_dropped_players(dropped_players)

        # if is_final is 0, not final. Do not put battle into reporting state
        if is_final == NOT_FINAL
          info_logger("Non-final battle #{battle_id}, no action required")
        else
          # Transition battle to reporting
          info_logger("Transitioning battle #{battle_id} state to reporting")
          @battle.reporting!

          # If final and under time threshold, finalize without changing companies
          if time_elapsed < MINIMUM_ELAPSED
            info_logger("Time elapsed #{time_elapsed} is less than reporting minimum #{MINIMUM_ELAPSED}. Marking abandoned")
            @battle.abandoned!
          else
            ## Update squads
            # Update surviving squads with vet
            # Add resupply availability
            # Auto rebuild
            # Remove dead squads
            starting_squads_by_id = @battle.squads.index_by(&:id)
            starting_squads_by_id = update_surviving_squads(starting_squads_by_id, surviving_squads)
            add_rubberband_vet(starting_squads_by_id)

            @battle.companies.each do |c|
              add_company_availability(c)
            end

            autorebuild_dead_squads(dead_squads)

            @battle.companies.each do |c|
              # Count number of squads for each unit, compare against AvailableUnit company max. If exceeds, reduce available until matches
              reconcile_company_unit_available(c)
            end

            ## Update company resources after rebuild
            recalculate_company_resources

            ## Update company and player VPs
            add_company_vps
            add_player_vps

            winner = map_winner(race_winner)

            # Mark battle as final with winner
            finalize_battle(winner)

            # Update player ratings
            maybe_update_player_ratings(winner, time_elapsed)

            # Update company stats
            process_battle_stats(battle_stats)
          end

          info_logger("Finished processing battle report for battle #{battle_id}")
        end
      end
    rescue StandardError => e
      Rails.logger.error("Failed to process battle report for battle #{battle_id}, error: #{e.message}")
      raise
    end

    begin
      info_logger("Attempting to send battle_finalized cable")
      service = BattleService.new(nil)
      service.finalize_battle(@battle)
    rescue StandardError => e
      # Catch but don't raise again
      Rails.logger.error("Failed to broadcast battle_finalized cable for battle #{@battle.id}, error: #{e.full_message}")
    end

    begin
      info_logger("Attempting to save battle report to S3")
      save_report_file(battle_id, is_final, reporting_player_name, time_elapsed, race_winner, map_name,
                       dead_squads, surviving_squads, dropped_players, battle_stats)
    rescue StandardError => e
      # Catch but don't raise again
      Rails.logger.error("Failed to upload battle report to S3 for battle #{@battle.id}, error: #{e.full_message}")
    end
  end

  private

  def validate_battle_ingame
    # Validate it is still in "ingame" state
    raise BattleReportValidationError.new "Invalid battle state '#{@battle.state}', expected 'ingame'" unless @battle.ingame?
  end

  def map_winner(race_winner)
    case race_winner
    when "Allies"
      Battle.winners[:allied]
    when "Axis"
      Battle.winners[:axis]
    else
      raise BattleReportValidationError.new "Unknown race winner #{race_winner}"
    end
  end

  # surviving_squads is a string in the format [squad_id],[experience];[squad_id],[experience];...
  def update_surviving_squads(starting_squads_by_id, surviving_squads)
    # From these starting squads, they will either be surviving squads with exp, dead squads to delete, or if neither
    # they are not called in. TODO do we give exp for squads not called in?
    squad_exp_pairs = surviving_squads.split(';')
    info_logger("Updating exp for #{squad_exp_pairs.size} surviving squads")
    squads_to_update = []
    # For all surviving squads with exp, remove from the starting_squads_by_id hash and update the squad vet value
    squad_exp_pairs.each do |squad_exp_str|
      squad_id, exp = squad_exp_str.split(',')
      squad = starting_squads_by_id.delete(squad_id.to_i)
      squad.vet = [squad.vet, exp.to_f].max
      squads_to_update << squad
    end
    Squad.import!(squads_to_update, on_duplicate_key_update: { conflict_target: [:id], columns: [:vet] })
    starting_squads_by_id
  end

  def add_rubberband_vet(starting_squads_by_id)
    # Add 5xp TODO rubber band
    info_logger("Adding rubberband exp for #{starting_squads_by_id.size} squads")
    starting_squads_by_id.values.each do |squad|
      squad.vet += RUBBERBAND_VET
    end
    Squad.import!(starting_squads_by_id.values.to_a, on_duplicate_key_update: { conflict_target: [:id], columns: [:vet] })
    starting_squads_by_id
  end

  # For a company, update available_unit available value
  # This is the minimum of available + resupply and the resupply_max
  def add_company_availability(company)
    # info_logger("Adding available_unit resupply for company #{company.id}")
    available_units_update = []
    company.available_units.each do |au|
      next if au.unit.disabled?

      new_availability = [au.available + au.resupply, au.resupply_max].min
      if new_availability != au.available
        au.available = new_availability
        available_units_update << au
      end
    end

    # info_logger("Saving #{available_units_update.size} available_unit updates")
    AvailableUnit.import!(available_units_update, on_duplicate_key_update: { conflict_target: [:id], columns: [:available] })
  end

  # Count number of squads for each unit, compare against AvailableUnit company max.
  # If exceeds, reduce available until matches
  # NOTE: This must be done after availability resupply and autorebuild is done in order to correct over resupply of
  # availability for surviving squads (and avoid exceeding the company max)
  def reconcile_company_unit_available(company)
    # info_logger("Reconciling company squad count + available for company #{company.id}")
    available_unit_to_squad_count = company.squads.group(:available_unit_id).count
    available_units_update = []
    company.available_units.each do |au|
      if available_unit_to_squad_count.include? au.id
        squad_count = available_unit_to_squad_count[au.id]
        if (squad_count + au.available) > au.company_max
          overage = (squad_count + au.available) - au.company_max
          new_available = [au.available - overage, 0].max
          au.available = new_available
          available_units_update << au
        end
      end
    end

    # info_logger("Saving #{available_units_update.size} available_unit updates for unit available reconciliation")
    AvailableUnit.import!(available_units_update, on_duplicate_key_update: { conflict_target: [:id], columns: [:available] })
  end

  # Attempt to autorebuild dead squads
  # available_unit.available has already been updated, we are reconciling squads against that value
  # dead_squads_str is a string in the format [squad_id];[squad_id];...
  def autorebuild_dead_squads(dead_squads_str)
    info_logger("Begin rebuilding dead squads")
    dead_squad_ids = dead_squads_str.split(";")
    dead_squads_by_available_unit = Squad.includes(:available_unit).where(id: dead_squad_ids).group_by(&:available_unit_id)
    squads_to_update = []
    available_units_to_update = []
    dead_squads_by_available_unit.each do |available_unit_id, squads|
      # Per available_unit, can get the available_unit available value at the start and update for all squads before saving
      available_unit = squads.first.available_unit
      info_logger("Available_unit #{available_unit_id} with #{squads.size} squads to rebuild, #{available_unit.available} available")
      squads.each do |squad|
        if available_unit.available > 0
          info_logger("Available #{available_unit.available} > 0 for Squad #{squad.id}, rebuilding")
          squad.vet = 0
          squad.name = nil
          available_unit.available -= 1
          squads_to_update << squad
          # TODO Reset squad stats
        else
          # Not enough availability to autorebuild, remove the dead squad
          info_logger("Available #{available_unit.available} is 0 for Squad #{squad.id}, deleting")
          squad.destroy!
        end
      end
      available_units_to_update << available_unit
    end
    info_logger("Saving auto rebuilt squads")
    Squad.import!(squads_to_update, on_duplicate_key_update: { conflict_target: [:id], columns: [:vet, :name] })
    AvailableUnit.import!(available_units_to_update, on_duplicate_key_update: { conflict_target: [:id], columns: [:available] })
  end

  # squads have been reconciled,
  def recalculate_company_resources
    info_logger("Recalculating company resources")
    @battle.companies.each do |c|
      CompanyService.new(c.player).recalculate_and_update_resources(c)
    end
  end

  def add_company_vps
    player_ids = @battle.players.pluck(:id)
    ruleset_id = @battle.ruleset_id
    info_logger("Start adding VPs to Companies for players #{player_ids} in ruleset #{ruleset_id}")
    companies = ActiveCompany.where(player_id: player_ids, ruleset_id: ruleset_id)
    companies_to_update = []
    companies.each do |c|
      if c.vps_earned >= @ruleset.max_vps
        info_logger("Company #{c.id} has #{c.vps_earned} VPs and cannot exceed #{@ruleset.max_vps}")
      else
        info_logger("Adding 1 VP to Company #{c.id}")
        c.vps_current += 1
        c.vps_earned += 1
        companies_to_update << c
      end
    end
    ActiveCompany.import!(companies_to_update, on_duplicate_key_update: { conflict_target: [:id], columns: [:vps_earned, :vps_current] })
  end

  # Player VPs are used to repopulate
  def add_player_vps
    info_logger("Adding player VPs as necessary")
    players = @battle.players.to_a
    players.each do |p|
      if p.vps < @ruleset.max_vps
        info_logger("Adding 1 VP to Player #{p.id}")
        p.vps += 1
      end
      p.total_vps_earned += 1
    end
    Player.import!(players, on_duplicate_key_update: { conflict_target: [:id], columns: [:vps, :total_vps_earned] })
  end

  # Skip updating ratings if battle is only 1v1
  # Skip updating ratings if battle time elapsed is less than MINIMUM_RANKED_ELAPSED
  def maybe_update_player_ratings(winner, time_elapsed)
    if @battle.size == 1
      info_logger("Battle #{@battle.id} size is 1, skipping updating player ratings")
      return
    end

    if time_elapsed > MINIMUM_RANKED_ELAPSED
      info_logger("Updating player ratings")
      ## Update player skill ratings
      update_player_ratings(winner)

      # Save historical battle player records
      # NOTE: Since historical battle player records are intended to help recalculate player ratings, there's no
      # point in saving if the battle does not qualify for player ratings to be updated
      save_historical_battle_players(@battle.id)
    end
  end

  def update_player_ratings(winner)
    Ratings::UpdateService.new(@battle.id).update_player_ratings(winner)
  end

  def save_historical_battle_players(battle_id)
    HistoricalBattlePlayerService.new(battle_id).create_historical_battle_players_for_battle
  end

  def finalize_battle(winner)
    # Update battle with winning side
    info_logger("Marking battle #{@battle.id} winner as #{winner}")
    @battle.update!(winner: winner)
    # Transition battle to final
    info_logger("Transitioning battle #{@battle.id} state to final")
    @battle.finalize!
  end

  def save_report_file(battle_id, is_final, reporting_player_name, time_elapsed, race_winner, map_name,
                       dead_squads, surviving_squads, dropped_players, battle_stats)
    report_hash = {
      battle_id: battle_id,
      final: is_final,
      is_final: is_final == 1,
      reporting_player_name: reporting_player_name,
      time_elapsed: time_elapsed,
      race_winner: race_winner,
      map: map_name,
      dead_squads: dead_squads,
      surviving_squads: surviving_squads,
      dropped_players: dropped_players,
      stats: battle_stats
    }
    @battle.report_file.attach(io: StringIO.new(report_hash.to_json), filename: "battle_#{battle_id}_report.json")
  end

  def process_battle_stats(battle_stats)
    BattleReportStats::ReportParseService.new(@battle.id, battle_stats).process_battle_stats
  end

  # NOTE: search by name is not ideal, even when constrained to the battle's players as it's possible players
  # could have duplicate names. Ideally would pass player ids
  def handle_dropped_players(dropped_players)
    names = dropped_players.split("; ")
    battle_players = @battle.battle_players.joins(:player).where(player: { name: names })
    battle_players.each do |bp|
      bp.update!(is_dropped: true)
    end
  end
end
