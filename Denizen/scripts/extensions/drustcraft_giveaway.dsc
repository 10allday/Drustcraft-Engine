# Drustcraft - Giveaway
# Giveaway
# https://github.com/drustcraft/drustcraft

drustcraftw_giveaway:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_giveaway.load
    
    on script reload:
      - run drustcraftt_giveaway.load
    

drustcraftt_giveaway:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <server.scripts.parse[name].contains[drustcraftw_npc]>:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_npc]>      
      
      - if <yaml.list.contains[drustcraft_giveaway]>:
        - yaml unload id:drustcraft_giveaway
    
      - if <server.has_file[/drustcraft_data/giveaway.yml]>:
        - yaml load:/drustcraft_data/giveaway.yml id:drustcraft_giveaway
      - else:
        - yaml create id:drustcraft_giveaway
        - yaml savefile:/drustcraft_data/giveaway.yml id:drustcraft_giveaway
      
      - foreach <yaml[drustcraft_giveaway].read[npcs]||<list[]>>:
        - define npc_id:<[value]>
        - ~run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_giveaway_interactor
        
      - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
        - wait 2t
        - waituntil <yaml.list.contains[drustcraft_tab_complete]>
        
        - run drustcraftt_tab_complete.completions def:giveaway|npc|_*npcs

    - else:
      - debug log 'Drustcraft Giveaway requires Drustcraft NPC installed'
        
  save:
    - yaml id:drustcraft_giveaway savefile:/drustcraft_data/giveaway.yml
    

drustcraftp_giveaway:
  type: procedure
  debug: false
  script:
    - determine <empty>
  
  get_items:
    - define target_npc:<[1]||<empty>>
    - define target_player:<[2]||<empty>>
    - define item_list:<list[]>
    
    - if !<[target_player].inventory.contains_item[*_boat]>:
      - define item_list:|:<list[<item[oak_boat]>|<item[spruce_boat]>|<item[birch_boat]>|<item[jungle_boat]>|<item[acacia_boat]>|<item[dark_oak_boat]>].random>
    - if !<[target_player].inventory.contains_item[apple]>:
      - define item_list:|:<item[apple[quantity=<util.random.int[1].to[3]>]]>
    - if !<[target_player].inventory.contains_item[*_sword]>:
      - define item_list:|:<item[wooden_sword]>
    - if !<[target_player].inventory.contains_item[*_pickaxe]>:
      - define item_list:|:<item[wooden_pickaxe]>
    - if !<[target_player].inventory.contains_item[*_axe]>:
      - define item_list:|:<item[wooden_axe]>
    
    - define give_iron:false
    - if !<[target_player].inventory.contains_item[netherrite_block]> && !<[target_player].inventory.contains_item[emerald_block]> && !<[target_player].inventory.contains_item[emerald]> && !<[target_player].inventory.contains_item[gold_block]> && !<[target_player].inventory.contains_item[iron_block]> && !<[target_player].inventory.contains_item[diamond]> && !<[target_player].inventory.contains_item[*_ingot]>:
      - define give_iron:true
    - define has_iron:<[target_player].inventory.quantity_item[iron_ingot]>    
    - if <[give_iron]> && <[has_iron]> < 4:
      - define iron_quantity:<util.random.int[2].to[6].sub[<[has_iron]>]>
      - if <[iron_quantity]> > 0:
        - define item_list:|:<item[iron_ingot[quantity=<[iron_quantity]>]]>
      
    - determine <[item_list]>
    

drustcraftc_giveaway:
  type: command
  debug: false
  name: giveaway
  description: Modifies NPC giveaway
  usage: /giveaway <&lt>npc<&gt>
  permission: drustcraft.giveaway
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:giveaway
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case npc:
        - define npc_id:<context.args.get[2]||<empty>>
        - if <[npc_id]> != <empty>:
          - if <[npc_id].is_integer>:
            - if <server.npcs.parse[id].contains[<[npc_id]>]>:
              
              - if <yaml[drustcraft_giveaway].read[npcs].contains[<[npc_id]>]||false> == false:
                - yaml id:drustcraft_giveaway set npcs:->:<[npc_id]>
                - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_giveaway_interactor
                - run drustcraftt_giveaway.save
                
              - narrate '<&e>The NPC is now a giveaway'
            - else:
              - narrate '<&e>The NPC Id was not found on this server'
          - else:
            - narrate '<&e>The NPC Id is invalid'
        - else:
          - narrate '<&e>You require to enter a NPC Id'
      
      - default:
        - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
        
        
drustcraftt_giveaway_interactor:
  type: task
  debug: false
  script:
    - define target_npc:<[1]>
    - define target_player:<[2]>
    - define action:<[3]>
  
    - choose <[action]||<empty>>:
      - case click:
        - define items:<proc[drustcraftp_giveaway.get_items].context[<[target_npc]>|<[target_player]>]>
        - if <[items].size> > 0:
          - foreach <[items]>:
            - if <[target_player].inventory.can_fit[<[value]>]>:
              - give <[value]> to:<[target_player].inventory>
              - narrate '<&e>Received <[value].quantity||1> x <[value].material.translated_name>'
            - else:
              - narrate '<&e>You didnt have room for <[value].quantity||1> x <[value].material.translated_name>'
        - else:
          - narrate '<proc[drustcraftp_chat_format].context[<[target_npc]>|I aint got nothing for ya!]>' targets:<[target_player]>
          - determine false
          
      - case entry:
        - define items:<proc[drustcraftp_giveaway.get_items].context[<[target_npc]>|<[target_player]>]>
        - define can_fit_all:true
        - define can_fit_any:false
        
        - foreach <[items]>:
          - if <[target_player].inventory.can_fit[<[value]>]>:
            - define can_fit_any:true
          - else:
            - define can_fit_all:false
        
        - if <[items].size> > 0:
          - if <[can_fit_any]>:
            - determine '<list[Psst, hey, need to get off this island?|Need something, I<&sq>ve got a few things]>'
