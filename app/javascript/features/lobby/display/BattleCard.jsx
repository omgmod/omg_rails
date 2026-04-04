import React from 'react'
import { Alert, AlertTitle, Box, Card, Typography } from "@mui/material";
import { makeStyles } from "@mui/styles";
import { useSelector } from "react-redux";
import { selectBattleById } from "../lobbySlice";
import { selectPlayer } from "../../player/playerSlice";
import { BattleCardPlayer } from "./BattleCardPlayer";
import { nanoid } from "@reduxjs/toolkit";
import { ALLIED_SIDE, AXIS_SIDE } from "../../../constants/doctrines";
import { GENERATING, INGAME } from "../../../constants/battles/states";
import { Link } from "react-router-dom";
import { DateTime } from "luxon";
import { ChangeBattleSize } from "./ChangeBattleSize";
import { AdminActions } from "./AdminActions";

const useStyles = makeStyles(theme => ({
  textInput: {
    '& .MuiOutlinedInput-input': {
      padding: "10px 5px"
    }
  },
  wrapperRow: {
    display: 'flex'
  },
  column: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: "inherit",
    flex: 1
  },
  vcColumn: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    height: '100%'
  },
  row: {
    display: "flex",
    alignItems: "center",
  },
  battleId: {
    textAlign: "center",
    display: "flex"
  },
  headerLeft: {
    flex: 1,
    display: "flex",
    alignItems: "center",
    justifyContent: "flex-start"
  },
  headerRight: {
    flex: 1,
    display: "flex",
    alignItems: "center",
    justifyContent: "flex-end"
  },
  battleTimes: {
    display: "flex",
    flexDirection: "column",
    justifyContent: "flex-start"
  },
  time: {
    fontStyle: "italic"
  },
  balanceAlertWrapper: {
    flex: 1,
    display: "flex",
    alignItems: "center",
    justifyContent: "center"
  },
  balanceAlertContainer: {
    display: "flex",
    alignItems: "center",
    justifyContent: "center"
  },
  balanceAlert: {
    alignItems: "center",
    justifyContent: "center"
  },
  balanceAlertTitle: {
    margin: 0
  },
  border: {
    borderColor: theme.palette.secondary.dark,
    borderWidth: '4px',
    borderStyle: 'solid'
  },
  adminWrapper: {
    marginTop: "0.5rem",
    maxWidth: "20rem"
  }
}))

const addPlaceholders = (battlePlayers, size) => {
  const battlePlayersCopy = battlePlayers.slice()
  if (battlePlayersCopy.length < size) {
    const difference = size - battlePlayersCopy.length
    for (let i = 0; i < difference; i++) {
      battlePlayersCopy.push({
        playerId: null,
        playerName: null,
        companyFaction: null,
        playerElo: null
      })
    }
  }
  return battlePlayersCopy
}

