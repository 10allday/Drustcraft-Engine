# Drustcraft - NPC
# NPC Utilities
# https://github.com/drustcraft/drustcraft

drustcraftw_npc:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_npc.load def:start
    
    on script reload:
      - run drustcraftt_npc.load def:reload
    
    on player respawns:
      - run drustcraftt_npc.spawn_close def:<context.location>

    after player joins:
      # Spawn NPCs that are within 25 blocks from the location
      - run drustcraftt_npc.spawn_close def:<player.location>
      - flag <player> drustcraft_npc_engaged:!
    
    on player quits:
      - run drustcraftt_npc.player_close def:<player>      

    on system time secondly every:5:
      # spawn NPCs that are within 50 blocks from a player and does not have the flag drustcraft_npc_killed
      - foreach <server.npcs.filter[location.find_entities[Player].within[50].size.is[OR_MORE].than[1]].filter[is_spawned.not].filter[has_flag[drustcraft_npc_killed].not]>:
        - spawn <[value]> <[value].location>

    on system time minutely:
      # despawn NPCs that are beyond 50 blocks from a player and is not navigating
      - foreach <server.npcs.filter[location.find_entities[Player].within[50].size.is[==].to[0]].filter[is_spawned].filter[not[is_navigating]]>:
        - if <[value].has_flag[drustcraft_npc_killed]>:
          - flag <[value]> drustcraft_npc_killed:!
          
        - despawn <[value]>

    on npc command:
      - choose <context.args.get[1]||<empty>>:
        - case create rename:
          - wait 5t
          - lookclose <player.selected_npc> true range:10 realistic
          - assignment set script:drustcrafta_npc npc:<player.selected_npc>
          
          - foreach <server.npcs>:
            - if <[value].name.starts_with[§]> == false:
              - adjust <[value]> name:<&e><[value].name>
    
    on entity death:
      - if <context.damager.object_type||<empty>> != PLAYER:
        - determine NO_XP
    
    on player closes inventory priority:100:
      - run drustcraftt_npc.player_close def:<player>


