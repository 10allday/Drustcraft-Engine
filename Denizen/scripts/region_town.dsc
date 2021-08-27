# Drustcraft - Town
# https://github.com/drustcraft/drustcraft

drustcraftw_region_town:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - ~run drustcraftt_region_town_load

    on script reload:
      - ~run drustcraftt_region_town_load


drustcraftt_region_town_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_region]>:
      - log ERROR 'Drustcraft Town: Drustcraft Region is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.region]>

    - run drustcraftt_region_type_register def:town|drustcraftt_region_town
    - flag server drustcraft.module.region_town:<script[drustcraftw_region_town].data_key[version]>


drustcraftt_region_town:
  type: task
  debug: false
  definitions: command|world|region|type|title|target_player
  script:
    - if <[target_player].gamemode> == SURVIVAL:
      - choose <[command]>:
        - case enter:
          - narrate '<proc[drustcraftp_msg_format].context[arrow|You are entering a town. You cannot build in this area]>'
          - title title:<&e><[title]> subtitle:<&e>Town
        - case exit:
          - narrate '<proc[drustcraftp_msg_format].context[arrow|You have left the town of <[title]>]>'
