# Drustcraft - Railway
# https://github.com/drustcraft/drustcraft

drustcraftw_region_railway:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - ~run drustcraftt_region_railway_load

    on script reload:
      - ~run drustcraftt_region_railway_load


drustcraftt_region_railway_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_region]>:
      - log ERROR 'Drustcraft Railway: Drustcraft Region is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.region]>

    - run drustcraftt_region_type_register def:railway|drustcraftt_region_railway
    - flag server drustcraft.module.region_railway:<script[drustcraftw_region_railway].data_key[version]>


drustcraftt_region_railway:
  type: task
  debug: false
  definitions: command|world|region|type|title|data|target_player
  script:
    - choose <[command]>:
      - case enter:
        - if <proc[drustcraftp_region_location_type].context[<[data]>]> != railway && <[target_player].gamemode> != SURVIVAL:
          - narrate '<proc[drustcraftp_msg_format].context[arrow|You are entering a railway. You cannot build near the tracks. Watch for moving carts]>' targets:<[target_player]>

