# Drustcraft - Banker
# Banker Management
# https://github.com/drustcraft/drustcraft

drustcraftw_banker:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_banker.load
      
    on script reload:
      - run drustcraftt_banker.load
    

    on player closes inventory:
      - if '<context.inventory.title.starts_with[Bank Vault]>':
        - define slot_items:<context.inventory.map_slots>
        - note remove as:drustcraft_bankvault_<player.uuid>
        - ~yaml id:drustcraft_banker set players.<player.uuid>.slots:<[slot_items]>
        - run drustcraftt_banker.save


drustcraftt_banker:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <yaml.list.contains[drustcraft_banker]>:
      - ~yaml unload id:drustcraft_banker

    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - waituntil <yaml.list.contains[drustcraft_tab_complete]>

      - run drustcraftt_tab_complete.completions def:banker|npc|add|_*npcs
      - run drustcraftt_tab_complete.completions def:banker|npc|remove|_*npcs
      - run drustcraftt_tab_complete.completions def:banker|reload
      - run drustcraftt_tab_complete.completions def:banker|save


    - if <server.has_file[/drustcraft_data/banker.yml]>:
      - yaml load:/drustcraft_data/banker.yml id:drustcraft_banker
    - else:
      - yaml create id:drustcraft_banker
      - yaml savefile:/drustcraft_data/banker.yml id:drustcraft_banker
    
    - wait 2t
    - waituntil <yaml.list.contains[drustcraft_npc]>

    - foreach <yaml[drustcraft_banker].read[npcs].deduplicate||<list[]>>:
      - ~run drustcraftt_npc.interactor def:<[value]>|drustcraftt_interactor_banker
                        
  save:
    - if <yaml.list.contains[drustcraft_banker]>:
      - yaml savefile:/drustcraft_data/banker.yml id:drustcraft_banker
      
  npc:
    add:
      - define npc_id:<[1]||<empty>>
      
      - waituntil <yaml.list.contains[drustcraft_banker]>
      - if <server.npcs.parse[id].contains[<[npc_id]>]>:
        - if <yaml[drustcraft_banker].read[npcs].contains[<[npc_id]>]> == false:
          - yaml id:drustcraft_banker set npcs:->:<[npc_id]>
          - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_interactor_banker
          - run drustcraftt_banker.save

    remove:
      - define npc_id:<[1]||<empty>>
      
      - waituntil <yaml.list.contains[drustcraft_banker]>
      - if <yaml[drustcraft_banker].read[npcs].contains[<[npc_id]>]> == false:
        - yaml id:drustcraft_banker set npcs:<-:<[npc_id]>
        - run drustcraftt_npc.interactor def:<[npc_id]>
        - run drustcraftt_banker.save


drustcraftp_banker:
  type: procedure
  debug: false
  script:
    - determine <empty>

  npc:
    list:
      - determine <yaml[drustcraft_banker].read[npcs]||<list[]>>


drustcraftc_banker:
  type: command
  debug: false
  name: banker
  description: Creates, Edits and Removes Bankers
  usage: /banker <&lt>create|remove|info|list<&gt>
  permission: drustcraft.banker
  permission message: <&8><&l>[<&4>x<&8><&l>] <&4>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:banker
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case reload:
        - ~run drustcraftt_banker.load
        - narrate '<&8><&l>[<&2>+<&8><&l>] <&2>Banker data reloaded'
      
      - case save:
        - ~run drustcraftt_banker.save
        - narrate '<&8><&l>[<&2>+<&8><&l>] <&2>Banker data saved'
        
      - case npc:
        - choose <context.args.get[2]||<empty>>:
          - case add:
            - define npc_id:<context.args.get[3]||<empty>>
            - if <[npc_id]> != <empty>:
              - if <[npc_id].is_integer> && <server.npcs.parse[id].contains[<[npc_id]>]>:
                  - if <proc[drustcraftp_banker.npc.list].contains[<[npc_id]>]> == false:
                    - ~run drustcraftt_banker.npc.add def:<[npc_id]>
                    - narrate '<&8><&l>[<&2>+<&8><&l>] <&2>The NPC ID <&f><[npc_id]> <&2>is set as a banker'
                  - else:
                    - narrate '<&8><&l>[<&4>x<&8><&l>] <&4>The NPC ID <&f><[npc_id]> <&4>is already set as a banker'
              - else:
                  - narrate '<&8><&l>[<&4>x<&8><&l>] <&4>The NPC ID <&f><[npc_id]> <&4>is not a valid NPC ID'
            - else:
              - narrate '<&8><&l>[<&4>x<&8><&l>] <&4>No NPC ID was entered to add as a banker'
              
          - case remove:
            - define npc_id:<context.args.get[3]||<empty>>
            - if <[npc_id]> != <empty>:
              - if <[npc_id].is_integer> && <server.npcs.parse[id].contains[<[npc_id]>]>:
                  - if <proc[drustcraftp_banker.npc.list].contains[<[npc_id]>]>:
                    - ~run drustcraftt_banker.npc.remove def:<[npc_id]>
                    - narrate '<&8><&l>[<&2>+<&8><&l>] <&2>The NPC ID <&f><[npc_id]> <&2>was removed as a banker'
                  - else:
                    - narrate '<&8><&l>[<&4>x<&8><&l>] <&4>The NPC ID <&f><[npc_id]> <&4>is not a banker'
              - else:
                  - narrate '<&8><&l>[<&4>x<&8><&l>] <&4>The NPC ID <&f><[npc_id]> <&4>is not a valid NPC ID'
            - else:
              - narrate '<&8><&l>[<&4>x<&8><&l>] <&4>No NPC ID was entered to add as a banker'
            
          - default:
            - narrate '<&8><&l>[<&4>x<&8><&l>] <&4>Unknown option. Try <queue.script.data_key[usage].parsed>'
          
      - default:
        - narrate '<&8><&l>[<&4>x<&8><&l>] <&4>Unknown option. Try <queue.script.data_key[usage].parsed>'
        

drustcraftt_interactor_banker:
  type: task
  debug: false
  script:
  - define target_npc:<[1]>
  - define target_player:<[2]>
  - define action:<[3]>
  
  - choose <[action]||<empty>>:
    - case click:
      - define bankvault_slots:<yaml[drustcraft_banker].read[players.<player.uuid>.slots]||<map[]>>
      - note 'in@generic[size=45;title=Bank Vault]' as:drustcraft_bankvault_<player.uuid>
      - inventory set d:in@drustcraft_bankvault_<player.uuid> o:<[bankvault_slots]>
      - inventory open d:in@drustcraft_bankvault_<player.uuid> o:<[bankvault_slots]>
      - determine false
