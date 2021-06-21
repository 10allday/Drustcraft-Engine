  # Drustcraft - Plot
# Town Plots
# https://github.com/drustcraft/drustcraft

drustcraftw_plot:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_plot.load
    
    on script reload:
      - run drustcraftt_plot.load
    
    on player drops item:
      - if <context.item.is_book> && <context.item.book_title.strip_color.starts_with[Plot<&sp>Deed:<&sp>]>:
        - define plot_name:<context.item.lore.space_separated.after[id:]||<empty>>
        - if <[plot_name]> != <empty>:
          - run drustcraftt_plot.drop def:<[plot_name]>
          - run drustcraftt_plot.save


    on player picks up item:
      - if <context.item.is_book> && <context.item.book_title.strip_color.starts_with[Plot<&sp>Deed:<&sp>]>:
        - define plot_name:<context.item.lore.space_separated.after[id:]||<empty>>
        - if <[plot_name]> != <empty>:
          - run drustcraftt_plot.owner def:<[plot_name]>|<player.uuid>
          - run drustcraftt_plot.save


    on player opens inventory:
      - foreach <context.inventory.map_slots>:
        - if <[value].is_book> && <[value].book_title.strip_color.starts_with[Plot<&sp>Deed:<&sp>]>:
          - define plot_name:<[value].lore.space_separated.after[id:]||<empty>>
          - if <[plot_name]> != <empty>:
            - if <proc[drustcraftp_plot.list].contains[<[plot_name]>]||false> == false:
              - inventory set slot:<[key]> o:air d:<context.inventory>
              

    # on player closes inventory:
      # todo remove NPC trading_with flag
      
#       - if <context.inventory.inventory_type> == MERCHANT:
#         - if <player.has_flag[drustcraft_trading_with]>:
#           - define target_npc:<player.flag[drustcraft_trading_with]>
#           - flag <player> drustcraft_trading_with:!
#           - flag <[target_npc]> drustcraft_trading_with:!
# 
#         - foreach <context.inventory.map_slots>:
#           - if <[value].is_book> && <[value].book_title.strip_color.starts_with[Plot<&sp>Deed:<&sp>]>:
#             - define plot_name:<[value].lore.space_separated.after[id:]||<empty>>
#             - if <[plot_name]> != <empty>:
#               - define owner_uuid:<proc[drustcraftp_plot.owner].context[<[plot_name]>]>
#               - if <[owner_uuid]> != <empty> && <[owner_uuid]> != <player.uuid>:
#                 - narrate '<&e>That plot has already been purchased by <&f><player[<[owner_uuid]>].name>'
#                 - inventory set slot:<[key]> o:air d:<context.inventory>
#                 - give emerald quantity:20 to:<player.inventory>
#                 # todo refund purchase
#               - else:
#                 - narrate HERE targets:<server.online_players>
#                 - run drustcraftt_plot.owner def:<[plot_name]>|<player.uuid>
#       
#       - run drustcraftt_plot.save
    
    on system time hourly:
      - run drustcraftt_plot.update
            
