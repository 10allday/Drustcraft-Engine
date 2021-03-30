# Drustcraft Fix - Message Buffer Overflow
# Limits message size to 4092 characters
# https://github.com/drustcraft/drustcraft

drustcraftw_msg_overflow:
  type: world
  debug: false
  events:
    on player receives message priority:-100:
      # In some cases, when enough huge messages are sent through to a player close together
      # they end up in the same packet and case a BufferOverflow in PaperMC (exceeding 32767 bytes)
      
      - if <context.message.length> > 4096:
        - determine MESSAGE:<context.message.substring[0,4080]><element[<&sp>*<&sp>SNIP<&sp>*]>
