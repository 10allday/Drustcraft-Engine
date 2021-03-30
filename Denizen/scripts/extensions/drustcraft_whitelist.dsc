# Drustcraft - Whitelist
# Whitelist players using a variety of mechanics
# https://github.com/drustcraft/drustcraft

drustcraftw_whitelist:
  type: world
  debug: false
  events:
    on server start:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_whitelist.load

    on script reload:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_whitelist.load

    on player logs in:
      - if <yaml.list.contains[drustcraft_whitelist]>:
        - if <yaml[drustcraft_whitelist].read[whitelist.players].contains[<player.uuid>]||false> == false:
          - if <server.flag[drustcraft_whitelist_linking_codes]||false> == true:
            - define code:<yaml[drustcraft_whitelist].read[whitelist.linking_codes.<player.uuid>]||<empty>>
            - if <[code]> == <empty>:
              - define code:<server.flag[drustcraft_whitelist_linking_code_next]||<empty>>
            
          - define msg:<server.flag[drustcraft_whitelist_linking_message]||<empty>>
          - define msg:<[msg].replace_text[$CODE$].with[<[code]>]>
            
          - determine passively KICKED:<&nl><&nl><[msg]>
          
          - if <[code]> != <empty> && <[code]> == <server.flag[drustcraft_whitelist_linking_code_next]||<empty>>:
            - yaml id:drustcraft_whitelist set whitelist.linking_codes.<player.uuid>:<[code]>
            - choose <server.flag[drustcraft_whitelist_storage]||<empty>>:
              - case yaml:
                - yaml id:drustcraft_whitelist savefile:drustcraft_whitelist.yml
              - case sql:
                - waituntil <server.sql_connections.contains[drustcraft_database]>
                - sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_linking_codes` WHERE `uuid` = "<player.uuid>";'
                - sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_linking_codes` (`uuid`,`playername`,`added_date`,`linking_code`) VALUES ("<player.uuid>", "<player.name>", <util.time_now.epoch_millis.div[1000].round>, "<[code]>");'
          
            - run drustcraftt_whitelist.generate_new_code
          - else:
            - determine KICKED:<&nl><&nl><server.flag[drustcraft_whitelist_kick_message]||<empty>>
        - else:
          - run drustcraftt_whitelist.transfer_player def:<player>
          
      - else:
        - determine 'KICKED:<&nl><&nl><&e>This server is currently not available to due to a whitelist error'
    
    on system time minutely every:5:
      - run drustcraftt_whitelist.sync

