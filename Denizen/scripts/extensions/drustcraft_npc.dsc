# Drustcraft - NPC
# NPC Utilities (De-spawns when no players are around)
# https://github.com/drustcraft/drustcraft

drustcraftw_npc:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_npc.load
    
    
    on script reload:
      - run drustcraftt_npc.load
    
    #on entity teleports:
      # Spawn NPCs that are within 25 blocks from the destination
      # We leave the original NPCs spawned incase the player returns, the minute counter will clean then up
      #- run drustcraftt_npc.spawn_close def:<context.destination>
      

    on player respawns:
      # Spawn NPCs that are within 25 blocks from the location
      - run drustcraftt_npc.spawn_close def:<context.location>


    after player joins:
      # Spawn NPCs that are within 25 blocks from the location
      - run drustcraftt_npc.spawn_close def:<player.location>


    #TODO this interferes with sentinel respawntime on death
    on system time secondly every:5:
      # Spawn NPCs that are within 25 blocks from a player
      - foreach <server.npcs.filter[location.find.entities[Player].within[50].size.is[OR_MORE].than[1]].filter[is_spawned.not]>:
        - spawn <[value]> <[value].location>


    on system time minutely:
      # Despawn NPCs that are spawned and further away then 25 blocks from a player - save server resources
      - foreach <server.npcs.filter[location.find.entities[Player].within[50].size.is[==].to[0]].filter[is_spawned].filter[not[is_navigating]]>:
        - despawn <[value]>


    # Ensure that NPC names start with the color code &e
    on npc command:
      - choose <context.args.get[1]||<empty>>:
        - case create rename:
          - wait 1t
          - lookclose <player.selected_npc> true range:10 realistic
          - assignment set script:drustcrafta_npc npc:<player.selected_npc>
          - if <player.selected_npc.traits.contains[sentinel]> == false:
            - trait state:true sentinel to:<player.selected_npc>
          - anchor add <player.selected_npc.location> id:spawn npc:<player.selected_npc>
          - execute as_player 'sentinel addtarget monsters'
          - execute as_player 'sentinel spawnpoint'
          
          - foreach <server.npcs>:
            - if <[value].name.starts_with[§]> == false:
              - adjust <[value]> name:<&e><[value].name>


drustcraftt_npc:
  type: task
  debug: false
  script:
    - determine <empty>

  load:
    - if <yaml.list.contains[drustcraft_npc_interactor]>:
      - ~yaml unload id:drustcraft_npc_interactor
    - yaml create id:drustcraft_npc_interactor

    - if <yaml.list.contains[drustcraft_npc]>:
      - ~yaml unload id:drustcraft_npc    
    - if <server.has_file[/drustcraft_data/npc.yml]>:
      - ~yaml load:/drustcraft_data/npc.yml id:drustcraft_npc
    - else:
      - ~yaml create id:drustcraft_npc
      
      # defaults
      - yaml id:drustcraft_npc set npc.storage:yaml
            
      - yaml savefile:/drustcraft_data/npc.yml id:drustcraft_npc

  save:
    - if <yaml.list.contains[drustcraft_npc]>:
      - yaml savefile:/drustcraft_data/npc.yml id:drustcraft_npc
  
  interactor:
    - define npc_id:<[1]||<empty>>
    - define task_name:<[2]||<empty>>
    
    - if <[npc_id]> != <empty>:
      - if <[task_name]> != <empty>:
        - yaml id:drustcraft_npc_interactor set interactor.<[npc_id]>:<[task_name]>
      - else:
        - yaml id:drustcraft_npc_interactor set interactor.<[npc_id]>:!


  spawn_close:
    - define target_location:<[1]>
    
    - foreach <server.npcs.filter[location.distance[<[target_location]>].is[OR_LESS].than[25]]>:
      - spawn <[value]> <[value].location>


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
      - define group:<yaml[drustcraft_greetings].read[greetings.npcs.<[target_npc].id>.group]||<empty>>
      
      - if <[group]> != <empty>:
        - define key:group.<[group]>
      - else:
        - if <yaml[drustcraft_greetings].list_keys[greetings.npcs].contains[<[target_npc].id>]||false>:
          - define key:npcs.<[target_npc].id>
      
      - define weather:default
      - if <[target_npc].location.world.has_storm>:
        - define weather:raining
      - if <[target_npc].location.world.thundering>:
        - define weather:thundering
      
      - if <yaml[drustcraft_greetings].list_keys[greetings.<[key]>].contains[<[weather]>]||false>:
        - define key:<[key]>.<[weather]>
      - else:
        - define key:<[key]>.default
      
      - define time:<[target_npc].location.world.time.period>            
      - if <yaml[drustcraft_greetings].list_keys[greetings.<[key]>].contains[<[time]>]||false>:
        - define key:<[key]>.<[time]>
      - else:
        - define key:<[key]>.default

      - define greetings:<yaml[drustcraft_greetings].read[greetings.<[key]>]||<list[]>>
      - if <[greetings].size> > 0:
        - determine <[greetings].random>
        
    - determine Hello


  interactor:
    - define npc_id:<[1]||<empty>>

    - if <[npc_id]> != <empty>:
      - determine <yaml[drustcraft_npc_interactor].read[interactor.<[npc_id]>]||<empty>>
    
    - determine <empty>


