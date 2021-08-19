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

    on player closes inventory server_flagged:drustcraft.module.inventories:
      - if <context.inventory.note_name.starts_with[drustcraft_inventories_inspect_]||false>:
        - define target_uuid:<context.inventory.note_name.after[<player.uuid>_].before[_]>
        - define target_gamemode:<context.inventory.note_name.after_last[_]>
        - if <server.online_players.parse[uuid].contains[<[target_uuid]>]>:
          - flag <player[<[target_uuid]>]> drustcraft.inventories.<[target_gamemode]>:<context.inventory.map_slots>
          - inventory set d:<player[<[target_uuid]>]> o:<context.inventory.map_slots>
        - else:
          - ~run drustcraftt_setting_set def:drustcraft.inventories.<[target_uuid]>.<[target_gamemode]>|<context.inventory.map_slots>


drustcraftt_inventories_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - log ERROR 'Drustcraft Inventories: Drustcraft Setting is required to be installed'
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - log ERROR 'Drustcraft Inventories: Drustcraft Tab Complete is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.setting]>
    - waituntil <server.has_flag[drustcraft.module.tabcomplete]>

    - run drustcraftt_tabcomplete_completion def:invinspect|_*players|_*gamemodes

    - flag server drustcraft.module.inventories:<script[drustcraftw_inventories].data_key[version]>


drustcraftc_inventories_inspect:
  type: command
  debug: false
  name: invinspect
  description: Inspects a players inventory
  usage: /invinspect player gamemode
  permission: drustcraft.inventories.inspect
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:invinspect
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.inventories]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Inventory tools not loaded. Check console for errors]>'
      - stop

    - if !<context.server||false>:
      - define player_name:<context.args.get[1]||<empty>>
      - define gamemode:<context.args.get[2]||survival>
      - if <[player_name]> != <empty>:
        - define found_player:<server.match_offline_player[<[player_name]>]>
        - if <[found_player].exists> && <[found_player].name> == <[player_name]>:
          - if <proc[drustcraftp_tabcomplete_gamemodes].contains[<[gamemode]>]>:
            - note '<inventory[generic[size=54;title=<[found_player].name> <[gamemode].to_titlecase>]]>' as:drustcraft_inventories_inspect_<player.uuid>_<[found_player].uuid>_<[gamemode]>
            - define slot_map:<map[]>
            - if <server.online_players.contains[<[found_player]>]>:
              - if <player.has_flag[drustcraft.inventories.<[gamemode]>]>:
                - define slot_map:<player.flag[drustcraft.inventories.<[gamemode]>]>
            - else:
              - ~run drustcraftt_setting_get def:drustcraft.inventories.<[found_player].uuid>.<[gamemode]>|<map[]> save:result
              - define slot_map:<entry[result].created_queue.determination.get[1]>

            - inventory set d:<inventory[drustcraft_inventories_inspect_<player.uuid>_<[found_player].uuid>_<[gamemode]>]> o:<[slot_map]>
            - inventory open d:<inventory[drustcraft_inventories_inspect_<player.uuid>_<[found_player].uuid>_<[gamemode]>]>
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The gamemode $e<[gamemode]> $ris not valid]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[player_name]> $rwas not found on the server]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|No player name was entered]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|This command cannot be run from the console]>'
