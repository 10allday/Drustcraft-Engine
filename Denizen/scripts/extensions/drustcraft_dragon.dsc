# Drustcraft - Dragon
# Dragon Travel
# https://github.com/drustcraft/drustcraft

drustcraftw_dragon:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_dragon.load
    
    on script reload:
      - run drustcraftt_dragon.load
    

drustcraftt_dragon:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <server.scripts.parse[name].contains[drustcraftw_npc]>:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_npc]>      
      
      - if <yaml.list.contains[drustcraft_dragon]>:
        - yaml unload id:drustcraft_dragon
    
      - if <server.has_file[/drustcraft_data/dragon.yml]>:
        - yaml load:/drustcraft_data/dragon.yml id:drustcraft_dragon
      - else:
        - yaml create id:drustcraft_dragon
        - yaml savefile:/drustcraft_data/dragon.yml id:drustcraft_dragon
      
      - foreach <yaml[drustcraft_dragon].list_keys[npcs]||<list[]>>:
        - define npc_id:<[value]>
        - ~run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_dragon_interactor
        
      - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
        - wait 2t
        - waituntil <yaml.list.contains[drustcraft_tab_complete]>
        
        - run drustcraftt_tab_complete.completions def:dragon|npc|_*npcs   

    - else:
      - debug log 'Drustcraft Dragon requires Drustcraft NPC installed'
        
  save:
    - yaml id:drustcraft_dragon savefile:/drustcraft_data/dragon.yml


drustcraftc_dragon:
  type: command
  debug: false
  name: dragon
  description: Modifies NPC dragon
  usage: /dragon <&lt>npc<&gt>
  permission: drustcraft.dragon
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:dragon
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case npc:
        - define npc_id:<context.args.get[2]||<empty>>
        - if <[npc_id]> != <empty>:
          - if <[npc_id].is_integer>:
            - if <server.npcs.parse[id].contains[<[npc_id]>]>:
              
              - if <yaml[drustcraft_dragon].list_keys[npcs].contains[<[npc_id]>]||false> == false:
                - yaml id:drustcraft_dragon set npcs.<[npc_id]>:ironport
                - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_dragon_interactor
                - run drustcraftt_dragon.save
                
              - narrate '<&e>The NPC is now a dragon agent'
            - else:
              - narrate '<&e>The NPC Id was not found on this server'
          - else:
            - narrate '<&e>The NPC Id is invalid'
        - else:
          - narrate '<&e>You require to enter a NPC Id'
      
      - default:
        - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
        
        
drustcraftt_dragon_interactor:
  type: task
  debug: false
  script:
    - define target_npc:<[1]>
    - define target_player:<[2]>
    - define action:<[3]>
  
    - choose <[action]||<empty>>:
      - case click:
        - execute as_server 'dt flight <yaml[drustcraft_dragon].read[npcs.<[target_npc].id>]> <[target_player].name>
        # - define slot_map:<yaml[drustcraft_bank].read[players.<[target_player].uuid>.slots]||<map[]>>
        # - note "in@generic[size=54;title=Bank Vault]" as:bank_<[target_player].uuid>
        # - inventory set d:in@bank_<player.uuid> o:<[slot_map]>
        # - inventory open d:in@bank_<player.uuid>
      - case entry:
        - if <[target_player].flag[drustcraft_firstspawn_dragon]||1> < 3:
          - flag <[target_player]> drustcraft_firstspawn_dragon:++
          - determine '<list[Hey <[target_player].name>, Im a Dragon travel agent|You can click on me to Travel.|Anything you store in your bank vault is safe and can be retrieved from any town bank you visit]>'