drustcraftt_plot:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <server.scripts.parse[name].contains[drustcraftw_npc]>:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_npc]>      
      
      - if <yaml.list.contains[drustcraft_plot]>:
        - yaml unload id:drustcraft_plot
    
      - if <server.has_file[/drustcraft_data/plots.yml]>:
        - yaml load:/drustcraft_data/plots.yml id:drustcraft_plot
      - else:
        - yaml create id:drustcraft_plot
        - yaml savefile:/drustcraft_data/plots.yml id:drustcraft_plot
      
      - foreach <yaml[drustcraft_plot].list_keys[plots]||<list[]>>:
        - define npc_id:<yaml[drustcraft_plot].read[plots.<[value]>.npc]||0>
        - define owner:<yaml[drustcraft_plot].read[plots.<[value]>.owner]||<empty>>
        - if <[npc_id]> != 0:
          - ~run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_plot_interactor
        - run drustcraftt_plot.owner def:<[value]>|<[owner]>
        
      - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
        - wait 2t
        - waituntil <yaml.list.contains[drustcraft_tab_complete]>
        
        - run drustcraftt_tab_complete.completions def:plot|list
        - run drustcraftt_tab_complete.completions def:plot|info|_*plot_names        
        - run drustcraftt_tab_complete.completions def:plot|create
        - run drustcraftt_tab_complete.completions def:plot|remove|_*plot_names
        - run drustcraftt_tab_complete.completions def:plot|npc|_*plot_names|_*npcs
        - run drustcraftt_tab_complete.completions def:plot|cost|_*plot_names|_*int
        - run drustcraftt_tab_complete.completions def:plot|sign
      

    - else:
      - debug log 'Drustcraft Plots requires Drustcraft NPC installed'
        
  save:
    - yaml id:drustcraft_plot savefile:/drustcraft_data/plots.yml
  
  
  create:
    - define plot_name:<[1]||<empty>>
    - define plot_region_name:<[2]||<empty>>
    - define plot_region_world:<[3]||<empty>>
    - if <[plot_name]> != <empty> && <[plot_region_name]> != <empty> && <[plot_region_world]> != <empty>:
      - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false> == false:
        - yaml id:drustcraft_plot set plots.<[plot_name]>.owner:<element[]>
        - yaml id:drustcraft_plot set plots.<[plot_name]>.region:<[plot_region_name]>
        - yaml id:drustcraft_plot set plots.<[plot_name]>.world:<[plot_region_world]>
        - run drustcraftt_plot.save
  
  
  remove:
    - define plot_name:<[1]||<empty>>
    - if <[plot_name]> != <empty>:
      - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
        - run drustcraftt_plot.sign_update def:<[plot_name]>|true
        - yaml id:drustcraft_plot set plots.<[plot_name]>:!
        - run drustcraftt_plot.save
  

  npc:
    - define plot_name:<[1]||<empty>>
    - define plot_npc_id:<[2]||<empty>>
    - if <[plot_name]> != <empty> && <[plot_npc_id].is_integer>:
      - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
        - yaml id:drustcraft_plot set plots.<[plot_name]>.npc:<[plot_npc_id]>
        - run drustcraftt_plot.save
  

  address:
    - define plot_name:<[1]||<empty>>
    - define plot_address:<[2]||<empty>>
    - if <[plot_name]> != <empty> && <[plot_address]> != <empty>:
      - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
        - yaml id:drustcraft_plot set plots.<[plot_name]>.address:<[plot_address]>
        - run drustcraftt_plot.sign_update def:<[plot_name]>
        - run drustcraftt_plot.save
  
  
  sign:
    - define plot_name:<[1]||<empty>>
    - define plot_sign:<[2]||<empty>>
    - if <[plot_name]> != <empty> && <[plot_sign]> != <empty>:
      - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
        - run drustcraftt_plot.sign_update def:<[plot_name]>|true
        - ~yaml id:drustcraft_plot set plots.<[plot_name]>.sign:<[plot_sign].round>
        - run drustcraftt_plot.sign_update def:<[plot_name]>
        - run drustcraftt_plot.save
  
  
  sign_update:
    - define plot_name:<[1]||<empty>>
    - define clear:<[2]||false>
    
    - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
      - define plot_info:<proc[drustcraftp_plot.info].context[<[plot_name]>]>
      
      - if <[plot_info].get[sign]> != <empty>:
        - if <[clear]> == false:
          - if <[plot_info].get[owner]> != <empty>:
            - sign type:automatic '<&6><[plot_info].get[address]>| |<&7>Owner|<player[<[plot_info].get[owner]>].name>' <[plot_info].get[sign]>
          - else:
            - sign type:automatic '<&6>For Sale|<[plot_info].get[address]>| |<[plot_info].get[cost]> emeralds' <[plot_info].get[sign]>
        - else:
          - sign type:automatic '| | | ' <[plot_info].get[sign]>
  

  cost:
    - define plot_name:<[1]||<empty>>
    - define plot_cost:<[2]||<empty>>
    - if <[plot_name]> != <empty> && <[plot_cost].is_integer>:
      - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
        - yaml id:drustcraft_plot set plots.<[plot_name]>.cost:<[plot_cost]>
        - run drustcraftt_plot.sign_update def:<[plot_name]>
        - run drustcraftt_plot.save
  

  owner:
    - define plot_name:<[1]||<empty>>
    - define plot_owner:<[2]||<empty>>
    
    - if <[plot_name]> != <empty>:
      - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
        - define plot_region:<yaml[drustcraft_plot].read[plots.<[plot_name]>.region]||<empty>>
        - define plot_world:<yaml[drustcraft_plot].read[plots.<[plot_name]>.world]||<empty>>
        
        - yaml id:drustcraft_plot set plots.<[plot_name]>.drop:!
        - yaml id:drustcraft_plot set plots.<[plot_name]>.owner:<[plot_owner]>

        - if <[plot_region]> != <empty> && <[plot_world]> != <empty>:
          - execute as_server 'rg removemember <[plot_region]> -w <[plot_world]> -a'
          
          - if <[plot_owner]> != <empty>:
            - execute as_server 'rg addmember <[plot_region]> -w <[plot_world]> <player[<[plot_owner]>].name>'
            
          - define info:<proc[drustcraftp_plot.info].context[<[plot_name]>]>
          - run drustcraftt_plot.sign_update def:<[plot_name]>
          - run drustcraftt_plot.save
        
  
  drop:
    - define plot_name:<[1]||<empty>>
    
    - if <[plot_name]> != <empty>:
      - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
        - yaml id:drustcraft_plot set plots.<[plot_name]>.drop:<util.time_now.epoch_millis.div[1000].round>
        - run drustcraftt_plot.save
  
  
  update:
    - define dirty:false
    
    - foreach <yaml[drustcraft_plot].list_keys[plots]||<empty>>:
      - define plot_name:<[value]>
      - define now:<util.time_now.epoch_millis.div[1000].round>
      
      - if <[now].sub[<yaml[drustcraft_plot].read[plots.<[plot_name]>.drop]||0>]> > 300:
        - run drustcraftt_plot.owner def:<[plot_name]>
        - yaml id:drustcraft_plot set plots.<[plot_name]>.drop:!
        - define dirty:true
    
    - if <[dirty]> == true:
      - run drustcraftt_plot.save



