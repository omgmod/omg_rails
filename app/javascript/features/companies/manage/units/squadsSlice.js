import { createAsyncThunk, createEntityAdapter, createSlice } from "@reduxjs/toolkit";
import axios from "axios"
import _ from "lodash"
import {
  ANTI_ARMOUR,
  ARMOUR,
  ASSAULT,
  CATEGORIES,
  CORE,
  HOLDING,
  INFANTRY,
  SUPPORT
} from "../../../../constants/company";
import { createSquad, loadSquad } from "./squad";
import {
  addNewCompanyOffmap,
  removeExistingCompanyOffmap,
  removeNewCompanyOffmap,
  selectMergedCompanyOffmaps
} from "../company_offmaps/companyOffmapsSlice";
import {
  addNewSquadUpgrade,
  removeSquadUpgrade,
  selectFlatSquadUpgrades,
  selectSquadUpgradesForSquad
} from "../squad_upgrades/squadUpgradesSlice";
import { selectAvailableUnitById, setSelectedAvailableUnitId } from "../available_units/availableUnitsSlice";
import { selectUnitById } from "./unitsSlice";
import { copySquadUpgrade } from "../squad_upgrades/squadUpgrade";
import { addCost } from "../../companiesSlice";
import { GLIDER } from "../../../../constants/units/types";

const squadsAdapter = createEntityAdapter()

const initialState = squadsAdapter.getInitialState({
  squadsStatus: "idle",
  squadsError: null,
  isChanged: false,
  notifySnackbar: false,
  callinModifiers: [],
  pop: 0,
  man: 0,
  mun: 0,
  fuel: 0,
  [CORE]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
  [ASSAULT]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
  [INFANTRY]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
  [ARMOUR]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
  [ANTI_ARMOUR]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
  [SUPPORT]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
  [HOLDING]: { 0: {} },
  selectedSquadTab: null,
  selectedSquadIndex: null,
  selectedSquadUuid: null,
  selectedSquadTransportUuid: null,
  isCompact: true,
  highlightedUuidChain: []
})

export const fetchCompanySquads = createAsyncThunk("squads/fetchCompanySquads", async ({ companyId }, { rejectWithValue }) => {
  try {
    const response = await axios.get(`/companies/${companyId}/squads`)
    return response.data
  } catch (err) {
    return rejectWithValue(err.response.data)
  }
})

export const fetchSnapshotCompanySquads = createAsyncThunk("squads/fetchSnapshotCompanySquads", async ({ uuid }, { rejectWithValue }) => {
  try {
    const response = await axios.get(`/snapshot_companies/${uuid}/squads`)
    return response.data
  } catch (err) {
    return rejectWithValue(err.response.data)
  }
})

export const upsertSquads = createAsyncThunk(
  "squads/upsertSquads",
  async ({ companyId }, { getState, rejectWithValue }) => {
    const state = getState()
    const offmaps = selectMergedCompanyOffmaps(state)
    const squadUpgrades = selectFlatSquadUpgrades(state)
    const squads = selectCurrentSquads(state)

    try {
      const response = await axios.post(`/companies/${companyId}/squads`, { squads, offmaps, squadUpgrades })
      return response.data
    } catch (err) {
      return rejectWithValue(err.response.data)
    }
  }
)

// Thunk to deep copy a squad
// https://redux.js.org/usage/writing-logic-thunks#writing-thunks
export const deepCopySquad = ({ squad, squadUpgrades }) => (dispatch, getState) => {
  if (squad.unitType === GLIDER) { // Only one glider per platoon
    return
  }

  const { tab, index } = squad

  // Copy the original squad, without transported squads
  const newSquad = copySingleSquad({ squad, squadUpgrades, transportUuid: squad.transportUuid, getState, dispatch })

  dispatch(setSelectedSquadAccess({ tab, index, uuid: newSquad.uuid, transportUuid: newSquad.transportUuid }))
  dispatch(setSelectedAvailableUnitId(newSquad.availableUnitId))

  // If the original squad had no transported squads, done
  if (!squad.transportedSquads) {
    return
  }

  // Handle transported
  const state = getState()
  const newTransportUuid = newSquad.uuid

  // Sequentially copy each transported squad (in case availability runs out mid way)
  Object.values(squad.transportedSquads).forEach(ts => {
    const tsu = selectSquadUpgradesForSquad(state, tab, index, ts.uuid)
    copySingleSquad({ squad: ts, squadUpgrades: tsu, transportUuid: newTransportUuid, getState, dispatch })
  })
}

