# Drustcraft - Analytics
# https://github.com/drustcraft/drustcraft

drustcraftw_analytics:
  type: world
  debug: false
  version: 3
  events:
    on server start:
      - run drustcraftt_analytics_load
      - waituntil <server.has_flag[drustcraft.module.analytics]>

      - waituntil <server.sql_connections.contains[drustcraft]>
      - flag server drustcraft_analytics_uptime_id:!
      - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>analytics_uptime` (`server`, `session_start`, `session_end`) VALUES("<bungee.server||<empty>>", <util.time_now.epoch_millis.div[1000].round>, 0);' save:sql_result
      - flag server drustcraft_analytics_uptime_id:<entry[sql_result].result.get[1].split[/].get[1]>

    on script reload:
      - run drustcraftt_analytics_load

    on system time minutely server_flagged:drustcraft.module.analytics:
      - waituntil <server.sql_connections.contains[drustcraft]>

      # TPS
      - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>analytics_tps` (`server`, `date`, `tps`, `players_online`, `ram_usage`, `entities`, `chunks_loaded`, `free_disk_space`) VALUES ("<bungee.server||<empty>>", <util.time_now.epoch_millis.div[1000].round>, <server.recent_tps.get[1].round>, <server.online_players.size>, <server.ram_usage.div[1048576].round>, <server.worlds.parse[entities.size].sum>, <server.worlds.parse[loaded_chunks.size].sum>, <server.disk_free.div[1048576].round>);'

      # Ping
      - define last_online:<list[]>
      - ~sql id:drustcraft 'query:SELECT `player_uuid` FROM `<server.flag[drustcraft.db.prefix]>analytics_sessions` WHERE (`server`="<bungee.server||<empty>>" AND `session_end`=0);' save:sql_result
      - foreach <entry[sql_result].result||<list[]>>:
          - define last_online:|:<[value].split[/].get[1]>

      - define date:<util.time_now.epoch_millis.div[1000].round>
      - foreach <server.online_players>:
        - define last_online:<-:<[value].uuid>
        - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>analytics_ping` (`player_uuid`, `server`, `date`, `ping`) VALUES ("<[value].uuid>", "<bungee.server||<empty>>", <[date]>, <[value].ping||0>);'

      - foreach <[last_online]>:
        - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>analytics_sessions` SET `session_end`=<[date]> WHERE (`server`="<bungee.server||<empty>>" AND `player_uuid`="<[value]>" AND `session_end`=0);'

      # Uptime
      - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>analytics_uptime` SET `session_end`=<[date]> WHERE (`server`="<bungee.server||<empty>>" AND `id`=<server.flag[drustcraft_analytics_uptime_id]>);'

    on player changes world server_flagged:drustcraft.module.analytics:
      - ~run drustcraftt_analytics_update_world_time def:<player>
      - flag player drustcraft_analytics_session_gamemode:<player.gamemode>
      - flag player drustcraft_analytics_session_gamemode_time:<util.time_now>
      - flag player drustcraft_analytics_session_gamemode_world:<context.destination_world.name>

    after player joins server_flagged:drustcraft.module.analytics:
      - waituntil <server.sql_connections.contains[drustcraft]>

      - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>analytics_sessions` (`player_uuid`, `server`, `session_start`, `session_end`, `afk_time`) VALUES("<player.uuid>", "<bungee.server||<empty>>", <util.time_now.epoch_millis.div[1000].round>, 0, 0);' save:sql_result
      - flag <player> drustcraft_analytics_session_id:<entry[sql_result].result.get[1].split[/].get[1]>
      - flag <player> drustcraft_analytics_session_afk_time:!

      - flag <player> drustcraft_analytics_session_gamemode:<player.gamemode>
      - flag <player> drustcraft_analytics_session_gamemode_time:<util.time_now>
      - flag <player> drustcraft_analytics_session_gamemode_world:<player.location.world.name>

    on player enters polygon server_flagged:drustcraft.module.analytics:
      - ~run drustcraftt_analytics_player_region_enter def:<player>|<context.area>

    on player enters cuboid server_flagged:drustcraft.module.analytics:
      - ~run drustcraftt_analytics_player_region_enter def:<player>|<context.area>

    on player exits polygon server_flagged:drustcraft.module.analytics:
      - ~run drustcraftt_analytics_player_region_exit def:<player>|<context.area>

    on player exits cuboid server_flagged:drustcraft.module.analytics:
      - ~run drustcraftt_analytics_player_region_exit def:<player>|<context.area>

    on player quits server_flagged:drustcraft.module.analytics:
      - waituntil <server.sql_connections.contains[drustcraft]>

      - run drustcraftt_analytics_player_end_afk_time def:<player>

      - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>analytics_region_times` SET `exited`=<util.time_now.epoch_millis.div[1000].round> WHERE `session_id`=<player.flag[drustcraft_analytics_session_id]> AND `server`="<bungee.server||<empty>>" AND `exited`=0;'
      - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>analytics_sessions` SET `session_end`=<util.time_now.epoch_millis.div[1000].round> WHERE `player_uuid`="<player.uuid>" AND `session_end`=0;'

      - ~run drustcraftt_analytics_update_world_time def:<player>
      - flag <player> drustcraft_analytics_session_id:!

    on player kicked server_flagged:drustcraft.module.analytics:
      - waituntil <server.sql_connections.contains[drustcraft]>
      - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>analytics_kicked` (`session_id`, `server`, `date`, `reason`) VALUES(<player.flag[drustcraft_analytics_session_id]>, "<bungee.server||<empty>>", <util.time_now.epoch_millis.div[1000].round>, "<context.reason||<empty>>");'

    # on player goes afk server_flagged:drustcraft.module.analytics:
    #   - waituntil <server.sql_connections.contains[drustcraft]>
    #   - flag <player> drustcraft_analytics_session_afk_time:<util.time_now>

    # on player returns from afk server_flagged:drustcraft.module.analytics:
    #   - waituntil <server.sql_connections.contains[drustcraft]>
    #   - run drustcraftt_analytics_player_end_afk_time def:<player>

    on player changes gamemode server_flagged:drustcraft.module.analytics:
      - ~run drustcraftt_analytics_update_world_time def:<player>
      - flag <player> drustcraft_analytics_session_gamemode:<context.gamemode>
      - flag <player> drustcraft_analytics_session_gamemode_time:<util.time_now>

    on entity death server_flagged:drustcraft.module.analytics:
      - waituntil <server.sql_connections.contains[drustcraft]>

      - define date:<util.time_now.epoch_millis.div[1000].round>

      - if <context.damager.is_player||false>:
        - define target_player:<[1]||<empty>>
        - define target_entity:<[2]||<empty>>

        - define entity_type:0
        - define entity_id:<context.entity.name||unknown>

        - if <context.entity.is_player||false>:
          - define entity_type:1
          - define entity_id:<context.entity.uuid>
        - else if <context.entity.is_npc>:
          - define entity_type:2
        - else if <context.entity.mythicmob.internal_name||<empty>> != <empty>:
          - define entity_id:<context.entity.mythicmob.internal_name>

        - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>analytics_kills` (`session_id`, `date`, `entity_type`, `entity_id`) VALUES(<context.damager.flag[drustcraft_analytics_session_id]>, <[date]>, <[entity_type]>, "<[entity_id]>");'

      - if <context.entity.is_player||false>:
        - define target_entity:<context.damager||<empty>>
        - define entity_type:0
        - define entity_id:<[target_entity].name||unknown>

        - if <[target_entity]> == <empty>:
          - define entity_type:-1
          - define entity_id:<element[]>
        - else if <[target_entity].is_player>:
          - define entity_type:1
          - define entity_id:<[target_entity].uuid>
        - else if <[target_entity].is_npc>:
          - define entity_type:2
        - else if <[target_entity].mythicmob.internal_name||<empty>> != <empty>:
          - define entity_id:<[target_entity].mythicmob.internal_name>

        - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>analytics_deaths` (`session_id`, `date`, `reason`, `entity_type`, `entity_id`) VALUES(<context.entity.flag[drustcraft_analytics_session_id]>, <[date]>, "<context.cause>", <[entity_type]>, "<[entity_id]>");'


drustcraftt_analytics_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - log ERROR 'Drustcraft Analytics: Drustcraft DB is required to be installed'
      - stop

    - waituntil <server.sql_connections.contains[drustcraft]>

    # fix previous version name
    - ~run drustcraftt_db_get_version def:drustcraft_analytics save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> != null:
      - ~run drustcraftt_db_clear_version: def:drustcraft_analytics
      - ~run drustcraftt_db_set_version: def:drustcraft_analytics|<[version]>
    # end of fix

    - ~run drustcraftt_db_get_version def:drustcraft.analytics save:result
    - define version:<entry[result].created_queue.determination.get[1]>

    - if <[version]> == null:
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>analytics_uptime` (`id` INT NOT NULL AUTO_INCREMENT, `server` VARCHAR(255) NOT NULL, `session_start` INT NOT NULL, `session_end` INT NOT NULL, PRIMARY KEY (`id`));'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>analytics_tps` (`server` VARCHAR(255) NOT NULL, `date` INT NOT NULL, `tps` INT NOT NULL, `players_online` INT NOT NULL, `ram_usage` INT NOT NULL, `entities` INT NOT NULL, `chunks_loaded` INT NOT NULL, `free_disk_space` INT NOT NULL);'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>analytics_sessions` (`id` INT NOT NULL AUTO_INCREMENT, `player_uuid` VARCHAR(255) NOT NULL, `server` VARCHAR(255) NOT NULL, `session_start` INT NOT NULL, `session_end` INT NOT NULL, `afk_time` INT NOT NULL, PRIMARY KEY (`id`));'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>analytics_ping` (`id` INT NOT NULL AUTO_INCREMENT, `player_uuid` VARCHAR(255) NOT NULL, `server` VARCHAR(255) NOT NULL, `date` INT NOT NULL, `ping` INT NOT NULL, PRIMARY KEY (`id`));'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>analytics_kills` (`session_id` INT NOT NULL, `date` INT NOT NULL, `entity_type` INT NOT NULL, `entity_id` VARCHAR(255) NOT NULL);'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>analytics_deaths` (`session_id` INT NOT NULL, `date` INT NOT NULL, `entity_type` INT NOT NULL, `entity_id` VARCHAR(255) NOT NULL, `reason` VARCHAR(255) NOT NULL);'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>analytics_worlds` (`id` INT NOT NULL AUTO_INCREMENT, `world_name` VARCHAR(255) NOT NULL, `server` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`));'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>analytics_world_times` (`id` INT NOT NULL AUTO_INCREMENT, `world_id` INT NOT NULL, `session_id` INT NOT NULL, `server` VARCHAR(255) NOT NULL, `survival_time` INT NOT NULL DEFAULT "0", `creative_time` INT NOT NULL DEFAULT "0", `adventure_time` INT NOT NULL DEFAULT "0", `spectator_time` INT NOT NULL DEFAULT "0", PRIMARY KEY (`id`));'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>analytics_kicked` (`id` INT NOT NULL AUTO_INCREMENT, `session_id` INT NOT NULL, `server` VARCHAR(255) NOT NULL, `date` INT NOT NULL, `reason` TEXT, PRIMARY KEY (`id`));'
      - run drustcraftt_db_set_version def:drustcraft.analytics|1
      - define version:1

    - if <[version]> == null || <[version]> == 1:
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>analytics_region_times` (`id` INT NOT NULL AUTO_INCREMENT, `region_id` VARCHAR(255) NOT NULL, `session_id` INT NOT NULL, `server` VARCHAR(255) NOT NULL, `entered` INT NOT NULL DEFAULT "0", `exited` INT NOT NULL DEFAULT "0", PRIMARY KEY (`id`));'
      - run drustcraftt_db_set_version def:drustcraft.analytics|2
      - define version:2

    - if <[version]> == 2:
      - run drustcraftt_db_set_version def:drustcraft.analytics|3
      - define version:3

    - if <[version]> != 3:
      - log ERROR 'Drustcraft Analytics: Database schema is an unsupported version'
      - stop

    - flag server drustcraft.module.analytics:<script[drustcraftw_analytics].data_key[version]>


drustcraftt_analytics_player_end_afk_time:
  type: task
  debug: false
  definitions: player
  script:
    - if <[player].has_flag[drustcraft_analytics_session_afk_time]>:
      - waituntil <server.sql_connections.contains[drustcraft]>
      - define afk_time:<util.time_now.duration_since[<[player].flag[drustcraft_analytics_session_afk_time]>].in_seconds.round||0>
      - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>analytics_sessions` SET `afk_time`=`afk_time`+<[afk_time]> WHERE `id`=<[player].flag[drustcraft_analytics_session_id]>;'
      - flag <[player]> drustcraft_analytics_session_afk_time:!


drustcraftt_analytics_update_world_time:
  type: task
  debug: false
  definitions: player
  script:
    - waituntil <server.sql_connections.contains[drustcraft]>

    - define gamemode:<[player].flag[drustcraft_analytics_session_gamemode]||<empty>>
    - define world_name:<[player].flag[drustcraft_analytics_session_gamemode_world]||<empty>>
    - define seconds:<util.time_now.duration_since[<[player].flag[drustcraft_analytics_session_gamemode_time]||<util.time_now>>].in_seconds||0>

    - if <[player].flag[drustcraft_analytics_session_id]||0> > 0 && <[gamemode]> != <empty> && <[world_name]> != <empty> && <[seconds]> != 0:
      - ~sql id:drustcraft 'query:SELECT `id` FROM `<server.flag[drustcraft.db.prefix]>analytics_worlds` WHERE (`world_name`="<[world_name]>" AND `server`="<bungee.server||<empty>>")' save:sql_result
      - define world_id:<entry[sql_result].result.get[1].split[/].get[1].unescaped||0>
      - if <[world_id]> == 0:
        - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>analytics_worlds` (`world_name`, `server`) VALUES("<[world_name]>","<bungee.server||<empty>>")' save:sql_result
        - define world_id:<entry[sql_result].result.get[1].split[/].get[1].unescaped||0>

      - if <[world_id]> != 0:
        - define gamemode_field:<[gamemode].to_lowercase>_time
        - ~sql id:drustcraft 'query:SELECT `id` FROM `<server.flag[drustcraft.db.prefix]>analytics_world_times` WHERE (`world_id`="<[world_id]>" AND `server`="<bungee.server||<empty>>" AND `session_id`=<[player].flag[drustcraft_analytics_session_id]>)' save:sql_result
        - define world_time_id:<entry[sql_result].result.get[1].split[/].get[1].unescaped||0>
        - if <[world_time_id]> != 0:
          - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>analytics_world_times` SET `<[gamemode_field]>`=`<[gamemode_field]>`+<[seconds]> WHERE `id`=<[world_time_id]>;'
        - else:
          - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>analytics_world_times` (`world_id`, `session_id`, `server`, `<[gamemode_field]>`) VALUES(<[world_id]>, <[player].flag[drustcraft_analytics_session_id]>, "<bungee.server||<empty>>", <[seconds]>);'


drustcraftt_analytics_player_region_enter:
  type: task
  debug: false
  definitions: player|region
  script:
    - waituntil <server.sql_connections.contains[drustcraft]>

    - if <[player].flag[drustcraft_analytics_session_id]||0> > 0 && <[region].note_name||<empty>> != <empty>:
      - define region_id:<[region].note_name>
      - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>analytics_region_times` (`region_id`, `session_id`, `server`, `entered`, `exited`) VALUES("<[region_id]>", <[player].flag[drustcraft_analytics_session_id]>, "<bungee.server||<empty>>", <util.time_now.epoch_millis.div[1000].round>, 0);'


drustcraftt_analytics_player_region_exit:
  type: task
  debug: false
  definitions: player|region
  script:
    - waituntil <server.sql_connections.contains[drustcraft]>

    - if <[player].flag[drustcraft_analytics_session_id]||0> > 0 && <[region].note_name||<empty>> != <empty>:
      - define region_id:<[region].note_name>
      - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>analytics_region_times` SET `exited`=<util.time_now.epoch_millis.div[1000].round> WHERE `region_id`="<[region_id]>" AND `session_id`=<[player].flag[drustcraft_analytics_session_id]> AND `server`="<bungee.server||<empty>>" AND `exited`=0;'