drustcraftp_plot:
  type: procedure
  debug: false
  script:
    - determine <empty>
  
  info:
    - define plot_name:<[1]||<empty>>
    - define plot_info:<map[]>

    - define plot_info:<[plot_info].with[owner].as[<yaml[drustcraft_plot].read[plots.<[plot_name]>.owner]||<empty>>]>
    - define plot_info:<[plot_info].with[region].as[<yaml[drustcraft_plot].read[plots.<[plot_name]>.region]||<empty>>]>
    - define plot_info:<[plot_info].with[npc].as[<yaml[drustcraft_plot].read[plots.<[plot_name]>.npc]||<empty>>]>
    - define plot_info:<[plot_info].with[address].as[<yaml[drustcraft_plot].read[plots.<[plot_name]>.address]||<empty>>]>
    - define plot_info:<[plot_info].with[cost].as[<yaml[drustcraft_plot].read[plots.<[plot_name]>.cost]||20>]>
    - define plot_info:<[plot_info].with[sign].as[<yaml[drustcraft_plot].read[plots.<[plot_name]>.sign]||<empty>>]>
    - determine <[plot_info]>
  
  list:
    - determine <yaml[drustcraft_plot].list_keys[plots]||<list[]>>
  
  owner:
    - define plot_name:<[1]||<empty>>
    - determine <yaml[drustcraft_plot].read[plots.<[plot_name]>.owner]||<empty>>
    
  cost:
    - define plot_name:<[1]||<empty>>
    - determine <yaml[drustcraft_plot].read[plots.<[plot_name]>.cost]||20>
    
  address:
    - define plot_name:<[1]||<empty>>
    - determine <yaml[drustcraft_plot].read[plots.<[plot_name]>.address]||<[plot_name]>>


