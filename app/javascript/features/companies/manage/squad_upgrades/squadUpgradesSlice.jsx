import { createEntityAdapter, createSlice } from "@reduxjs/toolkit";
import {
  copySquad,
  fetchCompanySquads, fetchSnapshotCompanySquads,
  moveSquad,
  removeSquad,
  removeTransportedSquad,
  upsertSquads
} from "../units/squadsSlice";
import { CATEGORIES } from "../../../../constants/company";
import { loadSquadUpgrade } from "./squadUpgrade";
import { removeNewCompanyOffmap } from "../company_offmaps/companyOffmapsSlice";
import _ from "lodash";

const find_or_memo = (memo, source, id) => {
  if (id in memo) {
    return memo[id]
  } else {
    const target = source.find(ele => ele.id === id)
    memo[id] = target
    return target
  }
}

const populateSquadUpgradesTree = (payload, upgrades, availableUpgrades, squads) => {
  const result = {}
  const upgradesMemo = {}
  const availableUpgradesMemo = {}
  const squadsMemo = {}
  payload.forEach(su => {
    const availableUpgrade = find_or_memo(availableUpgradesMemo, availableUpgrades, su.availableUpgradeId)
    const upgrade = find_or_memo(upgradesMemo, upgrades, availableUpgrade.upgradeId)
    const squad = find_or_memo(squadsMemo, squads, su.squadId)
    const newSquadUpgrade = loadSquadUpgrade(su, upgrade, availableUpgrade, squad)
    _.setWith(result, `[${newSquadUpgrade.tab}][${newSquadUpgrade.index}][${newSquadUpgrade.squadUuid}][${newSquadUpgrade.uuid}]`, newSquadUpgrade, Object)
  })
  return result
}

const squadUpgradesAdapter = createEntityAdapter()
const initialState = squadUpgradesAdapter.getInitialState({
  currentSquadUpgrades: {},
  isChanged: false
})

