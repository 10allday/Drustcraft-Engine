# Drustcraft - Guard
# Guards
# https://github.com/drustcraft/drustcraft

drustcraftw_guard:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_guard.load
    
    on script reload:
      - run drustcraftt_guard.load
    

drustcraftt_guard:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <server.scripts.parse[name].contains[drustcraftw_npc]>:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_npc]>      
      
      - if <yaml.list.contains[drustcraft_guard]>:
        - yaml unload id:drustcraft_guard
    
      - if <server.has_file[/drustcraft_data/guard.yml]>:
        - yaml load:/drustcraft_data/guard.yml id:drustcraft_guard
      - else:
        - yaml create id:drustcraft_guard
        - yaml savefile:/drustcraft_data/guard.yml id:drustcraft_guard
      
      - foreach <yaml[drustcraft_guard].read[npcs]||<list[]>>:
        - define npc_id:<[value]>
        - ~run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_guard_interactor
        
      - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
        - wait 2t
        - waituntil <yaml.list.contains[drustcraft_tab_complete]>
        
        - run drustcraftt_tab_complete.completions def:guard|npc|_*npcs   

    - else:
      - debug log 'Drustcraft Guard requires Drustcraft NPC installed'
        
  save:
    - yaml id:drustcraft_guard savefile:/drustcraft_data/guard.yml


drustcraftc_guard:
  type: command
  debug: false
  name: guard
  description: Modifies NPC guard
  usage: /guard <&lt>npc<&gt>
  permission: drustcraft.guard
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:guard
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case npc:
        - define npc_id:<context.args.get[2]||<empty>>
        - if <[npc_id]> != <empty>:
          - if <[npc_id].is_integer>:
            - if <server.npcs.parse[id].contains[<[npc_id]>]>:
              
              - if <yaml[drustcraft_guard].read[npcs].contains[<[npc_id]>]||false> == false:
                - yaml id:drustcraft_guard set npcs:->:<[npc_id]>
                - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_guard_interactor
                - run drustcraftt_guard.save
                
                - if <npc[<[npc_id]>].traits.contains[sentinel]> == false:
                  - trait state:true sentinel to:<npc[<[npc_id]>]>
                - adjust <npc[<[npc_id]>]> skin_layers:<npc[<[npc_id]>].skin_layers.exclude[cape]>
                - adjust <npc[<[npc_id]>]> name:<&e>Guard
                - execute as_player 'sentinel addtarget monsters --id <[npc_id]>'
                - execute as_player 'sentinel addtarget event:pvp --id <[npc_id]>'
                - execute as_player 'sentinel addtarget event:pvsentinel --id <[npc_id]>'
                - execute as_player 'sentinel autoswitch --id <[npc_id]>'
                - execute as_player 'sentinel spawnpoint true --id <[npc_id]>'
                - adjust <player> selected_npc:<npc[<[npc_id]>]>
                - execute as_player 'npc skin --url https://www.drustcraft.com.au/skins/guard.png'
                
              - narrate '<&e>The NPC is now a guard'
            - else:
              - narrate '<&e>The NPC Id was not found on this server'
          - else:
            - narrate '<&e>The NPC Id is invalid'
        - else:
          - narrate '<&e>You require to enter a NPC Id'
      
      - default:
        - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
        
        
drustcraftt_guard_interactor:
  type: task
  debug: false
  script:
    - define target_npc:<[1]>
    - define target_player:<[2]>
    - define action:<[3]>
  
    - choose <[action]||<empty>>:
      - case entry:
        - if <[target_player].flag[drustcraft_firstspawn_guard]||1> < 4:
          - flag <[target_player]> drustcraft_firstspawn_guard:++
          - choose <[target_player].flag[drustcraft_firstspawn_guard]||1>:
            - case 1:
              - determine '<list[Hey there|Make sure you dont leave anything laying around|There are thieves everywhere]>'
            - case 2:
              - determine '<list[Hello <[target_player].name>|We will try to protect you from mobs and PVP|But sometimes, I like to see how strong you are]>'
            - case 3:
              - determine '<list[<[target_player].name> take what you can, it may not be there when you come back]>'
