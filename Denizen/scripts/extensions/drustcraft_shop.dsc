# Drustcraft - Shop
# NPC Shopkeepers
# https://github.com/drustcraft/drustcraft

drustcraftw_shop:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_shop.load
    
    on script reload:
      - run drustcraftt_shop.load
      

drustcraftt_shop:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <server.scripts.parse[name].contains[drustcraftw_npc]>:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_npc]>      
      
      - if <yaml.list.contains[drustcraft_shop]>:
        - yaml unload id:drustcraft_shop
    
      - if <server.has_file[/drustcraft_data/shops.yml]>:
        - yaml load:/drustcraft_data/shops.yml id:drustcraft_shop
      - else:
        - yaml create id:drustcraft_shop
        - yaml savefile:/drustcraft_data/shops.yml id:drustcraft_shop
      
      - foreach <yaml[drustcraft_shop].list_keys[npc]||<list[]>>:
        - ~run drustcraftt_npc.interactor def:<[value]>|drustcraftt_shop_interactor

      - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
        - wait 2t
        - waituntil <yaml.list.contains[drustcraft_tab_complete]>
        
        - run drustcraftt_tab_complete.completions def:shop|list
        - run drustcraftt_tab_complete.completions def:shop|create
        - run drustcraftt_tab_complete.completions def:shop|remove|_*shop_names
        - run drustcraftt_tab_complete.completions def:shop|info|_*shop_names
        - run drustcraftt_tab_complete.completions def:shop|setowner|_*shop_names|_*players
        - run drustcraftt_tab_complete.completions def:shop|npc|_*shop_names|list
        - run drustcraftt_tab_complete.completions def:shop|npc|_*shop_names|add|_*npcs
        - run drustcraftt_tab_complete.completions def:shop|npc|_*shop_names|rem|_*npcs
        - run drustcraftt_tab_complete.completions def:shop|item|_*shop_names|list
        - run drustcraftt_tab_complete.completions def:shop|item|_*shop_names|add|_*materials
        - run drustcraftt_tab_complete.completions def:shop|item|_*shop_names|rem|_*materials

    - else:
      - debug log 'Drustcraft Shop requires Drustcraft NPC installed'
        
  save:
    - yaml id:drustcraft_shop savefile:/drustcraft_data/shops.yml
  

drustcraftp_shop:
  type: procedure
  debug: false
  script:
    - determine <empty>
  
  info:
    - define shop_name:<[1]||<empty>>
    - define shop_info:<map[]>

    - define shop_info:<[shop_info].with[owner].as[<yaml[drustcraft_shop].read[shop.<[shop_name]>.owner]>]||<empty>>
    - determine <[shop_info]>
  
  list:
    - determine <yaml[drustcraft_shop].list_keys[shop]||<list[]>>
    

