# Drustcraft - Whitelist
# Whitelist players using a variety of mechanics
# https://github.com/drustcraft/drustcraft

drustcraftw_whitelist:
  type: world
  debug: false
  version: 1
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
        - define whitelisted:<yaml[drustcraft_whitelist].read[whitelist.players].contains[<player.uuid>]||false>
        
        - if <server.flag[drustcraft_whitelist_linking_codes]||false> == false:
          # server IS NOT using linking codes
          - if <[whitelisted]> == false:
            # player IS NOT in whitelist
            - determine 'KICKED:<&nl><&nl><server.flag[drustcraft_whitelist_kick_message]||<empty>>'
        - else:
          # server IS using linking codes
          - define linking_code:<empty>
          
          - if <[whitelisted]> == false:
            # player IS NOT in whitelist
            - define linking_code:<server.flag[drustcraft_whitelist_linking_code_next]||<empty>>
            
          - else:
            # player IS in whitelist - check for linking code
            - define linking_code:<yaml[drustcraft_whitelist].read[whitelist.linking_codes.<player.uuid>]||<empty>>
          
          - if <[linking_code]> != <empty>:
            - define msg:<server.flag[drustcraft_whitelist_linking_message]||<empty>>
            - define msg:<[msg].replace_text[$CODE$].with[<[linking_code]>]>
            - determine passively KICKED:<&nl><&nl><[msg]>
          
            - if <[whitelisted]> == false:
              - yaml id:drustcraft_whitelist set whitelist.linking_codes.<player.uuid>:<[linking_code]>
              - choose <server.flag[drustcraft_whitelist_storage]||<empty>>:
                - case yaml:
                  - yaml id:drustcraft_whitelist savefile:drustcraft_whitelist.yml
                - case sql:
                  - waituntil <server.sql_connections.contains[drustcraft_database]>
                  - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` (`uuid`,`playername`,`added_date`,`linking_code`) VALUES ("<player.uuid>", "<player.name>", <util.time_now.epoch_millis.div[1000].round>, "<[linking_code]>");'

                  - if <server.scripts.parse[name].contains[drustcraftw_bungee]>:
                    - run drustcraftt_bungee.run def:whitelist_sync
            
              - run drustcraftt_whitelist.generate_new_code
          
      - else:
        - determine 'KICKED:<&nl><&nl><&e>This server is currently not available as it is restarting'
    
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
        - ~sql id:drustcraft_database 'query:SELECT version FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_version WHERE `name`="drustcraft_whitelist";' save:sql_result
        - if <entry[sql_result].result.size||0> >= 1:
          - define row:<entry[sql_result].result.get[1].split[/].get[1].unescaped||0>
          - define create_tables:false
          - if <[row]> == 1:
            - debug log 'Upgrading Whitelist table from version 1 to version 2'
            
            - ~sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` WHERE `name`="drustcraft_whitelist";'
            - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` (`name`,`version`) VALUES ("drustcraft_whitelist",2);'
            - ~sql id:drustcraft_database 'update:ALTER TABLE `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_accounts` RENAME TO `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist`;'
            - ~sql id:drustcraft_database 'update:ALTER TABLE `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` MODIFY `added_uuid` VARCHAR(36) DEFAULT "", ADD `linking_code` VARCHAR(6) DEFAULT "", ADD `reset_code` VARCHAR(6) DEFAULT "", ADD `reset_code_timeout` INT DEFAULT 0;'
            
            # move linking_codes to updated accounts table
            - ~sql id:drustcraft_database 'query:SELECT uuid,playername,added_date,linking_code FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_linking_codes WHERE 1;' save:sql_result_linking_code
            - if <entry[sql_result_linking_code].result.size||0> >= 1:
              - foreach <entry[sql_result_linking_code].result>:
                - define row:<[value].split[/]||<list[]>>
                - define uuid:<[row].get[1]||<empty>>
                - define playername:<[row].get[2]||<empty>>
                - define added_date:<[row].get[3]||<empty>>
                - define linking_code:<[row].get[4]||<empty>>
                
                - ~sql id:drustcraft_database 'query:SELECT uuid FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_accounts WHERE `uuid`="<[uuid]>";' save:sql_result_whitelist
                - if <entry[sql_result_whitelist].result.size||0> >= 1:
                  - sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` SET `linking_code`="<[linking_code]>" WHERE `uuid` = "<[uuid]>";'
            
            # move password_reset to updated accounts table
            - ~sql id:drustcraft_database 'query:SELECT playername,timeout,reset_code FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_password_reset WHERE 1;' save:sql_result_password_reset
            - if <entry[sql_result_password_reset].result.size||0> >= 1:
              - foreach <entry[sql_result_password_reset].result>:
                - define row:<[value].split[/]||<list[]>>
                - define playername:<[row].get[1]||<empty>>
                - define timeout:<[row].get[2]||<empty>>
                - define reset_code:<[row].get[3]||<empty>>
                
                - ~sql id:drustcraft_database 'query:SELECT playername FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_accounts WHERE `playername`="<[playername]>";' save:sql_result_whitelist
                - if <entry[sql_result_whitelist].result.size||0> >= 1:
                  - sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` SET `reset_code`="<[reset_code]>", `reset_code_timeout`=<[timeout]> WHERE `playername` = "<[playername]>";'

            - ~sql id:drustcraft_database 'update:DROP TABLE IF EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_linking_codes`;'
            - ~sql id:drustcraft_database 'update:DROP TABLE IF EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist_password_reset`;'
            
          - else if <[row]> == 2:
            # nothing to do
            - define nothing:true
          - else:
            - debug log 'Whitelist table version <[row]> is unsupported by this version of Drustcraft Whitelist'
            - stop
  
        - if <[create_tables]>:
          - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` (`name`,`version`) VALUES ("drustcraft_whitelist",2);'
          - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` (`uuid` VARCHAR(36), `playername` VARCHAR(255), `added_date` INT NOT NULL, `added_uuid` VARCHAR(36) NOT NULL`linking_code` VARCHAR(6) DEFAULT "", `reset_code` VARCHAR(6) DEFAULT "", `reset_code_timeout` INT DEFAULT 0);'
        - else:
          # cleanup database
          - define timeout:<util.time_now.epoch_millis.div[1000].round>
          
          - ~sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` SET `reset_code`="", `reset_code_timeout`=0 WHERE `reset_code_timeout` <&lt>= <[timeout]>;'
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

    - if <server.scripts.parse[name].contains[drustcraftw_bungee]>:
      - run drustcraftt_bungee.register def:whitelist_sync|drustcraftt_whitelist.sync
    
        
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
        
        - ~sql id:drustcraft_database 'query:SELECT `uuid`,`playername` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE 1;' save:sql_result
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
            
        - ~sql id:drustcraft_database 'query:SELECT `uuid`,`linking_code` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE `linking_code`!="";' save:sql_result
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
      - define characters:<list[3|4|6|7|8|9|A|B|C|D|E|F|G|H|J|K|M|N|P|Q|R|T|W|X|Y]>
      - define found:true
      
      - while <[found]>:
        - define code:<[characters].random><[characters].random><[characters].random><[characters].random><[characters].random><[characters].random>
        - ~sql id:drustcraft_database 'query:SELECT `uuid`,`linking_code` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE `linking_code`="<[code]>";' save:sql_result
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
        - sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` SET `uuid` = "<[target_player].uuid>" WHERE `playername` = "<[target_player].name>";'
      
    

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
                
                - sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` (`name`, `account`, `linking`, `added_date`, `added_player`) VALUES("<[name]>", <[account]>, <[linking]>, <[added_date]>, "<[added_player]>");'
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
                - sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE `name`="<[name]>";'
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
        
        - ~sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` set `reset_code`="<[reset_code]>", `reset_code_timeout`=<[timeout]> WHERE `uuid`="<player.uuid>";'
        
        - narrate '<&e>'
        - narrate '<&8><&l>[<&a><&l>+<&8><&l>] <&r><&2>Your website password reset code is <&f><[reset_code]>'
        - narrate '<&8><&l>[<&6><&l>!<&8><&l>] <&r><&6>DO NOT share this code with anyone else they will have access to your account. This code is valid for 72 hours'
        - narrate '<&e>'
      - else:
        - narrate '<&c>This command can only be run by a player'
    - else:
      - narrate '<&c>This command is only available when the whitelist is in SQL storage mode'