export const BattleCard = ({ id }) => {
  const classes = useStyles()
  const player = useSelector(selectPlayer)
  const battle = useSelector(state => selectBattleById(state, id))
  const size = battle.size
  const alliedPlayers = addPlaceholders(battle.battlePlayers.filter(p => p.side === 'allied'), size)
  const axisPlayers = addPlaceholders(battle.battlePlayers.filter(p => p.side === 'axis'), size)
  const generatingContent = battle.state === GENERATING ? <Typography>Generating</Typography> : ""
  const ingameContent = battle.state === INGAME ?
    <Link to={`/api/battles/${id}/battlefiles/zip`} target="_blank" download>Download Battlefile</Link> : ""
  const isFull = battle.battlePlayers.length === size * 2

  const playerInThisBattle = player ? battle.battlePlayers.some(bp => bp.playerId === player?.id) : false

  const balanceColor = (balance) => {
    switch (balance) {
      case "Perfect":
        return "gold";
      case "Balanced":
        return "green";
      case "Allied Stomp":
        return "blue";
      case "Axis Stomp":
        return "red";
      case "Allied Favoured":
        return "teal";
      case "Axis Favoured":
        return "pink";
      default:
        return "white";
    }
  }

  const minDiff = (size) => {
    if (size === 4)
      return 50
    else
      return 35
  }

  const balanceState = (balance) => {
    const min = minDiff(battle.size)
    const val = Math.abs(balance)
    if (!balance)
      return "Pending"

    if (balance < (0 - 100))
      return "Allied Stomp"
    else if (balance > 100)
      return "Axis Stomp"
    else if (balance < (0 - min))
      return "Allied Favoured"
    else if (balance > min)
      return "Axis Favoured"
    else if (balance < 10)
      return "Perfect"

    else
      return "Balanced"
  };

  let optimumBalance = false;
  const k = axisPlayers.reduce((accumulator, currentValue) => accumulator + currentValue.teamBalance, 0)
  if (k === size || k === size * 2) {
    optimumBalance = true;
  }

  const calculatedBalanceState = balanceState(battle.eloDifference)

  let optimumBalanceContent
  let eloDiffContent
  if (!optimumBalance && Math.abs(battle.eloDifference) > 50 && isFull) {
    optimumBalanceContent = (
      <Box className={classes.balanceAlertContainer}>
        <Alert severity="warning" className={classes.balanceAlert}>
          <AlertTitle className={classes.balanceAlertTitle}>
            Warning: Balance not optimum, rearrange teams into matching colours for optimum balance
          </AlertTitle>
        </Alert>
      </Box>
    )
    eloDiffContent = <Typography variant="h6" pl="0.25rem" gutterBottom
                                 color={balanceColor(calculatedBalanceState)}>({battle.eloDifference})</Typography>
  }

  const updatedAtTime = DateTime.fromISO(battle.updatedAt)
  const createdAtTime = DateTime.fromISO(battle.createdAt)

  const showBorder = isFull && playerInThisBattle
  return (
    <Card elevation={3} sx={{ padding: '1rem' }} className={showBorder ? classes.border : null}>
      <Box className={classes.row}>
        <Box className={classes.headerLeft}>
          <Typography variant="h6" gutterBottom>{battle.name}</Typography>
        </Box>
        <Box className={classes.battleId}>
          <Typography variant="h5" pl="0.5rem" gutterBottom>Battle ID: </Typography>
          <Typography variant="h5" pl="0.5rem" gutterBottom color="secondary">{battle.id}</Typography>
        </Box>
        <Box className={classes.headerRight}>
          <Typography variant="h6" pl="0.5rem" gutterBottom>Balance: </Typography>
          <Typography variant="h6" pl="0.5rem" gutterBottom
                      color={balanceColor(calculatedBalanceState)}>{calculatedBalanceState}</Typography>
          {eloDiffContent}
        </Box>
      </Box>
      <Box className={classes.row} sx={{ paddingBottom: "1rem" }}>
        <Box className={classes.battleTimes}>
          <Box>
            <Typography variant="caption" color="text.secondary">Created: </Typography>
            <Typography variant="caption" className={classes.time}
                        color="text.secondary">{createdAtTime.toLocaleString(DateTime.DATETIME_MED)}</Typography>
          </Box>
          <Box>
            <Typography variant="caption" color="text.secondary">Last Update: </Typography>
            <Typography variant="caption" className={classes.time}
                        color="text.secondary">{updatedAtTime.toLocaleString(DateTime.DATETIME_MED)}</Typography>
          </Box>
        </Box>
        <Box className={classes.balanceAlertWrapper}>
          {optimumBalanceContent}
        </Box>
      </Box>
      {/*{fullBanner}*/}
      {battle.map && (
        <Box sx={{ display: "flex", alignItems: "center", pb: 1 }}>
          <Typography variant="body1" color="text.secondary" sx={{ mr: 0.5 }}>Map:</Typography>
          <Typography variant="body1" fontWeight="bold">{battle.map}</Typography>
        </Box>
      )}
      {generatingContent}
      {ingameContent}
      <Box className={classes.row}>
        <Box className={classes.column}>
          {alliedPlayers.map(p => <BattleCardPlayer key={p.playerId || nanoid()}
                                                    battleId={id}
                                                    playerId={p.playerId}
                                                    playerName={p.playerName}
                                                    teamBalance={p.teamBalance}
                                                    playerElo={p.playerElo}
                                                    companyFaction={p.companyFaction}
                                                    side={ALLIED_SIDE}
                                                    battleState={battle.state}
                                                    ready={p.ready}
                                                    abandoned={p.abandoned}
                                                    isFull={isFull}
          />)}
        </Box>
        <Box pt={2} pb={2} className={classes.vsColumn}>
          vs
        </Box>
        <Box className={classes.column}>
          {axisPlayers.map(p => <BattleCardPlayer key={p.playerId || nanoid()}
                                                  battleId={id}
                                                  playerId={p.playerId}
                                                  playerName={p.playerName}
                                                  teamBalance={p.teamBalance}
                                                  playerElo={p.playerElo}
                                                  companyFaction={p.companyFaction}
                                                  side={AXIS_SIDE}
                                                  battleState={battle.state}
                                                  ready={p.ready}
                                                  abandoned={p.abandoned}
                                                  isFull={isFull}
          />)}
        </Box>
      </Box>
      <Box className={classes.adminWrapper}>
        <AdminActions battleId={id} />
      </Box>
    </Card>
  )
}
