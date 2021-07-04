# Drustcraft - NPC
# NPC Utilities
# https://github.com/drustcraft/drustcraft

drustcraftw_npc:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_npc.load
    
    on script reload:
      - run drustcraftt_npc.load
    
    on player respawns:
      - run drustcraftt_npc.spawn_close def:<context.location>

    after player joins:
      # Spawn NPCs that are within 25 blocks from the location
      - run drustcraftt_npc.spawn_close def:<player.location>
      - flag <player> npc_engaged:!

    on system time secondly every:5:
      # spawn NPCs that are within 50 blocks from a player and does not have the flag drustcraft_killed
      - foreach <server.npcs.filter[location.find_entities[Player].within[50].size.is[OR_MORE].than[1]].filter[is_spawned.not].filter[has_flag[drustcraft_killed].not]>:
        - spawn <[value]> <[value].location>

    on system time minutely:
      # despawn NPCs that are beyond 50 blocks from a player and is not navigating
      - foreach <server.npcs.filter[location.find_entities[Player].within[50].size.is[==].to[0]].filter[is_spawned].filter[not[is_navigating]]>:
        - if <[value].has_flag[drustcraft_killed]>:
          - flag <[value]> drustcraft_killed:!
          
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
      - if <context.entity.object_type||<empty>> == NPC:
        - flag <context.entity> drustcraft_killed:true
    
    on player closes inventory priority:100:
      - define prev_npc:<player.flag[npc_engaged]||<empty>>
      
      - if <[prev_npc]> != <empty>:
        - define gamemode:_<player.gamemode>
        - if <player.gamemode> == SURVIVAL:
          - define gamemode:<empty>

        - define task_name:<proc[drustcraftp_npc.interactor].context[<player.flag[npc_engaged]>]>
        - if <[task_name]> != <empty>:
          - ~run <[task_name]> def:<npc[<player.flag[npc_engaged]>]>|<player>|close<[gamemode]>|<context.inventory>
        
        - flag <player> npc_engaged:!
        


drustcraftt_npc:
  type: task
  debug: false
  script:
    - determine <empty>

  load:
    - wait 2t
    - waituntil <yaml.list.contains[drustcraft_server]>
    
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
    
    - foreach <server.npcs.filter[location.distance[<[target_location]>].is[OR_LESS].than[25]].filter[has_flag[drustcraft_killed].not]>:
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
              - ~run <[task_name]> def:<npc[<player.flag[npc_engaged]>]>|<player>|close<[gamemode]>
              
          - flag player npc_engaged:<npc.id>
          - define task_name:<proc[drustcraftp_npc.interactor].context[<player.flag[npc_engaged]>]>
          - if <[task_name]> != <empty>:
            - ~run <[task_name]> def:<npc>|<player>|click<[gamemode]> save:result
            - define show_greeting:<entry[result].created_queue.determination.get[1]||true>
              
          - if <[show_greeting]> && <player.gamemode> == SURVIVAL:
            #- if <player.item_in_hand.material.name||air>> == air:
            - narrate <proc[drustcraftp_message_format].context[<npc>|<proc[drustcraftp_npc.greeting].context[<npc.id>|<player>]>]>

      proximity trigger:
        entry:
          script:
            - define task_name:<proc[drustcraftp_npc.interactor].context[<npc.id>]>
            - if <[task_name]> != <empty>:
              - define gamemode:_<player.gamemode>
              - if <player.gamemode> == SURVIVAL:
                - define gamemode:<empty>
              
              - ~run <[task_name]> def:<npc>|<player>|entry<[gamemode]> save:result
              - define show_greeting:<entry[result].created_queue.determination.get[1]||<empty>>
              - if <[show_greeting]> != <empty>:
                - if <player.flag[drustcraft_npc_last_entry].from_now.in_seconds||99> > 5:
                  - flag <player> drustcraft_npc_last_entry:<util.time_now>
                  
                  - if <[show_greeting].object_type> == LIST:
                    - flag <player> drustcraft_npc_entry:<npc.id>
                    - foreach <[show_greeting]>:
                      - narrate <proc[drustcraftp_message_format].context[<npc>|<[value]>]>
                      - wait 5s
                      - if <player.flag[drustcraft_npc_entry]||0> != <npc.id>:
                        - foreach stop
                  - else:
                    - narrate <proc[drustcraftp_message_format].context[<npc>|<[show_greeting]>]>

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
