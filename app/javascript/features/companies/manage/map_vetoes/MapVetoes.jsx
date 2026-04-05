import React, { useEffect } from "react"
import { useDispatch, useSelector } from "react-redux"
import { useParams } from "react-router-dom"
import { Box, Chip, CircularProgress, Typography } from "@mui/material"
import BlockIcon from "@mui/icons-material/Block"

import {
  fetchMaps,
  fetchCompanyVetoes,
  addVeto,
  removeVeto,
  selectMaps,
  selectCompanyVetoes,
  selectLoadingMaps,
  selectLoadingVetoes,
} from "./mapVetoSlice"

const MapCard = ({ map, isVetoed, onToggle, disabled }) => {
  return (
    <Chip
      icon={isVetoed ? <BlockIcon /> : null}
      label={map.name}
      onClick={onToggle}
      color={isVetoed ? "error" : "default"}
      variant={isVetoed ? "filled" : "outlined"}
      disabled={disabled}
      sx={{ m: 0.5, fontSize: "0.85rem" }}
    />
  )
}

export const MapVetoes = () => {
  const dispatch = useDispatch()
  const { companyId } = useParams()

  const maps = useSelector(selectMaps)
  const companyVetoes = useSelector(selectCompanyVetoes)
  const loadingMaps = useSelector(selectLoadingMaps)
  const loadingVetoes = useSelector(selectLoadingVetoes)

  useEffect(() => {
    dispatch(fetchMaps())
    dispatch(fetchCompanyVetoes({ companyId }))
  }, [companyId])

  const vetoedMapIds = companyVetoes.map((m) => m.id)
  const competitiveMaps = maps.filter((m) => m.category === "competitive")
  const memeMaps = maps.filter((m) => m.category === "meme")

  const getSizePrefix = (name) => name.match(/^\d+p/)?.[0]

  const handleToggle = (map) => {
    const isVetoed = vetoedMapIds.includes(map.id)

    if (isVetoed) {
      dispatch(removeVeto({ companyId, mapId: map.id }))
    } else {
      if (map.category === "competitive") {
        const sizePrefix = getSizePrefix(map.name)
        const existingVeto = sizePrefix && companyVetoes.find(
          (m) => m.category === "competitive" && getSizePrefix(m.name) === sizePrefix
        )
        if (existingVeto) {
          // Remove existing competitive veto for this size first, then add new one
          dispatch(removeVeto({ companyId, mapId: existingVeto.id })).then(
            () => {
              dispatch(addVeto({ companyId, mapId: map.id }))
            }
          )
        } else {
          dispatch(addVeto({ companyId, mapId: map.id }))
        }
      } else {
        dispatch(addVeto({ companyId, mapId: map.id }))
      }
    }
  }

  if (loadingMaps || loadingVetoes) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
        <CircularProgress />
      </Box>
    )
  }

  if (maps.length === 0) {
    return (
      <Box sx={{ p: 2 }}>
        <Typography color="text.secondary">
          No maps available. An admin needs to sync maps from the CDN.
        </Typography>
      </Box>
    )
  }

  return (
    <Box sx={{ p: 2, width: "100%" }}>
      <Typography variant="h6" gutterBottom>
        Map Vetoes
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        Veto maps you don't want to play. You can veto one competitive map per
        size and any number of meme maps.
      </Typography>

      <Typography variant="subtitle1" sx={{ mt: 2, mb: 1, fontWeight: "bold" }}>
        Competitive Maps
        <Typography component="span" variant="body2" color="text.secondary" sx={{ ml: 1 }}>
          (1 veto per size)
        </Typography>
      </Typography>
      <Box sx={{ display: "flex", flexWrap: "wrap" }}>
        {competitiveMaps.map((map) => (
          <MapCard
            key={map.id}
            map={map}
            isVetoed={vetoedMapIds.includes(map.id)}
            onToggle={() => handleToggle(map)}
            disabled={false}
          />
        ))}
        {competitiveMaps.length === 0 && (
          <Typography color="text.secondary" variant="body2">No competitive maps configured.</Typography>
        )}
      </Box>

      <Typography variant="subtitle1" sx={{ mt: 3, mb: 1, fontWeight: "bold" }}>
        Meme Maps
        <Typography component="span" variant="body2" color="text.secondary" sx={{ ml: 1 }}>
          (unlimited vetoes)
        </Typography>
      </Typography>
      <Box sx={{ display: "flex", flexWrap: "wrap" }}>
        {memeMaps.map((map) => (
          <MapCard
            key={map.id}
            map={map}
            isVetoed={vetoedMapIds.includes(map.id)}
            onToggle={() => handleToggle(map)}
            disabled={false}
          />
        ))}
        {memeMaps.length === 0 && (
          <Typography color="text.secondary" variant="body2">No meme maps configured.</Typography>
        )}
      </Box>
    </Box>
  )
}
