# Drustcraft - Warm
# Drustcraft Mute, Warning and Ban System
# https://github.com/drustcraft/drustcraft

drustcraftw_warn:
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
      - if <yaml.list.contains[drustcraft_warn]>:
        - if <yaml[drustcraft_warn].read[players].contains[<player.uuid>]||false> == false:
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
                  - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` (`uuid`,`playername`,`added_date`,`linking_code`) VALUES ("<player.uuid>", "<player.name>", <util.time_now.epoch_millis.div[1000].round>, "<[code]>");'

                  - if <server.scripts.parse[name].contains[drustcraftw_bungee]>:
                    - run drustcraftt_bungee.run def:whitelist_sync
            
              - run drustcraftt_whitelist.generate_new_code
          - else:
            - determine KICKED:<&nl><&nl><server.flag[drustcraft_whitelist_kick_message]||<empty>>
        - else:
          - run drustcraftt_whitelist.transfer_player def:<player>
          
      - else:
        - determine 'KICKED:<&nl><&nl><&8><&l>[<&6>!<&8><&l>]<&6> This server is currently not available to due to a configuration error'
    
    on system time minutely every:5:
      - run drustcraftt_warn.sync

drustcraftt_warn:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <yaml.list.contains[drustcraft_warn]>:
      - ~yaml id:drustcraft_warn unload    
    
    - flag server drustcraft_warn_storage:!
    - define whitelist_storage:<yaml[drustcraft_server].read[drustcraft.warnings.storage]||<empty>>
    - define 'whitelist_kick_message:<yaml[drustcraft_server].read[drustcraft.whitelist.kick_message]||<element[<&e>You are not whitelisted to play on this server]>>'
    - define 'whitelist_linking_message:<yaml[drustcraft_server].read[drustcraft.whitelist.kick_message]||<element[<&e>You are not whitelisted to play on this server.<&nl><&nl>Register at <&f>drustcraft.com.au <&e>and use linking code <&f><&l>$CODE$]>>'      
    - define whitelist_linking_codes:<yaml[drustcraft_server].read[drustcraft.whitelist.linking_codes]||false>

    # If the drustcraft server YML doesnt have a whitelist storage setting, default to YAML
    - if <list[yaml|sql].contains[<[whitelist_storage]>]> == false:
      - yaml id:drustcraft_server set drustcraft.whitelist.storage:yaml
      - define whitelist_storage:yaml

    - if <[warn_storage]> == 'sql':
      - if <server.scripts.parse[name].contains[drustcraftw_sql]>:
        - waituntil <server.sql_connections.contains[drustcraft_database]>
        - define create_tables:true
        - ~sql id:drustcraft_database 'query:SELECT version FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_version WHERE `name`="drustcraft_warn";' save:sql_result
        - if <entry[sql_result].result.size||0> >= 1:
          - define row:<entry[sql_result].result.get[1].split[/].get[1].unescaped||0>
          - define create_tables:false
          - if <[row]> != 1:
            - debug log 'Warn table version <[row]> is unsupported by this version of Drustcraft Whitelist'
            - stop
  
        - if <[create_tables]>:
          - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` (`name`,`version`) VALUES ("drustcraft_warn",1);'
          - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_warn` (`uuid` VARCHAR(36), `playername` VARCHAR(255), `added_date` INT NOT NULL, `added_uuid` VARCHAR(36) NOT NULL`linking_code` VARCHAR(6) DEFAULT "", `reset_code` VARCHAR(6) DEFAULT "", `reset_code_timeout` INT DEFAULT 0);'
        - else:
          # cleanup database
          - define timeout:<util.time_now.epoch_millis.div[1000].round>
          
          - ~sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` SET `reset_code`="", `reset_code_timeout`=0 WHERE `reset_code_timeout` <&lt>= <[timeout]>;'
      - else:
        - debug log 'Drustcraft Warn in SQL storage mode requires the Drustcraft SQL script installed'
        - stop
        
    - flag server drustcraft_warn_storage:<[warn_storage]>
    
    - ~run drustcraftt_warn.sync

    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - run drustcraftt_tab_complete.completions def:warn|_*players|_*warn_type
      - run drustcraftt_tab_complete.completions def:unwarn|_*players|_*warn_id
      - run drustcraftt_tab_complete.completions def:ban|_*players|_*warn_time
      - run drustcraftt_tab_complete.completions def:unban|_*players
      - run drustcraftt_tab_complete.completions def:mute|_*players|_*warn_time
      - run drustcraftt_tab_complete.completions def:unmute|_*players
      - run drustcraftt_tab_complete.completions def:note|_*players
      - run drustcraftt_tab_complete.completions def:unnote|_*players|_*note_id
      
      - run drustcraftt_tab_complete.completions def:warnlist
      - run drustcraftt_tab_complete.completions def:warnhistory|_*players
      - run drustcraftt_tab_complete.completions def:warntrack|info
      - run drustcraftt_tab_complete.completions def:warntrack|add
      - run drustcraftt_tab_complete.completions def:warntrack|edit
      - run drustcraftt_tab_complete.completions def:warntrack|remove

    - if <server.scripts.parse[name].contains[drustcraftw_bungee]>:
      - run drustcraftt_bungee.register def:whitelist_sync|drustcraftt_whitelist.sync
  
  save:
            
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


