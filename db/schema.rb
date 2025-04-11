# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2025_04_11_224053) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "available_offmaps", comment: "Offmap availability per company", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "offmap_id"
    t.integer "available", default: 0, null: false, comment: "Number of this offmap available to purchase for the company"
    t.integer "max", default: 0, null: false, comment: "Max number of this offmap that the company can hold"
    t.integer "mun", default: 0, null: false, comment: "Munitions cost of this offmap"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_available_offmaps_on_company_id"
    t.index ["offmap_id"], name: "index_available_offmaps_on_offmap_id"
  end

  create_table "available_units", comment: "Unit availability per company", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "unit_id"
    t.string "type", null: false, comment: "Type of available unit"
    t.integer "available", default: 0, null: false, comment: "Number of this unit available to purchase for the company"
    t.integer "resupply", default: 0, null: false, comment: "Per game resupply"
    t.integer "resupply_max", default: 0, null: false, comment: "How much resupply is available from saved up resupplies, <= company max"
    t.integer "company_max", default: 0, null: false, comment: "Maximum number of the unit a company can hold"
    t.decimal "pop", null: false, comment: "Calculated pop cost of this unit for the company"
    t.integer "man", null: false, comment: "Calculated man cost of this unit for the company"
    t.integer "mun", null: false, comment: "Calculated mun cost of this unit for the company"
    t.integer "fuel", null: false, comment: "Calculated fuel cost of this unit for the company"
    t.decimal "callin_modifier", null: false, comment: "Calculated base callin modifier of this unit for the company"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "unit_id", "type"], name: "index_available_units_on_company_id_and_unit_id_and_type", unique: true
    t.index ["company_id"], name: "index_available_units_on_company_id"
    t.index ["unit_id"], name: "index_available_units_on_unit_id"
  end

  create_table "available_upgrades", comment: "Upgrade availability per company and unit", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "upgrade_id"
    t.bigint "unit_id"
    t.string "type", null: false, comment: "Type of available upgrade"
    t.decimal "pop", null: false, comment: "Calculated pop cost of this upgrade for the company"
    t.integer "man", null: false, comment: "Calculated man cost of this upgrade for the company"
    t.integer "mun", null: false, comment: "Calculated mun cost of this upgrade for the company"
    t.integer "fuel", null: false, comment: "Calculated fuel cost of this upgrade for the company"
    t.integer "uses", comment: "Uses of this upgrade"
    t.integer "max", comment: "Maximum number of this upgrade purchasable by a unit"
    t.integer "upgrade_slots", comment: "Upgrade slot cost for per model upgrades"
    t.integer "unitwide_upgrade_slots", comment: "Upgrade slot cost for unit wide upgrades"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "upgrade_id", "unit_id", "type"], name: "idx_available_upgrade_uniq", unique: true
    t.index ["company_id"], name: "index_available_upgrades_on_company_id"
    t.index ["unit_id"], name: "index_available_upgrades_on_unit_id"
    t.index ["upgrade_id"], name: "index_available_upgrades_on_upgrade_id"
  end

  create_table "battle_players", force: :cascade do |t|
    t.bigint "battle_id", null: false
    t.bigint "player_id", null: false
    t.bigint "company_id", null: false
    t.boolean "ready", default: false, comment: "Ready flag for the player"
    t.string "side", null: false, comment: "Team side"
    t.boolean "abandoned", default: false, comment: "Is this player abandoning?"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "team_balance", comment: "Assigned team for balance"
    t.boolean "is_dropped", default: false, comment: "Has this player dropped?"
    t.index ["battle_id"], name: "index_battle_players_on_battle_id"
    t.index ["company_id"], name: "index_battle_players_on_company_id"
    t.index ["player_id"], name: "index_battle_players_on_player_id"
  end

  create_table "battles", force: :cascade do |t|
    t.string "name", comment: "Optional battle name"
    t.string "state", null: false, comment: "Battle status"
    t.integer "size", null: false, comment: "Size of each team"
    t.string "winner", comment: "Winning side"
    t.bigint "ruleset_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "elo_diff", comment: "Elo difference between most balanced teams, absolute value"
    t.datetime "last_notified", precision: nil, comment: "Last time a notification was sent to players"
    t.string "map", comment: "Map name"
    t.index ["ruleset_id"], name: "index_battles_on_ruleset_id"
    t.index ["state"], name: "index_battles_on_state"
  end

  create_table "callin_modifier_allowed_units", comment: "Units allowed in a callin for a callin modifier to take effect", force: :cascade do |t|
    t.bigint "callin_modifier_id"
    t.bigint "unit_id"
    t.string "unit_name", comment: "Denormalized unit name for faster access"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["callin_modifier_id"], name: "index_callin_modifier_allowed_units_on_callin_modifier_id"
    t.index ["unit_id"], name: "index_callin_modifier_allowed_units_on_unit_id"
  end

  create_table "callin_modifier_required_units", comment: "Unit required for the callin modifier to be applied", force: :cascade do |t|
    t.bigint "callin_modifier_id"
    t.bigint "unit_id"
    t.string "unit_name", comment: "Denormalized unit name for faster access"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["callin_modifier_id"], name: "index_callin_modifier_required_units_on_callin_modifier_id"
    t.index ["unit_id"], name: "index_callin_modifier_required_units_on_unit_id"
  end

  create_table "callin_modifiers", force: :cascade do |t|
    t.decimal "modifier", comment: "Modifies callin time"
    t.string "modifier_type", comment: "Type of modification"
    t.integer "priority", comment: "Priority in which the modifier is applied, from 1 -> 100"
    t.string "description", comment: "Description"
    t.string "unlock_name", comment: "Name of the unlock associated with this callin modifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chat_messages", comment: "messages for a chat room", force: :cascade do |t|
    t.bigint "chat_id"
    t.bigint "sender_id", null: false
    t.text "content", comment: "chat message content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_chat_messages_on_chat_id"
    t.index ["sender_id"], name: "index_chat_messages_on_sender_id"
  end

  create_table "chats", comment: "chat rooms", force: :cascade do |t|
    t.string "name", null: false, comment: "chat room name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_chats_on_name", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.string "uuid", null: false, comment: "Uuid"
    t.string "name", comment: "Company name"
    t.string "type", null: false, comment: "Company type"
    t.bigint "player_id", null: false
    t.bigint "doctrine_id", null: false
    t.bigint "faction_id", null: false
    t.bigint "ruleset_id", null: false
    t.integer "vps_earned", default: 0, null: false, comment: "VPs earned by this company"
    t.integer "vps_current", default: 0, null: false, comment: "VPs available to spend"
    t.integer "man", default: 0, null: false, comment: "Manpower available to this company"
    t.integer "mun", default: 0, null: false, comment: "Munitions available to this company"
    t.integer "fuel", default: 0, null: false, comment: "Fuel available to this company"
    t.integer "pop", default: 0, null: false, comment: "Population cost of this company"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctrine_id"], name: "index_companies_on_doctrine_id"
    t.index ["faction_id"], name: "index_companies_on_faction_id"
    t.index ["player_id"], name: "index_companies_on_player_id"
    t.index ["ruleset_id"], name: "index_companies_on_ruleset_id"
    t.index ["uuid"], name: "index_companies_on_uuid", unique: true
  end

  create_table "company_callin_modifiers", comment: "Mapping of company to available callin modifiers", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "callin_modifier_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["callin_modifier_id"], name: "index_company_callin_modifiers_on_callin_modifier_id"
    t.index ["company_id"], name: "index_company_callin_modifiers_on_company_id"
  end

  create_table "company_offmaps", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "available_offmap_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["available_offmap_id"], name: "index_company_offmaps_on_available_offmap_id"
    t.index ["company_id"], name: "index_company_offmaps_on_company_id"
  end

  create_table "company_resource_bonuses", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "resource_bonus_id"
    t.integer "level", comment: "Number of this bonus taken"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_resource_bonuses_on_company_id"
    t.index ["resource_bonus_id"], name: "index_company_resource_bonuses_on_resource_bonus_id"
  end

  create_table "company_stats", comment: "Holds company stats updated after every battle", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.integer "infantry_kills_1v1", default: 0, null: false
    t.integer "infantry_kills_2v2", default: 0, null: false
    t.integer "infantry_kills_3v3", default: 0, null: false
    t.integer "infantry_kills_4v4", default: 0, null: false
    t.integer "vehicle_kills_1v1", default: 0, null: false
    t.integer "vehicle_kills_2v2", default: 0, null: false
    t.integer "vehicle_kills_3v3", default: 0, null: false
    t.integer "vehicle_kills_4v4", default: 0, null: false
    t.integer "infantry_losses_1v1", default: 0, null: false
    t.integer "infantry_losses_2v2", default: 0, null: false
    t.integer "infantry_losses_3v3", default: 0, null: false
    t.integer "infantry_losses_4v4", default: 0, null: false
    t.integer "vehicle_losses_1v1", default: 0, null: false
    t.integer "vehicle_losses_2v2", default: 0, null: false
    t.integer "vehicle_losses_3v3", default: 0, null: false
    t.integer "vehicle_losses_4v4", default: 0, null: false
    t.integer "wins_1v1", default: 0, null: false
    t.integer "wins_2v2", default: 0, null: false
    t.integer "wins_3v3", default: 0, null: false
    t.integer "wins_4v4", default: 0, null: false
    t.integer "losses_1v1", default: 0, null: false
    t.integer "losses_2v2", default: 0, null: false
    t.integer "losses_3v3", default: 0, null: false
    t.integer "losses_4v4", default: 0, null: false
    t.integer "streak_1v1", default: 0, null: false, comment: "win streak 1v1"
    t.integer "streak_2v2", default: 0, null: false, comment: "win streak 2v2"
    t.integer "streak_3v3", default: 0, null: false, comment: "win streak 3v3"
    t.integer "streak_4v4", default: 0, null: false, comment: "win streak 4v4"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "idx_company_stats_company_id_uniq", unique: true
    t.index ["company_id"], name: "index_company_stats_on_company_id"
  end

  create_table "company_unlocks", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "doctrine_unlock_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_unlocks_on_company_id"
    t.index ["doctrine_unlock_id"], name: "index_company_unlocks_on_doctrine_unlock_id"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "doctrine_unlocks", comment: "Associates doctrines to unlocks", force: :cascade do |t|
    t.bigint "doctrine_id"
    t.bigint "unlock_id"
    t.bigint "ruleset_id", null: false
    t.string "internal_description", comment: "Doctrine and Unlock names"
    t.integer "vp_cost", default: 0, null: false, comment: "VP cost of this doctrine unlock"
    t.integer "tree", comment: "Which tree of the doctrine this unlock will appear at"
    t.integer "branch", comment: "Which branch of the doctrine tree this unlock will appear at"
    t.integer "row", comment: "Which row of the doctrine tree branch this unlock will appear at"
    t.boolean "disabled", default: false, null: false, comment: "Is this doctrine unlock disabled?"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctrine_id", "tree", "branch", "row", "ruleset_id"], name: "index_doctrine_unlocks_on_doctrine_tree", unique: true
    t.index ["doctrine_id", "unlock_id"], name: "index_doctrine_unlocks_on_doctrine_id_and_unlock_id", unique: true
    t.index ["doctrine_id"], name: "index_doctrine_unlocks_on_doctrine_id"
    t.index ["ruleset_id"], name: "index_doctrine_unlocks_on_ruleset_id"
    t.index ["unlock_id"], name: "index_doctrine_unlocks_on_unlock_id"
  end

  create_table "doctrines", comment: "Faction doctrines", force: :cascade do |t|
    t.string "name", null: false, comment: "Raw name"
    t.string "display_name", null: false, comment: "Display name"
    t.string "const_name", null: false, comment: "Doctrine CONST name for battlefile"
    t.string "internal_name", null: false, comment: "Name for internal code use, may not be needed"
    t.bigint "faction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["const_name"], name: "index_doctrines_on_const_name", unique: true
    t.index ["faction_id"], name: "index_doctrines_on_faction_id"
    t.index ["name"], name: "index_doctrines_on_name", unique: true
  end

  create_table "factions", comment: "Game factions", force: :cascade do |t|
    t.string "name", null: false, comment: "Raw name"
    t.string "display_name", null: false, comment: "Display name"
    t.string "const_name", null: false, comment: "Faction CONST name for battlefile"
    t.string "internal_name", null: false, comment: "Name for internal code use, may not be needed"
    t.string "side", null: false, comment: "Allied or Axis side"
    t.integer "race", comment: "In-game race id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["const_name"], name: "index_factions_on_const_name", unique: true
    t.index ["name"], name: "index_factions_on_name", unique: true
  end

  create_table "historical_battle_players", comment: "Historical record of battle results by player", force: :cascade do |t|
    t.bigint "player_id"
    t.string "player_name", null: false, comment: "Denormalized player name in case player record is deleted"
    t.string "battle_id", null: false, comment: "Battle id, could be duplicates in the long run through multiple war resets"
    t.bigint "faction_id", null: false
    t.bigint "doctrine_id", null: false
    t.boolean "is_winner", null: false, comment: "Whether the player won"
    t.integer "elo", comment: "Trueskill mu normalized, after battle"
    t.float "mu", comment: "Trueskill mu, after battle"
    t.float "sigma", comment: "Trueskill sigma, after battle"
    t.integer "wins", default: 0, comment: "wins to date"
    t.integer "losses", default: 0, comment: "losses to date"
    t.date "date", comment: "date of the battle"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ruleset_id"
    t.index ["doctrine_id"], name: "index_historical_battle_players_on_doctrine_id"
    t.index ["faction_id"], name: "index_historical_battle_players_on_faction_id"
    t.index ["player_id"], name: "index_historical_battle_players_on_player_id"
    t.index ["player_name"], name: "index_historical_battle_players_on_player_name"
    t.index ["ruleset_id"], name: "index_historical_battle_players_on_ruleset_id"
  end

  create_table "historical_player_ratings", force: :cascade do |t|
    t.string "player_name", comment: "historical player name"
    t.bigint "player_id"
    t.integer "elo", comment: "trueskill mu normalized between 1000 and 2000"
    t.float "mu", comment: "trueskill mu"
    t.float "sigma", comment: "trueskill sigma"
    t.date "last_played", comment: "last played match"
    t.integer "wins", default: 0, comment: "wins to date"
    t.integer "losses", default: 0, comment: "losses to date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_historical_player_ratings_on_player_id"
    t.index ["player_name"], name: "index_historical_player_ratings_on_player_name", unique: true
  end

  create_table "offmaps", force: :cascade do |t|
    t.string "name", null: false, comment: "Offmap name"
    t.string "display_name", null: false, comment: "Offmap display name"
    t.string "const_name", null: false, comment: "Offmap const name for battlefile"
    t.string "description", null: false, comment: "Offmap description"
    t.string "upgrade_rgd", comment: "upgrade rgd name"
    t.string "ability_rgd", comment: "ability_rgd_name"
    t.integer "cooldown", comment: "Cooldown between uses, in seconds"
    t.integer "duration", comment: "Offmap duration in seconds"
    t.boolean "unlimited_uses", null: false, comment: "Whether this offmap has limited or unlimited uses"
    t.string "buffs", comment: "Description of buffs this offmap grants"
    t.string "debuffs", comment: "Description of debuffs this offmap inflicts"
    t.string "weapon_rgd", comment: "Weapon rgd name"
    t.integer "shells_fired", comment: "Number of shells fired during the offmap"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ruleset_id", null: false
    t.boolean "disabled", default: false, null: false, comment: "override that disables the offmap from being purchased or used"
    t.index ["name", "ruleset_id"], name: "index_offmaps_on_name_and_ruleset_id", unique: true
    t.index ["ruleset_id"], name: "index_offmaps_on_ruleset_id"
  end

  create_table "player_discord_temp", comment: "Temporary table for migrating player discord ids", force: :cascade do |t|
    t.string "player_name"
    t.string "discord_id"
  end

  create_table "player_ratings", force: :cascade do |t|
    t.bigint "player_id"
    t.integer "elo", comment: "trueskill mu normalized between 1000 and 2000"
    t.float "mu", comment: "trueskill mu"
    t.float "sigma", comment: "trueskill sigma"
    t.date "last_played", comment: "last played match"
    t.integer "wins", default: 0, comment: "wins to date"
    t.integer "losses", default: 0, comment: "losses to date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "elo_override", comment: "Override elo to provide a handicap"
    t.index ["mu"], name: "index_player_ratings_on_mu"
    t.index ["player_id"], name: "index_player_ratings_on_player_id"
  end

  create_table "players", comment: "Player record", force: :cascade do |t|
    t.string "name", null: false, comment: "Player screen name"
    t.text "avatar", comment: "Player avatar url"
    t.string "provider", comment: "Omniauth provider"
    t.string "uid", comment: "Omniauth uid"
    t.string "discord_id", comment: "Discord id"
    t.integer "vps", default: 0, null: false, comment: "WAR VPs earned up to ruleset max"
    t.integer "total_vps_earned", default: 0, null: false, comment: "Total WAR VPs earned, not capped"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "role", null: false, comment: "Player role for permissions"
    t.index ["provider", "uid"], name: "index_players_on_provider_and_uid", unique: true
  end

  create_table "quotes", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "resource_bonuses", force: :cascade do |t|
    t.bigint "ruleset_id", null: false
    t.string "name", null: false, comment: "Resource bonus name"
    t.string "resource", null: false, comment: "Resource type"
    t.integer "man", default: 0, null: false, comment: "Man change"
    t.integer "mun", default: 0, null: false, comment: "Mun change"
    t.integer "fuel", default: 0, null: false, comment: "Fuel change"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource", "ruleset_id"], name: "index_resource_bonuses_on_resource_and_ruleset_id", unique: true
    t.index ["ruleset_id"], name: "index_resource_bonuses_on_ruleset_id"
  end

  create_table "restriction_callin_modifiers", comment: "Association of Restriction to CallinModifier", force: :cascade do |t|
    t.bigint "restriction_id"
    t.bigint "callin_modifier_id"
    t.bigint "ruleset_id"
    t.string "internal_description", null: false, comment: "What does this RestrictionCallinModifier do?"
    t.string "type", null: false, comment: "What effect this restriction has on the callin modifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["callin_modifier_id"], name: "index_restriction_callin_modifiers_on_callin_modifier_id"
    t.index ["restriction_id"], name: "index_restriction_callin_modifiers_on_restriction_id"
    t.index ["ruleset_id"], name: "index_restriction_callin_modifiers_on_ruleset_id"
  end

  create_table "restriction_offmaps", comment: "Association of Restriction to Offmap", force: :cascade do |t|
    t.bigint "restriction_id"
    t.bigint "offmap_id"
    t.bigint "ruleset_id"
    t.string "internal_description", null: false, comment: "What does this RestrictionOffmap do?"
    t.string "type", null: false, comment: "What effect this restriction has on the offmap"
    t.integer "max", comment: "Maximum number purchasable"
    t.integer "mun", comment: "Munitions cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["offmap_id"], name: "index_restriction_offmaps_on_offmap_id"
    t.index ["restriction_id"], name: "index_restriction_offmaps_on_restriction_id"
    t.index ["ruleset_id"], name: "index_restriction_offmaps_on_ruleset_id"
  end

  create_table "restriction_units", comment: "Association of Restriction to Unit", force: :cascade do |t|
    t.bigint "restriction_id"
    t.bigint "unit_id"
    t.bigint "ruleset_id"
    t.string "internal_description", null: false, comment: "What does this RestrictionUnit do?"
    t.string "type", null: false, comment: "What effect this restriction has on the unit"
    t.decimal "pop", comment: "Population cost"
    t.integer "man", comment: "Manpower cost"
    t.integer "mun", comment: "Munition cost"
    t.integer "fuel", comment: "Fuel cost"
    t.integer "resupply", comment: "Per game resupply"
    t.integer "resupply_max", comment: "How much resupply is available from saved up resupplies, <= company max"
    t.integer "company_max", comment: "Maximum number of the unit a company can hold"
    t.decimal "callin_modifier", comment: "Base callin modifier"
    t.integer "priority", comment: "Priority order to apply the modification from 1 -> 100"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "upgrade_slots", comment: "Slots used for per model weapon upgrades"
    t.integer "unitwide_upgrade_slots", comment: "Unit wide weapon replacement slot"
    t.index ["restriction_id", "ruleset_id"], name: "index_restriction_units_on_restriction_id_and_ruleset_id"
    t.index ["restriction_id", "unit_id", "ruleset_id", "type"], name: "index_restriction_units_restriction_unit_ruleset_type", unique: true
    t.index ["restriction_id"], name: "index_restriction_units_on_restriction_id"
    t.index ["ruleset_id"], name: "index_restriction_units_on_ruleset_id"
    t.index ["unit_id", "ruleset_id"], name: "index_restriction_units_on_unit_id_and_ruleset_id"
    t.index ["unit_id"], name: "index_restriction_units_on_unit_id"
  end

  create_table "restriction_upgrade_units", comment: "Association between RestrictionUpgrade and Units", force: :cascade do |t|
    t.bigint "restriction_upgrade_id"
    t.bigint "unit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restriction_upgrade_id"], name: "index_restriction_upgrade_units_on_restriction_upgrade_id"
    t.index ["unit_id"], name: "index_restriction_upgrade_units_on_unit_id"
  end

  create_table "restriction_upgrades", force: :cascade do |t|
    t.bigint "restriction_id"
    t.bigint "upgrade_id"
    t.bigint "ruleset_id"
    t.string "internal_description", comment: "What does this RestrictionUpgrade do?"
    t.string "type", null: false, comment: "What effect this restriction has on the upgrade"
    t.integer "uses", comment: "Number of uses this upgrade provides"
    t.integer "max", comment: "Maximum number of purchases per unit"
    t.integer "pop", comment: "Population cost"
    t.integer "man", comment: "Manpower cost"
    t.integer "mun", comment: "Munition cost"
    t.integer "fuel", comment: "Fuel cost"
    t.integer "priority", comment: "Priority of this restriction"
    t.integer "upgrade_slots", comment: "Upgrade slot cost for per model upgrades"
    t.integer "unitwide_upgrade_slots", comment: "Upgrade slot cost for unit wide upgrades"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restriction_id", "upgrade_id", "ruleset_id", "type", "uses", "max", "man", "mun", "fuel"], name: "idx_restriction_upgrades_ruleset_type_uniq", unique: true
    t.index ["restriction_id"], name: "index_restriction_upgrades_on_restriction_id"
    t.index ["ruleset_id", "restriction_id"], name: "index_restriction_upgrades_on_ruleset_id_and_restriction_id"
    t.index ["ruleset_id", "upgrade_id"], name: "index_restriction_upgrades_on_ruleset_id_and_upgrade_id"
    t.index ["ruleset_id"], name: "index_restriction_upgrades_on_ruleset_id"
    t.index ["upgrade_id"], name: "index_restriction_upgrades_on_upgrade_id"
  end

  create_table "restrictions", force: :cascade do |t|
    t.string "name", comment: "Restriction name"
    t.text "description", comment: "Restriction description"
    t.bigint "faction_id"
    t.bigint "doctrine_id"
    t.bigint "doctrine_unlock_id"
    t.bigint "unlock_id"
    t.integer "vet_requirement", comment: "Minimum veterancy requirement"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctrine_id"], name: "index_restrictions_on_doctrine_id"
    t.index ["doctrine_id"], name: "unique_not_null_doctrine_id", unique: true, where: "(doctrine_id IS NOT NULL)"
    t.index ["doctrine_unlock_id"], name: "index_restrictions_on_doctrine_unlock_id"
    t.index ["doctrine_unlock_id"], name: "unique_not_null_doctrine_unlock_id", unique: true, where: "(doctrine_unlock_id IS NOT NULL)"
    t.index ["faction_id"], name: "index_restrictions_on_faction_id"
    t.index ["faction_id"], name: "unique_not_null_faction_id", unique: true, where: "(faction_id IS NOT NULL)"
    t.index ["unlock_id"], name: "index_restrictions_on_unlock_id"
    t.index ["unlock_id"], name: "unique_not_null_unlock_id", unique: true, where: "(unlock_id IS NOT NULL)"
    t.check_constraint "num_nonnulls(faction_id, doctrine_id, doctrine_unlock_id, unlock_id) = 1", name: "chk_only_one_is_not_null"
  end

  create_table "rulesets", force: :cascade do |t|
    t.string "name", null: false, comment: "Ruleset name"
    t.string "ruleset_type", null: false, comment: "Type of ruleset this is"
    t.boolean "is_active", null: false, comment: "Is this ruleset active for its ruleset type?"
    t.string "description", comment: "Description"
    t.integer "starting_man", null: false, comment: "Company starting manpower"
    t.integer "starting_mun", null: false, comment: "Company starting muntions"
    t.integer "starting_fuel", null: false, comment: "Company starting fuel"
    t.integer "starting_vps", null: false, comment: "Company starting vps"
    t.integer "max_vps", null: false, comment: "Company max vps"
    t.integer "max_resource_bonuses", null: false, comment: "Company maximum number of resource bonuses"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ruleset_type", "is_active"], name: "index_rulesets_on_ruleset_type_and_is_active"
  end

  create_table "squad_upgrades", comment: "Upgrades purchased for squad", force: :cascade do |t|
    t.bigint "squad_id"
    t.bigint "available_upgrade_id"
    t.boolean "is_free", comment: "Flag for whether this upgrade is free for the squad and has no availability cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["available_upgrade_id"], name: "index_squad_upgrades_on_available_upgrade_id"
    t.index ["squad_id"], name: "index_squad_upgrades_on_squad_id"
  end

  create_table "squads", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "available_unit_id"
    t.string "tab_category", null: false, comment: "Tab this squad is in"
    t.integer "category_position", null: false, comment: "Position within the tab the squad is in"
    t.string "uuid", null: false, comment: "Unique uuid"
    t.decimal "vet", comment: "Squad's veterancy"
    t.string "name", comment: "Squad's custom name"
    t.decimal "pop", comment: "Total pop of the squad including unit and all upgrades"
    t.integer "total_model_count", comment: "Total model count of the unit and all upgrades"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["available_unit_id"], name: "index_squads_on_available_unit_id"
    t.index ["company_id"], name: "index_squads_on_company_id"
    t.index ["uuid"], name: "index_squads_on_uuid", unique: true
  end

  create_table "stats_abilities", force: :cascade do |t|
    t.bigint "ruleset_id", null: false
    t.string "reference", null: false, comment: "Attrib reference string, a unique identifier"
    t.jsonb "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.index ["ruleset_id", "reference"], name: "index_stats_abilities_on_ruleset_id_and_reference", unique: true
    t.index ["ruleset_id"], name: "index_stats_abilities_on_ruleset_id"
  end

  create_table "stats_doc_markers", force: :cascade do |t|
    t.bigint "ruleset_id", null: false
    t.string "const_name", null: false
    t.string "reference", null: false
    t.string "faction", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ruleset_id", "reference"], name: "index_stats_doc_markers_on_ruleset_id_and_reference", unique: true
    t.index ["ruleset_id"], name: "index_stats_doc_markers_on_ruleset_id"
  end

  create_table "stats_entities", comment: "Table for entity level stats, no const name but expect unique by reference", force: :cascade do |t|
    t.bigint "ruleset_id", null: false
    t.string "reference", null: false, comment: "Attrib reference string, a unique identifier"
    t.jsonb "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.index ["ruleset_id", "reference"], name: "index_stats_entities_on_ruleset_id_and_reference", unique: true
    t.index ["ruleset_id"], name: "index_stats_entities_on_ruleset_id"
  end

  create_table "stats_slot_items", force: :cascade do |t|
    t.bigint "ruleset_id", null: false
    t.string "reference", null: false, comment: "Attrib reference string, a unique identifier"
    t.jsonb "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.index ["ruleset_id", "reference"], name: "index_stats_slot_items_on_ruleset_id_and_reference", unique: true
    t.index ["ruleset_id"], name: "index_stats_slot_items_on_ruleset_id"
  end

  create_table "stats_units", comment: "Table for squad level stats, allows duplicate references as multiple const_names may refer to the same reference", force: :cascade do |t|
    t.bigint "ruleset_id", null: false
    t.string "reference", null: false, comment: "Attrib reference string"
    t.string "const_name", null: false, comment: "SCAR const string, a unique identifier"
    t.jsonb "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.index ["ruleset_id", "const_name"], name: "index_stats_units_on_ruleset_id_and_const_name", unique: true
    t.index ["ruleset_id", "reference"], name: "index_stats_units_on_ruleset_id_and_reference"
    t.index ["ruleset_id"], name: "index_stats_units_on_ruleset_id"
  end

  create_table "stats_upgrades", force: :cascade do |t|
    t.bigint "ruleset_id", null: false
    t.string "reference", null: false, comment: "Attrib reference string, a unique identifier"
    t.string "const_name", comment: "SCAR const string, optional"
    t.jsonb "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.index ["ruleset_id", "const_name"], name: "index_stats_upgrades_on_ruleset_id_and_const_name", unique: true, where: "(const_name IS NOT NULL)"
    t.index ["ruleset_id", "reference", "const_name"], name: "index_stats_upgrades_on_ruleset_id_and_reference_and_const_name", unique: true
    t.index ["ruleset_id"], name: "index_stats_upgrades_on_ruleset_id"
  end

  create_table "stats_weapons", comment: "Table for entity level stats, expect unique by reference", force: :cascade do |t|
    t.bigint "ruleset_id", null: false
    t.string "reference", null: false, comment: "Attrib reference string, a unique identifier"
    t.jsonb "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.index ["ruleset_id", "reference"], name: "index_stats_weapons_on_ruleset_id_and_reference", unique: true
    t.index ["ruleset_id"], name: "index_stats_weapons_on_ruleset_id"
  end

  create_table "transport_allowed_units", comment: "Association of transport units and the units they are allowed to transport", force: :cascade do |t|
    t.bigint "transport_id", null: false
    t.bigint "allowed_unit_id", null: false
    t.string "internal_description", comment: "Internal description of this TransportAllowedUnit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["allowed_unit_id"], name: "index_transport_allowed_units_on_allowed_unit_id"
    t.index ["transport_id", "allowed_unit_id"], name: "idx_transport_allowed_units_uniq", unique: true
    t.index ["transport_id"], name: "index_transport_allowed_units_on_transport_id"
  end

  create_table "transported_squads", comment: "Association of transport squad to embarked squad", force: :cascade do |t|
    t.bigint "transport_squad_id", null: false
    t.bigint "embarked_squad_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["embarked_squad_id"], name: "idx_transported_squads_embarked_squad_uniq", unique: true
    t.index ["embarked_squad_id"], name: "index_transported_squads_on_embarked_squad_id"
    t.index ["transport_squad_id", "embarked_squad_id"], name: "idx_transported_squads_assoc_uniq", unique: true
    t.index ["transport_squad_id"], name: "index_transported_squads_on_transport_squad_id"
  end

  create_table "unit_swaps", comment: "Association of old and new units to swap for an unlock", force: :cascade do |t|
    t.bigint "unlock_id", null: false
    t.bigint "old_unit_id", null: false
    t.bigint "new_unit_id", null: false
    t.string "internal_description", comment: "Internal description of this UnitSwap"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["new_unit_id"], name: "index_unit_swaps_on_new_unit_id"
    t.index ["old_unit_id"], name: "index_unit_swaps_on_old_unit_id"
    t.index ["unlock_id", "new_unit_id"], name: "index_unit_swaps_on_unlock_id_and_new_unit_id", unique: true
    t.index ["unlock_id", "old_unit_id"], name: "index_unit_swaps_on_unlock_id_and_old_unit_id", unique: true
    t.index ["unlock_id"], name: "index_unit_swaps_on_unlock_id"
  end

  create_table "unit_vet", comment: "Unit veterancy levels and descriptions", force: :cascade do |t|
    t.bigint "unit_id", null: false
    t.integer "vet1_exp", default: 0, null: false
    t.string "vet1_desc", null: false
    t.integer "vet2_exp", default: 0, null: false
    t.string "vet2_desc", null: false
    t.integer "vet3_exp", default: 0, null: false
    t.string "vet3_desc", null: false
    t.integer "vet4_exp", default: 0, null: false
    t.string "vet4_desc", null: false
    t.integer "vet5_exp", default: 0, null: false
    t.string "vet5_desc", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "idx_unit_vet_unit_id_uniq", unique: true
    t.index ["unit_id"], name: "index_unit_vet_on_unit_id"
  end

  create_table "units", comment: "Metadata for a unit", force: :cascade do |t|
    t.string "name", null: false, comment: "Unique unit name"
    t.string "type", null: false, comment: "Unit type"
    t.string "const_name", null: false, comment: "Const name of the unit for the battle file"
    t.string "display_name", null: false, comment: "Display name"
    t.text "description", comment: "Display description of the unit"
    t.integer "upgrade_slots", default: 0, null: false, comment: "Slots used for per model weapon upgrades"
    t.integer "unitwide_upgrade_slots", default: 0, null: false, comment: "Unit wide weapon replacement slot"
    t.integer "model_count", comment: "How many model entities this base unit consists of"
    t.integer "transport_squad_slots", comment: "How many squads this unit can transport"
    t.integer "transport_model_slots", comment: "How many models this unit can transport"
    t.boolean "is_airdrop", default: false, null: false, comment: "Is this unit airdroppable?"
    t.boolean "is_infiltrate", default: false, null: false, comment: "Is this unit able to infiltrate?"
    t.string "retreat_name", comment: "Name for retreating unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled", default: false, null: false, comment: "override that disables the unit from being purchased or used"
    t.index ["name"], name: "index_units_on_name", unique: true
  end

  create_table "unlocks", comment: "Metadata for a generic doctrine ability", force: :cascade do |t|
    t.string "name", null: false, comment: "Unlock internal name"
    t.string "display_name", null: false, comment: "Unlock display name"
    t.string "const_name", comment: "Const name of the doctrine ability for the battle file"
    t.text "description", comment: "Display description of this doctrine ability"
    t.string "image_path", comment: "Url to the image to show for this doctrine ability"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ruleset_id", null: false
    t.index ["name", "ruleset_id"], name: "index_unlocks_on_name_and_ruleset_id", unique: true
    t.index ["ruleset_id"], name: "index_unlocks_on_ruleset_id"
  end

  create_table "upgrade_swap_units", comment: "Association of upgrade swap to affected units", force: :cascade do |t|
    t.bigint "upgrade_swap_id", null: false
    t.bigint "unit_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "index_upgrade_swap_units_on_unit_id"
    t.index ["upgrade_swap_id", "unit_id"], name: "index_upgrade_swap_units_on_upgrade_swap_id_and_unit_id", unique: true
    t.index ["upgrade_swap_id"], name: "index_upgrade_swap_units_on_upgrade_swap_id"
  end

  create_table "upgrade_swaps", comment: "Association of old and new upgrades to swap for in an unlock", force: :cascade do |t|
    t.bigint "unlock_id", null: false
    t.bigint "old_upgrade_id", null: false
    t.bigint "new_upgrade_id", null: false
    t.string "internal_description", comment: "Internal description of this UpgradeSwap"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["new_upgrade_id"], name: "index_upgrade_swaps_on_new_upgrade_id"
    t.index ["old_upgrade_id"], name: "index_upgrade_swaps_on_old_upgrade_id"
    t.index ["unlock_id", "new_upgrade_id"], name: "index_upgrade_swaps_on_unlock_id_and_new_upgrade_id", unique: true
    t.index ["unlock_id", "old_upgrade_id"], name: "index_upgrade_swaps_on_unlock_id_and_old_upgrade_id", unique: true
    t.index ["unlock_id"], name: "index_upgrade_swaps_on_unlock_id"
  end

  create_table "upgrades", force: :cascade do |t|
    t.string "const_name", comment: "Upgrade const name used by the battlefile"
    t.string "name", null: false, comment: "Unique upgrade name"
    t.string "display_name", null: false, comment: "Display upgrade name"
    t.string "description", comment: "Upgrade description"
    t.integer "model_count", comment: "How many model entities this unit replacement consists of"
    t.integer "additional_model_count", comment: "How many model entities this upgrade adds to the base unit"
    t.string "type", null: false, comment: "Type of Upgrade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disabled", default: false, null: false, comment: "override that disables the upgrade from being purchased or used"
    t.index ["name"], name: "index_upgrades_on_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "available_offmaps", "companies"
  add_foreign_key "available_offmaps", "offmaps"
  add_foreign_key "available_units", "companies"
  add_foreign_key "available_units", "units"
  add_foreign_key "available_upgrades", "companies"
  add_foreign_key "available_upgrades", "units"
  add_foreign_key "available_upgrades", "upgrades"
  add_foreign_key "callin_modifier_allowed_units", "callin_modifiers"
  add_foreign_key "callin_modifier_allowed_units", "units"
  add_foreign_key "callin_modifier_required_units", "callin_modifiers"
  add_foreign_key "callin_modifier_required_units", "units"
  add_foreign_key "chat_messages", "chats"
  add_foreign_key "chat_messages", "players", column: "sender_id"
  add_foreign_key "companies", "doctrines"
  add_foreign_key "companies", "factions"
  add_foreign_key "companies", "players"
  add_foreign_key "companies", "rulesets"
  add_foreign_key "company_callin_modifiers", "callin_modifiers"
  add_foreign_key "company_callin_modifiers", "companies"
  add_foreign_key "company_offmaps", "available_offmaps"
  add_foreign_key "company_offmaps", "companies"
  add_foreign_key "company_resource_bonuses", "companies"
  add_foreign_key "company_resource_bonuses", "resource_bonuses"
  add_foreign_key "company_unlocks", "companies"
  add_foreign_key "company_unlocks", "doctrine_unlocks"
  add_foreign_key "doctrine_unlocks", "doctrines"
  add_foreign_key "doctrine_unlocks", "rulesets"
  add_foreign_key "doctrine_unlocks", "unlocks"
  add_foreign_key "doctrines", "factions"
  add_foreign_key "historical_battle_players", "rulesets"
  add_foreign_key "offmaps", "rulesets"
  add_foreign_key "player_ratings", "players"
  add_foreign_key "resource_bonuses", "rulesets"
  add_foreign_key "restriction_callin_modifiers", "callin_modifiers"
  add_foreign_key "restriction_callin_modifiers", "restrictions"
  add_foreign_key "restriction_callin_modifiers", "rulesets"
  add_foreign_key "restriction_offmaps", "offmaps"
  add_foreign_key "restriction_offmaps", "restrictions"
  add_foreign_key "restriction_offmaps", "rulesets"
  add_foreign_key "restriction_units", "restrictions"
  add_foreign_key "restriction_units", "rulesets"
  add_foreign_key "restriction_units", "units"
  add_foreign_key "restriction_upgrade_units", "restriction_upgrades"
  add_foreign_key "restriction_upgrade_units", "units"
  add_foreign_key "restriction_upgrades", "restrictions"
  add_foreign_key "restriction_upgrades", "rulesets"
  add_foreign_key "restriction_upgrades", "upgrades"
  add_foreign_key "restrictions", "doctrine_unlocks"
  add_foreign_key "restrictions", "doctrines"
  add_foreign_key "restrictions", "factions"
  add_foreign_key "restrictions", "unlocks"
  add_foreign_key "squad_upgrades", "available_upgrades"
  add_foreign_key "squad_upgrades", "squads"
  add_foreign_key "squads", "available_units"
  add_foreign_key "squads", "companies"
  add_foreign_key "stats_abilities", "rulesets"
  add_foreign_key "stats_doc_markers", "rulesets"
  add_foreign_key "stats_entities", "rulesets"
  add_foreign_key "stats_slot_items", "rulesets"
  add_foreign_key "stats_units", "rulesets"
  add_foreign_key "stats_upgrades", "rulesets"
  add_foreign_key "stats_weapons", "rulesets"
  add_foreign_key "transport_allowed_units", "units", column: "allowed_unit_id"
  add_foreign_key "transport_allowed_units", "units", column: "transport_id"
  add_foreign_key "transported_squads", "squads", column: "embarked_squad_id"
  add_foreign_key "transported_squads", "squads", column: "transport_squad_id"
  add_foreign_key "unit_swaps", "units", column: "new_unit_id"
  add_foreign_key "unit_swaps", "units", column: "old_unit_id"
  add_foreign_key "unit_swaps", "unlocks"
  add_foreign_key "unlocks", "rulesets"
  add_foreign_key "upgrade_swap_units", "units"
  add_foreign_key "upgrade_swap_units", "upgrade_swaps"
  add_foreign_key "upgrade_swaps", "unlocks"
  add_foreign_key "upgrade_swaps", "upgrades", column: "new_upgrade_id"
  add_foreign_key "upgrade_swaps", "upgrades", column: "old_upgrade_id"

  create_view "company_exps", sql_definition: <<-SQL
      SELECT c.id AS company_id,
      COALESCE(sum(s.vet), (0)::numeric) AS total_exp
     FROM (companies c
       LEFT JOIN squads s ON ((c.id = s.company_id)))
    GROUP BY c.id;
  SQL
  create_view "company_leaderboard_stats", sql_definition: <<-SQL
      SELECT cs.company_id,
      c.name AS company_name,
      p.name AS player_name,
      p.id AS player_id,
      f.name AS faction_name,
      f.display_name AS faction_display_name,
      d.name AS doctrine_name,
      d.display_name AS doctrine_display_name,
      ce.total_exp,
      cs.infantry_kills_1v1,
      cs.infantry_kills_2v2,
      cs.infantry_kills_3v3,
      cs.infantry_kills_4v4,
      (((cs.infantry_kills_1v1 + cs.infantry_kills_2v2) + cs.infantry_kills_3v3) + cs.infantry_kills_4v4) AS total_infantry_kills,
      cs.vehicle_kills_1v1,
      cs.vehicle_kills_2v2,
      cs.vehicle_kills_3v3,
      cs.vehicle_kills_4v4,
      (((cs.vehicle_kills_1v1 + cs.vehicle_kills_2v2) + cs.vehicle_kills_3v3) + cs.vehicle_kills_4v4) AS total_vehicle_kills,
      cs.infantry_losses_1v1,
      cs.infantry_losses_2v2,
      cs.infantry_losses_3v3,
      cs.infantry_losses_4v4,
      (((cs.infantry_losses_1v1 + cs.infantry_losses_2v2) + cs.infantry_losses_3v3) + cs.infantry_losses_4v4) AS total_infantry_losses,
      cs.vehicle_losses_1v1,
      cs.vehicle_losses_2v2,
      cs.vehicle_losses_3v3,
      cs.vehicle_losses_4v4,
      (((cs.vehicle_losses_1v1 + cs.vehicle_losses_2v2) + cs.vehicle_losses_3v3) + cs.vehicle_losses_4v4) AS total_vehicle_losses,
      (cs.infantry_kills_1v1 + cs.vehicle_kills_1v1) AS unit_kills_1v1,
      (cs.infantry_kills_2v2 + cs.vehicle_kills_2v2) AS unit_kills_2v2,
      (cs.infantry_kills_3v3 + cs.vehicle_kills_3v3) AS unit_kills_3v3,
      (cs.infantry_kills_4v4 + cs.vehicle_kills_4v4) AS unit_kills_4v4,
      (((((((cs.infantry_kills_1v1 + cs.infantry_kills_2v2) + cs.infantry_kills_3v3) + cs.infantry_kills_4v4) + cs.vehicle_kills_1v1) + cs.vehicle_kills_2v2) + cs.vehicle_kills_3v3) + cs.vehicle_kills_4v4) AS total_unit_kills,
      (cs.infantry_losses_1v1 + cs.vehicle_losses_1v1) AS unit_losses_1v1,
      (cs.infantry_losses_2v2 + cs.vehicle_losses_2v2) AS unit_losses_2v2,
      (cs.infantry_losses_3v3 + cs.vehicle_losses_3v3) AS unit_losses_3v3,
      (cs.infantry_losses_4v4 + cs.vehicle_losses_4v4) AS unit_losses_4v4,
      (((((((cs.infantry_losses_1v1 + cs.infantry_losses_2v2) + cs.infantry_losses_3v3) + cs.infantry_losses_4v4) + cs.vehicle_losses_1v1) + cs.vehicle_losses_2v2) + cs.vehicle_losses_3v3) + cs.vehicle_losses_4v4) AS total_unit_losses,
          CASE
              WHEN ((cs.wins_1v1 + cs.losses_1v1) = 0) THEN (0)::double precision
              ELSE (((cs.infantry_kills_1v1 + cs.vehicle_kills_1v1))::double precision / ((cs.wins_1v1 + cs.losses_1v1))::double precision)
          END AS avg_kills_1v1,
          CASE
              WHEN ((cs.wins_2v2 + cs.losses_2v2) = 0) THEN (0)::double precision
              ELSE (((cs.infantry_kills_2v2 + cs.vehicle_kills_2v2))::double precision / ((cs.wins_2v2 + cs.losses_2v2))::double precision)
          END AS avg_kills_2v2,
          CASE
              WHEN ((cs.wins_3v3 + cs.losses_3v3) = 0) THEN (0)::double precision
              ELSE (((cs.infantry_kills_3v3 + cs.vehicle_kills_3v3))::double precision / ((cs.wins_3v3 + cs.losses_3v3))::double precision)
          END AS avg_kills_3v3,
          CASE
              WHEN ((cs.wins_4v4 + cs.losses_4v4) = 0) THEN (0)::double precision
              ELSE (((cs.infantry_kills_4v4 + cs.vehicle_kills_4v4))::double precision / ((cs.wins_4v4 + cs.losses_4v4))::double precision)
          END AS avg_kills_4v4,
          CASE
              WHEN ((((((((cs.wins_1v1 + cs.wins_2v2) + cs.wins_3v3) + cs.wins_4v4) + cs.losses_1v1) + cs.losses_2v2) + cs.losses_3v3) + cs.losses_4v4) = 0) THEN (0)::double precision
              ELSE (((((((((cs.infantry_kills_1v1 + cs.infantry_kills_2v2) + cs.infantry_kills_3v3) + cs.infantry_kills_4v4) + cs.vehicle_kills_1v1) + cs.vehicle_kills_2v2) + cs.vehicle_kills_3v3) + cs.vehicle_kills_4v4))::double precision / ((((((((cs.wins_1v1 + cs.wins_2v2) + cs.wins_3v3) + cs.wins_4v4) + cs.losses_1v1) + cs.losses_2v2) + cs.losses_3v3) + cs.losses_4v4))::double precision)
          END AS combined_avg_kills,
          CASE
              WHEN ((cs.wins_1v1 + cs.losses_1v1) = 0) THEN (0)::double precision
              ELSE (((cs.infantry_losses_1v1 + cs.vehicle_losses_1v1))::double precision / ((cs.wins_1v1 + cs.losses_1v1))::double precision)
          END AS avg_losses_1v1,
          CASE
              WHEN ((cs.wins_2v2 + cs.losses_2v2) = 0) THEN (0)::double precision
              ELSE (((cs.infantry_losses_2v2 + cs.vehicle_losses_2v2))::double precision / ((cs.wins_2v2 + cs.losses_2v2))::double precision)
          END AS avg_losses_2v2,
          CASE
              WHEN ((cs.wins_3v3 + cs.losses_3v3) = 0) THEN (0)::double precision
              ELSE (((cs.infantry_losses_3v3 + cs.vehicle_losses_3v3))::double precision / ((cs.wins_3v3 + cs.losses_3v3))::double precision)
          END AS avg_losses_3v3,
          CASE
              WHEN ((cs.wins_4v4 + cs.losses_4v4) = 0) THEN (0)::double precision
              ELSE (((cs.infantry_losses_4v4 + cs.vehicle_losses_4v4))::double precision / ((cs.wins_4v4 + cs.losses_4v4))::double precision)
          END AS avg_losses_4v4,
          CASE
              WHEN ((((((((cs.wins_1v1 + cs.wins_2v2) + cs.wins_3v3) + cs.wins_4v4) + cs.losses_1v1) + cs.losses_2v2) + cs.losses_3v3) + cs.losses_4v4) = 0) THEN (0)::double precision
              ELSE (((((((((cs.infantry_losses_1v1 + cs.infantry_losses_2v2) + cs.infantry_losses_3v3) + cs.infantry_losses_4v4) + cs.vehicle_losses_1v1) + cs.vehicle_losses_2v2) + cs.vehicle_losses_3v3) + cs.vehicle_losses_4v4))::double precision / ((((((((cs.wins_1v1 + cs.wins_2v2) + cs.wins_3v3) + cs.wins_4v4) + cs.losses_1v1) + cs.losses_2v2) + cs.losses_3v3) + cs.losses_4v4))::double precision)
          END AS combined_avg_losses,
      cs.wins_1v1,
      cs.wins_2v2,
      cs.wins_3v3,
      cs.wins_4v4,
      (((cs.wins_1v1 + cs.wins_2v2) + cs.wins_3v3) + cs.wins_4v4) AS total_wins,
      cs.losses_1v1,
      cs.losses_2v2,
      cs.losses_3v3,
      cs.losses_4v4,
      (((cs.losses_1v1 + cs.losses_2v2) + cs.losses_3v3) + cs.losses_4v4) AS total_losses,
      cs.streak_1v1,
      cs.streak_2v2,
      cs.streak_3v3,
      cs.streak_4v4,
      (((cs.streak_1v1 + cs.streak_2v2) + cs.streak_3v3) + cs.streak_4v4) AS total_streak
     FROM (((((company_stats cs
       JOIN companies c ON (((cs.company_id = c.id) AND ((c.type)::text = 'ActiveCompany'::text))))
       JOIN company_exps ce ON ((ce.company_id = cs.company_id)))
       JOIN players p ON ((c.player_id = p.id)))
       JOIN factions f ON ((f.id = c.faction_id)))
       JOIN doctrines d ON ((d.id = c.doctrine_id)));
  SQL
end
