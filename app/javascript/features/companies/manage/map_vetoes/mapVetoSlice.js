import { createAsyncThunk, createSlice } from "@reduxjs/toolkit"
import axios from "axios"

const initialState = {
  maps: [],
  companyVetoes: [],
  loadingMaps: false,
  loadingVetoes: false,
  error: null
}

export const fetchMaps = createAsyncThunk(
  "mapVetoes/fetchMaps",
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.get("/maps")
      return response.data
    } catch (err) {
      return rejectWithValue(err.response.data)
    }
  }
)

export const fetchCompanyVetoes = createAsyncThunk(
  "mapVetoes/fetchCompanyVetoes",
  async ({ companyId }, { rejectWithValue }) => {
    try {
      const response = await axios.get("/map_vetoes", { params: { companyId } })
      return response.data
    } catch (err) {
      return rejectWithValue(err.response.data)
    }
  }
)

export const addVeto = createAsyncThunk(
  "mapVetoes/addVeto",
  async ({ companyId, mapId }, { rejectWithValue }) => {
    try {
      const response = await axios.post("/map_vetoes", { companyId, mapId })
      return response.data
    } catch (err) {
      return rejectWithValue(err.response.data)
    }
  }
)

export const removeVeto = createAsyncThunk(
  "mapVetoes/removeVeto",
  async ({ companyId, mapId }, { rejectWithValue }) => {
    try {
      const response = await axios.delete("/map_vetoes", { data: { companyId, mapId } })
      return response.data
    } catch (err) {
      return rejectWithValue(err.response.data)
    }
  }
)

const mapVetoSlice = createSlice({
  name: "mapVetoes",
  initialState,
  reducers: {},
  extraReducers(builder) {
    builder
      .addCase(fetchMaps.pending, (state) => {
        state.loadingMaps = true
        state.error = null
      })
      .addCase(fetchMaps.fulfilled, (state, action) => {
        state.loadingMaps = false
        state.maps = action.payload
      })
      .addCase(fetchMaps.rejected, (state, action) => {
        state.loadingMaps = false
        state.error = action.payload
      })
      .addCase(fetchCompanyVetoes.pending, (state) => {
        state.loadingVetoes = true
        state.error = null
      })
      .addCase(fetchCompanyVetoes.fulfilled, (state, action) => {
        state.loadingVetoes = false
        state.companyVetoes = action.payload || []
      })
      .addCase(fetchCompanyVetoes.rejected, (state, action) => {
        state.loadingVetoes = false
        state.error = action.payload
      })
      .addCase(addVeto.fulfilled, (state, action) => {
        state.companyVetoes = action.payload || []
      })
      .addCase(addVeto.rejected, (state, action) => {
        state.error = action.payload
      })
      .addCase(removeVeto.fulfilled, (state, action) => {
        state.companyVetoes = action.payload || []
      })
      .addCase(removeVeto.rejected, (state, action) => {
        state.error = action.payload
      })
  }
})

export const selectMaps = (state) => state.mapVetoes.maps
export const selectCompanyVetoes = (state) => state.mapVetoes.companyVetoes
export const selectLoadingMaps = (state) => state.mapVetoes.loadingMaps
export const selectLoadingVetoes = (state) => state.mapVetoes.loadingVetoes
export const selectMapVetoError = (state) => state.mapVetoes.error

export default mapVetoSlice.reducer
