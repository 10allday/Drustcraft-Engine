# Drustcraft - Whitelist
# Whitelist players using a variety of mechanics
# https://github.com/drustcraft/drustcraft

drustcraftw_whitelist:
    type: world
    debug: false
    events:
        on drustcraft load:
            - define whitelist_storage:<yaml[drustcraft_server].read[drustcraft.whitelist.storage]||<empty>>

            # If the drustcraft server YML doesnt have a whitelist storage setting, default to YAML
            - if <list[yaml|sql].contains[<[whitelist_storage]>]> == false:
                - yaml id:drustcraft_server set drustcraft.whitelist.storage:yaml
                - define whitelist_storage:yaml
    
            - choose <[whitelist_storage]>:
                - case yaml:
                    - if <yaml.list.contains[drustcraft_whitelist]>:
                        - yaml id:drustcraft_whitelist unload

                    - if <server.has_file[drustcraft_whitelist.yml]>:
                        - yaml id:drustcraft_whitelist load:drustcraft_whitelist.yml
                    - else:
                        - yaml id:drustcraft_whitelist create
                        - yaml id:drustcraft_whitelist set whitelist.players:->:nomadjimbob
                        - yaml id:drustcraft_whitelist set 'whitelist.kick_text:You are not whitelisted'
                        - yaml id:drustcraft_whitelist savefile:drustcraft_whitelist.yml
                - case sql:
                    - waituntil <yaml.list.contains[drustcraft_server]>

                    - define create_tables:true
                    - ~sql id:drustcraft_database 'query:SELECT version FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_version WHERE name="drustcraft_whitelist";' save:sql_result
                    - if <entry[sql_result].result.size||0> >= 1:
                        - define row:<entry[sql_result].result.get[1].split[/]||0>
                        - define create_tables:false
                        - if <[row]> >= 2 || <[row]> < 1:
                            # Weird version error
                            - stop

                    - if <[create_tables]>:
                        - ~sql id:drustcraft_database 'update:INSERT INTO `drustcraft_version` (`name`,`version`) VALUES ("drustcraft_whitelist",'1');'
                        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` (`player` VARCHAR(255) NOT NULL);'
                        
            
            - flag server drustcraft_whitelist_storage:<[whitelist_storage]>
            
            - run drustcraftt_tabcomplete.aliases def:whitelist|wl
            - run drustcraftt_tabcomplete.completions def:whitelist|add
            - run drustcraftt_tabcomplete.completions def:whitelist|rem|*_players
            - run drustcraftt_tabcomplete.completions def:whitelist|remove|*_players
            - run drustcraftt_tabcomplete.completions def:whitelist|list|*_int
    
    
        on player logs in:
            - choose <server.flag[drustcraft_whitelist_storage]>:
                - case yaml:
                    - if <yaml[drustcraft_whitelist].read[whitelist.players].contains[<player.name>]> == false:
                        - determine:<yaml[drustcraft_whitelist].read[whitelist.kick_text]>
                - case sql:
                    - if <yaml.list.contains[drustcraft_server]> == false:
                        - 'determine:Server is not ready'
                    - ~sql id:drustcraft_database 'query:SELECT `name` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE name="<player.name>";' save:sql_result
                    - if <entry[sql_result].result.size||0> == 0:
                        - determine:<yaml[drustcraft_whitelist].read[whitelist.kick_text]>


drustcraftc_whitelist:
    type: command
    debug: false
    name: whitelist
    description: Adds, removes or lists whitelisted players
    usage: /whitelist <add|remove|list> <player>
    permission: drustcraft.whitelist
    permission message: <&c>I'm sorry, you do not have permission to perform this command
    aliases:
        - wl
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
                            - ~sql id:drustcraft_database 'query:SELECT `name` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE name="<[name]>";' save:sql_result
                            - if <entry[sql_result].result.size||0> == 0:
                                - sql id:drustcraft_database 'query:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` (`name`) VALUES("<[name]>");'
                                - narrate '<&e>The player <&sq><[name]><&sq> has been added to the whitelist of this server'
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
                            - ~sql id:drustcraft_database 'query:SELECT `name` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE name="<[name]>";' save:sql_result
                            - if <entry[sql_result].result.size||0> > 0:
                                - sql id:drustcraft_database 'query:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE `name`="<[name]>";'
                                - narrate '<&e>The player <&sq><[name]><&sq> has been removed from the whitelist of this server'
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
                        - ~sql id:drustcraft_database 'query:SELECT `name` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_whitelist` WHERE 1";' save:sql_result
                        - define list:<entry[sql_result].result||<list[]>>

                - run drustcraft.chat_paginate 'def:Whitelisted Players|<context.args.get[2]||1>|<[list]>|whitelist||false'