const copySingleSquad = ({ squad, squadUpgrades, transportUuid, getState, dispatch }) => {
  const { tab, index, companyId } = squad
  const state = getState()
  const targetTransportUuid = transportUuid || squad.transportUuid

  // Check availability to create a copy of this squad
  const availableUnit = selectAvailableUnitById(state, squad.availableUnitId)
  if (availableUnit.available <= 0) {
    return
  }
  const unit = selectUnitById(state, squad.unitId)

  // Have availability, create a copy of the squad with upgrades
  const newSquad = createSquad(availableUnit, unit, index, tab, companyId, targetTransportUuid)
  let pop = newSquad.pop,
    man = newSquad.man,
    mun = newSquad.mun,
    fuel = newSquad.fuel
  const newSquadUpgrades = squadUpgrades.map(su => {
    const newSquadUpgrade = copySquadUpgrade(su, newSquad)
    newSquad.pop += newSquadUpgrade.pop || 0
    newSquad.totalModelCount += newSquadUpgrade.addModelCount || 0
    pop += newSquadUpgrade.pop
    man += newSquadUpgrade.man
    mun += newSquadUpgrade.mun
    fuel += newSquadUpgrade.fuel
    return newSquadUpgrade
  })

  dispatch(copySquad({ squad: newSquad, squadUpgrades: newSquadUpgrades, transportUuid: targetTransportUuid }))

  dispatch(addCost({
    id: squad.companyId,
    pop: pop,
    man: man,
    mun: mun,
    fuel: fuel
  }))

  if (newSquad.transportUuid) {
    // While we are targeting creating the squad in the targetTransportUuid, it's possible that the transport cannot hold it.
    // In that case, we look at the platoon level
    const squadInTransport = selectSquadInTabIndexTransportUuid(getState(), tab, index, newSquad.transportUuid, newSquad.uuid)
    if (squadInTransport) {
      return squadInTransport
    }
  }
  return selectSquadInTabIndexUuid(getState(), tab, index, newSquad.uuid)
}

const flattenPlatoonSquads = (topLevelSquads) => {
  const squads = []
  for (const tls of topLevelSquads) {
    // Check if the tls has transportedUnits
    if (!_.isEmpty(tls.transportedSquads)) {
      // If yes, build list of transported squad uuids
      const transportedSquadUuids = []
      for (const transportedSquad of _.values(tls.transportedSquads)) {
        // for each squad, get uuid and insert into transportedSquadUuids
        transportedSquadUuids.push(transportedSquad.uuid)
        // overwrite squad's transportUuid with tls uuid just in case (should never be different)
        // append transported squads to squads list
        squads.push({ ...transportedSquad, transportUuid: tls.uuid })
      }
      // done with transported squads, set transportedSquadUuids on transport squad
      // Clear transportedSquads so that isn't in payload
      // append transport squad to squads list
      squads.push({ ...tls, transportedSquadUuids: transportedSquadUuids, transportedSquads: null })
    } else {
      squads.push(tls)
    }
  }
  return squads
}

/**
 * Flattens all squads in the categories/index object into one list for the backend.
 * If a squad is a transport and has transportedUnits, construct a list of all transported squad uuids and attach to
 * the transport squad.
 * Transported squads will retain their transportUuid
 */
const selectCurrentSquads = state => {
  let squads = []
  CATEGORIES.forEach(category => {
    const squadsForCat = state.squads[category]
    Object.values(squadsForCat)
      .filter(indexSquads => !_.isEmpty(indexSquads))
      .forEach(indexSquads => {
        squads = squads.concat(
          flattenPlatoonSquads(Object.values(indexSquads))
        )
      })
  })
  return squads
}

/**
 * Given a list of squad objects,
 * @param squads: Array of squad objects, including tab and index values to identify which tab index the squad belongs to
 * @returns object containing keys of Tab Categories, and values of objects representing the 8 tab indices
 */
