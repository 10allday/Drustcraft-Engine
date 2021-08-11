# Drustcraft - Creative
# https://github.com/drustcraft/drustcraft

drustcraftw_region_creative:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - ~run drustcraftt_region_creative_load

    on script reload:
      - ~run drustcraftt_region_creative_load


drustcraftt_region_creative_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_region]>:
      - log ERROR 'Drustcraft Creative: Drustcraft Region is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.region]>

    - run drustcraftt_region_type_register def:creative|drustcraftt_region_creative
    - flag server drustcraft.module.region_creative:<script[drustcraftw_region_creative].data_key[version]>


drustcraftt_region_creative:
  type: task
  debug: false
  definitions: command|world|region|type|title
  script:
    - choose <[command]>:
      - case enter:
        - narrate '<proc[drustcraftp_msg_format].context[arrow|You are entering a creative area. Griefing other players creations is not allowed]>'
        - title title:<&2><[title]> 'subtitle:<&2>Creative Area'
      - case exit:
        - narrate '<proc[drustcraftp_msg_format].context[arrow|You have left the creative area of <[title]>]>'