drustcraftt_npc:
  type: task
  debug: false
  script:
    - determine <empty>

  load:
    - define action:<[1]||start>
    
    - wait 2t
    - waituntil <yaml.list.contains[drustcraft_server]>
    
    - if <yaml.list.contains[drustcraft_npc]>:
      - ~yaml unload id:drustcraft_npc    
    - if <server.has_file[/drustcraft_data/npc.yml]>:
      - ~yaml load:/drustcraft_data/npc.yml id:drustcraft_npc
    - else:
      - ~yaml create id:drustcraft_npc
      
    # run remove_queue
    - foreach <yaml[drustcraft_npc].read[npc.remove_queue]>:
      - if <proc[drustcraftp.script_exists].context[<[value]>]>:
        - ~run <[value]> def:remove|<[key]>|<empty>|<empty>
        - yaml id:drustcraft_npc set npc.remove_queue.<[key]>:!
      
    # remove NPCs from yaml that no longer exist
    - foreach <yaml[drustcraft_npc].read[npc.interactor]>:
      - if !<server.npcs.parse[id].contains[<[key]>]>:
        - if <proc[drustcraftp.script_exists].context[<[value]>]>:
          - ~run <[value]> def:<[key]>|<empty>|<empty>
        - else:
          - yaml id:drustcraft_npc set npc.remove_queue.<[key]>:<[value]>
        
        - yaml id:drustcraft_npc set npc.interactor.<[key]>:!
    
    # initalize NPCs
    - foreach <server.npcs>:
      - define interactor:<yaml[drustcraft_npc].read[npc.interactor.<[value].id>]||<empty>>
      - if <[interactor]> != <empty>
        - flag <[value]> drustcraft_npc_interactor:<[interactor]>
      - else:
        - flag <[value]> drustcraft_npc_interactor:!
      
      - if <[action]> == start:
        - flag <[value]> drustcraft_npc_engaged:!

  save:
    - if <yaml.list.contains[drustcraft_npc]>:
      - yaml savefile:/drustcraft_data/npc.yml id:drustcraft_npc
  
  spawn_close:
    - define target_location:<[1]>
    
    - foreach <server.npcs.filter[location.distance[<[target_location]>].is[OR_LESS].than[25]].filter[has_flag[drustcraft_npc_killed].not]>:
      - spawn <[value]> <[value].location>

  set_interactor:
    - define target_npc:<[1]||<empty>>
    - define interactor_task:<[2]||<empty>>
    
    - if <[target_npc].object_type> == NPC:
      - if <[interactor_task]> != <empty>:
        - if <proc[drustcraftp.script_exists].context[<[interactor_task]>]>:
          - waituntil <yaml.list.contains[drustcraft_npc]>
          - if <server.npcs.contains[<[target_npc]>]>:
            - define old_interactor:<yaml[drustcraft_npc].read[npc.interactor.<[target_npc].id>]||<empty>>
            - if <[old_interactor]> != <empty>:
              - if <proc[drustcraftp.script_exists].context[<[old_interactor]>]>:
                - ~run <[old_interactor]> def:remove|<[target_npc].id>|<empty>|<empty>
              - else:
                - yaml id:drustcraft_npc set npc.remove_queue.<[target_npc].id>:<[old_interactor]>
            
            - yaml id:drustcraft_npc set npc.interactor.<[target_npc].id>:<[interactor_task]>
            - flag <[target_npc]> drustcraft_npc_interactor:<[interactor_task]>
            - ~run <[interactor_task]> def:add|<[target_npc]>|<empty>|<empty>
      - else:
        - run drustcraftt_npc.clear_interactor def:<[target_npc]>
  
  clear_interactor:
    - define target_npc:<[1]||<empty>>
    
    - if <[target_npc].object_type> == NPC:
      - if <yaml[drustcraft_npc].list_keys[npc.interactor].contains[<[target_npc].id>]>:
        - define interactor:<yaml[drustcraft_npc].read[npc.interactor.<[target_npc].id>]>
        - if <proc[drustcraftp.script_exists].context[<[interactor]>]>:
          - ~run <[old_interactor]> def:remove|<[target_npc].id>|<empty>|<empty>
        - else:
          - yaml id:drustcraft_npc set npc.remove_queue.<[target_npc].id>:<[interactor]>
          
        - yaml id:drustcraft_npc set npc.interactor.<[target_npc].id>:!

      - if <server.npcs.contains[<[target_npc]>]>:
        - flag <[target_npc]> drustcraft_npc_interactor:!      
  
  player_close:
    - define target_player:<[1]>

      - if <[target_player].has_flag[drustcraft_npc_engaged]>:
        - define player_npc:<npc[<[target_player].flag[drustcraft_npc_engaged]>]>
        - if <[player_npc].has_flag[drustcraft_player_engaged]> && <[player_npc].flag[drustcraft_player_engaged]> == <[target_player].uuid>:
          - define no_greeting:false
          - define greeting:<empty>
          
          - if <[player_npc].has_flag[drustcraft_npc_interactor]>:
            - define action:close
            - if <[target_player].gamemode> == CREATIVE:
              - define action:<[action]>-creative
            
            - ~run <[player_npc].flag[drustcraft_npc_interactor]> def:<[action]>|<[player_npc]>|<[target_player]> save:result
            - define result_map:<proc[drustcraftp.determine_map].context[<entry[result].created_queue.determination>]>
            - define no_greeting:<[result_map].get[no_greeting]||false>
            - define greeting:<[result_ma[].get[greeting]||<empty>>
          
          - if !<[no_greeting]>:
            - if <[greeting]> == <empty>:
              - narrate <proc[drustcraftp_npc.greeting].context[close|<npc>|<player>]>
            - else:
              - narrate <proc[drustcraftp_npc.greeting].context[custom|<npc>|<player>|<[greeting]>]>
              
          - flag <npc[<[target_player].flag[drustcraft_npc_engaged]>]> drustcraft_player_engaged:!
        - flag <[target_player]> drustcraft_npc_engaged:!
  
  greeting:
    - define action:<[1]||<empty>>
    - define target_npc:<[2]||<empty>>
    - define target_player:<[3]||<empty>>

  # remove 04/10/2021
  interactor:
    - define npc_id:<[1]||<empty>>
    - define task_name:<[2]||<empty>>
    
    - debug log 'OBSOLETE FUNCTION CALLED: drustcraftt_npc.interactor'
    - run drustcraftt_npc.interactor def:<npc[<[npc_id]>]>|<[task_name]>


drustcraftp_npc:
  type: procedure
  debug: false
  script:
    - determine <empty>
    
  greeting:
    - define target_npc:<npc[<[1]||0>]||<empty>>
    - define target_player:<[2]||<empty>>
    
    - if <[target_npc]> != <empty> && <[target_player]> != <empty>:
      - define key:default
      - define group:<yaml[drustcraft_npc].read[greetings.npcs.<[target_npc].id>.group]||<empty>>
      
      - if <[group]> != <empty>:
        - define key:group.<[group]>
      - else:
        - if <yaml[drustcraft_npc].list_keys[greetings.npcs].contains[<[target_npc].id>]||false>:
          - define key:npcs.<[target_npc].id>
      
      - define weather:default
      - if <[target_npc].location.world.has_storm>:
        - define weather:raining
      - if <[target_npc].location.world.thundering>:
        - define weather:thundering
      
      - if <yaml[drustcraft_npc].list_keys[greetings.<[key]>].contains[<[weather]>]||false>:
        - define key:<[key]>.<[weather]>
      - else:
        - define key:<[key]>.default
      
      - define time:<[target_npc].location.world.time.period>            
      - if <yaml[drustcraft_npc].list_keys[greetings.<[key]>].contains[<[time]>]||false>:
        - define key:<[key]>.<[time]>
      - else:
        - define key:<[key]>.default

      - define greetings:<yaml[drustcraft_npc].read[greetings.<[key]>]||<list[]>>
      - if <[greetings].size> > 0:
        - determine <[greetings].random>
        
    - determine '<list[Hello|Hi|...|Yes?|What do you want?|Maybe I can, maybe I cant|Hey|You again].random>'
    

drustcrafti_npc:
  type: interact
  debug: false
  speed: 0
  steps:
    1:
      click trigger:
        script:
          - define action:click
          
          - if <player.gamemode> == CREATIVE:
            - define action:<[action]>-creative
          
          - if <player.has_flag[drustcraft_npc_engaged]>:
            - if <player.flag[drustcraft_npc_engaged]> == <npc.id>:
              - stop
            - if <npc[<player.flag[drustcraft_npc_engaged]>].has_flag[drustcraft_player_engaged]||false> && <npc[<player.flag[drustcraft_npc_engaged]>].flag[drustcraft_player_engaged]||<empty>> == <player.uuid>:
              - flag <npc[<player.flag[drustcraft_npc_engaged]>]> drustcraft_player_engaged:!

          - if <npc.has_flag[drustcraft_player_engaged]> && <npc.flag[drustcraft_player_engaged]> != <player.uuid>:
            - narrate <proc[drustcraftp_npc.greeting].context[busy|<npc>|<player>|<player[<npc.flag[drustcraft_player_engaged]>]>]>
            - stop
          
          - define no_greeting:false
          - define busy:false
          - define greeting:<empty>
          
          - if <npc.has_flag[drustcraft_npc_interactor]>:
            - ~run <npc.flag[drustcraft_npc_interactor]> def:<[action]>|<npc>|<player> save:result
            - define result_map:<proc[drustcraftp.determine_map].context[<entry[result].created_queue.determination>]>
            - define no_greeting:<[result_map].get[no_greeting]||false>
            - define busy:<[result_map].get[busy]||false>
            - define greeting:<[result_map].get[greeting]||<empty>>
          
          - if !<[no_greeting]>:
            - if <[greeting]> == <empty>:
              - narrate <proc[drustcraftp_npc.greeting].context[click|<npc>|<player>]>
            - else:
              - narrate <proc[drustcraftp_npc.greeting].context[custom|<npc>|<player>|<[greeting]>]>
          - if <[busy]>:
            - flag <npc> drustcraft_player_engaged:<player.uuid>
            - flag <player> drustcraft_npc_engaged:<npc.id>

      proximity trigger:
        entry:
          script:
            - define no_greeting:false
            - define greeting:<empty>

            - define npc_last_enter_map:<player.flag[drustcraft_npc_last_enter]||<map[]>>
            - if <[npc_last_enter_map].get[<npc.id>].from_now.in_seconds||99> < 5:
              - stop                
            - flag <player> drustcraft_npc_last_enter:<[npc_last_enter_map].with[<npc.id>].as[<util.time_now]>

            - if <npc.has_flag[drustcraft_npc_interactor]>:
              - define action:playerenter
              - if <player.gamemode> == CREATIVE:
                - define action:<[action]>-creative
              
              - ~run <npc.flag[drustcraft_npc_interactor]> def:<[action]>|<npc>|<player> save:result
              - define result_map:<proc[drustcraftp.determine_map].context[<entry[result].created_queue.determination>]>
              - define no_greeting:<[result_map].get[no_greeting]||false>
              - define greeting:<[result_map].get[greeting]||<empty>>
            
              - if <npc.has_flag[drustcraft_player_engaged]> && <npc.flag[drustcraft_player_engaged]> == <player.uuid>:
                - flag <npc> drustcraft_player_engaged:!
              - if <player.has_flag[drustcraft_npc_engaged]> && <player.flag[drustcraft_npc_engaged]> == <npc.id>:
                - flag <player> drustcraft_npc_engaged:!

            - if !<[no_greeting]>:
              - if <[greeting]> == <empty>:
                - narrate <proc[drustcraftp_npc.greeting].context[playerexit|<npc>|<player>]>
              - else:
                - narrate <proc[drustcraftp_npc.greeting].context[custom|<npc>|<player>|<[greeting]>]>

        exit:
          script:
            - define no_greeting:false
            - define greeting:<empty>

            - define npc_last_exit_map:<player.flag[drustcraft_npc_last_exit]||<map[]>>
            - if <[npc_last_exit_map].get[<npc.id>].from_now.in_seconds||99> < 5:
              - stop                
            - flag <player> drustcraft_npc_last_exit:<[npc_last_exit_map].with[<npc.id>].as[<util.time_now]>

            - if <npc.has_flag[drustcraft_npc_interactor]>:
              - define action:playerexit
              - if <player.gamemode> == CREATIVE:
                - define action:<[action]>-creative
              
              - ~run <npc.flag[drustcraft_npc_interactor]> def:<[action]>|<npc>|<player> save:result
              - define result_map:<proc[drustcraftp.determine_map].context[<entry[result].created_queue.determination>]>
              - define no_greeting:<[result_map].get[no_greeting]||false>
              - define greeting:<[result_map].get[greeting]||<empty>>
            
              - if <npc.has_flag[drustcraft_player_engaged]> && <npc.flag[drustcraft_player_engaged]> == <player.uuid>:
                - flag <npc> drustcraft_player_engaged:!
              - if <player.has_flag[drustcraft_npc_engaged]> && <player.flag[drustcraft_npc_engaged]> == <npc.id>:
                - flag <player> drustcraft_npc_engaged:!

            - if !<[no_greeting]>:
              - if <[greeting]> == <empty>:
                - narrate <proc[drustcraftp_npc.greeting].context[playerexit|<npc>|<player>]>
              - else:
                - narrate <proc[drustcraftp_npc.greeting].context[custom|<npc>|<player>|<[greeting]>]>
  

drustcrafta_npc:
  type: assignment
  debug: false
  actions:
      on assignment:
        - trigger name:click state:true
        - trigger name:chat state:true
        - trigger name:proximity state:true
      
      on mob enter proximity:
        - if <npc.has_flag[drustcraft_interactor]>:
          - ~run <[drustcraft_interactor]> def:mobenter|<npc>|<context.entity> save:result
          - define result_map:<proc[drustcraftp.determine_map].context[<entry[result].created_queue.determination>]>
          - define no_greeting:<[result_map].get[no_greeting]||false>
          - define greeting:<[result_map].get[greeting]||<empty>>
          
          - if !<[no_greeting]>:
            - if <[greeting]> == <empty>:
              - narrate <proc[drustcraftp_npc.greeting].context[mobenter|<npc>|<context.entity>]>
            - else:
              - narrate <proc[drustcraftp_npc.greeting].context[custom|<npc>|<context.entity>|<[greeting]>]>

      on mob exit proximity:
        - if <npc.has_flag[drustcraft_interactor]>:
          - ~run <[drustcraft_interactor]> def:mobexit|<npc>|<context.entity> save:result
          - define result_map:<proc[drustcraftp.determine_map].context[<entry[result].created_queue.determination>]>
          - define no_greeting:<[result_map].get[no_greeting]||false>
          - define greeting:<[result_map].get[greeting]||<empty>>
          
          - if !<[no_greeting]>:
            - if <[greeting]> == <empty>:
              - narrate <proc[drustcraftp_npc.greeting].context[mobenter|<npc>|<context.entity>]>
            - else:
              - narrate <proc[drustcraftp_npc.greeting].context[custom|<npc>|<context.entity>|<[greeting]>]>

      on mob move proximity:
        - if <npc.has_flag[drustcraft_interactor]>:
          - ~run <[drustcraft_interactor]> def:mobmove|<npc>|<context.entity>

      on death:
        - if <npc.has_flag[drustcraft_interactor]>:
          - if <npc.has_trait[sentinel]>:
            - flag <context.entity> drustcraft_npc_killed:true
          - ~run <[drustcraft_interactor]> def:death|<npc>|<context.killer>|<context.shooter>|<context.damage>|<context.death_cause>

  interact scripts:
  - drustcrafti_npc

# Interactor scripts receive the following:
# mobenter|<npc>|<context.entity>
# mobexit|<npc>|<context.entity>
# mobmove|<npc>|<context.entity>
# death|<npc>|<context.killer>|<context.shooter>|<context.damage>|<context.death_cause>
# click|<npc>|<player>    determine false to cancel greeting
# click-creative|<npc>|<player>   determine false to cancel greeting
# playerenter|<npc>|<player>    determine false to cancel greeting
# playerenter-creative|<npc>|<player>   determine false to cancel greeting
# playerexit|<npc>|<player>   determine false to cancel greeting
# playerexit-creative|<npc>|<player>    determine false to cancel greeting