drustcraftc_plot:
  type: command
  debug: false
  name: plot
  description: Modifies town plots
  usage: /plot <&lt>list|create<&gt>
  permission: drustcraft.plot
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:plot
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case list:
        - define page_no:<context.args.get[2]||1>
        - run drustcraftt_chat_paginate 'def:<list[Plots|<[page_no]>].include_single[<proc[drustcraftp_plot.list]>].include[plot list|plot info]>'

      - case info:
        - define plot_name:<context.args.get[2]||<empty>>
        - if <[plot_name]> != <empty>:
          - run drustcraftt_chat_gui.title 'def:Plot: <[plot_name]>'
          
          - define plot_info:<proc[drustcraftp_plot.info].context[<[plot_name]>]>
          - if <[plot_info]> != <empty>:
            
            # Owner
            - define owner:<[plot_info].get[owner]||<empty>>
            - define owner:<player[<[owner]>].name||<&c>(none)>
            - define 'row:<&9>Owner: <&6><[owner]> <element[<&7><&lb>Edit<&rb>].on_click[/plot setowner <[plot_name]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
            - narrate <[row]>
            
            # Region
            - define region:<[plot_info].get[region]||<empty>>
            #- define npc:<npc[<[owner]>].name||<&c>(none)>
            - define 'row:<&9>Region: <&6><[region]> <element[<&7><&lb>Edit<&rb>].on_click[/plot npc <[plot_name]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]> <element[<&c><&lb>Rem<&rb>].on_click[/plot remnpc <[plot_name]>].on_hover[Click to remove]>'
            - narrate <[row]>

            # Address
            - define address:<[plot_info].get[address]||<&c>(none)>
            - define 'row:<&9>Address: <&6><[address]> <element[<&7><&lb>Edit<&rb>].on_click[/plot address <[plot_name]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
            - narrate <[row]>

            # NPC
            - define plot_npc:<[plot_info].get[npc]||<empty>>
            - define plot_npc:<npc[<[plot_npc]>].name||<&c>(none)>
            - define 'row:<&9>NPC: <&6><[plot_npc]> <element[<&7><&lb>Edit<&rb>].on_click[/plot npc <[plot_name]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]> <element[<&c><&lb>Rem<&rb>].on_click[/plot remnpc <[plot_name]>].on_hover[Click to remove]>'
            - narrate <[row]>
            
            # Cost
            - define plot_cost:<[plot_info].get[cost]||<empty>>
            - define 'row:<&9>Cost: <&6><[plot_cost]> emeralds <element[<&7><&lb>Edit<&rb>].on_click[/plot cost <[plot_name]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
            - narrate <[row]>
            
            # Sign
            - define plot_sign:<[plot_info].get[sign]||<empty>>
            - if <[plot_sign]> == <empty>:
              - define plot_sign:<&c>(none)
            - define 'row:<&9>Sign: <&6><[plot_sign]> <element[<&7><&lb>Edit<&rb>].on_click[/plot sign <[plot_name]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
            - narrate <[row]>
            
          - else:
            - narrate '<&e>There was an error getting the plot information'
        - else:
          - narrate '<&e>No plot name was entered'
      
      - case create:
        - define plot_name:<context.args.get[2]||<empty>>
        - if <[plot_name]> != <empty>:
          - if <proc[drustcraftp_plot.list].contains[<[plot_name]>]||false> == false:
            - define plot_region:<context.args.get[3]||<empty>>
            - define plot_world:<context.args.get[4]||<empty>>
            
            - if <[plot_region]> != <empty>: 
              - if <[plot_world]> == <empty>:
                - if <player||<empty>> != <empty>:
                  - define plot_world:<player.location.world.name>
                - else:
                  - narrate '<&e>A world name is required when creating a plot from the console'
              
              - if <[plot_world]> != <empty>:
                - if <proc[drustcraftp_region.list].context[<[plot_world]>].contains[<[plot_region]>]>:
                  - run drustcraftt_plot.create def:<[plot_name]>|<[plot_region]>|<player.location.world.name>
                  - run drustcraftt_plot.save
                  - execute as_server 'rg flag <[plot_region]> -w <player.location.world.name> -g nonmembers build deny'
                  - execute as_server 'rg removemember <[plot_region]> -w <player.location.world.name> -a'
                  - execute as_server 'rg removeowner <[plot_region]> -w <player.location.world.name> -a'
                  - narrate '<&e>The plot <&f><[plot_name]> <&e>was created'
                  - narrate '<&e>The build flag for non members has been set to deny for the region <&f><[plot_name]>'
                  - narrate '<&e>Removed all members from the region <&f><[plot_name]>'
                - else:
                  - narrate '<&e>The plot region name <[plot_region]> was not found in world <[plot_world]>'
            - else:
              - narrate '<&e>A plot region name is required when creating a plot'
          - else:
            - narrate '<&e>A unique name is required when creating a plot'
        - else:
          - narrate '<&e>A unique name is required when creating a plot'
        
        
      - case remove:
        - define plot_name:<context.args.get[2]||<empty>>
        - if <[plot_name]> != <empty>:
          - if <proc[drustcraftp_plot.list].contains[<[plot_name]>]||false> == true:
            - run drustcraftt_plot.remove def:<[plot_name]>
            - narrate '<&e>The plot has been removed'
            - narrate '<&e>No changes have been made to the plots WorldGuard region'
          - else:
            - narrate '<&e>That plot does not exist'
        - else:
          - narrate '<&e>A plot name is required when removing a plot'
        
        
      # todo
      # - case remove delete del:
      #   - define name:<context.args.get[2]||<empty>>
      #   - if <[name]> != <empty>:
      #     - if <yaml[drustcraft_shop].list_keys[shop].contains[<[name]>]||false>:
      #       - yaml id:drustcraft_shop set shop.<[name]>:!
      #       - run drustcraftt_shop.save
      #       - narrate '<&e>The shop <&f><[name]> <&e>was deleted'
      #     - else:
      #       - narrate '<&e>The shop <&f><[name]> <&e>was not found'
      #   - else:
      #     - narrate '<&e>A shop name is required when deleting a shop'
      
      # todo
      # - case setowner:
      #   - define shop_name:<context.args.get[2]||<empty>>
      #   - if <[shop_name]> != <empty>:
      #     - if <yaml[drustcraft_shop].list_keys[shop].contains[<[shop_name]>]||false>:
      #       - define player_name:<context.args.get[3]||<empty>>
      #       - if <[player_name]> != <empty>:
      #         - define target_player:<server.match_offline_player[<[player_name]>]>
      #         - if <[target_player].object_type> == Player && <[target_player].name> == <[player_name]>:
      #           - yaml id:drustcraft_shop set shop.<[shop_name]>.owner:<[target_player].uuid>
      #           - run drustcraftt_shop.save
      #           - narrate '<&e>The shop owner was updated'
      #         - else:
      #           - narrate '<&e>The player <&f><[player_name]> <&e>was not found on this server'
      #       - else:
      #         - narrate '<&e>A new owner is required to be entered'
      #     - else:
      #       - narrate '<&e>The shop <&f><[shop_name]> <&e>was not found'
      #   - else:
      #     - narrate '<&e>No shop name was entered'
      
      - case npc:
        - define plot_name:<context.args.get[2]||<empty>>
        - if <[plot_name]> != <empty>:
          - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
            - define npc_id:<context.args.get[3]||<empty>>
            - if <[npc_id]> != <empty>:
              - if <[npc_id].is_integer>:
                - if <server.npcs.parse[id].contains[<[npc_id]>]>:
                  - run drustcraftt_plot.npc def:<[plot_name]>|<[npc_id]>
                  - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_plot_interactor                  
                  - run drustcraftt_plot.save
                  - narrate '<&e>The NPC now sells the plot <&f><[plot_name]>'
                - else:
                  - narrate '<&e>The NPC Id was not found on this server'
              - else:
                - narrate '<&e>The NPC Id is invalid'
            - else:
              - narrate '<&e>You require to enter a NPC Id'
          - else:
            - narrate '<&e>The plot <&f><[plot_name]> <&e>was not found'
        - else:
          - narrate '<&e>No plot name was entered'
      
      - case cost:
        - define plot_name:<context.args.get[2]||<empty>>
        - if <[plot_name]> != <empty>:
          - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
            - define cost:<context.args.get[3]||<empty>>
            - if <[cost]> != <empty>:
              - if <[cost].is_integer>:
                - run drustcraftt_plot.cost def:<[plot_name]>|<[cost]>
                - run drustcraftt_plot.save
                - narrate '<&e>The plot <&f><[plot_name]> <&e>now sells for <&f><[cost]> <&e>emeralds'
              - else:
                - narrate '<&e>The cost is invalid'
            - else:
              - narrate '<&e>You require to enter a cost'
          - else:
            - narrate '<&e>The plot <&f><[plot_name]> <&e>was not found'
        - else:
          - narrate '<&e>No plot name was entered'
      
      - case address:
        - define plot_name:<context.args.get[2]||<empty>>
        - if <[plot_name]> != <empty>:
          - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
            - define address:<context.args.remove[1|2].space_separated||<empty>>
            - if <[address]> != <empty>:
              - run drustcraftt_plot.address def:<[plot_name]>|<[address]>
              - run drustcraftt_plot.save
              - narrate '<&e>The plot <&f><[plot_name]> <&e>address is now <&f><[address]>'
            - else:
              - narrate '<&e>You require to enter an address'
          - else:
            - narrate '<&e>The plot <&f><[plot_name]> <&e>was not found'
        - else:
          - narrate '<&e>No plot name was entered'
      
      - case sign:
        - define plot_name:<context.args.get[2]||<empty>>
        - if <[plot_name]> != <empty>:
          - if <yaml[drustcraft_plot].list_keys[plots].contains[<[plot_name]>]||false>:
            - if <player.cursor_on.material.contains[sign]>:
              - run drustcraftt_plot.sign def:<[plot_name]>|<player.cursor_on>
              - run drustcraftt_plot.save
              - run drustcraftt_plot.owner def:<[plot_name]>|<proc[drustcraftp_plot.owner].context[<[plot_name]>]>
              - narrate '<&e>The plot <&f><[plot_name]> <&e>sign is updated'
            - else:
              - narrate '<&e>Your cursor is not on a sign'
          - else:
            - narrate '<&e>The plot <&f><[plot_name]> <&e>was not found'
        - else:
          - narrate '<&e>No plot name was entered'

      
      - default:
        - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
        
        
