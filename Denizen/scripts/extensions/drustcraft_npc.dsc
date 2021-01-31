# Drustcraft - NPC
# NPC Utilities
# https://github.com/drustcraft/drustcraft

drustcraftw_npc:
    type: world
    debug: false
    events:
        on entity teleports:
            # Spawn NPCs that are within 25 blocks from the destination
            # We leave the original NPCs spawned incase the player returns, the minute counter will clean then up
            - run drustcraftt_npc.spawn_close def:<context.destination>
            

        on player respawns:
            # Spawn NPCs that are within 25 blocks from the location
            - run drustcraftt_npc.spawn_close def:<context.location>


        after player joins:
            # Spawn NPCs that are within 25 blocks from the location
            - run drustcraftt_npc.spawn_close def:<player.location>


        on system time secondly every:5:
            # Spawn NPCs that are within 25 blocks from a player
            - foreach <server.npcs.filter[location.find.entities[Player].within[25].size.is[OR_MORE].than[1]].filter[is_spawned.not]>:
                - spawn <[value]> <[value].location>


        on system time minutely:
            # Despawn NPCs that are spawned and further away then 25 blocks from a player - save server resources
            - foreach <server.npcs.filter[location.find.entities[Player].within[25].size.is[==].to[0]].filter[is_spawned]>:
                - despawn <[value]>

        # Ensure that NPC names start with the color code &e
        on npc command:
            - choose <context.args.get[1]||<empty>>:
                - case create rename:
                    - wait 1t
                    - foreach <server.npcs>:
                        - if <[value].name.starts_with[§]> == false:
                            - adjust <[value]> name:<&e><[value].name>


drustcraftt_npc:
    type: task
    debug: false
    script:
        - determine <empty>
    
    spawn_close:
        - define target_location:<[1]>
        
        - foreach <server.npcs.filter[location.distance[<[target_location]>].is[OR_LESS].than[25]]>:
            - spawn <[value]> <[value].location>
        