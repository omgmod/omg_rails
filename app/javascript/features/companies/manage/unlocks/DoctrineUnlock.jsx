import React from 'react'
import { Box, Button, Paper, Typography } from "@mui/material";
import { makeStyles } from "@mui/styles";
import { unlockImageMapping } from "../../../../constants/unlocks/all_factions";
import { UnlockCard } from "./UnlockCard";
import { useDispatch, useSelector } from "react-redux";
import { purchaseUnlock, refundUnlock } from "./companyUnlocksSlice";

const useStyles = makeStyles(theme => ({
  unlockContainer: {
    display: 'flex',
    minHeight: '25rem',
    minWidth: '4rem',
    '&.owned': {
      borderColor: theme.palette.secondary.light,
      borderWidth: '2px',
      borderStyle: 'solid'
    }
  },
  unlockInnerContainer: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    flex: 1
  },
  unlockCardBox: {
    display: 'flex',
    justifyContent: 'center',
    marginBottom: '0.35em'
  },
  titleText: {
    minHeight: '4rem'
  },
  ownedText: {
    color: theme.palette.secondary.light
  },
  button: {
    margin: 'auto'
  }
}))

export const DoctrineUnlock = ({ doctrineUnlock, companyUnlock }) => {
  const classes = useStyles()
  const dispatch = useDispatch()
  const isSaving = useSelector(state => state.companyUnlocks.isSaving)

  const unlock = doctrineUnlock.unlock
  const isOwned = !_.isNil(companyUnlock)

  const purchase = () => {
    dispatch(purchaseUnlock({ doctrineUnlockId: doctrineUnlock.id }))
  }

  const refund = () => {
    dispatch(refundUnlock({ companyUnlockId: companyUnlock.id }))
  }

  let buttonContent
  if (isOwned) {
    buttonContent = (
      <Button variant="contained" color="error" size="small" onClick={refund} className={classes.button}
              disabled={isSaving}>
        <Typography variant="button" display="block">
          Refund {doctrineUnlock.vpCost} VP
        </Typography>
      </Button>
    )
  } else {
    buttonContent = (
      <Button variant="contained" color="secondary" size="small" onClick={purchase} className={classes.button}
              disabled={isSaving}>
        <Typography variant="button" display="block">
          {doctrineUnlock.vpCost} VP
        </Typography>
      </Button>
    )
  }

  let innerContent
  if (!doctrineUnlock.disabled) {
    innerContent = (
      <Box p={2} className={classes.unlockInnerContainer}>
        <Typography variant="h5" gutterBottom align="center"
                    className={`${classes.titleText} ${isOwned ? classes.ownedText : null}`}>
          {unlock.displayName}
        </Typography>
        <Box className={classes.unlockCardBox}>
          <UnlockCard image={unlockImageMapping[unlock.name]} label={unlock.name} />
        </Box>
        <Typography variant="body2" gutterBottom align="center" className={isOwned ? classes.ownedText : null}>
          {unlock.description}
        </Typography>
        <Box sx={{ marginTop: 'auto' }}>
          {buttonContent}
        </Box>
      </Box>
    )
  }

  return (
    <Paper key={`${doctrineUnlock.tree}-${doctrineUnlock.branch}-${doctrineUnlock.row}`}
           className={`${classes.unlockContainer} ${isOwned ? 'owned' : ''}`}>
      {innerContent}
    </Paper>
  )
}