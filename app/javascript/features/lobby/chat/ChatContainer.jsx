import React from 'react'
import { Box, Button, Paper, TextField, Typography } from "@mui/material";
import { useDispatch, useSelector } from "react-redux";
import { lobbyChatMessages, sendChatMessage } from "../lobbySlice";
import { makeStyles } from "@mui/styles";
import { selectPlayer } from "../../player/playerSlice";
import { LOBBY_CHAT } from "../../../constants/chat";
import { Controller, useForm } from "react-hook-form";
import { format, isSameDay } from "date-fns";

const useStyles = makeStyles(theme => ({
  chatPaper: {
    paddingTop: "0.5rem",
    paddingBottom: "0.5rem"
  },
  messagesGrid: {
    height: "220px",
    maxHeight: "100%",
    overflowY: "auto",
    display: "flex",
    flexDirection: "column-reverse",
    marginBottom: "0.5rem"
  },
  chatMessageContainer: {
    display: "flex",
    flexDirection: "row"
  },
  nameItem: {
    display: "flex",
    justifyContent: "flex-end",
    fontWeight: "bold",
    width: "150px",
    minWidth: "150px",
    textOverflow: "ellipsis",
    paddingRight: "0.5rem"
  },
  messageItem: {
    maxWidth: "900px",
    overflowWrap: "break-word"
  },
  timeItem: {
    paddingLeft: "0.5rem",
    paddingRight: "0.5rem",
    marginLeft: "auto",
    whiteSpace: "nowrap"
  },
  chatActions: {
    display: "flex",
    alignItems: "center"
  },
  chatInput: {
    flexGrow: 1
  },
  chatSend: {
    marginRight: "0.5rem"
  }
}))

const ChatMessage = ({ message }) => {
  const classes = useStyles()

  const date = new Date(message.createdAt)
  const now = new Date()
  let dateString
  if (isSameDay(now, date)) {
    dateString = format(date, "h:mm a")
  } else {
    dateString = format(date, "d/M/yy h:mm a")
  }

  return (
    <Box className={classes.chatMessageContainer}>
      <Box className={classes.nameItem}>
        <Typography sx={{ fontWeight: "bold" }} color="text.secondary">{message.senderName}</Typography>
      </Box>
      <Box className={classes.messageItem}>
        <Typography color="text.secondary">{message.content}</Typography>
      </Box>
      <Box className={classes.timeItem}>
        <Typography variant="caption" color="text.secondary">{dateString}</Typography>
      </Box>
    </Box>
  )
}

export const ChatContainer = ({}) => {
  const classes = useStyles()
  const dispatch = useDispatch()

  const player = useSelector(selectPlayer)
  const chatMessages = useSelector(lobbyChatMessages)

  const { reset, handleSubmit, control, formState: { errors, isSubmitting } } = useForm();

  const sendMessage = (data) => {
    if (data.message) {
      dispatch(sendChatMessage({ chatName: LOBBY_CHAT, senderId: player.id, content: data.message }))
      reset({ message: "" })
    }
  }

  return (
    <Paper className={classes.chatPaper}>
      <Box className={classes.messagesGrid}>
        <Box>
          {/*Need this inner box for flex-direction: column-reverse to work */}
          {chatMessages.map(message => <ChatMessage key={message.id} message={message}/>)}
        </Box>
      </Box>
      <form onSubmit={handleSubmit(sendMessage)}>
        <Box className={classes.chatActions}>
          <Box pl={1} pr={1} className={classes.chatInput}>
            <Controller
              name="message" control={control}
              defaultValue=""
              render={({ field }) => (
                <TextField
                  variant="outlined"
                  size="small"
                  color="secondary"
                  fullWidth
                  className={classes.textInput} {...field}
                />)}
            />
          </Box>
          <Button variant="contained" type="submit" color="secondary" size="small"
                  className={classes.chatSend}>Send</Button>
        </Box>
      </form>
    </Paper>
  )
}
