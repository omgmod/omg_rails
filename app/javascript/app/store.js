import { configureStore } from '@reduxjs/toolkit'
import playerSlice from "../features/player/playerSlice";
import companiesSlice from "../features/companies/companiesSlice";
import doctrinesSlice from "../features/doctrines/doctrinesSlice";
import unitsSlice from "../features/companies/manage/units/unitsSlice";
import availableUnitsSlice from "../features/companies/manage/available_units/availableUnitsSlice";
import squadsSlice from "../features/companies/manage/units/squadsSlice";
import lobbySlice from "../features/lobby/lobbySlice";
import companyUnlocksSlice from "../features/companies/manage/unlocks/companyUnlocksSlice";
import availableOffmapsSlice from "../features/companies/manage/available_offmaps/availableOffmapsSlice";
import companyOffmapsSlice from "../features/companies/manage/company_offmaps/companyOffmapsSlice";
import availableUpgradesSlice from "../features/companies/manage/available_upgrades/availableUpgradesSlice";
import upgradesSlice from "../features/companies/manage/upgrades/upgradesSlice";
import squadUpgradesSlice from "../features/companies/manage/squad_upgrades/squadUpgradesSlice";
import companyBonusesSlice from "../features/companies/manage/bonuses/companyBonusesSlice";
import restrictionUnitsSlice from "../features/restrictions/restriction_units/restrictionUnitsSlice";
import factionsSlice from "../features/factions/factionsSlice";
import companyLeaderboardSlice from "../features/leaderboards/company_leaderboard/companyLeaderboardSlice";
import snapshotCompanySlice from "../features/companies/snapshotCompaniesSlice";
import warLogSlice from "../features/leaderboards/war_log/warLogSlice";
import warStatsSlice from "../features/leaderboards/war_stats/warStatsSlice";
import rulesetsSlice from "../features/rulesets/rulesetsSlice";
import statsUnitsSlice from "../features/stats/units/statsUnitsSlice";
import statsEntitiesSlice from "../features/stats/entities/statsEntitiesSlice";
import statsWeaponsSlice from "../features/stats/weapons/statsWeaponsSlice";
import mapVetoSlice from "../features/companies/manage/map_vetoes/mapVetoSlice";

export default configureStore({
  reducer: {
    player: playerSlice,
    companies: companiesSlice,
    companyUnlocks: companyUnlocksSlice,
    companyBonuses: companyBonusesSlice,
    doctrines: doctrinesSlice,
    factions: factionsSlice,
    units: unitsSlice,
    availableUnits: availableUnitsSlice,
    availableOffmaps: availableOffmapsSlice,
    squads: squadsSlice,
    companyOffmaps: companyOffmapsSlice,
    lobby: lobbySlice,
    availableUpgrades: availableUpgradesSlice,
    upgrades: upgradesSlice,
    squadUpgrades: squadUpgradesSlice,
    restrictionUnits: restrictionUnitsSlice,
    companyLeaderboard: companyLeaderboardSlice,
    snapshotCompanies: snapshotCompanySlice,
    warLog: warLogSlice,
    warStats: warStatsSlice,
    rulesets: rulesetsSlice,
    statsUnits: statsUnitsSlice,
    statsEntities: statsEntitiesSlice,
    statsWeapons: statsWeaponsSlice,
    mapVetoes: mapVetoSlice,
  },
})
