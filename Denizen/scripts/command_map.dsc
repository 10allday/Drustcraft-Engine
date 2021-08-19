# Drustcraft - Map
# https://github.com/drustcraft/drustcraft

drustcraftc_map:
  type: command
  debug: false
  name: map
  description: Displays the map URL
  usage: /map
  script:
    - narrate '<proc[drustcraftp_msg_format].context[arrow|The live Drustcraft map can be viewed at $e<element[map.drustcraft.com.au].on_click[https://map.drustcraft.com.au/].type[OPEN_URL].on_hover[Opens URL in browser]>]>'