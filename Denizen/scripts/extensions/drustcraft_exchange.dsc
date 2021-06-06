# Drustcraft - Exchange
# Exchange
# https://github.com/drustcraft/drustcraft

drustcraftw_exchange:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_exchange.load
    
    on script reload:
      - run drustcraftt_exchange.load


drustcraftt_exchange:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <server.scripts.parse[name].contains[drustcraftw_npc]>:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_npc]>      
      
      - if <yaml.list.contains[drustcraft_exchange]>:
        - yaml unload id:drustcraft_exchange
    
      - if <server.has_file[/drustcraft_data/exchange.yml]>:
        - yaml load:/drustcraft_data/exchange.yml id:drustcraft_exchange
      - else:
        - yaml create id:drustcraft_exchange
        - yaml savefile:/drustcraft_data/exchange.yml id:drustcraft_exchange
      
      - foreach <yaml[drustcraft_exchange].read[npcs]||<list[]>>:
        - define npc_id:<[value]>
        - ~run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_exchange_interactor
        
      - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
        - wait 2t
        - waituntil <yaml.list.contains[drustcraft_tab_complete]>
        
        - run drustcraftt_tab_complete.completions def:exchange|npc|_*npcs

    - else:
      - debug log 'Drustcraft Exchange requires Drustcraft NPC installed'
        
  save:
    - yaml id:drustcraft_exchange savefile:/drustcraft_data/exchange.yml


drustcraftc_exchange:
  type: command
  debug: false
  name: exchange
  description: Modifies NPC exchange
  usage: /bank <&lt>npc<&gt>
  permission: drustcraft.exchange
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:exchange
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case npc:
        - define npc_id:<context.args.get[2]||<empty>>
        - if <[npc_id]> != <empty>:
          - if <[npc_id].is_integer>:
            - if <server.npcs.parse[id].contains[<[npc_id]>]>:
              
              - if <yaml[drustcraft_bank].read[npcs].contains[<[npc_id]>]||false> == false:
                - yaml id:drustcraft_exchange set npcs:->:<[npc_id]>
                - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_exchange_interactor
                - run drustcraftt_exchange.save
                
              - narrate '<&e>The NPC is now a exchange'
            - else:
              - narrate '<&e>The NPC Id was not found on this server'
          - else:
            - narrate '<&e>The NPC Id is invalid'
        - else:
          - narrate '<&e>You require to enter a NPC Id'
      
      - default:
        - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
        
        
drustcraftt_exchange_interactor:
  type: task
  debug: false
  script:
    - define target_npc:<[1]>
    - define target_player:<[2]>
    - define action:<[3]>
  
    - choose <[action]||<empty>>:
      - case click:
        - define items:<list[]>
        
        - define items:|:trade[inputs=<item[iron_ingot[quantity=4]]>|<item[air]>;result=<item[emerald]>;max_uses=9999]
        - define items:|:trade[inputs=<item[emerald]>|<item[air]>;result=<item[iron_ingot[quantity=4]]>;max_uses=9999]
        - define items:|:trade[inputs=<item[iron_ingot[quantity=4]]>|<item[air]>;result=<item[gold_ingot]>;max_uses=9999]
        - define items:|:trade[inputs=<item[gold_ingot]>|<item[air]>;result=<item[emerald]>;max_uses=9999]
        
        - define items:|:trade[inputs=<item[iron_ingot[quantity=36]]>|<item[air]>;result=<item[emerald_block]>;max_uses=9999]
        - define items:|:trade[inputs=<item[emerald[quantity=9]]>|<item[air]>;result=<item[emerald_block]>;max_uses=9999]
        - define items:|:trade[inputs=<item[emerald_block]>|<item[air]>;result=<item[emerald[quantity=9]]>;max_uses=9999]
        
        - define items:|:trade[inputs=<item[emerald[quantity=13]]>|<item[air]>;result=<item[netherite_ingot]>;max_uses=9999]
        - define items:|:trade[inputs=<item[netherite_ingot]>|<item[air]>;result=<item[emerald[quantity=13]]>;max_uses=9999]
        
        - define items:|:trade[inputs=<item[netherite_ingot[quantity=9]]>|<item[air]>;result=<item[netherite_block]>;max_uses=9999]
        - define items:|:trade[inputs=<item[emerald_block[quantity=13]]>|<item[air]>;result=<item[netherite_block]>;max_uses=9999]
        - define items:|:trade[inputs=<item[netherite_block]>|<item[air]>;result=<item[netherite_ingot[quantity=9]]>;max_uses=9999]
        - define items:|:trade[inputs=<item[netherite_block]>|<item[air]>;result=<item[emerald_block[quantity=13]]>;max_uses=9999]

        - if <[items].size> > 0:
          - opentrades <[items]> 'title:Currency Exchange'