const buildNewSquadTabs = (squads) => {
  const tabs = {
    [CORE]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
    [ASSAULT]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
    [INFANTRY]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
    [ARMOUR]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
    [ANTI_ARMOUR]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
    [SUPPORT]: { 0: {}, 1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {} },
    [HOLDING]: { 0: {} }
  }
  const transportedSquads = []
  squads.forEach(squad => {
    // For each squad, add to the platoon if the squad does not have a transportUuid. This means the squad is at the top level
    // If transported, add to the transportedSquads array and iterate later (the transport may not have been seen yet in this loop)
    if (_.isNil(squad.transportUuid)) {
      const platoon = tabs[squad.tab][squad.index]
      platoon[squad.uuid] = loadSquad(squad)
    } else {
      transportedSquads.push(squad)
    }
  })

  if (transportedSquads.length > 0) {
    // For transported squads, locate the transport and set on the transport's transportedSquads mapping
    transportedSquads.forEach(squad => {
      const transport = tabs[squad.tab][squad.index][squad.transportUuid]
      const transportedSquads = { ...transport.transportedSquads, [squad.uuid]: loadSquad(squad) }
      const popWithTransported = transport.popWithTransported + parseFloat(squad.pop)
      const usedSquadSlots = transport.usedSquadSlots + 1
      const usedModelSlots = transport.usedModelSlots + squad.totalModelCount
      tabs[squad.tab][squad.index][squad.transportUuid] = {
        ...transport,
        popWithTransported: popWithTransported,
        transportedSquads: transportedSquads,
        usedSquadSlots: usedSquadSlots,
        usedModelSlots: usedModelSlots
      }
    })
  }
  return tabs
}

