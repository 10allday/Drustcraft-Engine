# Drustcraft - Group Utilities
# Simplified group management without the need of giving permissions to LP
# https://github.com/drustcraft/drustcraft

drustcraftw_group:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_group.load
    
    
    on script reload:
      - run drustcraftt_group.load


drustcraftt_group:
  type: task
  debug: false
  script:
    - determine <empty>

  load:
    - flag server drustcraftt_group:!
    - wait 2t
    
    - if <server.plugins.parse[name].contains[LuckPerms]>:
      - if <server.scripts.parse[name].contains[drustcraftw_chat_paginate]>:
        - flag server drustcraftt_group:true
    
        - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
          - waituntil <yaml.list.contains[drustcraft_tab_complete]>
    
          - run drustcraft.tab_complete.completions def:group|create
          - run drustcraft.tab_complete.completions def:group|remove|_*groups
          - run drustcraft.tab_complete.completions def:group|list|_*pageno
          - run drustcraft.tab_complete.completions def:group|info|_*quests
          - run drustcraft.tab_complete.completions def:group|addmember|_*groups|_^players
          - run drustcraft.tab_complete.completions def:group|remmember|_*groups|_^players
          - run drustcraft.tab_complete.completions def:group|addowner|_*groups|_^players
          - run drustcraft.tab_complete.completions def:group|remowner|_*groups|_^players
      - else:
        - debug log 'Drustcraft Groups requires Drustcraft Chat Paginate installed'
    - else:
      - debug log 'Drustcraft Groups requires LuckPerms installed'


  create:
    - define group_name:<[1]||<empty>>

    - if <[group_name]> != <empty>:
      - execute as_server 'lp creategroup <[group_name]>'
           
  remove:
    - define group_name:<[1]||<empty>>

    # todo need a better way than this. Can we use the non existant of owner?
    - if <[group_name]> != <empty> && <list[default|moderator|builder|leader|developer].contains[<[group_name]>]> == false:
      - execute as_server 'lp deletegroup <[group_name]>'
  
  add_owner:
    - define group_name:<[1]||<empty>>
    - define target_player:<[2]||<player>>

    # todo need a better way than this
    - if <[group_name]> != <empty> && <list[default|moderator|builder|leader|developer].contains[<[group_name]>]> == false:
      - if <[target_player].is_player>:
        - execute as_server 'lp user <[target_player].name> group add <[group_name]>'
        - execute as_server 'lp user <[target_player].name> permission set owner.<[group_name]>'

  remove_owner:
    - define group_name:<[1]||<empty>>
    - define target_player:<[2]||<player>>

    - if <[group_name]> != <empty> && <[target_player].is_player>:
      - execute as_server 'lp user <[target_player].name> permission unset owner.<[group_name]>'

  add_member:
    - define group_name:<[1]||<empty>>
    - define target_player:<[2]||<player>>

    - if <[group_name]> != <empty> && <[target_player].is_player>:
      - execute as_server 'lp user <[target_player].name> group add <[group_name]>'
  
  remove_member:
    - define group_name:<[1]||<empty>>
    - define target_player:<[2]||<player>>

    - if <[group_name]> != <empty> && <[target_player].is_player>:
      - execute as_server 'lp user <[target_player].name> group remove <[group_name]>'


drustcraftp_group:
  type: procedure
  debug: false
  script:
    - determine <empty>

  is_owner:
    - define group_name:<[1]||<empty>>
    - define target_player:<[2]||<player>>

    - if <[group_name]> != <empty> && <[target_player].has_permission[owner.<[group_name]>]||false>:
      - determine true
        
    - determine false
  
  owners:
    - define group_name:<[1]||<empty>>

    - determine <server.players.filter[has_permission[owner.<[group_name]>]]>
      
  is_member:
    - define group_name:<[1]||<empty>>
    - define target_player:<[2]||<player>>

    - if <[target_player].type> == Player:
      - determine <[target_player].in_group[<[group_name]>]||false>
    
    - determine false

  members:
    - define group_name:<[1]||<empty>>
    
    - determine <server.players.filter[has_permission[group.<[group_name]>]]>


  in_group:
    - define group_name:<[1]||<empty>>
    - define target_player:<[2]||<empty>>

    - if <[group_name]> != <empty> && <[target_player].type> == Player:
      - if <proc[drustcraftp_group.is_owner].context[<[group_name]>|<[target_player]>]> || <proc[drustcraftp_group.is_member].context[<[group_name]>|<[target_player]>]>:
        - determine true
        
    - determine false
  
  exists:
    - define group_name:<[1]||<empty>>

    - if <[group_name]> != <empty> && <server.permission_groups.contains[<[group_name]>]>:
      - determine true

    - determine false

  list:
    - define target_player:<[1]||<empty>>

    - if <[target_player]> != <empty>:
      - if <[target_player].is_player||false>:
        - determine <[target_player].groups>
      
      - determine <list[]>

    - determine <server.permission_groups>
    

