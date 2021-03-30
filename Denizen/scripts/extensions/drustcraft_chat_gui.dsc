# Drustcraft - Chat GUI
# Provides a Chat GUI
# https://github.com/drustcraft/drustcraft

drustcraftw_chat_gui:
  type: world
  debug: false
  events:
    on server start:
      - wait 2t

drustcraftt_chat_gui:
  type: task
  debug: false
  script:
    - determine <empty>
  
  title:
    - define title:<[1]||<empty>>
    - define horz_line:-------------------------
    
    - define 'line: <[title]> '
    - define line_length:<[line].text_width>
    - define horz_size:<[horz_line].text_width.sub[<[line].text_width.div[2].round_up>].div[6].round_down>
    - define line:<&e><[horz_line].substring[0,<[horz_size]>]><&f><[line]><&e><[horz_line].substring[0,<[horz_size]>]>
    - narrate <[line]>