const squadsSlice = createSlice({
  name: "squads",
  initialState,
  reducers: {
    /**
     * For a non-transported squad, simply add the squad by uuid to the platoon at the squad's tab and index
     */
    addNonTransportedSquad(state, action) {
      const { uuid, index, tab } = action.payload
      const platoon = state[tab][index]
      if (!Object.keys(platoon).includes(uuid)) {
        platoon[uuid] = action.payload
      }
      state.isChanged = true
    },
    /**
     * For a transported squad, find the transporting squad by the squad's transportUuid, index, and tab.
     * If the transporting
     */
    addTransportedSquad(state, action) {
      const { newSquad, transportUuid } = action.payload
      const { uuid, index, tab, totalModelCount, pop } = newSquad
      const platoon = state[tab][index]
      if (_.has(platoon, transportUuid)) {
        const transport = platoon[transportUuid]
        if (!_.isPlainObject(transport.transportedSquads)) {
          transport.transportedSquads = {}
        }
        if (!_.isArray(transport.transportedSquadUuids)) {
          transport.transportedSquadUuids = []
        }
        const transportedSquads = transport.transportedSquads,
          transportedSquadUuids = transport.transportedSquadUuids

        if (!_.has(transportedSquads, uuid)) {
          const usedSquadSlots = (transport.usedSquadSlots || 0)
          const usedModelSlots = (transport.usedModelSlots || 0)
          // If the transporting squad has both squad and model slots left, add the squad to the transport
          if (usedSquadSlots + 1 <= transport.transportSquadSlots && usedModelSlots + totalModelCount <= transport.transportModelSlots) {
            transportedSquads[uuid] = newSquad
            transportedSquadUuids.push(uuid)
            transport.transportedSquads = transportedSquads
            transport.transportedSquadUuids = transportedSquadUuids
            transport.usedSquadSlots = usedSquadSlots + 1
            transport.usedModelSlots = usedModelSlots + totalModelCount
            transport.popWithTransported = parseFloat(transport.popWithTransported) + parseFloat(pop)
          } else {
            // Otherwise, add the squad to the platoon
            if (!Object.keys(platoon).includes(uuid)) {
              platoon[uuid] = newSquad
            }
          }
        }
      } else {
        if (!Object.keys(platoon).includes(uuid)) {
          platoon[uuid] = newSquad
        }
      }
      state.isChanged = true
    },
    removeSquad(state, action) {
      const { uuid, index, tab } = action.payload
      const platoon = state[tab][index]
      if (Object.keys(platoon).includes(uuid)) {
        const squad = platoon[uuid]
        // Check if this squad has transportedSquads. If so, move them to the platoon level first
        const transportedSquads = _.values(squad.transportedSquads)
        if (!_.isEmpty(transportedSquads)) {
          transportedSquads.forEach(ts => {
            platoon[ts.uuid] = { ...ts, transportUuid: null }
          })
        }

        delete platoon[uuid]
      }
      state.isChanged = true

      // in Firefox, an onMouseLeave event does not fire when dragging cards across drop targets, meaning we have an
      // extra uuid of the same value left in the stack, causing a stuck tooltip. Pop it manually as we shouldn't have
      // two of the same uuid in the stack sequentially
      state.highlightedUuidChain = []
    },
    removeTransportedSquad(state, action) {
      const { squad, transportUuid } = action.payload
      const platoon = state[squad.tab][squad.index]
      if (_.has(platoon, transportUuid)) {
        const transport = platoon[transportUuid]
        if (_.has(transport.transportedSquads, squad.uuid)) {
          const squadToDestroy = transport.transportedSquads[squad.uuid]
          transport.popWithTransported = parseFloat(transport.popWithTransported) - parseFloat(squadToDestroy.pop)
          transport.usedSquadSlots -= 1
          transport.usedModelSlots -= squadToDestroy.totalModelCount
          delete transport.transportedSquads[squadToDestroy.uuid]
          delete transport.transportedSquadUuids[transport.transportedSquadUuids.indexOf(squadToDestroy.uuid)]

          if (squadToDestroy.uuid === state.selectedSquadUuid) {
            state.selectedSquadTab = null
            state.selectedSquadIndex = null
            state.selectedSquadUuid = null
            state.selectedSquadTransportUuid = null
          }
        }
      }
      state.isChanged = true

      // in Firefox, an onMouseLeave event does not fire when dragging cards across drop targets, meaning we have an
      // extra uuid of the same value left in the stack, causing a stuck tooltip. Pop it manually as we shouldn't have
      // two of the same uuid in the stack sequentially
      state.highlightedUuidChain = []
    },
    /** Moving a squad from the old index and tab to a new index and tab, with optional target transportUuid if the
     * squad is moving into a transport in the target platoon.
     * If the squad has non-null transportUuid, it is located in a transport in its source platoon and will need to be
     * removed */
    moveSquad(state, action) {
      const { squad, unit, newIndex, newTab, targetTransportUuid } = action.payload
      const uuid = squad.uuid
      const oldPlatoon = state[squad.tab][squad.index]
      let workingSquad, sourceTransport
      if (_.isNil(squad.transportUuid)) {
        // Not transported
        workingSquad = oldPlatoon[uuid]
        delete oldPlatoon[uuid]
      } else {
        // Source is transport
        sourceTransport = oldPlatoon[squad.transportUuid]
        workingSquad = sourceTransport.transportedSquads[uuid]

        // Uncouple squad from the source transport
        workingSquad.transportUuid = null
        sourceTransport.popWithTransported = parseFloat(sourceTransport.popWithTransported) - parseFloat(workingSquad.pop)
        sourceTransport.usedSquadSlots -= 1
        sourceTransport.usedModelSlots -= workingSquad.totalModelCount
        delete sourceTransport.transportedSquads[uuid]
      }
      workingSquad.tab = newTab
      workingSquad.index = newIndex
      const newPlatoon = state[newTab][newIndex]

      if (_.isNil(targetTransportUuid)) {
        // Moving into platoon
        newPlatoon[uuid] = workingSquad

        // If this squad is transporting other squads, update the transported squads
        if (workingSquad.transportedSquads) {
          Object.values(workingSquad.transportedSquads).forEach(ts => {
            ts.tab = newTab
            ts.index = newIndex
          })
        }
        state.selectedSquadTransportUuid = null
      } else {
        // Moving into transport
        const targetTransport = newPlatoon[targetTransportUuid]
        if (!_.isPlainObject(targetTransport.transportedSquads)) {
          targetTransport.transportedSquads = {}
        }
        if (!_.isArray(targetTransport.transportedSquadUuids)) {
          targetTransport.transportedSquadUuids = []
        }
        const transportedSquads = targetTransport.transportedSquads,
          transportedSquadUuids = targetTransport.transportedSquadUuids

        transportedSquads[uuid] = workingSquad
        transportedSquadUuids.push(uuid)
        workingSquad.transportUuid = targetTransportUuid
        targetTransport.transportedSquads = transportedSquads
        targetTransport.transportedSquadUuids = transportedSquadUuids
        targetTransport.usedSquadSlots = (targetTransport.usedSquadSlots || 0) + 1
        targetTransport.usedModelSlots = (targetTransport.usedModelSlots || 0) + workingSquad.totalModelCount
        targetTransport.popWithTransported = parseFloat(targetTransport.popWithTransported) + parseFloat(workingSquad.pop)
        state.selectedSquadTransportUuid = targetTransportUuid
      }

      state.selectedSquadTab = newTab
      state.selectedSquadIndex = newIndex
      state.selectedSquadUuid = uuid
      state.isChanged = true


      // in Firefox, an onMouseLeave event does not fire when dragging cards across drop targets, meaning we have an
      // extra uuid of the same value left in the stack, causing a stuck tooltip. Pop it manually as we shouldn't have
      // two of the same uuid in the stack sequentially
      state.highlightedUuidChain = []
    },
    /**
     * Copy a squad in the same index and tab.
     * Combine this with add squad reducers as they are very similar/dupes
     */
    copySquad(state, action) {
      const { squad, transportUuid } = action.payload
      const { uuid, index, tab, totalModelCount, pop } = squad

      const platoon = state[tab][index]
      if (_.has(platoon, transportUuid)) {
        const transport = platoon[transportUuid]
        if (!_.isPlainObject(transport.transportedSquads)) {
          transport.transportedSquads = {}
        }
        if (!_.isArray(transport.transportedSquadUuids)) {
          targetTransport.transportedSquadUuids = []
        }
        const transportedSquads = transport.transportedSquads,
          transportedSquadUuids = transport.transportedSquadUuids

        if (!_.has(transportedSquads, uuid)) {
          const usedSquadSlots = (transport.usedSquadSlots || 0)
          const usedModelSlots = (transport.usedModelSlots || 0)
          // If the transporting squad has both squad and model slots left, add the squad to the transport
          if (usedSquadSlots + 1 <= transport.transportSquadSlots && usedModelSlots + totalModelCount <= transport.transportModelSlots) {
            transportedSquads[uuid] = squad
            transportedSquadUuids.push(uuid)
            transport.transportedSquads = transportedSquads
            transport.transportedSquadUuids = transportedSquadUuids
            transport.usedSquadSlots = usedSquadSlots + 1
            transport.usedModelSlots = usedModelSlots + totalModelCount
            transport.popWithTransported = parseFloat(transport.popWithTransported) + parseFloat(pop)
          } else {
            // Otherwise, add the squad to the platoon
            if (!Object.keys(platoon).includes(uuid)) {
              platoon[uuid] = squad
            }
          }
        }
      } else {
        if (!Object.keys(platoon).includes(uuid)) {
          platoon[uuid] = squad
        }
      }

      state.isChanged = true
    },
    resetSquadState: () => initialState,
    clearNotifySnackbar(state) {
      state.notifySnackbar = false
      state.squadsStatus = "idle"
      state.squadsError = null
    },
    showSnackbar: (state, action) => {
      state.notifySnackbar = true
    },
    setSelectedSquadAccess: (state, action) => {
      state.selectedSquadTab = action.payload.tab
      state.selectedSquadIndex = action.payload.index
      state.selectedSquadUuid = action.payload.uuid
      state.selectedSquadTransportUuid = action.payload.transportUuid
    },
    clearSelectedSquad: (state) => {
      state.selectedSquadTab = null
      state.selectedSquadIndex = null
      state.selectedSquadUuid = null
      state.selectedSquadTransportUuid = null
    },
    setIsCompanyManagerCompact: (state, action) => {
      state.isCompact = action.payload
    },
    setHighlightedUuid: (state, action) => {
      state.highlightedUuidChain.push(action.payload.uuid)
    },
    clearHighlightedUuid: (state) => {
      state.highlightedUuidChain.pop()
    }
  },
  extraReducers(builder) {
    builder
      .addCase(fetchCompanySquads.pending, (state, action) => {
        state.squadsStatus = "pending"
        state.squadsError = null
      })
      .addCase(fetchCompanySquads.fulfilled, (state, action) => {
        squadsAdapter.setAll(state, action.payload.squads)
        const newTabs = buildNewSquadTabs(action.payload.squads)
        for (const tabName of CATEGORIES) {
          state[tabName] = newTabs[tabName]
        }

        state.callinModifiers = action.payload.callinModifiers
        state.squadsStatus = "idle"
      })
      .addCase(fetchCompanySquads.rejected, (state, action) => {
        state.squadsStatus = "idle"
        state.squadsError = action.payload.error
      })

      .addCase(fetchSnapshotCompanySquads.pending, (state, action) => {
        state.squadsStatus = "pending"
        state.squadsError = null
      })
      .addCase(fetchSnapshotCompanySquads.fulfilled, (state, action) => {
        squadsAdapter.setAll(state, action.payload.squads)
        const newTabs = buildNewSquadTabs(action.payload.squads)
        for (const tabName of CATEGORIES) {
          state[tabName] = newTabs[tabName]
        }

        state.callinModifiers = action.payload.callinModifiers
        state.squadsStatus = "idle"
      })
      .addCase(fetchSnapshotCompanySquads.rejected, (state, action) => {
        state.squadsStatus = "idle"
        state.squadsError = action.payload.error
      })

      .addCase(upsertSquads.pending, (state, action) => {
        state.squadsStatus = "pending"
        state.squadsError = null
        state.notifySnackbar = false
      })
      .addCase(upsertSquads.fulfilled, (state, action) => {
        // action.payload.squads & action.payload.availableUnits
        squadsAdapter.setAll(state, action.payload.squads)
        const newTabs = buildNewSquadTabs(action.payload.squads)
        for (const tabName of CATEGORIES) {
          state[tabName] = newTabs[tabName]
        }
        state.squadsStatus = "idle"
        state.isChanged = false
        state.notifySnackbar = true
      })
      .addCase(upsertSquads.rejected, (state, action) => {
        state.squadsStatus = "idle"
        state.squadsError = action.payload.error
        state.notifySnackbar = true
      })

      .addCase(addNewCompanyOffmap, (state) => {
        state.isChanged = true
      })
      .addCase(removeNewCompanyOffmap, (state) => {
        state.isChanged = true
      })
      .addCase(removeExistingCompanyOffmap, (state) => {
        state.isChanged = true
      })

      .addCase(addNewSquadUpgrade, (state, action) => {
        const { newSquadUpgrade } = action.payload
        const tab = newSquadUpgrade.tab,
          index = newSquadUpgrade.index,
          squadUuid = newSquadUpgrade.squadUuid
        const platoon = state[tab][index]

        let squad
        // Find the squad, either at top level or in transport
        if (Object.keys(platoon).includes(squadUuid)) {
          squad = platoon[squadUuid]
        } else {
          // Iterate through transportedSquads of top level squads
          const transport = Object.values(platoon).find(s => {
            if (s.transportedSquads) {
              return Object.keys(s.transportedSquads).includes(squadUuid)
            } else {
              return false
            }
          })
          if (transport) {
            squad = transport.transportedSquads[squadUuid]
          } else {
            return // Squad is not in the expected location
          }
        }

        // For Pop or modelcount we update the squad
        if (newSquadUpgrade.pop > 0 || newSquadUpgrade.addModelCount > 0) {
          let workingSquad
          let transportSquad
          if (squad.transportUuid) {
            transportSquad = state[tab][index][squad.transportUuid]
            workingSquad = transportSquad.transportedSquads[squadUuid]
          } else {
            workingSquad = state[tab][index][squadUuid]
          }
          workingSquad.pop += newSquadUpgrade.pop || 0
          workingSquad.popWithTransported += newSquadUpgrade.pop || 0
          workingSquad.totalModelCount += newSquadUpgrade.addModelCount || 0
          if (transportSquad) {
            transportSquad.popWithTransported += newSquadUpgrade.pop || 0
            transportSquad.usedModelSlots += newSquadUpgrade.addModelCount || 0
          }
        }
        state.isChanged = true
      })

      .addCase(removeSquadUpgrade, (state, action) => {
        const { squadUpgrade } = action.payload
        const tab = squadUpgrade.tab,
          index = squadUpgrade.index,
          squadUuid = squadUpgrade.squadUuid;

        const platoon = state[tab][index]
        let squad, transport
        // First look for top level squad
        if (Object.keys(platoon).includes(squadUuid)) {
          squad = platoon[squadUuid]
        } else {
          // Iterate through transportedSquads of top level squads
          transport = Object.values(platoon).find(s => {
            if (s.transportedSquads) {
              return Object.keys(s.transportedSquads).includes(squadUuid)
            } else {
              return false
            }
          })
          if (transport) {
            squad = transport.transportedSquads[squadUuid]
          } else {
            return // Squad is not in the expected location
          }
        }
        squad.pop -= squadUpgrade.pop || 0
        squad.popWithTransported -= squadUpgrade.pop || 0
        squad.totalModelCount -= squadUpgrade.addModelCount || 0
        if (transport) {
          transport.popWithTransported -= squadUpgrade.pop || 0
          transport.usedModelSlots -= squadUpgrade.addModelCount || 0
        }
      })
  }
})