drustcraftc_shop:
  type: command
  debug: false
  name: shop
  description: Modifies player shops
  usage: /shop <&lt>list<&gt>
  permission: drustcraft.shop
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:shop
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case list:
        - define page_no:<context.args.get[2]||1>
        - run drustcraftt_chat_paginate 'def:<list[Shops|<[page_no]>].include_single[<proc[drustcraftp_shop.list]>].include[shop list|shop info]>'
      
      - case create:
        - define name:<context.args.get[2]||<empty>>
        - if <[name]> != <empty>:
          - if <yaml[drustcraft_shop].list_keys[shop].contains[<[name]>]||false> == false:
            - yaml id:drustcraft_shop set shop.<[name]>.owner:<player.uuid||console>
            - run drustcraftt_shop.save
            - narrate '<&e>The shop <&f><[name]> <&e>was created'
          - else:
            - narrate '<&e>A unique name is required when creating a shop'
        - else:
          - narrate '<&e>A unique name is required when creating a shop'
        
      - case remove delete del:
        - define name:<context.args.get[2]||<empty>>
        - if <[name]> != <empty>:
          - if <yaml[drustcraft_shop].list_keys[shop].contains[<[name]>]||false>:
            - yaml id:drustcraft_shop set shop.<[name]>:!
            - run drustcraftt_shop.save
            - narrate '<&e>The shop <&f><[name]> <&e>was deleted'
          - else:
            - narrate '<&e>The shop <&f><[name]> <&e>was not found'
        - else:
          - narrate '<&e>A shop name is required when deleting a shop'
      
      - case info:
        - define shop_name:<context.args.get[2]||<empty>>
        - if <[shop_name]> != <empty>:
          - run drustcraftt_chat_gui.title 'def:Shop: <[shop_name]>'
          
          - define shop_info:<proc[drustcraftp_shop.info].context[<[shop_name]>]>
          - if <[shop_info]> != <empty>:
            
            # Owner
            - define owner:<[shop_info].get[owner]||<empty>>
            - define owner:<player[<[owner]>].name||<&c>(none)>
            - define 'row:<&9>Owner: <&6><[owner]> <element[<&7><&lb>Edit<&rb>].on_click[/shop setowner <[shop_name]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
            - narrate <[row]>
            
            # NPCs
            - define npc_list:<yaml[drustcraft_shop].read[npc].filter_tag[<[filter_value].equals[<[shop_name]>]>].keys||<list[]>>

            - define 'row:<&9>NPCs: <&6><[npc_list].size> NPCs <element[<&7><&lb>View<&rb>].on_click[/shop npc <[shop_name]> list].on_hover[Click to view]> <element[<&a><&lb>Add<&rb>].on_click[/shop npc <[shop_name]> add ].type[SUGGEST_COMMAND].on_hover[Click to add]>'
            - narrate <[row]>
            
            # Items
            - define item_list:<yaml[drustcraft_shop].read[shop.<[shop_name]>.items]||<list[]>>

            - define 'row:<&9>Items: <&6><[item_list].size> items <element[<&7><&lb>View<&rb>].on_click[/shop item <[shop_name]> list].on_hover[Click to view]> <element[<&a><&lb>Add<&rb>].on_click[/shop item <[shop_name]> add ].type[SUGGEST_COMMAND].on_hover[Click to add]>'
            - narrate <[row]>
            
          - else:
            - narrate '<&e>There was an error getting the shop information'
        - else:
          - narrate '<&e>No shop name was entered'
      
      - case setowner:
        - define shop_name:<context.args.get[2]||<empty>>
        - if <[shop_name]> != <empty>:
          - if <yaml[drustcraft_shop].list_keys[shop].contains[<[shop_name]>]||false>:
            - define player_name:<context.args.get[3]||<empty>>
            - if <[player_name]> != <empty>:
              - define target_player:<server.match_offline_player[<[player_name]>]>
              - if <[target_player].object_type> == Player && <[target_player].name> == <[player_name]>:
                - yaml id:drustcraft_shop set shop.<[shop_name]>.owner:<[target_player].uuid>
                - run drustcraftt_shop.save
                - narrate '<&e>The shop owner was updated'
              - else:
                - narrate '<&e>The player <&f><[player_name]> <&e>was not found on this server'
            - else:
              - narrate '<&e>A new owner is required to be entered'
          - else:
            - narrate '<&e>The shop <&f><[shop_name]> <&e>was not found'
        - else:
          - narrate '<&e>No shop name was entered'
        
      - case npc:
        - define shop_name:<context.args.get[2]||<empty>>
        - if <[shop_name]> != <empty>:
          - if <yaml[drustcraft_shop].list_keys[shop].contains[<[shop_name]>]||false>:
            - choose <context.args.get[3]||<empty>>:
              - case list:
                - define page_no:<context.args.get[4]||1>
                - define npc_list:<yaml[drustcraft_shop].read[npc].filter_tag[<[filter_value].equals[<[shop_name]>]>].keys||<list[]>>
                
                - define npc_map:<map[]>
                - foreach <[npc_list]>:
                  - define npc_map:<[npc_map].with[<[value]>].as[<npc[<[value]>].name||<&7>(not<&sp>found)>]>
                
                - run drustcraftt_chat_paginate 'def:<list[Shop <[shop_name]> NPCs|<[page_no]>].include_single[<[npc_map]>].include[shop npc <[shop_name]> list|<empty>|true|<empty>|shop npc <[shop_name]> rem]>'
              
              - case add:
                - define npc_id:<context.args.get[4]||<empty>>
                - if <[npc_id]> != <empty>:
                  - if <[npc_id].is_integer>:
                    - if <server.npcs.parse[id].contains[<[npc_id]>]>:
                      - yaml id:drustcraft_shop set npc.<player.selected_npc.id>:<[shop_name]>
                      - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_shop_interactor
                      
                      - run drustcraftt_shop.save
                      - narrate '<&e>The NPC now sells items from the shop <&f><[shop_name]>'
                    - else:
                      - narrate '<&e>The NPC Id was not found on this server'
                  - else:
                    - narrate '<&e>The NPC Id is invalid'
                - else:
                  - if <player.selected_npc||<empty>> != <empty>:
                    - yaml id:drustcraft_shop set npc.<player.selected_npc.id>:<[shop_name]>
                    - run drustcraftt_npc.interactor def:<player.selected_npc.id>|drustcraftt_shop_interactor
                    - run drustcraftt_shop.save
                    - narrate '<&e>The NPC now sells items from the shop <&f><[shop_name]>'
                  - else:
                    - narrate '<&e>You require to enter a NPC Id or have an NPC selected'
              
              - case del delete rem remove:
                - define npc_id:<context.args.get[4]||<empty>>
                - if <[npc_id]> != <empty>:
                  - if <[npc_id].is_integer>:
                    - if <server.npcs.parse[id].contains[<[npc_id]>]>:
                      - yaml id:drustcraft_shop set npc.<[npc_id]>:!
                      - run drustcraftt_npc.interactor def:<[npc_id]>|<empty>
                      - run drustcraftt_shop.save
                      
                      - narrate '<&e>The NPC no longer sells items from the shop <&f><[shop_name]>'
                    - else:
                      - narrate '<&e>The NPC Id was not found on this server'
                  - else:
                    - narrate '<&e>The NPC Id is invalid'
                - else:
                  - if <player.selected_npc||<empty>> != <empty>:
                    - yaml id:drustcraft_shop set npc.<player.selected_npc.id>:!
                    - run drustcraftt_npc.interactor def:<player.selected_npc.id>|<empty>
                    - run drustcraftt_shop.save
                    - narrate '<&e>The NPC no longer sells items from the shop <&f><[shop_name]>'
                  - else:
                    - narrate '<&e>You require to enter a NPC Id or have an NPC selected'
              
              - default:
                - narrate '<&e>The shop npc action is unknown. Try <&lt>list|add|rem<&gt>'
          - else:
            - narrate '<&e>The shop <&f><[shop_name]> <&e>was not found'
        - else:
          - narrate '<&e>No shop name was entered'
      
      - case item:
        - define shop_name:<context.args.get[2]||<empty>>
        - if <[shop_name]> != <empty>:
          - if <yaml[drustcraft_shop].list_keys[shop].contains[<[shop_name]>]||false>:
            - choose <context.args.get[3]||<empty>>:
              - case list:
                - define page_no:<context.args.get[4]||1>
                - define item_list:<yaml[drustcraft_shop].read[shop.<[shop_name]>.items]||<list[]>>
                
                - run drustcraftt_chat_paginate 'def:<list[Shop <[shop_name]> Items|<[page_no]>].include_single[<[item_list]>].include[shop item <[shop_name]> list|<empty>|true|<empty>|shop item <[shop_name]> rem]>'
              
              - case add:
                - define item:<context.args.get[4]||<empty>>
                - if <[item]> != <empty>:
                  - if <server.material_types.parse[name].contains[<[item]>]>:
                    - if <yaml[drustcraft_shop].read[shop.<[shop_name]>.items].contains[<[item]>]||false> == false:
                      - yaml id:drustcraft_shop set shop.<[shop_name]>.items:->:<[item]>
                      - run drustcraftt_shop.save
                      - narrate '<&e>The shop <&f><[shop_name]> <&e>now sells <&f><[item]>'
                    - else:
                      - narrate '<&e>The item <&f><[item]> <&e>is already added to this shop'
                  - else:
                    - narrate '<&e>The item <&f><[item]> <&e>was not found on this server'
                - else:
                  - narrate '<&e>You require to enter a item to add to the shop'
              
              - case del delete rem remove:
                - define item:<context.args.get[4]||<empty>>
                - if <[item]> != <empty>:
                  - if <server.material_types.parse[name].contains[<[item]>]>:
                    - if <yaml[drustcraft_shop].read[shop.<[shop_name]>.items].contains[<item]>]||false>:
                      - yaml id:drustcraft_shop set shop.<[shop_name]>.items:<-:<[item]>
                      - run drustcraftt_shop.save
                      - narrate '<&e>The shop <&f><[shop_name]> <&e>no longer sells <&f><[item]>'
                    - else:
                      - narrate '<&e>The item <&f><[item]> <&e>is not listed in this shop'
                  - else:
                    - narrate '<&e>The item <&f><[item]> <&e>was not found on this server'
                - else:
                  - narrate '<&e>You require to enter a item to remove from the shop'
              
              - default:
                - narrate '<&e>The shop npc action is unknown. Try <&lt>list|add|rem<&gt>'
          - else:
            - narrate '<&e>The shop <&f><[shop_name]> <&e>was not found'
        - else:
          - narrate '<&e>No shop name was entered'
      
      - default:
        - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
        
        
