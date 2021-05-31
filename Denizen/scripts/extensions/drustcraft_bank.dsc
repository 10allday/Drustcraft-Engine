# Drustcraft - Bank
# Banker
# https://github.com/drustcraft/drustcraft

drustcraftw_bank:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_bank.load
    
    on script reload:
      - run drustcraftt_bank.load
    
    on player closes inventory:
      - if '<context.inventory.title.starts_with[Bank Vault]>':
        - define slot_map:<context.inventory.map_slots>
        - note remove as:bank_<player.uuid>
        - ~yaml id:drustcraft_bank set players.<player.uuid>.slots:<[slot_map]>
        - run drustcraftt_bank.save


drustcraftt_bank:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <server.scripts.parse[name].contains[drustcraftw_npc]>:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_npc]>      
      
      - if <yaml.list.contains[drustcraft_bank]>:
        - yaml unload id:drustcraft_bank
    
      - if <server.has_file[/drustcraft_data/bank.yml]>:
        - yaml load:/drustcraft_data/bank.yml id:drustcraft_bank
      - else:
        - yaml create id:drustcraft_bank
        - yaml savefile:/drustcraft_data/bank.yml id:drustcraft_bank
      
      - foreach <yaml[drustcraft_bank].read[npcs]||<list[]>>:
        - define npc_id:<[value]>
        - ~run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_bank_interactor
        
      - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
        - wait 2t
        - waituntil <yaml.list.contains[drustcraft_tab_complete]>
        
        - run drustcraftt_tab_complete.completions def:bank|npc|_*npcs   

    - else:
      - debug log 'Drustcraft Bank requires Drustcraft NPC installed'
        
  save:
    - yaml id:drustcraft_bank savefile:/drustcraft_data/bank.yml


drustcraftc_bank:
  type: command
  debug: false
  name: bank
  description: Modifies NPC bank
  usage: /bank <&lt>npc<&gt>
  permission: drustcraft.bank
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:bank
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case npc:
        - define npc_id:<context.args.get[2]||<empty>>
        - if <[npc_id]> != <empty>:
          - if <[npc_id].is_integer>:
            - if <server.npcs.parse[id].contains[<[npc_id]>]>:
              
              - if <yaml[drustcraft_bank].read[npcs].contains[<[npc_id]>]||false> == false:
                - yaml id:drustcraft_bank set npcs:->:<[npc_id]>
                - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_bank_interactor
                - run drustcraftt_bank.save
                
              - narrate '<&e>The NPC is now a bank'
            - else:
              - narrate '<&e>The NPC Id was not found on this server'
          - else:
            - narrate '<&e>The NPC Id is invalid'
        - else:
          - narrate '<&e>You require to enter a NPC Id'
      
      - default:
        - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
        
        
drustcraftt_bank_interactor:
  type: task
  debug: false
  script:
    - define target_npc:<[1]>
    - define target_player:<[2]>
    - define action:<[3]>
  
    - choose <[action]||<empty>>:
      - case click:
        - define slot_map:<yaml[drustcraft_bank].read[players.<[target_player].uuid>.slots]||<map[]>>
        - note "in@generic[size=54;title=Bank Vault]" as:bank_<[target_player].uuid>
        - inventory set d:in@bank_<player.uuid> o:<[slot_map]>
        - inventory open d:in@bank_<player.uuid>
      - case entry:
        - if <[target_player].flag[drustcraft_firstspawn_bank]||1> < 3:
          - flag <[target_player]> drustcraft_firstspawn_bank:++
          - determine '<list[Hey <[target_player].name>, welcome to a town bank|You can click on me to open your personal vault.|Anything you store in your bank vault is safe and can be retrieved from any town bank you visit]>'