export default squadsSlice.reducer

export const {
  addNonTransportedSquad,
  addTransportedSquad,
  removeSquad,
  removeTransportedSquad,
  moveSquad,
  copySquad,
  resetSquadState,
  clearNotifySnackbar,
  showSnackbar,
  setSelectedSquadAccess,
  clearSelectedSquad,
  setIsCompanyManagerCompact,
  setHighlightedUuid,
  clearHighlightedUuid
} = squadsSlice.actions

export const {
  selectAll: selectAllSquads,
  selectById: selectSquadById
} = squadsAdapter.getSelectors(state => state.squads)

export const selectCoreSquads = state => state.squads[CORE]
export const selectAssaultSquads = state => state.squads[ASSAULT]
export const selectInfantrySquads = state => state.squads[INFANTRY]
export const selectArmourSquads = state => state.squads[ARMOUR]
export const selectAntiArmourSquads = state => state.squads[ANTI_ARMOUR]
export const selectSupportSquads = state => state.squads[SUPPORT]
export const selectHoldingSquads = state => state.squads[HOLDING]

export const selectSquadsLoadingStatus = state => state.squads.squadsStatus
export const selectSquadsInTabIndex = (state, tab, index) => {
  return state.squads[tab][index]
}
export const selectSquadsInTab = (state, tab) => {
  const indices = Object.values(state.squads[tab])
  return indices.map(i => Object.values(i)).flat()
}

