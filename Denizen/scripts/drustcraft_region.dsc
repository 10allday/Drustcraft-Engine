# Drustcraft - Regions
# https://github.com/drustcraft/drustcraft

drustcraftw_region:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_region_load

    on script reload:
      - run drustcraftt_region_load

    after player joins:
      - wait 40t
      - if <server.online_players.contains[<player>]>:
        - adjust <player> gamemode:<proc[drustcraftp_region_location_gamemode].context[<player.location>]>

    on player enters polygon:
      - run drustcraftt_region_enter def:<context.area.note_name>|<context.from||<empty>>

    on player enters cuboid:
      - run drustcraftt_region_enter def:<context.area.note_name>|<context.from||<empty>>

    on player exits polygon:
      - run drustcraftt_region_exit def:<context.area.note_name>|<context.from||<empty>>

    on player exits cuboid:
      - run drustcraftt_region_exit def:<context.area.note_name>|<context.from||<empty>>

    on rg|region command:
      - define args:<context.args>
      - define region:<context.args.get[2]||<empty>>
      - define world:<player.location.world.name||<empty>>

      # update world name if flag present
      - foreach <[args]>:
        - if <[value]> == -w:
          - define args:<[args].remove[<[loop_index]>]>
          - if <[args].size> >= <[loop_index]>:
            - define world:<[args].get[<[loop_index]>]>
            - define args:<[args].remove[<[loop_index]>]>
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|World flag used, but no world name was entered]>'
            - determine fulfilled
          - foreach stop

      - if <[world]> != <empty>:
        - choose <context.args.get[1]||<empty>>:
          # title
          - case title:
            - determine passively fulfilled
            - if <[args].size> >= 2:
              - define title:<[args].remove[1|2].space_separated||<empty>>
              - if <world[<[world]>].list_regions.parse[id].contains[<[region]>]>:
                - if <[title]> != <empty>:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.title:<[title]>
                  - waituntil <server.sql_connections.contains[drustcraft]>
                  - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>region_title`(`region_id`,`world_id`,`title`) VALUES("<[region]>", <server.flag[drustcraft.region.world.<[world]>]>, "<[title]>") ON DUPLICATE KEY UPDATE `title` = "<[title]>";'
                  - narrate '<proc[drustcraftp_msg_format].context[success|The title for region $e<[region]> $rhas been updated]>'
                - else:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.title:!
                  - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>region_title` WHERE `region_id` = "<[region]>" AND `world_id` = <server.flag[drustcraft.region.world.<[world]>]>;'
                  - narrate '<proc[drustcraftp_msg_format].context[success|The title for region $e<[region]> $rhas been cleared]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The region $e<[region]> $rwas not found in world $e<[world]>]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|Too few argument]>'

          # type
          - case type:
            - determine passively fulfilled
            - if <[args].size> >= 2:
              - define type:<[args].get[3]||<empty>>
              - if <world[<[world]>].list_regions.parse[id].contains[<[region]>]>:
                - if <[type]> != <empty>:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.type:<[type]>
                  - waituntil <server.sql_connections.contains[drustcraft]>
                  - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>region_type`(`region_id`,`world_id`,`type`) VALUES("<[region]>", <server.flag[drustcraft.region.world.<[world]>]>, "<[type]>") ON DUPLICATE KEY UPDATE `type` = "<[type]>";'
                  - narrate '<proc[drustcraftp_msg_format].context[success|The type for region $e<[region]> $rhas been updated]>'
                - else:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.type:!
                  - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>region_type` WHERE `region_id` = "<[region]>" AND `world_id` = <server.flag[drustcraft.region.world.<[world]>]>;'
                  - narrate '<proc[drustcraftp_msg_format].context[success|The type for region $e<[region]> $rhas been cleared]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The region $e<[region]> $rwas not found in world $e<[world]>]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|Too few argument]>'

          # define redefine reload
          - case define create d remove rem delete del redefine update move load reload:
            - wait 1t
            - execute as_server 'rg save'
            - wait 100t
            - run drustcraftt_region_reload

          # addmember
          - case addmember addmem am:
            - wait 1t
            - define members:<[args].remove[1|2]||<list[]>>
            - if <world[<[world]>].has_region[<[region]>]||false>:
              - foreach <[members]> as:member:
                - if <[member].starts_with[g:]>:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.members.groups:->:<[member]>
                - else if <server.players.parse[name].contains[<[member]>]>:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.members.players:->:<player[<[member]>].uuid>

          # remmember
          - case remmember remmem rm:
            - wait 1t
            - define members:<[args].remove[1|2]||<list[]>>
            - if <world[<[world]>].has_region[<[region]>]||false>:
              - foreach <[members]> as:member:
                - if <[member].starts_with[g:]>:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.members.groups:<-:<[member]>
                - else if <server.players.parse[name].contains[<[member]>]>:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.members.players:<-:<player[<[member]>].uuid>

          # addowner
          - case addowner ao:
            - wait 1t
            - define owners:<[args].remove[1|2]||<list[]>>
            - if <world[<[world]>].has_region[<[region]>]||false>:
              - foreach <[owners]> as:owner:
                - if <[owner].starts_with[g:]>:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.owners.groups:->:<[owner]>
                - else if <server.players.parse[name].contains[<[owner]>]>:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.owners.players:->:<player[<[owner]>].uuid>

          # remowner
          - case remowner ro:
            - wait 1t
            - define owners:<[args].remove[1|2]||<list[]>>
            - if <world[<[world]>].has_region[<[region]>]||false>:
              - foreach <[owners]> as:owner:
                - if <[owner].starts_with[g:]>:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.owners.groups:<-:<[owner]>
                - else if <server.players.parse[name].contains[<[owner]>]>:
                  - flag server drustcraft.region.list.<[world]>.<[region]>.owners.players:<-:<player[<[owner]>].uuid>

          # info
          - case info:
            - if <player.has_permission[worldguard.region.info.*]||<context.server>>:
              - wait 5t
              - if <world[<[world]>].list_regions.parse[id].contains[<[region]>]>:
                - if !<server.has_flag[drustcraft.region.list.<[world]>.<[region]>.title]>:
                  - narrate '<&9>Title: <&c>(none)'
                - else:
                  - narrate '<&9>Title: <&7><server.flag[drustcraft.region.list.<[world]>.<[region]>.title]>'

                - if !<server.has_flag[drustcraft.region.list.<[world]>.<[region]>.type]>:
                  - narrate '<&9>Type: <&c>(none)'
                - else:
                  - narrate '<&9>Type: <&7><server.flag[drustcraft.region.list.<[world]>.<[region]>.type]>'