drustcraftt_plot_interactor:
  type: task
  debug: false
  script:
    - define target_npc:<[1]>
    - define target_player:<[2]>
    - define action:<[3]>
    - define target_inventory:<[4]||<empty>>
  
    - choose <[action]||<empty>>:
      - case click:
        - define items:<list[]>

        - if <[target_npc].has_flag[drustcraft_trading_with]> && <server.online_players.contains[<[target_npc].flag[drustcraft_trading_with]>]> && <[target_player]> != <[target_npc].flag[drustcraft_trading_with]>:
          - define player_name:<[target_npc].flag[drustcraft_trading_with].name>
          - define greetings:<list[]>
          - define 'greetings:|:Hey, Im talking to <[player_name]>'
          - define 'greetings:|:One sec, Im trading with <[player_name]> first'
          
          - narrate <proc[drustcraftp_chat_format].context[<[target_npc]>|<[greetings].random>]>
          - determine false
        
        - foreach <yaml[drustcraft_plot].list_keys[plots]||<list[]>>:
          - define plot_name:<[value]>

          - if <yaml[drustcraft_plot].read[plots.<[plot_name]>.npc]||0> == <[target_npc].id> && <proc[drustcraftp_plot.owner].context[<[plot_name]>]> == <empty> && <proc[drustcraftp_plot.address].context[<[plot_name]>]> != <empty>:
            - define 'book_title:<&3>Plot Deed<&co> <proc[drustcraftp_plot.address].context[<[plot_name]>]>'
            - define book_author:<&e><[target_npc].name>
            - define 'book_pages:<list_single[<&3><bold>Congratulations<&nl>Land Owner!<p><&0>You are the proud owner of:<p><&6><proc[drustcraftp_plot.address].context[<[plot_name]>]><p>|<&c><bold>Owners notice<p><&0>As long as you hold this deed, only you can build, destory, and open items such as chests and doors on this plot.<p>If you give this deed to someone else, then they become the new plot owners!]>'
            - define 'lore:<&nl>Only holder of this deed is able<&nl>to buildand open items in this plot<&nl><element[<&0>id:<[plot_name]>].split_lines[40]||<empty>>'
              
            - define book_map:<map.with[title].as[<[book_title]>].with[author].as[<[book_author]>].with[pages].as[<[book_pages]>]>
            - define plotdeed:<item[drustcraft_plotdeed[book=<[book_map]>;lore=<[lore]>]]>

            - define emerald_qty:<proc[drustcraftp_plot.cost].context[<[plot_name]>]||20>
            - define item_qty:1
            
            - define cost_item:<item[emerald[quantity=<[emerald_qty]>]]>
            - define sell_item:<item[<[plotdeed]>]>
            - define trade_item:trade[inputs=<[cost_item]>|<item[air]>;result=<[sell_item]>;max_uses=1]
            - define items:|:<[trade_item]>
            
        - foreach <[target_player].inventory.map_slots>:
          - if <[value].is_book> && <[value].book_title.strip_color.starts_with[Plot<&sp>Deed:<&sp>]>:
            - define plot_name:<[value].lore.space_separated.after[id:]||<empty>>
            - if <[plot_name]> != <empty>:
              - define sell_item:<item[emerald[quantity=<proc[drustcraftp_plot.cost].context[<[plot_name]>]>]]>
              - define trade_item:trade[inputs=<[value]>|<item[air]>;result=<[sell_item]>;max_uses=1]
              - define items:|:<[trade_item]>
              
        - if <[items].size> > 0:
          - flag <[target_npc]> drustcraft_trading_with:<[target_player]>
          - flag <[target_player]> drustcraft_trading_with:<[target_npc]>
          - opentrades <[items]>
        - else:
          - define greetings:<list[]>
          - define 'greetings:|:I have nothing to sell today'
          - define 'greetings:|:I am all sold out of plots'
          - define 'greetings:|:I<&sq>ve got nothing left'
          
          - narrate <proc[drustcraftp_chat_format].context[<[target_npc]>|<[greetings].random>]>
        
        - determine false

      - case close:
        - if <[target_npc].flag[drustcraft_trading_with]> == <[target_player]>:
          - flag <[target_npc]> drustcraft_trading_with:!
        
        - if <[target_player].has_flag[drustcraft_trading_with]> == <[target_npc]>:
          - flag <[target_player]> drustcraft_trading_with:!

        - foreach <[target_inventory].trades>:
          - if <[value].uses> > 0:
            - define item:<[value].result||<empty>>
            - if <[item].is_book> && <[item].book_title.strip_color.starts_with[Plot<&sp>Deed:<&sp>]>:
              - define plot_name:<[item].lore.space_separated.after[id:]||<empty>>            
              - define owner_uuid:<proc[drustcraftp_plot.owner].context[<[plot_name]>]>
              - define plot_address:<proc[drustcraftp_plot.address].context[<[plot_name]>]>
              - if <[owner_uuid]> != <empty> && <[owner_uuid]> != <player.uuid>:
                - narrate '<&e>The plot <[plot_address]> has already been purchased by <&f><player[<[owner_uuid]>].name>' targets:<[target_player]>
                - take <[item]> from:<[target_player].inventory>
                - give emerald quantity:<proc[drustcraftp_plot.cost].context[<[plot_name]>]> to:<[target_player].inventory>
              - else:
                - narrate 'Bought <[plot_address]>' targets:<[target_player]>
                - run drustcraftt_plot.owner def:<[plot_name]>|<[target_player].uuid>
  
            - foreach <[value].inputs||<empty>> as:item:
              - if <[item].is_book> && <[item].book_title.strip_color.starts_with[Plot<&sp>Deed:<&sp>]>:
                - define plot_name:<[item].lore.space_separated.after[id:]||<empty>>
                - define plot_address:<proc[drustcraftp_plot.address].context[<[plot_name]>]>
                - narrate 'Sold <[plot_address]>' targets:<[target_player]>
                - run drustcraftt_plot.owner def:<[plot_name]>
  

drustcraftp_tab_complete_plot_names:
  type: procedure
  debug: false
  script:
    - determine <proc[drustcraftp_plot.list]>


drustcraft_plotdeed:
  type: book
  title: Plot Deed
  author: Plot Deed
  signed: true
  text:
  - You should not be seeing this padiwan. Can you report how you got it using the command /report please?