const squadUpgradesSlice = createSlice({
  name: "squadUpgrades",
  initialState,
  reducers: {
    addNewSquadUpgrade(state, action) {
      const { newSquadUpgrade } = action.payload
      const tab = newSquadUpgrade.tab,
        index = newSquadUpgrade.index,
        squadUuid = newSquadUpgrade.squadUuid,
        uuid = newSquadUpgrade.uuid
      _.setWith(state.currentSquadUpgrades, `[${tab}][${index}][${squadUuid}][${uuid}]`, newSquadUpgrade, Object)
      state.isChanged = true
    },
    removeSquadUpgrade(state, action) {
      const { squadUpgrade } = action.payload

      delete state.currentSquadUpgrades[squadUpgrade.tab][squadUpgrade.index][squadUpgrade.squadUuid][squadUpgrade.uuid]
      state.isChanged = true
    }
  },
  extraReducers(builder) {
    builder
      .addCase(fetchCompanySquads.fulfilled, (state, action) => {
        squadUpgradesAdapter.setAll(state, action.payload.squadUpgrades)
        state.currentSquadUpgrades = populateSquadUpgradesTree(action.payload.squadUpgrades, action.payload.upgrades, action.payload.availableUpgrades, action.payload.squads)
        state.isChanged = false
      })
      .addCase(fetchSnapshotCompanySquads.fulfilled, (state, action) => {
        squadUpgradesAdapter.setAll(state, action.payload.squadUpgrades)
        state.currentSquadUpgrades = populateSquadUpgradesTree(action.payload.squadUpgrades, action.payload.upgrades, action.payload.availableUpgrades, action.payload.squads)
        state.isChanged = false
      })
      .addCase(upsertSquads.fulfilled, (state, action) => {
        squadUpgradesAdapter.setAll(state, action.payload.squadUpgrades)
        state.currentSquadUpgrades = populateSquadUpgradesTree(action.payload.squadUpgrades, action.payload.upgrades, action.payload.availableUpgrades, action.payload.squads)
        state.isChanged = false
      })
      .addCase(removeSquad, (state, action) => {
        const { uuid, index, tab } = action.payload

        if (!state.currentSquadUpgrades?.[tab]?.[index]?.[uuid]) return

        delete state.currentSquadUpgrades[tab][index][uuid]
        state.isChanged = true
      })
      .addCase(removeTransportedSquad, (state, action) => {
        const { uuid, index, tab } = action.payload

        if (!state.currentSquadUpgrades?.[tab]?.[index]?.[uuid]) return

        delete state.currentSquadUpgrades[tab][index][uuid]
        state.isChanged = true
      })
      .addCase(moveSquad, (state, action) => {
        const { squad, newIndex, newTab, targetTransportUuid } = action.payload

        if (_.isNil(squad.transportUuid)) {
          // Not transported
          if (squad.tab === newTab && squad.index === newIndex && _.isNil(targetTransportUuid)) {
            return; // moving within the same tab and index (and not into a transport) does nothing
          }
        } else {
          // Source is transport
          if (squad.tab === newTab && squad.index === newIndex && squad.transportUuid === targetTransportUuid) {
            return; // moving within the same tab and index and transport does nothing
          }

        }

        // update all squad upgrades for the squad with new tab and index
        const squadUuid = squad.uuid,
          oldTab = squad.tab,
          oldIndex = squad.index;

        if (!state.currentSquadUpgrades?.[oldTab]?.[oldIndex]) return

        const oldPlatoon = state.currentSquadUpgrades[oldTab][oldIndex]
        if (squadUuid in oldPlatoon && (oldTab !== newTab || oldIndex !== newIndex)) {
          const oldSquadUpgrades = oldPlatoon[squadUuid]
          Object.values(oldSquadUpgrades).forEach(osu => {
            // Create new copy with updated location
            const newSquadUpgrade = { ...osu, index: newIndex, tab: newTab }
            _.setWith(state.currentSquadUpgrades, `[${newTab}][${newIndex}][${squadUuid}][${newSquadUpgrade.uuid}]`, newSquadUpgrade, Object)
          })

          delete state.currentSquadUpgrades[oldTab][oldIndex][squadUuid]
        }

        // If the squad has transportedSquads, also update their squad upgrades
        if (squad.transportedSquads) {
          Object.values(squad.transportedSquads).forEach(ts => {
            const tsUuid = ts.uuid
            if (tsUuid in oldPlatoon) {
              const oldSquadUpgrades = oldPlatoon[tsUuid]
              Object.values(oldSquadUpgrades).forEach(osu => {
                const newSquadUpgrade = { ...osu, index: newIndex, tab: newTab }
                _.setWith(state.currentSquadUpgrades, `[${newTab}][${newIndex}][${tsUuid}][${newSquadUpgrade.uuid}]`, newSquadUpgrade, Object)
              })
              delete state.currentSquadUpgrades[oldTab][oldIndex][tsUuid]
            }
          })
        }
      })
      .addCase(copySquad, (state, action) => {
        const { squad, squadUpgrades, transportUuid } = action.payload
        squadUpgrades.forEach(su => {
          _.setWith(state.currentSquadUpgrades, `[${su.tab}][${su.index}][${su.squadUuid}][${su.uuid}]`, su, Object)
        })
        state.isChanged = true
      })
  }
})

export default squadUpgradesSlice.reducer
export const { addNewSquadUpgrade, removeSquadUpgrade } = squadUpgradesSlice.actions

export const {
  selectAll: selectAllSquadUpgrades,
  selectById: selectSquadUpgradeById
} = squadUpgradesAdapter.getSelectors(state => state.upgrades)

export const selectSquadUpgradesForSquad = (state, tab, index, squadUuid) => _.values(state.squadUpgrades.currentSquadUpgrades[tab]?.[index]?.[squadUuid])

const transformForApi = squadUpgrade => {
  return {
    id: squadUpgrade.id,
    availableUpgradeId: squadUpgrade.availableUpgradeId,
    squadId: squadUpgrade.squadId,
    squadUuid: squadUpgrade.squadUuid
  }
}
const flattenIndexSquads = (squads) => {
  return squads.reduce((acc, current) => acc.concat(_.values(current).map(transformForApi)), [])
}
/**
 * Flatten all squad upgrades into one list for the backend
 */
export const selectFlatSquadUpgrades = (state) => {
  let squadUpgrades = []
  CATEGORIES.forEach(category => {
    const indices = state.squadUpgrades.currentSquadUpgrades[category]
    _.values(indices)
      .filter(indexSquads => !_.isEmpty(indexSquads))
      .forEach(indexSquads => {
        squadUpgrades = squadUpgrades.concat(
          flattenIndexSquads(_.values(indexSquads))
        )
      })
  })
  return squadUpgrades
}
