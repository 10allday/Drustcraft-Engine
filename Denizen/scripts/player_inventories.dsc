# Drustcraft - Player Inventories
# https://github.com/drustcraft/drustcraft

drustcraftw_inventories:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_inventories_load

    on script reload:
      - run drustcraftt_inventories_load

    after player joins server_flagged:drustcraft.module.inventories:
      - wait 20t
      - ~run drustcraftt_setting_get def:drustcraft.inventories.<player.uuid>.adventure|<map[]> save:result
      - flag <player> drustcraft.inventories.adventure:<entry[result].created_queue.determination.get[1]>
      - ~run drustcraftt_setting_get def:drustcraft.inventories.<player.uuid>.creative|<map[]> save:result
      - flag <player> drustcraft.inventories.creative:<entry[result].created_queue.determination.get[1]>
      - ~run drustcraftt_setting_get def:drustcraft.inventories.<player.uuid>.survival|<map[]> save:result
      - flag <player> drustcraft.inventories.survival:<entry[result].created_queue.determination.get[1]>

      - inventory clear
      - inventory set d:<player.inventory> o:<player.flag[drustcraft.inventories.<player.gamemode>]||<map[]>>

    on player quits:
      - flag player drustcraft.inventories.<player.gamemode>:<player.inventory.map_slots>
      - ~run drustcraftt_setting_set def:drustcraft.inventories.<player.uuid>.adventure|<player.flag[drustcraft.inventories.adventure]> save:result
      - ~run drustcraftt_setting_set def:drustcraft.inventories.<player.uuid>.creative|<player.flag[drustcraft.inventories.creative]> save:result
      - ~run drustcraftt_setting_set def:drustcraft.inventories.<player.uuid>.survival|<player.flag[drustcraft.inventories.survival]> save:result

    on player changes gamemode server_flagged:drustcraft.module.inventories:
      - flag player drustcraft.inventories.<player.gamemode>:<player.inventory.map_slots>
      - inventory clear
      - inventory set d:<player.inventory> o:<player.flag[drustcraft.inventories.<context.gamemode>]||<map[]>>

    on player opens inventory server_flagged:drustcraft.module.inventories:
      - if <player.gamemode> != SURVIVAL && !<player.has_permission[drustcraft.inventories.open]>:
        - narrate '<proc[drustcraftp_msg_format].context[error|You cannot open chests or inventories while not in Surival mode]>'
        - determine CANCELLED

    on player drops item server_flagged:drustcraft.module.inventories:
      - if <player.gamemode> != SURVIVAL && !<player.has_permission[drustcraft.inventories.drop]>:
        - narrate '<proc[drustcraftp_msg_format].context[error|You cannot drop items while not in Surival mode]>'
        - determine CANCELLED


drustcraftt_inventories_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - log ERROR 'Drustcraft NPC: Drustcraft Setting is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.setting]>
    - flag server drustcraft.module.inventories:<script[drustcraftw_inventories].data_key[version]>