export const selectSquadInTabIndexUuid = (state, tab, index, uuid) => state.squads?.[tab]?.[index]?.[uuid]
export const selectSquadInTabIndexTransportUuid = (state, tab, index, transportUuid, uuid) => {
  const transport = state.squads[tab][index][transportUuid]
  return transport.transportedSquads[uuid]
}

export const selectCallinModifiers = state => state.squads.callinModifiers

export const selectSelectedSquad = state => {
  const tab = state.squads.selectedSquadTab,
    index = state.squads.selectedSquadIndex,
    uuid = state.squads.selectedSquadUuid,
    transportUuid = state.squads.selectedSquadTransportUuid;
  if (!_.isNil(tab) && !_.isNil(index) && !_.isNil(uuid)) {
    if (!_.isNil(transportUuid)) {
      const transport = state.squads[tab][index][transportUuid]
      if (!_.isNil(transport) && _.has(transport.transportedSquads, uuid)) {
        return state.squads[tab][index][transportUuid].transportedSquads[uuid]
      }
    } else {
      return state.squads[tab][index][uuid]
    }
  }
  return null
}

export const selectSelectedSquadUuid = state => state.squads.selectedSquadUuid
export const selectIsCompanyManagerCompact = state => state.squads.isCompact

export const selectHighlightedUuid = state => {
  const slice = state.squads.highlightedUuidChain.slice(-1)
  if (slice.length === 1) {
    return slice[0]
  } else {
    return null
  }
}
