# Drustcraft - Whitelist
# Whitelist players using a variety of mechanics
# https://github.com/drustcraft/drustcraft

drustcraftw_whitelist:
    type: world
    debug: false
    events:
        on drustcraft load:
            - define whitelist_storage:<yaml[drustcraft_server].read[drustcraft.whitelist.storage]||<empty>>
            
            - if <list[yaml].contains[<[whitelist_storage]>]> == false:
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
                    - if <yaml[drustcraft_whitelist].read[whitelist.players].contains[<[name]>]> == false:
                        - yaml id:drustcraft_whitelist set whitelist.players:->:<[name]>
                        - yaml id:drustcraft_whitelist savefile:drustcraft_whitelist.yml
                        - narrate '<&e>The player <&sq><[name]><&sq> has been added to the whitelist of this server'
                    - else:
                        - narrate '<&e>The player <&sq><[name]><&sq> was already on the whitelist of this server'
                - else:
                    - narrate '<&e>No player name was entered to add to the whitelist'
            - case rem remove:
                - define name:<context.args.get[2]||<empty>>

                - if <[name]> != <empty>:
                    - if <yaml[drustcraft_whitelist].read[whitelist.players].contains[<[name]>]>:
                        - yaml id:drustcraft_whitelist set whitelist.players:<-:<[name]>
                        - yaml id:drustcraft_whitelist savefile:drustcraft_whitelist.yml
                        - narrate '<&e>The player <&sq><[name]><&sq> has been removed from the whitelist of this server'
                    - else:
                        - narrate '<&e>The player <&sq><[name]><&sq> was not on the whitelist of this server'
                - else:
                    - narrate '<&e>No player name was entered to remove from the whitelist'
            - case list:
                - run drustcraft.chat_paginate 'def:Whitelisted Players|<context.args.get[2]||1>|<yaml[drustcraft_whitelist].read[whitelist.players]>|whitelist||false'