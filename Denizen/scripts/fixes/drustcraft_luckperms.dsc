# Drustcraft Fix - Luckperms
# https://github.com/drustcraft/drustcraft

drustcraftw_luckperms:
    type: world
    debug: false
    events:
        on lp command:
            - define args:<list[lp]>
            - define override:false

            # Floodgate player names start with * which is not recognised by LuckPerms.
            # Convert these player names to their floodgate UUIDs and run the command again.
            # This will be fixed in FloodGate 2.0 - https://github.com/lucko/LuckPerms/pull/2449
            - foreach <context.args>:
                - if <[value].starts_with[*]>:
                    - define plist:<server.match_offline_player[<[value]>]||<empty>>
                    - if <[plist].type> == Player && <[plist].name> == <[value]>:
                        - define override:true
                        - define args:->:<[plist].uuid>
                    - else:
                        - narrate '<&c>Unknown player'
                        - determine fulfilled
                - else:
                    - define args:->:<[value]>
            
            - if <[override]>:
                - determine passively fulfilled
                - if <context.server||false>:
                    - execute as_server <[args].space_separated>
                - else:
                    - execute as_player <[args].space_separated>