drustcrafti_npc:
  type: interact
  debug: false
  speed: 0
  steps:
    1:
      click trigger:
        script:
          - define prev_npc:<player.flag[npc_engaged]||<empty>>
          - define show_greeting:true
          
          - define gamemode:_<player.gamemode>
          - if <player.gamemode> == SURVIVAL:
            - define gamemode:<empty>

          - if <[prev_npc]> != <empty> && <[prev_npc]> != <npc.id>:
            - define task_name:<proc[drustcraftp_npc.interactor].context[<player.flag[npc_engaged]>]>
            - if <[task_name]> != <empty>:
              - ~run <[task_name]> def:<player.flag[npc_engaged]>|<player>|close<[gamemode]>
              
          - flag player npc_engaged:<npc.id>
          - define task_name:<proc[drustcraftp_npc.interactor].context[<player.flag[npc_engaged]>]>
          - if <[task_name]> != <empty>:
            - ~run <[task_name]> def:<npc>|<player>|click<[gamemode]> save:result
            - define show_greeting:<entry[result].created_queue.determination.get[1]||true>
              
          - if <[show_greeting]> && <player.gamemode> == SURVIVAL:
            - narrate <proc[drustcraftp_chat_format].context[<npc>|<proc[drustcraftp_npc.greeting].context[<npc.id>|<player>]>]>

      proximity trigger:
        entry:
          script:
            - define task_name:<proc[drustcraftp_npc.interactor].context[<npc.id>]>
            - if <[task_name]> != <empty>:
              - define gamemode:_<player.gamemode>
              - if <player.gamemode> == SURVIVAL:
                - define gamemode:<empty>
              
              - ~run <[task_name]> def:<npc>|<player>|entry<[gamemode]>

        exit:
          script:
            - define task_name:<proc[drustcraftp_npc.interactor].context[<npc.id>]>
            - if <[task_name]> != <empty>:
              - define gamemode:_<player.gamemode>
              - if <player.gamemode> == SURVIVAL:
                - define gamemode:<empty>

              - ~run <[task_name]> def:<npc>|<player>|exit<[gamemode]>
            
            - if <player.flag[npc_engaged]||<empty>> == <npc.id>:
              - flag player npc_engaged:!

drustcrafta_npc:
  type: assignment
  debug: false
  actions:
      on assignment:
        - trigger name:click state:true
        - trigger name:chat state:true
        - trigger name:proximity state:true
      
      on mob enter proximity:
        - foreach <npc.flag[drustcraft_trait_functions]||<list[]>>:
          - ~run <[value]> def:mobenter|<context.entity>

      on mob exit proximity:
        - foreach <npc.flag[drustcraft_trait_functions]||<list[]>>:
          - ~run <[value]> def:mobexit|<context.entity>

      on mob move proximity:
        - foreach <npc.flag[drustcraft_trait_functions]||<list[]>>:
          - ~run <[value]> def:mobmove|<context.entity>

      on death:
        - foreach <npc.flag[drustcraft_trait_functions]||<list[]>>:
          - ~run <[value]> def:death|<context.killer>|<context.shooter>|<context.damage>|<context.death_cause>

  interact scripts:
  - drustcrafti_npc