drustcraftt_shop_interactor:
  type: task
  debug: false
  script:
    - define target_npc:<[1]>
    - define target_player:<[2]>
    - define action:<[3]>
  
    - choose <[action]||<empty>>:
      - case click:
        - define items:<list[]>
        - define shop_name:<yaml[drustcraft_shop].read[npc.<[target_npc].id>]||<empty>>
        
        - if <[shop_name]> != <empty>:
          - foreach <yaml[drustcraft_shop].read[shop.<[shop_name]>.items]||<list[]>>:
            - define item_value:<proc[drustcraftp_value.get].context[<[value]>].round_to[2]||0>
            - if <[item_value]> > 0:
              
              # buy item
              - define emerald_qty:1
              - define item_qty:1
              
              - if <[item_value]> < 1:
                - define item_qty:<element[1].div[<[item_value]>].round>
              - else:
                - define emerald_qty:<[item_value]>
                - while <[emerald_qty].round> != <[emerald_qty]>:
                  - define emerald_qty:+:<[item_value]>
                  - define item_qty:++
                
              - define cost_item:<item[emerald[quantity=<[emerald_qty]>]]>
              - define sell_item:<item[<[value]>[quantity=<[item_qty]>]]>
              
              - define trade_item:trade[inputs=<[cost_item]>|<item[air]>;result=<[sell_item]>;max_uses=9999]
              - define items:|:<[trade_item]>
              
              # sell item
              - define emerald_qty:1
              - define item_qty:1
              
              - define item_value:<[item_value].div[1.2].round_down_to_precision[0.01]>
              - if <[item_value]> < 1:
                - define item_qty:<element[1].div[<[item_value]>].round||1>
              - else:
                - define emerald_qty:<[item_value]>
                - while <[emerald_qty].round> != <[emerald_qty]>:
                  - define emerald_qty:+:<[item_value]>
                  - define item_qty:++
                
              - define cost_item:<item[emerald[quantity=<[emerald_qty]>]]>
              - define sell_item:<item[<[value]>[quantity=<[item_qty]>]]>
              
              - define trade_item:trade[inputs=<[sell_item]>|<item[air]>;result=<[cost_item]>;max_uses=9999]
              - define items:|:<[trade_item]>
              
            
          # - foreach <yaml[drustcraft_shop].list_keys[shops.<[target_npc].id>.items]||<list[]>>:
          #   - define available:<yaml[drustcraft_shop].read[shops.<[target_npc].id>.items.<[value]>.available]||<empty>>
          #   - define group:<yaml[drustcraft_shop].read[shops.<[target_npc].id>.items.<[value]>.in_group]||<empty>>
          #   
          #   - if <[available]> == <empty> || <[available].split[,].contains[<util.time_now.day_of_week>]||false>:
          #     - if <[group]> == <empty> || <[target_player].in_group[<[group]>]>:
          #       - define sell_item:<yaml[drustcraft_shop].read[shops.<[target_npc].id>.items.<[value]>.sell_item]||<empty>>
          #       - define sell_qty:<yaml[drustcraft_shop].read[shops.<[target_npc].id>.items.<[value]>.sell_qty]||1>
          #       - define sell_item:<item[<[sell_item]>[quantity=<[sell_qty]>]]>
          #       
          #       - define cost_item:<yaml[drustcraft_shop].read[shops.<[target_npc].id>.items.<[value]>.cost_item]||<empty>>
          #       - define cost_qty:<yaml[drustcraft_shop].read[shops.<[target_npc].id>.items.<[value]>.cost_qty]||1>
          #       - define cost_item:<item[<[cost_item]>[quantity=<[cost_qty]>]]>
          #       - define cost_item_b:<item[air]>
          #     
          #       - define trade_item:trade[inputs=<[cost_item]>|<[cost_item_b]>;result=<[sell_item]>;max_uses=9999]
          #       - define items:|:<[trade_item]>
        
        - if <[items].size> > 0:
          - opentrades <[items]>
        - else:
          - define greetings:<list[]>
          - define 'greetings:|:I have nothing to sell today'
          - define 'greetings:|:I am all sold out'
          - define 'greetings:|:I<&sq>ve got nothing left'
          
          - narrate <proc[drustcraftp_chat_format].context[<[target_npc]>|<[greetings].random>]>
        
        - determine false


drustcraftp_tab_complete_shop_names:
  type: procedure
  debug: false
  script:
    - determine <proc[drustcraftp_shop.list]>
