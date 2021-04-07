# Drustcraft - Builder
# Gives players creative mode in defined areas
# https://github.com/drustcraft/drustcraft

drustcraftw_builder:
  type: world
  debug: false
  events:
    on player exits cuboid:
      - if <player.in_group[builder]> && <player.in_group[developer]> == false:
        - if <player.gamemode> == CREATIVE:
          - define allow:false

        - if <context.to||<empty>> != <empty>:
          - define allow:false
          - if <proc[drustcraftp_region.gamemode].context[<context.to>]||SURVIVAL> != CREATIVE:
            - foreach <context.to.regions||<list[]>> as:target_region:
              - if <proc[drustcraftp_region.is_member].context[<[target_region]>|<player>]||false>:
                - define allow:true
                - foreach stop
                
          - if <[allow]> == false:
            - adjust <player> gamemode:SURVIVAL
                  
          - define show_disabled:false
          - foreach <context.from.regions||<list[]>> as:target_region:
            - if <proc[drustcraftp_region.is_member].context[<[target_region]>|<player>]>:
              - define show_disabled:true
              - foreach stop
                      
          - if <[show_disabled]>:
            - narrate '<&e>Builder tools disabled'
            - narrate '<&c>You do not have permission to build in this region'
          - else:
            - adjust <player> gamemode:SURVIVAL
                        
    on player places block:
      - if <player.gamemode> == CREATIVE && <player.in_group[developer]> == false && <proc[drustcraftp_region.gamemode].context[<context.location>]> != CREATIVE:
        - define can_build:false

        - foreach <context.location.regions||<list[]>> as:target_region:
          - if <proc[drustcraftp_region.is_member].context[<[target_region]>|<player>]> || <proc[drustcraftp_region.is_owner].context[<[target_region]>|<player>]>:
            - define can_build:true
            - foreach stop

        - if <[can_build]> == false:
          - narrate "<&c>You cannot build in this location"
          - determine cancelled

    on player breaks block:
      - if <player.gamemode> == CREATIVE && <player.in_group[developer]> == false && <proc[drustcraftp_region.gamemode].context[<context.location>]> != CREATIVE:
        - define can_build:false
        
        - foreach <context.location.regions||<list[]>> as:target_region:
          - if <proc[drustcraftp_region.is_member].context[<[target_region]>|<player>]> || <proc[drustcraftp_region.is_owner].context[<[target_region]>|<player>]>:
            - define can_build:true
            - foreach stop

        - if <[can_build]> == false:
          - narrate "<&c>You cannot build in this location"
          - determine cancelled


drustcraftc_builder:
  type: command
  debug: false
  name: builder
  description: Enables or disables builder mode
  usage: /builder [(toggle|enable|disable)]
  permission: drustcraft.builder
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:notice
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if <player||<empty>> != <empty>:
      - define action:<context.args.get[1]||toggle>

      - if <[action]> == toggle:
        - if <player.gamemode> == CREATIVE:
          - define action:disable
        - else:
          - define action:enable

      - choose <[action]>:
        - case enable enabled allow true:
          - if <player.gamemode> == CREATIVE:
            - narrate '<&e>Builder tools already enabled'
          - else:
            - define allow:false

            - if <player.in_group[developer]> == false:
              - foreach <player.location.regions||<list[]>> as:target_region:
                - if <proc[drustcraftp_region.is_member].context[<[target_region]>|<player>]||false> || <proc[drustcraftp_region.is_owner].context[<[target_region]>|<player>]||false>:
                  - define allow:true
                  - foreach stop
            - else:
              - define allow:true

            - if <[allow]>:
              - adjust <player> gamemode:CREATIVE
              - narrate '<&e>Builder tools enabled'
              
            - else:
              - narrate '<&c>You do not have permission to build in this region'
        - case disable disabled deny false:
          - if <proc[drustcraftp_region.gamemode].context[<player.location>]||SURVIVAL> != CREATIVE:
            - if <player.gamemode> == CREATIVE:
              - adjust <player> gamemode:SURVIVAL
              - narrate '<&e>Builder tools disabled'
            - else:
              - narrate '<&e>Builder tools already disabled'
          - else:
            - narrate '<&e>You cannot disable builder tools in a creative area'
        - default:
          - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
    - else:
      - narrate '<&c>This command can only be run by a player'