drustcraftt_whitelist:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <yaml.list.contains[drustcraft_whitelist]>:
      - ~yaml id:drustcraft_whitelist unload    
    
    - flag server drustcraft_whitelist_storage:!
    - define whitelist_storage:<yaml[drustcraft_server].read[drustcraft.whitelist.storage]||<empty>>
    - define 'whitelist_kick_message:<yaml[drustcraft_server].read[drustcraft.whitelist.kick_message]||<element[<&e>You are not whitelisted to play on this server]>>'
    - define 'whitelist_linking_message:<yaml[drustcraft_server].read[drustcraft.whitelist.kick_message]||<element[<&e>You are not whitelisted to play on this server.<&nl><&nl>Register at <&f>drustcraft.com.au <&e>and use linking code <&f><&l>$CODE$]>>'      
    - define whitelist_linking_codes:<yaml[drustcraft_server].read[drustcraft.whitelist.linking_codes]||false>

    # If the drustcraft server YML doesnt have a whitelist storage setting, default to YAML
    - if <list[yaml|sql].contains[<[whitelist_storage]>]> == false:
      - yaml id:drustcraft_server set drustcraft.whitelist.storage:yaml
      - define whitelist_storage:yaml

    - if <[whitelist_storage]> == 'sql':
      - if <server.scripts.parse[name].contains[drustcraftw_sql]>:
        - waituntil <server.sql_connections.contains[drustcraft_database]>
        - define create_tables:true
        - ~sql id:drustcraft_database 'query:SELECT version FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_version WHERE name="drustcraft_whitelist";' save:sql_result
        - if <entry[sql_result].result.size||0> >= 1:
          - define row:<entry[sql_result].result.get[1].split[/]||0>
          - define create_tables:false
          - if <[row]> >= 2 || <[row]> < 1:
            # Weird version error
            - stop
  
        - if <[create_tables]>:
          - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` (`name`,`version`) VALUES ("drustcraft_whitelist",1);'
          - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_accounts` (`uuid` VARCHAR(36), `playername` VARCHAR(255), `added_date` INT NOT NULL, `added_uuid` VARCHAR(36) NOT NULL);'
          - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_linking_codes` (`id` INT NOT NULL AUTO_INCREMENT, `uuid` VARCHAR(36) NOT NULL, `playername` VARCHAR(255) NOT NULL, `added_date` INT NOT NULL, `linking_code` VARCHAR(6) NOT NULL, PRIMARY KEY (`id`));'
          - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_password_reset` (`id` INT NOT NULL AUTO_INCREMENT, `playername` VARCHAR(255) NOT NULL, `timeout` INT NOT NULL, `reset_code` VARCHAR(6) NOT NULL, PRIMARY KEY (`id`));'
        - else:
          # cleanup database
          - ~sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_linking_codes` where `id` NOT IN(SELECT `id` from (SELECT MAX(`id`) as `id` from `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_linking_codes` GROUP BY `playername`) AS `t`);'
          - ~sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_linking_codes` where `uuid` IN(SELECT `uuid` from `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_accounts`);'
          - ~sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_password_reset` where `timeout` <&lt> <util.time_now.epoch_millis.div[1000].round>;'
      - else:
        - debug log 'Drustcraft Whitelist in SQL storage mode requires the Drustcraft SQL script installed'
        - stop
        
    - flag server drustcraft_whitelist_storage:<[whitelist_storage]>
    - flag server drustcraft_whitelist_kick_message:<[whitelist_kick_message]>
    - flag server drustcraft_whitelist_linking_message:<[whitelist_linking_message]>
    - flag server drustcraft_whitelist_linking_codes:<[whitelist_linking_codes]>
    
    - ~run drustcraftt_whitelist.sync
    - ~run drustcraftt_whitelist.generate_new_code

    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - run drustcraftt_tab_complete.completions def:whitelist|add
      - run drustcraftt_tab_complete.completions def:whitelist|rem|_*players
      - run drustcraftt_tab_complete.completions def:whitelist|remove|_*players
      - run drustcraftt_tab_complete.completions def:whitelist|list|_*int
        
  sync:
    - if <yaml.list.contains[drustcraft_whitelist]>:
      - ~yaml id:drustcraft_whitelist unload
    
    - choose <server.flag[drustcraft_whitelist_storage]||<empty>>:
      - case yaml:
        - if <server.has_file[/drustcraft_data/drustcraft_whitelist.yml]>:
          - yaml id:drustcraft_whitelist load:/drustcraft_data/drustcraft_whitelist.yml

      - case sql:
        - waituntil <server.sql_connections.contains[drustcraft_database]>
        - yaml id:drustcraft_whitelist create
        
        - ~sql id:drustcraft_database 'query:SELECT `uuid`,`playername` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_accounts` WHERE 1;' save:sql_result
        - if <entry[sql_result].result.size||0> > 0:  
          - foreach <entry[sql_result].result>:
            - define row:<[value].split[/]||<list[]>>
            - define uuid:<[row].get[1]||<empty>>
            - define playername:<[row].get[2]||<empty>>
            - if <[uuid]> != <empty> && <[uuid]> != 'null':
              - yaml id:drustcraft_whitelist set whitelist.players:->:<[uuid]>
            - else:
              - if <[playername]> != <empty> && <[playername]> != 'null':
                - yaml id:drustcraft_whitelist set whitelist.players:->:<[playername]>
            
        - ~sql id:drustcraft_database 'query:SELECT `uuid`,`linking_code` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_linking_codes` WHERE 1;' save:sql_result
        - if <entry[sql_result].result.size||0> > 0:
          - foreach <entry[sql_result].result>:
            - define row:<[value].split[/]||<list[]>>
            - define uuid:<[row].get[1]||<empty>>
            - define linking:<[row].get[2]||<empty>>
            - if <[uuid]> != <empty>:
              - yaml id:drustcraft_whitelist set whitelist.linking_codes.<[uuid]>:<[linking]>
    
    - if <yaml.list.contains[drustcraft_whitelist]> == false:
      - if <server.flag[drustcraft_whitelist_linking_codes]> == true:
        - yaml id:drustcraft_whitelist create

  generate_new_code:
    - if <server.flag[drustcraft_whitelist_linking_codes]||false> == true:
      - define characters:<list[0|1|2|3|4|5|6|7|8|9|A|B|C|D|E|F|G|H|J|K|M|N|P|Q|R|S|T|U|W|X|Z]>
      - define found:true
      
      - while <[found]>:
        - define code:<[characters].random><[characters].random><[characters].random><[characters].random><[characters].random><[characters].random>
        - ~sql id:drustcraft_database 'query:SELECT `uuid`,`linking_code` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_linking_codes` WHERE `linking_code` = "<[code]>";' save:sql_result
        - if <entry[sql_result].result.size||0> == 0:
          - flag server drustcraft_whitelist_linking_code_next:<[code]>
          - define found:false
  
  transfer_player:
    - define target_player:<[1]>
    - if <yaml[drustcraft_whitelist].read[whitelist.players].contains[<[target_player].name>]||false>:
      - if <yaml[drustcraft_whitelist].read[whitelist.accounts].contains[<[target_player].uuid>]||false> == false:
        - yaml id:drustcraft_whitelist set whitelist.accounts:->:<[target_player].uuid>
      - yaml id:drustcraft_whitelist set whitelist.players:<-:<[target_player].name>
    
    - choose <server.flag[drustcraft_whitelist_storage]||<empty>>:
      - case yaml:
        - yaml id:drustcraft_whitelist savefile:drustcraft_whitelist.yml
      - case sql:
        - waituntil <server.sql_connections.contains[drustcraft_database]>
        - sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_accounts` SET `uuid` = "<[target_player].uuid>" WHERE `playername` = "<[target_player].name>";'
      
    

drustcraftc_whitelist:
  type: command
  debug: false
  name: whitelist
  description: Adds, removes or lists whitelisted players
  usage: /whitelist <&lt>add|remove|list<&gt> <&lt>player<&gt>
  permission: drustcraft.whitelist
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  aliases:
    - wl
  tab complete:
    - define command:whitelist
    - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case add:
        - define name:<context.args.get[2]||<empty>>

        - if <[name]> != <empty>:
          - choose <server.flag[drustcraft_whitelist_storage]>:
            - case yaml:
              - if <yaml[drustcraft_whitelist].read[whitelist.players].contains[<[name]>]> == false:
                - yaml id:drustcraft_whitelist set whitelist.players:->:<[name]>
                - yaml id:drustcraft_whitelist savefile:drustcraft_whitelist.yml
                - narrate '<&e>The player <&sq><[name]><&sq> has been added to the whitelist of this server'
              - else:
                - narrate '<&e>The player <&sq><[name]><&sq> was already on the whitelist of this server'
            - case sql:
              - waituntil <server.sql_connections.contains[drustcraft_database]>
              - ~sql id:drustcraft_database 'query:SELECT `name` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE name="<[name]>";' save:sql_result
              - if <entry[sql_result].result.size||0> == 0:
                - define account:0
                - define linking:0
                - define added_date:<util.time_now.epoch_millis.div[1000].round>
                - define added_player:<player.name||console>
                
                - sql id:drustcraft_database 'query:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` (`name`, `account`, `linking`, `added_date`, `added_player`) VALUES("<[name]>", <[account]>, <[linking]>, <[added_date]>, "<[added_player]>");'
                - narrate '<&e>The player <&sq><[name]><&sq> has been added to the whitelist of this server. It will take a few minutes to propagate across the network'
              - else:
                - narrate '<&e>The player <&sq><[name]><&sq> was already on the whitelist of this server'
        - else:
          - narrate '<&e>No player name was entered to add to the whitelist'
      - case rem remove:
        - define name:<context.args.get[2]||<empty>>

        - if <[name]> != <empty>:
          - choose <server.flag[drustcraft_whitelist_storage]>:
            - case yaml:
              - if <yaml[drustcraft_whitelist].read[whitelist.players].contains[<[name]>]>:
                - yaml id:drustcraft_whitelist set whitelist.players:<-:<[name]>
                - yaml id:drustcraft_whitelist savefile:drustcraft_whitelist.yml
                - narrate '<&e>The player <&sq><[name]><&sq> has been removed from the whitelist of this server'
              - else:
                - narrate '<&e>The player <&sq><[name]><&sq> was not on the whitelist of this server'
            - case sql:
              - waituntil <server.sql_connections.contains[drustcraft_database]>
              - ~sql id:drustcraft_database 'query:SELECT `name` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE name="<[name]>";' save:sql_result
              - if <entry[sql_result].result.size||0> > 0:
                - sql id:drustcraft_database 'query:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE `name`="<[name]>";'
                - run drustcraftt_whitelist.sync
                - narrate '<&e>The player <&sq><[name]><&sq> has been removed from the whitelist of this server. It will take a few minutes to propagate across the network'
              - else:
                - narrate '<&e>The player <&sq><[name]><&sq> was not on the whitelist of this server'
        - else:
          - narrate '<&e>No player name was entered to remove from the whitelist'
      - case list:
        - define list:<list[]>
        
        - choose <server.flag[drustcraft_whitelist_storage]>:
          - case yaml:
            - define list:<yaml[drustcraft_whitelist].read[whitelist.players]>
          - case sql:
            - waituntil <server.sql_connections.contains[drustcraft_database]>
            - ~sql id:drustcraft_database 'query:SELECT `name` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE 1";' save:sql_result
            - define list:<entry[sql_result].result||<list[]>>

        - run drustcraft.chat_paginate 'def:Whitelisted Players|<context.args.get[2]||1>|<[list]>|whitelist||false'


drustcraftc_whitelist_resetpassword:
  type: command
  debug: false
  name: resetpassword
  description: Resets your Drustcraft website password
  usage: /resetpassword
  aliases:
  - resetpw
  - resetpwd
  - resetpass
  script:
    - if <server.scripts.parse[name].contains[drustcraftw_sql]>:
      - if <player||<empty>> != <empty>:
        - waituntil <server.sql_connections.contains[drustcraft_database]>

        - define reset_code:<util.random.int[10000].to[999999]>
        - define timeout:<util.time_now.epoch_millis.div[1000].round_down.add[259200]>
        
        - ~sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_password_reset` where `playername` = "<player.name>");'
        - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_password_reset` (`playername`,`reset_code`,`timeout`) VALUES ("<player.name>",<[reset_code]>,<[timeout]>);'
        
        - narrate '<&c>Your website password reset code is <&f><[reset_code]>'
        - narrate '<&c>DO NOT share this code with any players, else they will have access to your account'
        - narrate '<&c>This code is only valid for the next 3 days'
      - else:
        - narrate '<&c>This command can only be run by a player'
    - else:
      - narrate '<&c>This command is only available when the whitelist is in SQL storage mode'
