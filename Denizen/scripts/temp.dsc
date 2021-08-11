test:
  type: world
  debug: false
  events:
    after player joins:
      - narrate '<proc[drustcraftp_msg_format].context[warning|Some features of Drustcraft are currently not available and are still being migrated by Game Masters]>'
      - narrate '<proc[drustcraftp_msg_format].context[warning|Thanks for your patience]>'
    # on player logs in priority:-1000:
      # - if <player.name> != nomadjimbob:
      #   - determine 'KICKED:<&e>Server is currently upgrading to 1.17.<&nl>We expect it to be completed on Thurs 5 Aug'

    # on player chats:
      # - determine FORMAT:test_format
      # - narrate '<proc[drustcraftp_msg_format].context[error|Chat is currently disabled while we upgrade the server]>'
      # - determine cancelled