drustcraftp_warn:
  type: procedure
  script:
    - determine <empty>
  
  list:
    - determine <yaml[drustcraft_warn].list_keys[reasons]||<list[]>>

  info:
    - define warn_info:<map[]>
    
    # set map
    
  track_item_readable:
    - define item:<[1]||<empty>>
    
    - if <[item]> == warn || <[item]> == kick:
      - determine <[item].to_lowercase>
    - if <[item].substring[0,4]> == mute:
      - define duration:<[item].substring[4]>
      - define integer:<[duration].substring[0,<[duration].length.sub[1]>]>
      - define unit:<[duration].substring[<[duration].length.sub[1]>]>

      - if <[duration]> != perm:
        - if <[integer].is_integer> == false || <list[m|d].contains[<[unit]>]> == false:
          - determine Unknown
      
      - determine '<[item].substring[0,4].to_lowercase> <[duration]>'
    - if <[item].substring[0,3]> == ban:
      - define duration:<[item].substring[4]>
      - define integer:<[duration].substring[0,<[duration].length.sub[1]>]>
      - define unit:<[duration].substring[<[duration].length.sub[1]>]>

      - if <[duration]> != perm:
        - if <[integer].is_integer> == false || <list[m|d].contains[<[unit]>]> == false:
          - determine Unknown
      
      - determine '<[item].substring[0,4].to_lowercase> <[duration]>'

drustcraftc_warn:
  type: command
  debug: false
  name: warn
  description: Adds a warning to a player
  usage: /warn <&lt>player<&gt> <&lt>reason<&gt> <&lb>details<&rb>
  permission: drustcraft.warn
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  aliases:
    - warning
  tab complete:
    - define command:warn
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



# /warn
# /unwarn
# /mute
# /ban
# /unmute
# /unban
# /warnlist
# /warnhistory
# /note
# /unnote
# /warntrack list
# /warntrack view <name>
# /warntrack add <name> mute3d kick perm 
# /warntrack edit <name> mute3d kick perm 
# /warntrack delete <name> mute3d kick perm 

drustcraftc_warn_warntrack:
  type: command
  debug: false
  name: warntrack
  description: Creates / edits or deletes a warning punishment track
  usage: /warntrack
  permission: drustcraft.warn
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  script:
    - choose <context.args.get[1]||<empty>>:
        - case list:
          - define list:<proc[drustcraftp_warn.list]||<list[]>>
          - define page_no:<context.args.get[2]||1>
          - run drustcraftt_chat_paginate 'def:<list[Warning Reasons|<[page_no]>].include_single[<[list]>].include[warntrack list|warntrack info|false|warntrack edit|warntrack remove]>'
          
        - case info:
          - define reason:<context.args.get[2]||<empty>>
          - if <[reason]> != <empty>:
            - if <proc[drustcraftp_warn.list].contains[<[reason]>]||false>:
              - define reason_info:<proc[drustcraftp_warn.info].context[<[reason]>]>
              
              - define description:<[reason_info].get[description]||<&7>(none)>
              - define track_list:<[reason_info].get[track]||<list[]>>
              
              
              - run drustcraftt_chat_gui 'def:Warning: <[reason]>'
              - narrate '<&8><&l>[<&3>-<&8><&l>] <&3>Description: <&f><[description]>'
              - narrate '<&8><&l>[<&3>-<&8><&l>] <&3>Track: <&f><[track]>'
            - else:
              - narrate '<&8><&l>[<&4><&l>x<&8><&l>] <&c>The reason ID <&f><[reason]> <&c>is not a valid'
          - else:
            - narrate '<&8><&l>[<&4><&l>x<&8><&l>] <&c>No reason ID was entered'
          
        - case add:
          
        - case edit:
          
        - case remove:
        
      - default:
        - narrate '<&8><&l>[<&4><&l>x<&8><&l>] <&c>Unknown option. Try <queue.script.data_key[usage].parsed>'