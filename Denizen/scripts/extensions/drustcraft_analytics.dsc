# Drustcraft - Analytics
# Record player and world analytics
# https://github.com/drustcraft/drustcraft

drustcraftw_analytics:
  type: world
  debug: false
  events:
    on server starts:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      
      - if <server.scripts.parse[name].contains[drustcraftw_sql]>:
        - flag server drustcraft_analytics_uptime_id:!
        - waituntil <server.sql_connections.contains[drustcraft_database]>
            
        - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_uptime` (`server`, `session_start`, `session_end`) VALUES("<bungee.server>", <util.time_now.epoch_millis.div[1000].round>, 0);' save:sql_result
        - flag server drustcraft_analytics_uptime_id:<entry[sql_result].result.get[1].split[/].get[1]>

        - run drustcraftt_analytics.load
      - else:
        - debug log 'Drustcraft Analytics requires the Drustcraft SQL script installed'
      
      
    on script reload:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_analytics.load      
      
    on system time minutely server_flagged:drustcraft_analytics:
      - waituntil <server.sql_connections.contains[drustcraft_database]>
      
      # TPS
      - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_tps` (`server`, `date`, `tps`, `players_online`, `ram_usage`, `entities`, `chunks_loaded`, `free_disk_space`) VALUES ("<bungee.server>", <util.time_now.epoch_millis.div[1000].round>, <server.recent_tps.get[1].round>, <server.online_players.size>, <server.ram_usage.div[1048576].round>, <server.worlds.parse[entities.size].sum>, <server.worlds.parse[loaded_chunks.size].sum>, <server.disk_free.div[1048576].round>);'
      
      # Ping
      - define last_online:<list[]>
      - ~sql id:drustcraft_database 'query:SELECT `player_uuid` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_sessions` WHERE (`server`="<bungee.server>" AND `session_end`=0);' save:sql_result
      - foreach <entry[sql_result].result||<list[]>>:
          - define last_online:|:<[value].split[/].get[1]>
      
      - define date:<util.time_now.epoch_millis.div[1000].round>
      - foreach <server.online_players>:
        - define last_online:<-:<[value].uuid>
        - sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_ping` (`player_uuid`, `server`, `date`, `ping`) VALUES ("<[value].uuid>", "<bungee.server>", <[date]>, <[value].ping||0>);'
      
      - foreach <[last_online]>:
        - sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_sessions` SET `session_end`=<[date]> WHERE (`server`="<bungee.server>" AND `player_uuid`="<[value]>" AND `session_end`=0);'
      
      # Uptime
      - ~sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_uptime` SET `session_end`=<[date]> WHERE (`server`="<bungee.server>" AND `id`=<server.flag[drustcraft_analytics_uptime_id]>);'
    

    on player changes world:
      - ~run drustcraftt_analytics.player.update_world_time def:<player>
      - flag player drustcraft_analytics_session_gamemode:<player.gamemode>
      - flag player drustcraft_analytics_session_gamemode_time:<util.time_now>
      - flag player drustcraft_analytics_session_gamemode_world:<context.destination_world.name>


    after player joins:
      - waituntil <server.sql_connections.contains[drustcraft_database]>
      
      - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_sessions` (`player_uuid`, `server`, `session_start`, `session_end`, `afk_time`) VALUES("<player.uuid>", "<bungee.server>", <util.time_now.epoch_millis.div[1000].round>, 0, 0);' save:sql_result
      - flag <player> drustcraft_analytics_session_id:<entry[sql_result].result.get[1].split[/].get[1]>
      - flag <player> drustcraft_analytics_session_afk_time:!
      
      - flag <player> drustcraft_analytics_session_gamemode:<player.gamemode>
      - flag <player> drustcraft_analytics_session_gamemode_time:<util.time_now>
      - flag <player> drustcraft_analytics_session_gamemode_world:<player.location.world.name>


    on player quits:
      - waituntil <server.sql_connections.contains[drustcraft_database]>

      - run drustcraftt_analytics.player.end_afk_time def:<player>

      - ~sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_sessions` SET `session_end`=<util.time_now.epoch_millis.div[1000].round> WHERE `id`=<player.flag[drustcraft_analytics_session_id]>;'
          
      - ~run drustcraftt_analytics.player.update_world_time def:<player>
      - flag <player> drustcraft_analytics_session_id:!


    on player kicked:
      - waituntil <server.sql_connections.contains[drustcraft_database]>
      - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_kicked` (`session_id`, `server`, `date`, `reason`) VALUES(<player.flag[drustcraft_analytics_session_id]>, "<bungee.server>", <util.time_now.epoch_millis.div[1000].round>, "<context.reason||<empty>>");'


    on player goes afk:
      - waituntil <server.sql_connections.contains[drustcraft_database]>
      - flag <player> drustcraft_analytics_session_afk_time:<util.time_now>
            
            
    on player returns from afk:
      - waituntil <server.sql_connections.contains[drustcraft_database]>
      - run drustcraftt_analytics.player.end_afk_time def:<player>


    on player changes gamemode:
      - ~run drustcraftt_analytics.player.update_world_time def:<player>
      - flag <player> drustcraft_analytics_session_gamemode:<context.gamemode>
      - flag <player> drustcraft_analytics_session_gamemode_time:<util.time_now>


    on entity death:
      - waituntil <server.sql_connections.contains[drustcraft_database]>
      
      - define date:<util.time_now.epoch_millis.div[1000].round>
      
      - if <context.damager.is_player||false>:
        - define target_player:<[1]||<empty>>
        - define target_entity:<[2]||<empty>>
        
        - define entity_type:0
        - define entity_id:<context.entity.name||unknown>
        
        - if <context.entity.is_player>:
          - define entity_type:1
          - define entity_id:<context.entity.uuid>
        - else if <context.entity.is_npc>:
          - define entity_type:2
        - else if <context.entity.mythicmob.internal_name||<empty>> != <empty>:
          - define entity_id:<context.entity.mythicmob.internal_name>
        
        - ~sql id:drustcraft_database 'update:INSERT `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_kills` (`session_id`, `date`, `entity_type`, `entity_id`) VALUES(<context.damager.flag[drustcraft_analytics_session_id]>, <[date]>, <[entity_type]>, "<[entity_id]>");'

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
        
        - ~sql id:drustcraft_database 'update:INSERT `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_deaths` (`session_id`, `date`, `reason`, `entity_type`, `entity_id`) VALUES(<context.entity.flag[drustcraft_analytics_session_id]>, <[date]>, "<context.cause>", <[entity_type]>, "<[entity_id]>");'
        