drustcraftc_group:
  type: command
  debug: false
  name: group
  description: Modifies player groups
  usage: /group (create|remove|list|info|addmember|removemember|addowner|removeowner) <&lt>id<&gt> [<&lt>player<&gt>]
  permission: drustcraft.group;drustcraft.group.override
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:group
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if <server.flag[]||false>:
    
      - choose <context.args.get[1]||<empty>>:
        - case create define add:
          - define id:<context.args.get[2]||<empty>>
  
          - if <[id]> != <empty> && <[id].to_lowercase.matches_character_set[abcdefghijklmnopqrstuvwxyz0123456789_]>:
            - if <server.permission_groups.contains[<[id]>]> == false:
              - run drustcraftt_group.create def:<[id]>
              
              - if <context.server||false> == false:
                - run drustcraftt_group.add_owner def:<[id]>|<player>
              
              - narrate '<&e>The group <&sq><[id]><&sq> was created'
            - else:
              - narrate '<&c>The group <&sq><[id]><&sq> already exists'
          - else:
            - narrate '<&c>The group <&sq><[id]><&sq> was not created because it contains unsupported characters'
        
        - case remove rem del delete:
          - define id:<context.args.get[2]||<empty>>
  
          - if <[id]> != <empty>:
            - if <proc[drustcraftp_group.exists].context[<[id]>]>:
              - if <context.server> || <player.has_permission[drustcraftt_group.override]> || <player.has.has_permission<proc[drustcraftp_group.is_owner].context[<[id]>|<player>]>:
                - run drustcraftt_group.remove def:<[id]>
                - narrate '<&e>The group <&sq><[id]><&sq> was removed'
              - else:
                - narrate '<&c>You cannot remove the group <&sq><[id]><&sq> as you are not an owner of it'
            - else:
              - narrate '<&c>The group <&sq><[id]><&sq> does not exist'
          - else:
            - narrate '<&c>You need to enter a group name to remove'
        
        - case list:
          - define page_no:<context.args.get[2]||1>
          - run drustcraftt_chat_paginate 'def:<list[Groups|<[page_no]>].include_single[<server.permission_groups>].include[group list|group info]>'
        
        - case info:
          - define group_id:<context.args.get[2]||<empty>>
  
          - if <[group_id]> != <empty>:
            - if <proc[drustcraftp_group.exists].context[<[group_id]>]>:
              - narrate '<&9>Group: <&e><[group_id]>'
  
              - define 'txt:<&9>Owners: '
              - define list:<proc[drustcraftp_group.owners].context[<[group_id]>].parse[name]>
              - if <[list].size> > 0:
                - define 'txt:<[txt]><element[<&6><[list].separated_by[, ]>].on_hover[Owners]> '
              - else:
                - define 'txt:<[txt]><&c>(none) '
              - define 'txt:<[txt]><element[<&a><&lb>Add<&rb>].on_click[/group addowner <[group_id]> ].type[SUGGEST_COMMAND].on_hover[Click to add owner]> '
              - define 'txt:<[txt]><element[<&c><&lb>Rem<&rb>].on_click[/group remowner <[group_id]> ].type[SUGGEST_COMMAND].on_hover[Click to remove owner]> '
              - narrate <[txt]>
  
              - define 'txt:<&9>Members: '
              - define list:<proc[drustcraftp_group.members].context[<[group_id]>].parse[name]>
              - if <[list].size> > 0:
                - define 'txt:<[txt]><element[<&6><[list].separated_by[, ]>].on_hover[Members]> '
              - else:
                - define 'txt:<[txt]><&c>(none) '
              - define 'txt:<[txt]><element[<&a><&lb>Add<&rb>].on_click[/group addmember <[group_id]> ].type[SUGGEST_COMMAND].on_hover[Click to add member]> '
              - define 'txt:<[txt]><element[<&c><&lb>Rem<&rb>].on_click[/group remmember <[group_id]> ].type[SUGGEST_COMMAND].on_hover[Click to remove member]> '
              - narrate <[txt]>
            - else:
              - narrate '<&c>The group <&sq><[group_id]><&sq> does not exist'
          - else:
            - narrate '<&c>You need to enter a group name'
  
        - case am addmem addmember:
          - define group_name:<context.args.get[2]||<empty>>
          - if <[group_name]> != <empty>:
            - if <proc[drustcraftp_group.exists].context[<[group_name]>]>:
              - define player_list:<context.args.get[3]||<empty>>
              - if <[player_list]> != <empty>:
                - if <context.server> || <player.has_permission[drustcraftt_group.override]> || <proc[drustcraftp_group.is_owner].context[<[group_name]>|<player>]>:
                  - define player_items:<[player_list].split[,]>
                  - foreach <[player_items]>:
                    - define target_player:<server.match_offline_player[<[value]>]||<empty>>
                    - if <[target_player]> != <empty> && <[target_player].name> == <context.args.get[3]>:
                      - if <proc[drustcraftp_group.is_member].context[<[group_name]>|<[target_player]>]> == false:
                        - run drustcraftt_group.add_member def:<[group_name]>|<[target_player]>
                        - narrate '<&e><&sq><[target_player].name><&sq> was added as a member of <&sq><[group_name]><&sq>'
                        - if <[target_player]> != <player||<empty>>:
                          - narrate '<&e>You are now a member of <&sq><[group_name]><&sq>' targets:<[target_player]>
                      - else:
                        - narrate '<&e><&sq><[target_player].name><&sq> is already a member of the group <&sq><[group_name]><&sq>'
                    - else:
                      - narrate '<&e>The player <&sq><[target_player].name><&sq> does not exist'
                - else:
                  - narrate '<&c>I<&sq>m sorry, you do not have permission modify the group <&sq><[group_name]><&sq>'                
              - else:
                - narrate '<&e>You need to enter a player name'
            - else:
              - narrate '<&c>The group <&sq><[group_name]><&sq> does not exist'
          - else:
            - narrate '<&e>You need to enter a group name'
  
        - case ao addown addowner:
          - define group_name:<context.args.get[2]||<empty>>
          - if <[group_name]> != <empty>:
            - if <proc[drustcraftp_group.exists].context[<[group_name]>]>:
              - define player_list:<context.args.get[3]||<empty>>
              - if <[player_list]> != <empty>:
                - if <context.server> || <player.has_permission[drustcraftt_group.override]> || <proc[drustcraftp_group.is_owner].context[<[group_name]>|<player>]>:
                  - define player_items:<[player_list].split[,]>
                  - foreach <[player_items]>:
                    - define target_player:<server.match_offline_player[<[value]>]||<empty>>
                    - if <[target_player]> != <empty> && <[target_player].name> == <context.args.get[3]>:
                      - if <proc[drustcraftp_group.is_owner].context[<[group_name]>|<[target_player]>]> == false:
                        - run drustcraftt_group.add_owner def:<[group_name]>|<[target_player]>
                        - narrate '<&e><&sq><[target_player].name><&sq> was added as an owner and member of <&sq><[group_name]><&sq>'
                        - if <[target_player]> != <player||<empty>>:
                          - narrate '<&e>You are now an owner and member of <&sq><[group_name]><&sq>' targets:<[target_player]>
                      - else:
                        - narrate '<&e><&sq><[target_player].name><&sq> is already a owner of the group <&sq><[group_name]><&sq>'
                    - else:
                      - narrate '<&e>The player <&sq><[target_player].name><&sq> does not exist'
                - else:
                  - narrate '<&c>I<&sq>m sorry, you do not have permission modify the group <&sq><[group_name]><&sq>'                
              - else:
                - narrate '<&e>You need to enter a player name'
            - else:
              - narrate '<&c>The group <&sq><[group_name]><&sq> does not exist'
          - else:
            - narrate '<&e>You need to enter a group name'
  
        - case rm remmem remmember removemember:
          - define group_name:<context.args.get[2]||<empty>>
          - if <[group_name]> != <empty>:
            - if <proc[drustcraftp_group.exists].context[<[group_name]>]>:
              - define player_list:<context.args.get[3]||<empty>>
              - if <[player_list]> != <empty>:
                - if <context.server> || <player.has_permission[drustcraftt_group.override]> || <proc[drustcraftp_group.is_owner].context[<[group_name]>|<player>]>:
                  - define player_items:<[player_list].split[,]>
                  - foreach <[player_items]>:
                    - define target_player:<server.match_offline_player[<[value]>]||<empty>>
                    - if <[target_player]> != <empty> && <[target_player].name> == <context.args.get[3]>:
                      - if <proc[drustcraftp_group.is_member].context[<[group_name]>|<[target_player]>]>:
                        - run drustcraftt_group.remove_member def:<[group_name]>|<[target_player]>
                        - narrate '<&e><&sq><[target_player].name><&sq> was removed as a member of <&sq><[group_name]><&sq>'
                        - if <[target_player]> != <player||<empty>>:
                          - narrate '<&e>You have been removed as a member of <&sq><[group_name]><&sq>' targets:<[target_player]>
                      - else:
                        - narrate '<&e><&sq><[target_player].name><&sq> is not a member of the group <&sq><[group_name]><&sq>'
                    - else:
                      - narrate '<&e>The player <&sq><[target_player].name><&sq> does not exist'
                - else:
                  - narrate '<&c>I<&sq>m sorry, you do not have permission modify the group <&sq><[group_name]><&sq>'                
              - else:
                - narrate '<&e>You need to enter a player name'
            - else:
              - narrate '<&c>The group <&sq><[group_name]><&sq> does not exist'
          - else:
            - narrate '<&e>You need to enter a group name'
  
        - case ro remown remowner removeowner:
          - define group_name:<context.args.get[2]||<empty>>
          - if <[group_name]> != <empty>:
            - if <proc[drustcraftp_group.exists].context[<[group_name]>]>:
              - define player_list:<context.args.get[3]||<empty>>
              - if <[player_list]> != <empty>:
                - if <context.server> || <player.has_permission[drustcraftt_group.override]> || <proc[drustcraftp_group.is_owner].context[<[group_name]>|<player>]>:
                  - define player_items:<[player_list].split[,]>
                  - foreach <[player_items]>:
                    - define target_player:<server.match_offline_player[<[value]>]||<empty>>
                    - if <[target_player]> != <empty> && <[target_player].name> == <context.args.get[3]>:
                      - if <proc[drustcraftp_group.is_owner].context[<[group_name]>|<[target_player]>]>:
                        - run drustcraftt_group.remove_owner def:<[group_name]>|<[target_player]>
                        - narrate '<&e><&sq><[target_player].name><&sq> was removed as an owner of <&sq><[group_name]><&sq>'
                        - if <[target_player]> != <player||<empty>>:
                          - narrate '<&e>You have been removed as an owner of <&sq><[group_name]><&sq>' targets:<[target_player]>
                      - else:
                        - narrate '<&e><&sq><[target_player].name><&sq> is not an owner of the group <&sq><[group_name]><&sq>'
                    - else:
                      - narrate '<&e>The player <&sq><[target_player].name><&sq> does not exist'
                - else:
                  - narrate '<&c>I<&sq>m sorry, you do not have permission modify the group <&sq><[group_name]><&sq>'                
              - else:
                - narrate '<&e>You need to enter a player name'
            - else:
              - narrate '<&c>The group <&sq><[group_name]><&sq> does not exist'
          - else:
            - narrate '<&e>You need to enter a group name'
        
        - default:
          - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
    - else:
      - narrate '<&c>The Drustcraft Groups extension is not loaded'


drustcraftc_groups:
  type: command
  debug: false
  name: groups
  description: Displays the groups you are within
  usage: /groups
  permission: drustcraftt_groups
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  script:
    - narrate '<&e>You are in the groups:'
		- narrate '<&f><player.groups.separated_by[<&e>, <&f>]>'