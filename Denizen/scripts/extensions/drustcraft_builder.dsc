# Drustcraft - Builder
# Gives players creative mode in defined areas
# https://github.com/drustcraft/drustcraft

drustcraftw_builder:
  type: world
  debug: false
  events:
    on player exits cuboid:
      - if <player.in_group[builder]> && <player.in_group[staff]> == false:
        - if <player.gamemode> == CREATIVE:
          - define allow:false

        - if <context.to||<empty>> != <empty>:
          - define allow:false
          - if <proc[drustcraftp_region.gamemode].context[<context.to>]||SURVIVAL> != CREATIVE:
            - foreach <context.to.regions||<list[]>> as:target_region:
              - if <proc[drustcraftp_region.is_member].context[<[target_region]>|<player>]||false>:
                - define allow:true
                - foreach stop

              - foreach <yaml[drustcraft_regions].read[regions.<[target_region].world.name>.<[target_region].id>.members.groups].filter[ends_with[_edit]]||<list[]>>:
                - if <player.in_group[<[value].before[_edit]>]>:
                  - run drustcraftt_group.add_member def:<[value]>|<player>
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
            - foreach <player.groups.filter[ends_with[_edit]]>:
              - run drustcraftt_group.remove_member context:<[value]>|<player>

            - narrate '<&e>Builder tools disabled'
            - narrate '<&c>You do not have permission to build in this region'
          - else:
            - adjust <player> gamemode:SURVIVAL
                        
    on player places block:
      - if <player.in_group[staff]> == false && <proc[drustcraftp_region.gamemode].context[<context.location>]> != <player.gamemode>:
        - define can_build:false

        - foreach <context.location.regions||<list[]>> as:target_region:
          - if <proc[drustcraftp_region.is_member].context[<[target_region]>|<player>]> || <proc[drustcraftp_region.is_owner].context[<[target_region]>|<player>]>:
            - define can_build:true
            - foreach stop

        - if <[can_build]> == false:
          - narrate "<&8><&l>[<&4>-<&8><&l>] <&c>You can't place blocks in this location"
          - determine cancelled

    on player breaks block:
      - if <player.in_group[staff]> == false && <proc[drustcraftp_region.gamemode].context[<context.location>]> != <player.gamemode>:        
        - define can_build:false
        
        - foreach <context.location.regions||<list[]>> as:target_region:
          - if <proc[drustcraftp_region.is_member].context[<[target_region]>|<player>]> || <proc[drustcraftp_region.is_owner].context[<[target_region]>|<player>]>:
            - define can_build:true
            - foreach stop

        - if <[can_build]> == false:
          - narrate "<&8><&l>[<&4>-<&8><&l>] <&c>You can't break blocks in this location"
          - determine cancelled
    
    on portal created:
      - if <context.entity.is_player||false>:
        - foreach <context.blocks.parse[regions].combine.deduplicate||<list[]>> as:target_region:
          - if <proc[drustcraftp_region.is_member].context[<[target_region]>|<context.entity>]> || <proc[drustcraftp_region.is_owner].context[<[target_region]>|<context.entity>]>:
            - narrate '<&e>You cannot create portals in regions that you are either a member or owner' targets:<context.entity.as_player>
            - determine cancelled

    on player opens inventory:
      - if <player.gamemode> != SURVIVAL:
        - if <player.groups.contains[staff]> == false:
          - narrate '<&e>You cannot open inventories in creative mode'
          - determine cancelled

    on system time minutely:
      - foreach <server.online_players.filter[location.find.npcs.within[50].size.is_more_than[20]].filter[gamemode.equals[CREATIVE]]>:
        - define npc_count:<[value].location.find.npcs.within[50].size>
        - narrate '<&8><&l>[<&6>!<&8><&l>] <&6>There is currently <&f><[npc_count]> <&6>NPCs within 50 blocks of your location. This is higher than the recommended limit of <&f>20<&6>. Try spacing out some NPCs to reduce the chance of server lag' targets:<[value]>


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

            - if <player.in_group[staff]> == false:
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
              - narrate '<&e>Builder tools enabled'
              
            - else:
              - narrate '<&c>You do not have permission to build in this region'
        - case disable disabled deny false:
          - if <proc[drustcraftp_region.gamemode].context[<player.location>]||SURVIVAL> != CREATIVE:
            - if <player.gamemode> == CREATIVE:
              - adjust <player> gamemode:SURVIVAL
              
              # - define region_builder_groups:<list[]>
              # - foreach <player.location.regions||<list[]>> as:target_region:
              #   - define region_builder_groups:|:<yaml[drustcraft_regions].read[regions.<[target_region].world.name>.<[target_region].id>.members.groups].filter[ends_with[_edit]]||<list[]>>
              # - define player_builder_groups:<player.groups.filter[ends_with[_edit]]||<list[]>>
              # - define remove_builder_groups:<[player_builder_groups].exclude[<[region_builder_groups]>]>
              # - foreach <[remove_builder_groups]>:
              #   - run drustcraftt_group.remove_member context:<[value]>|<player>
              
              - foreach <player.groups.filter[ends_with[_edit]]>:
                - run drustcraftt_group.remove_member context:<[value]>|<player>
              
              - narrate '<&e>Builder tools disabled'
            - else:
              - narrate '<&e>Builder tools already disabled'
          - else:
            - narrate '<&e>You cannot disable builder tools in a creative area'
        - default:
          - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
    - else:
      - narrate '<&c>This command can only be run by a player'