drustcraftt_analytics:
    type: task
    debug: false
    script:
        - determine <empty>
    
    
    load:
      - flag server drustcraft_analytics:true
      - waituntil <server.sql_connections.contains[drustcraft_database]>

      - define create_tables:true
      - ~sql id:drustcraft_database 'query:SELECT version FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_version WHERE name="drustcraft_analytics";' save:sql_result
      - if <entry[sql_result].result.size||0> >= 1:
        - define row:<entry[sql_result].result.get[1].split[/]||0>
        - define create_tables:false
        - if <[row]> >= 2 || <[row]> < 1:
          # Weird version error
          - flag server drustcraft_analytics:!

      - if <[create_tables]>:
        - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` (`name`,`version`) VALUES ("drustcraft_analytics",'1');'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_uptime` (`id` INT NOT NULL AUTO_INCREMENT, `server` VARCHAR(255) NOT NULL, `session_start` INT NOT NULL, `session_end` INT NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_tps` (`server` VARCHAR(255) NOT NULL, `date` INT NOT NULL, `tps` INT NOT NULL, `players_online` INT NOT NULL, `ram_usage` INT NOT NULL, `entities` INT NOT NULL, `chunks_loaded` INT NOT NULL, `free_disk_space` INT NOT NULL);'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_sessions` (`id` INT NOT NULL AUTO_INCREMENT, `player_uuid` VARCHAR(255) NOT NULL, `server` VARCHAR(255) NOT NULL, `session_start` INT NOT NULL, `session_end` INT NOT NULL, `afk_time` INT NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_ping` (`id` INT NOT NULL AUTO_INCREMENT, `player_uuid` VARCHAR(255) NOT NULL, `server` VARCHAR(255) NOT NULL, `date` INT NOT NULL, `ping` INT NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_kills` (`session_id` INT NOT NULL, `date` INT NOT NULL, `entity_type` INT NOT NULL, `entity_id` VARCHAR(255) NOT NULL);'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_deaths` (`session_id` INT NOT NULL, `date` INT NOT NULL, `entity_type` INT NOT NULL, `entity_id` VARCHAR(255) NOT NULL, `reason` VARCHAR(255) NOT NULL);'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_worlds` (`id` INT NOT NULL AUTO_INCREMENT, `world_name` VARCHAR(255) NOT NULL, `server` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_world_times` (`id` INT NOT NULL AUTO_INCREMENT, `world_id` INT NOT NULL, `session_id` INT NOT NULL, `server` VARCHAR(255) NOT NULL, `survival_time` INT NOT NULL DEFAULT "0", `creative_time` INT NOT NULL DEFAULT "0", `adventure_time` INT NOT NULL DEFAULT "0", `spectator_time` INT NOT NULL DEFAULT "0", PRIMARY KEY (`id`));'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_kicked` (`id` INT NOT NULL AUTO_INCREMENT, `session_id` INT NOT NULL, `server` VARCHAR(255) NOT NULL, `date` INT NOT NULL, `reason` TEXT, PRIMARY KEY (`id`));'
    
    
    player:
      end_afk_time:
        - define target_player:<[1]||<empty>>
        - if <[target_player].has_flag[drustcraft_analytics_session_afk_time]>:
          - define afk_time:<util.time_now.duration_since[<[target_player].flag[drustcraft_analytics_session_afk_time]>].in_seconds.round||0>
          - ~sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_sessions` SET `afk_time`=`afk_time`+<[afk_time]> WHERE `id`=<[target_player].flag[drustcraft_analytics_session_id]>;'
          - flag <[target_player]> drustcraft_analytics_session_afk_time:!
      
      
      update_world_time:
        - waituntil <server.sql_connections.contains[drustcraft_database]>
        
        - define target_player:<[1]||<empty>>
        - define gamemode:<[target_player].flag[drustcraft_analytics_session_gamemode]||<empty>>
        - define world_name:<[target_player].flag[drustcraft_analytics_session_gamemode_world]||<empty>>
        - define seconds:<util.time_now.duration_since[<[target_player].flag[drustcraft_analytics_session_gamemode_time]||<util.time_now>>].in_seconds||0>
        
        - if <[target_player].flag[drustcraft_analytics_session_id]||0> > 0 && <[gamemode]> != <empty> && <[world_name]> != <empty> && <[seconds]> != 0:
          - ~sql id:drustcraft_database 'query:SELECT `id` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_worlds` WHERE (`world_name`="<[world_name]>" AND `server`="<bungee.server>")' save:sql_result
          - define world_id:<entry[sql_result].result.get[1].split[/].get[1]||0>
          - if <[world_id]> == 0:
            - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_worlds` (`world_name`, `server`) VALUES("<[world_name]>","<bungee.server>")' save:sql_result
            - define world_id:<entry[sql_result].result.get[1].split[/].get[1]||0>
          
          - if <[world_id]> != 0:
            - define gamemode_field:<[gamemode].to_lowercase>_time
            - ~sql id:drustcraft_database 'query:SELECT `id` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_world_times` WHERE (`world_id`="<[world_id]>" AND `server`="<bungee.server>" AND `session_id`=<[target_player].flag[drustcraft_analytics_session_id]>)' save:sql_result
            - define world_time_id:<entry[sql_result].result.get[1].split[/].get[1]||0>
            - if <[world_time_id]> != 0:
              - ~sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_world_times` SET `<[gamemode_field]>`=`<[gamemode_field]>`+<[seconds]> WHERE `id`=<[world_time_id]>;'
            - else:
              - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_analytics_world_times` (`world_id`, `session_id`, `server`, `<[gamemode_field]>`) VALUES(<[world_id]>, <[target_player].flag[drustcraft_analytics_session_id]>, "<bungee.server>", <[seconds]>);'