drustcraftt_region_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR 'Drustcraft Region: Drustcraft DB is required to be installed'
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_group]>:
      - debug ERROR 'Drustcraft Region: Drustcraft Group is required'
      - stop

    - if !<server.plugins.parse[name].contains[WorldGuard]>:
      - debug ERROR 'Drustcraft Region: WorldGuard is required to be installed'
      - stop

    # - if <server.plugins.parse[name].contains[dynmap]>:
    #   - debug ERROR 'Drustcraft Region: WorldGuard is required to be installed'
    #   - stop

    - waituntil <server.has_flag[drustcraft.module.db]>

    - ~yaml id:worldguard_config load:../WorldGuard/config.yml
    - if !<yaml[worldguard_config].read[regions.sql.use]||false>:
      - debug ERROR 'Drustcraft region requires WorldGuard storage method set to MySQL'
      - yaml id:worldguard_config unload
      - stop

    - flag server drustcraft.region.worldguard_prefix:<yaml[worldguard_config].read[regions.sql.table-prefix]||<empty>>
    - yaml id:worldguard_config unload

    - define create_tables:true
    - ~run drustcraftt_db_get_version def:drustcraft.region save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> != 1:
      - if <[version]> != null:
        - debug ERROR "Drustcraft Region: Unexpected database version. Ignoring DB storage"
      - else:
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>region_title` (`region_id` VARCHAR(128) NOT NULL, `world_id` INT NOT NULL, `title` VARCHAR(128) NOT NULL, PRIMARY KEY (`region_id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>region_type` (`region_id` VARCHAR(128) NOT NULL, `world_id` INT NOT NULL, `type` VARCHAR(128) NOT NULL, PRIMARY KEY (`region_id`));'
        - run drustcraftt_db_set_version def:drustcraft.region|1

    - flag server drustcraft.module.region:<script[drustcraftw_region].data_key[version]>

    - run drustcraftt_region_reload


# reload worldguard and drustcraft region data
drustcraftt_region_reload:
  type: task
  debug: false
  script:
    - flag server drustcraft.region.list:!
    - flag server drustcraft.region.world:!

    - waituntil <server.sql_connections.contains[drustcraft]>

    - ~sql id:drustcraft 'query:SELECT `<server.flag[drustcraft.region.worldguard_prefix]>region`.`id`, `<server.flag[drustcraft.region.worldguard_prefix]>world`.`name`, `priority`, `title`, `<server.flag[drustcraft.db.prefix]>region_type`.`type`, `<server.flag[drustcraft.region.worldguard_prefix]>region_flag`.`value` AS `game-mode` FROM `<server.flag[drustcraft.region.worldguard_prefix]>region` LEFT JOIN `<server.flag[drustcraft.region.worldguard_prefix]>world` ON `<server.flag[drustcraft.region.worldguard_prefix]>world`.`id` = `<server.flag[drustcraft.region.worldguard_prefix]>region`.`world_id` LEFT JOIN `<server.flag[drustcraft.db.prefix]>region_title` ON `<server.flag[drustcraft.db.prefix]>region_title`.`region_id` = `<server.flag[drustcraft.region.worldguard_prefix]>region`.`id` LEFT JOIN `<server.flag[drustcraft.db.prefix]>region_type` ON `<server.flag[drustcraft.db.prefix]>region_type`.`region_id` = `<server.flag[drustcraft.region.worldguard_prefix]>region`.`id` LEFT JOIN `<server.flag[drustcraft.region.worldguard_prefix]>region_flag` ON `<server.flag[drustcraft.region.worldguard_prefix]>region_flag`.`region_id` = `<server.flag[drustcraft.region.worldguard_prefix]>region`.`id` AND `<server.flag[drustcraft.region.worldguard_prefix]>region_flag`.`world_id` = `<server.flag[drustcraft.region.worldguard_prefix]>region`.`world_id` AND `<server.flag[drustcraft.region.worldguard_prefix]>region_flag`.`flag` = "game-mode" WHERE 1' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define id:<[row].get[1]||<empty>>
      - define world:<[row].get[2].unescaped||<empty>>
      - define priority:<[row].get[3]||<empty>>
      - define title:<[row].get[4].unescaped||<empty>>
      - define type:<[row].get[5].unescaped||<empty>>
      - define gamemode:<[row].get[6].unescaped||<empty>>

      - flag server drustcraft.region.list.<[world]>.<[id]>.priority:<[priority]>
      - if <[title]> != null:
        - flag server drustcraft.region.list.<[world]>.<[id]>.title:<[title]>
      - if <[type]> != null:
        - flag server drustcraft.region.list.<[world]>.<[id]>.type:<[type]>
      - if <[gamemode]> != null:
        - flag server drustcraft.region.list.<[world]>.<[id]>.gamemode:<[gamemode].to_lowercase.trim_to_character_set[abcdefghijklmnopqrstuvwxyz]>

    # get world ids
    - ~sql id:drustcraft 'query:SELECT `id`, `name` FROM `<server.flag[drustcraft.region.worldguard_prefix]>world` WHERE 1' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define id:<[row].get[1]||<empty>>
      - define world:<[row].get[2]||<empty>>
      - flag server drustcraft.region.world.<[world]>:<[id]>

    # get owners/members
    - ~sql id:drustcraft 'query:SELECT `<server.flag[drustcraft.region.worldguard_prefix]>region_players`.`region_id`, `<server.flag[drustcraft.region.worldguard_prefix]>world`.`name`, `<server.flag[drustcraft.region.worldguard_prefix]>user`.`uuid`, `owner` FROM `<server.flag[drustcraft.region.worldguard_prefix]>region_players` LEFT JOIN `<server.flag[drustcraft.region.worldguard_prefix]>world` ON `<server.flag[drustcraft.region.worldguard_prefix]>world`.`id` = `<server.flag[drustcraft.region.worldguard_prefix]>region_players`.`world_id` LEFT JOIN `<server.flag[drustcraft.region.worldguard_prefix]>user` ON `<server.flag[drustcraft.region.worldguard_prefix]>region_players`.`user_id` = `<server.flag[drustcraft.region.worldguard_prefix]>user`.`id` WHERE 1' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define id:<[row].get[1]||<empty>>
      - define world:<[row].get[2]||<empty>>
      - define uuid:<[row].get[3]||<empty>>
      - define owner:<[row].get[4]||<empty>>

      - if <[owner]> == 0:
        - flag server drustcraft.region.list.<[world]>.<[id]>.owners.players:->:<[uuid]>
      - else:
        - flag server drustcraft.region.list.<[world]>.<[id]>.members.players:->:<[uuid]>

    # get owners/members groups
    - ~sql id:drustcraft 'query:SELECT `<server.flag[drustcraft.region.worldguard_prefix]>region_groups`.`region_id`, `<server.flag[drustcraft.region.worldguard_prefix]>world`.`name`, `<server.flag[drustcraft.region.worldguard_prefix]>group`.`name`, `owner` FROM `<server.flag[drustcraft.region.worldguard_prefix]>region_groups` LEFT JOIN `<server.flag[drustcraft.region.worldguard_prefix]>world` ON `<server.flag[drustcraft.region.worldguard_prefix]>world`.`id` = `<server.flag[drustcraft.region.worldguard_prefix]>region_groups`.`world_id` LEFT JOIN `<server.flag[drustcraft.region.worldguard_prefix]>group` ON `<server.flag[drustcraft.region.worldguard_prefix]>region_groups`.`group_id` = `<server.flag[drustcraft.region.worldguard_prefix]>group`.`id` WHERE 1' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define id:<[row].get[1]||<empty>>
      - define world:<[row].get[2]||<empty>>
      - define group:<[row].get[3]||<empty>>
      - define owner:<[row].get[4]||<empty>>

      - if <[owner]> == 0:
        - flag server drustcraft.region.list.<[world]>.<[id]>.members.groups:->:<[group]>
      - else:
        - flag server drustcraft.region.list.<[world]>.<[id]>.owners.groups:->:<[group]>

    - foreach <server.worlds> as:world:
      - foreach <[world].list_regions> as:region:
        - note <[region].area> as:drustcraft_region_<[world].name>_<[region].id>


drustcraftt_region_type_register:
  type: task
  debug: false
  definitions: type|task_name
  script:
    - flag server drustcraft.region.type.<[type]>:<[task_name]>


drustcraftt_region_enter:
  type: task
  debug: false
  definitions: note_name|from
  script:
    - if <[note_name].starts_with[drustcraft_region_]>:
      - define world:<[note_name].after[drustcraft_region_].before[_]>
      - define region:<[note_name].after[drustcraft_region_<[world]>_]>
      - define type:<server.flag[drustcraft.region.list.<[world]>.<[region]>.type]||null>
      - define title:<server.flag[drustcraft.region.list.<[world]>.<[region]>.title]||null>
      - if <[type]> != null:
        - if <server.has_flag[drustcraft.region.type.<[type]>]>:
          - run <server.flag[drustcraft.region.type.<[type]>]> def:enter|<[world]>|<[region]>|<[type]>|<[title]>|<[from]>
      - else if <[title]> != null:
        - title title:<&f><[title]>


drustcraftt_region_exit:
  type: task
  debug: false
  definitions: note_name|from
  script:
    - if <[note_name].starts_with[drustcraft_region_]>:
      - define world:<[note_name].after[drustcraft_region_].before[_]>
      - define region:<[note_name].after[drustcraft_region_<[world]>_]>
      - define type:<server.flag[drustcraft.region.list.<[world]>.<[region]>.type]||null>
      - define title:<server.flag[drustcraft.region.list.<[world]>.<[region]>.title]||null>
      - if <[type]> != null:
        - if <server.has_flag[drustcraft.region.type.<[type]>]>:
          - run <server.flag[drustcraft.region.type.<[type]>]> def:exit|<[world]>|<[region]>|<[type]>|<[title]>|<[from]>


drustcraftp_region_map:
  type: procedure
  debug: false
  definitions: location
  script:
    - define region_list:<[location].regions.parse[id]>
    - define region_priority_map:<map[]>
    - foreach <[region_list]> as:region:
      - define region_priority_map:<[region_priority_map].with[<[region]>].as[<server.flag[drustcraft.region.list.<[location].world.name>.<[region]>.priority]||0>]>

    - determine <proc[drustcraftp_util_map_reverse].context[<[region_priority_map].sort_by_value>]>


drustcraftp_region_location_type:
  type: procedure
  debug: false
  definitions: location
  script:
    - define type:null
    - define region_priority_map:<proc[drustcraftp_region_map].context[<[location]>]>
    - foreach <[region_priority_map]> key:region:
      - if <server.has_flag[drustcraft.region.list.<[location].world.name>.<[region]>.type]>:
        - define type:<server.flag[drustcraft.region.list.<[location].world.name>.<[region]>.type]>

    - determine <[type]>


drustcraftp_region_location_gamemode:
  type: procedure
  debug: false
  definitions: location
  script:
    - define gamemode:SURVIVAL
    - define region_priority_map:<proc[drustcraftp_region_map].context[<[location]>]>
    - foreach <[region_priority_map]> key:region:
      - if <server.has_flag[drustcraft.region.list.<[location].world.name>.<[region]>.gamemode]>:
        - define gamemode:<server.flag[drustcraft.region.list.<[location].world.name>.<[region]>.gamemode]>

    - determine <[gamemode]>

drustcraftp_region_player_is_member:
  type: procedure
  debug: false
  definitions: region|world|target_player
  script:
    - if <server.flag[drustcraft.region.list.<[world]>.<[region]>.members.players].contains[<[target_player].uuid>]||false>:
      - determine true
    - foreach <server.flag[drustcraft.region.list.<[world]>.<[region]>.members.groups]||<list[]>> as:group:
      - if <proc[drustcraftp_group_is_member].context[<[group]>|<[target_player]>]>:
        - determine true
    - determine false


drustcraftp_region_member_groups:
  type: procedure
  debug: false
  definitions: region|world
  script:
    - determine <server.flag[drustcraft.region.list.<[world]>.<[region]>.members.groups]||<list[]>>

drustcraftp_region_player_is_owner:
  type: procedure
  debug: false
  definitions: region|world|target_player
  script:
    - if <server.flag[drustcraft.region.list.<[world]>.<[region]>.owners.players].contains[<[target_player].uuid>]||false>:
      - determine true
    - foreach <server.flag[drustcraft.region.list.<[world]>.<[region]>.owners.groups]||<list[]>> as:group:
      - if <proc[drustcraftp_group_is_member].context[<[group]>|<player[<[target_player]>]>]>:
        - determine true
    - determine false


drustcraftp_region_owner_groups:
  type: procedure
  debug: false
  definitions: region|world
  script:
    - determine <server.flag[drustcraft.region.list.<[world]>.<[region]>.owners.groups]||<list[]>>
