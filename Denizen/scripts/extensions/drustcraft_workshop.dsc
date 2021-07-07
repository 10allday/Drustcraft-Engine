# Drustcraft - Workshop
# Gives players creative mode in defined areas
# https://github.com/drustcraft/drustcraft

drustcraftw_workshop:
  type: world
  debug: false
  events:
    on server start:
      - flag server drustcraft_workshop:true
      
    after player joins:
      - wait 40t
      - if <player.has_flag[drustcraft_workshop_back]>:
        - teleport <player> <player.flag[drustcraft_workshop_back]>
        - flag player drustcraft_workshop_back:!


drustcraftc_workshop:
  type: command
  debug: false
  name: workshop
  description: Enters or exits a workshop
  usage: /workshop
  permission: drustcraft.workshop
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:workshop
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if <player||<empty>> != <empty>:
      - if <context.args.get[1]||<empty>> != <empty>:
        - if <list[exit|leave].contains[<context.args.get[1]>]>:
          - if <player.has_flag[drustcraft_workshop_back]>:
            - teleport <player> <player.flag[drustcraft_workshop_back]>
            - flag player drustcraft_workshop_back:!
          - else:
            - teleport <player> <world[azentina].spawn_location>
          - narrate '<proc[drustcraftp.message_format].context[warning|You have left the workshop]>'
        - else:
          - if <list[isaac].contains[<context.args.get[1]>]> && <player.groups.contains_any[<list[isaac_builder|isaac_staff|staff]>]>:
            - if !<player.has_flag[drustcraft_workshop_back]>:
              - flag player drustcraft_workshop_back:<player.location>
            - teleport <player> <location[-1178,64,-614,7,87,azentina]>
            - narrate '<proc[drustcraftp.message_format].context[|You have joined the Isaac workshop]>'

            - define allow:false

            - if !<player.location.world.name.starts_with[workshop_]> && <player.in_group[staff]> == false:
              - foreach <player.location.regions||<list[]>> as:target_region:
                - if <proc[drustcraftp_region.is_member].context[<[target_region]>|<player>]||false> || <proc[drustcraftp_region.is_owner].context[<[target_region]>|<player>]||false>:
                  - define allow:true
                  - foreach stop

                - foreach <yaml[drustcraft_regions].read[regions.<[target_region].world.name>.<[target_region].id>.members.groups].filter[ends_with[_edit]]||<list[]>>:
                  - if <player.in_group[<[value].before[_edit]>]>:
                    - run drustcraftt_group.add_member def:<[value]>|<player>
                    - define allow:true
                    - foreach stop
                
            - else:
              - define allow:true

            - if <[allow]>:
              - adjust <player> gamemode:CREATIVE
              - narrate '<proc[drustcraftp.message_format].context[|Builder tools enabled]>'
              
            - else:
              - narrate '<&c>You do not have permission to build in this region'

          - else:
            - narrate '<proc[drustcraftp.message_format].context[error|You do not have access to or that workshop is not running yet]>'
      - else:
        - narrate '<proc[drustcraftp.message_format].context[error|You need to enter a workshop name or $fleave $r to leave the current workshop]>'
    - else:
      - narrate '<proc[drustcraftp.message_format].context[error|This command can only be run by a player]>'
  