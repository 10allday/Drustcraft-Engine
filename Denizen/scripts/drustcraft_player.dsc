# Drustcraft - Player
# https://github.com/drustcraft/drustcraft

drustcraftw_player:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_player_load

    on script reload:
      - run drustcraftt_player_load

    on player joins:
      - playsound <server.online_players> sound:ENTITY_FIREWORK_ROCKET_LAUNCH sound_category:AMBIENT
      - determine '<proc[drustcraftp_msg_format].context[success|$e<player.name> $rjoined Drustcraft]>'

    on player death:
      - determine passively KEEP_INV
      - determine passively NO_DROPS

      - if <player.has_flag[drustcraft.player.death_message]>:
        - determine passively <player.flag[drustcraft.player.death_message]>
        - flag player drustcraft.player.death_message:!

      - foreach <player.inventory.map_slots> as:item:
        - define skip:false
        - foreach <yaml[drustcraft_player].read[death_drop_confirm]||<list[]>> as:confirm_proc:
          - if <proc[<[confirm_proc]>].context[<[item]>]>:
            - define skip:true
            - foreach stop

        - if !<[skip]>:
          - take slot:<[key]> quantity:<[item].quantity>
          - drop <[item]> <player.location.add[-2,-2,-2].to_cuboid[<player.location.add[2,2,2]>].spawnable_blocks.random||<player.location>>

    on luckperms|lp command:
      - run drustcraftt_util_run_once_later def:drustcraftt_player_update_groups|5


drustcraftt_player_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR 'Drustcraft player requires Drustcraft Database installed'
      - stop
    - if !<server.plugins.parse[name].contains[LuckPerms]>:
      - debug ERROR 'Drustcraft player requires LuckPerms installed'
      - stop

    - ~yaml id:luckperms_config load:../LuckPerms/config.yml
    - if <yaml[luckperms_config].read[storage-method]||null> != MySQL:
      - debug ERROR 'Drustcraft player requires LuckPerms storage method set to MySQL'
      - yaml id:luckperms_config unload
      - stop

    - flag server drustcraft.player.luckperms_prefix:<yaml[luckperms_config].read[data.table-prefix]||<empty>>
    - yaml id:luckperms_config unload

    - if <yaml.list.contains[drustcraft_player]>:
      - ~yaml unload id:drustcraft_player
    - yaml create id:drustcraft_player

    - run drustcraftt_player_update_groups

    - flag server drustcraft.module.player:<script[drustcraftw_player].data_key[version]>
    - debug log 'Drustcraft player loaded'


drustcraftt_player_update_groups:
  type: task
  debug: false
  script:
    - flag server drustcraft.player.group_inheritence:!
    - flag server drustcraft.player.players:!

    - waituntil <server.sql_connections.contains[drustcraft]>
    # load group inheritence
    - ~sql id:drustcraft 'query:SELECT `name`, REPLACE(`permission`, "group.", "") FROM `<server.flag[drustcraft.player.luckperms_prefix]>group_permissions` WHERE `permission` LIKE "group.<&pc>"' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define group_name:<[row].get[1]||<empty>>
      - define inherited_group_name:<[row].get[2]||<empty>>
      - flag server drustcraft.player.group_inheritence.<[group_name]>:->:<[inherited_group_name]>

    # load all players default group
    - ~sql id:drustcraft 'query:SELECT `uuid`, `primary_group` FROM `<server.flag[drustcraft.player.luckperms_prefix]>players`' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define uuid:<[row].get[1]||<empty>>
      - define group_name:<[row].get[2]||<empty>>
      - flag server drustcraft.player.players.<[uuid]>.groups:->:<[group_name]>
      - if <server.has_flag[drustcraft.player.group_inheritence.<[group_name]>]>:
        - flag server drustcraft.player.players.<[uuid]>.groups:<server.flag[drustcraft.player.players.<[uuid]>.groups].include[<server.flag[drustcraft.player.group_inheritence.<[group_name]>]>].deduplicate>

    # load all players groups from user permissions
    - ~sql id:drustcraft 'query:SELECT `uuid`, REPLACE(`permission`, "group.", "") FROM `<server.flag[drustcraft.player.luckperms_prefix]>user_permissions` WHERE `permission` LIKE "group.<&pc>"' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define uuid:<[row].get[1]||<empty>>
      - define group_name:<[row].get[2]||<empty>>
      - flag server drustcraft.player.players.<[uuid]>.groups:->:<[group_name]>
      - if <server.has_flag[drustcraft.player.group_inheritence.<[group_name]>]>:
        - flag server drustcraft.player.players.<[uuid]>.groups:<server.flag[drustcraft.player.players.<[uuid]>.groups].include[<server.flag[drustcraft.player.group_inheritence.<[group_name]>]>].deduplicate>


drustcraftt_player_death_drop_confirm:
  type: task
  debug: false
  definitions: proc_name
  script:
    - if !<yaml[drustcraft_player].read[death_drop_confirm].contains[<[proc_name]>]>:
      - yaml id:drustcraft_player set death_drop_confirm:|:<[proc_name]>


drustcraftp_player_groups:
  type: procedure
  debug: false
  definitions: player
  script:
    - if <[player].is_online>:
      - determine <[player].groups>
    - else:
      - determine <server.flag[drustcraft.player.players.<[player].uuid>.groups].unescaped||<list[]>>


drustcraftp_player_in_group:
  type: procedure
  debug: false
  definitions: player|group
  script:
    - if <[player].is_online>:
      - determine <[player].in_group[<[group]>]>
    - else:
      - determine <proc[drustcraftp_player_groups].context[<[player]>].contains[<[group]>]>
