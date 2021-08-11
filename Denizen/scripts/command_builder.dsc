# Drustcraft - Builder
# https://github.com/drustcraft/drustcraft

drustcraftw_builder:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_builder_load

    on script reload:
      - run drustcraftt_builder_load

    on player exits cuboid server_flagged:drustcraft.module.builder:
      - run drustcraftt_builder_update_player def:<player>|<context.to||<empty>>|<context.from||<empty>>

    on player exits polygon server_flagged:drustcraft.module.builder:
      - run drustcraftt_builder_update_player def:<player>|<context.to||<empty>>|<context.from||<empty>>

    on player places block server_flagged:drustcraft.module.builder:
      - if !<player.location.world.name.starts_with[workshop_]> && !<player.has_permission[drustcraft.builder.override]> && <proc[drustcraftp_region_location_gamemode].context[<context.location>]> != <player.gamemode>:
        - define can_build:false

        - foreach <context.location.regions||<list[]>> as:target_region:
          - if <proc[drustcraftp_region_player_is_member].context[<[target_region].id>|<[target_region].world.name>|<player.uuid>]> || <proc[drustcraftp_region_player_is_owner].context[<[target_region].id>|<[target_region].world.name>|<player.uuid>]>:
            - define can_build:true
            - foreach stop

        - if !<[can_build]>:
          - narrate '<proc[drustcraftp_msg_format].context[error|You can<&sq>t place blocks in this location]>'
          - determine cancelled

    on player breaks block server_flagged:drustcraft.module.builder:
      - if !<player.location.world.name.starts_with[workshop_]> && !<player.has_permission[drustcraft.builder.override]> && <proc[drustcraftp_region_location_gamemode].context[<context.location>]> != <player.gamemode>:
        - define can_build:false

        - foreach <context.location.regions||<list[]>> as:target_region:
          - if <proc[drustcraftp_region_player_is_member].context[<[target_region].id>|<[target_region].world.name>|<player.uuid>]> || <proc[drustcraftp_region_player_is_owner].context[<[target_region].id>|<[target_region].world.name>|<player.uuid>]>:
            - define can_build:true
            - foreach stop

        - if !<[can_build]>:
          - narrate '<proc[drustcraftp_msg_format].context[error|You can<&sq>t break blocks in this location]>'
          - determine cancelled

    on portal created server_flagged:drustcraft.module.builder:
      - if <context.entity.is_player||false>:
        - foreach <context.blocks.parse[regions].combine.deduplicate||<list[]>> as:target_region:
          - if <proc[drustcraftp_region_player_is_member].context[<[target_region].id>|<[target_region].world.name>|<context.entity.uuid>]> || <proc[drustcraftp_region_player_is_owner].context[<[target_region].id>|<[target_region].world.name>|<context.entity.uuid>]>:
            - narrate '<proc[drustcraftp_msg_format].context[error|You cannot create portals in regions that you are either a member or owner]>' targets:<context.entity.as_player>
            - determine cancelled

    on player opens inventory server_flagged:drustcraft.module.builder:
      - if <player.gamemode> != SURVIVAL:
        - if !<player.has_permission[drustcraft.builder.override]>:
          - narrate '<proc[drustcraftp_msg_format].context[error|You cannot open chests or storage items in creative mode]>'
          - determine cancelled

    on player quits server_flagged:drustcraft.module.builder:
      - foreach <proc[drustcraftp_group_player_member_list].context[<player>].filter[starts_with[builder_]]>:
        - run drustcraftt_group_remove_member context:<[value]>|<player>

    on player changes gamemode:
      - if <player.has_effect[NIGHT_VISION]>:
        - cast NIGHT_VISION remove <player>

    # only when group_name starts with group_
    on luckperms|lp command:
      - run drustcraftt_util_run_once_later def:drustcraftt_builder_update_groups|5

    on player walks flagged:drustcraft.builder.noclip:
      - if <player.gamemode> == CREATIVE:
        - define noclip:false
        - if <player.location.sub[0,0.1,0].material.name> != AIR && <player.is_sneaking>:
          - define noclip:true
        - else:
          - define noclip:<proc[drustcraftp_builder_isnoclip].context[<player>]>

        - if <[noclip]>:
          - adjust <player> gamemode:SPECTATOR
      - else if <player.gamemode> == SPECTATOR:
        - define noclip:false
        - if <player.location.sub[0,0.1,0].material.name> != AIR:
          - define noclip:true
          - define noclip:<proc[drustcraftp_builder_isnoclip].context[<player>]>

        - if !<[noclip]>:
          - adjust <player> gamemode:CREATIVE


drustcraftt_builder_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_group]>:
      - debug ERROR 'Drustcraft Build: Drustcraft Group is required to be installed'
      - stop
    - if !<server.scripts.parse[name].contains[drustcraftw_region]>:
      - debug ERROR 'Drustcraft Build: Drustcraft Region is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.region]>
    - waituntil <Server.has_flag[drustcraft.module.group]>

    - run drustcraftt_builder_update_groups

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>
      - run drustcraftt_tabcomplete_completion def:builder|toggle
      - run drustcraftt_tabcomplete_completion def:builder|enable
      - run drustcraftt_tabcomplete_completion def:builder|disable

    - flag server drustcraft.module.builder:<script[drustcraftw_builder].data_key[version]>


drustcraftt_builder_update_groups:
  type: task
  debug: false
  script:
    - foreach <server.permission_groups.filter[starts_with[group_]].exclude[<server.permission_groups.filter[starts_with[builder_]].parse[replace_text[builder_].with[group_]]>].parse[after[group_]]>:
      - run drustcraftt_group_create def:builder_<[value]>


drustcraftt_builder_update_player:
  type: task
  debug: false
  definitions: target_player|target_to|target_from
  script:
    - if !<[target_player].location.world.name.starts_with[workshop_]> && <[target_player].has_permission[drustcraft.builder]> && !<[target_player].has_permission[drustcraft.builder.override]>:
      - if <[target_player].gamemode> == CREATIVE:
        - define allow:false

      - if <[target_to]||<empty>> != <empty>:
        - define allow:false
        - if <proc[drustcraftp_region_location_gamemode].context[<[target_to]>]||SURVIVAL> != CREATIVE:
          - foreach <[target_to].regions||<list[]>> as:target_region:
            - if <proc[drustcraftp_region_player_is_member].context[<[target_region].id>|<[target_region].world.name>|<[target_player].uuid>]||false>:
              - define allow:true
              - foreach stop

            - foreach <proc[drustcraftp_region_member_groups].context[<[target_region].id>|<[target_region].world.name>].filter[starts_with[builder_]]||<list[]>>:
              - if <proc[drustcraftp_group_is_member].context[group_<[value].after[builder_]>|<[target_player]>]>:
                - run drustcraftt_group_add_member def:<[value]>|<[target_player]>
                - define allow:true
                - foreach stop

        - if !<[allow]>:
          - adjust <[target_player]> gamemode:SURVIVAL

        - define show_disabled:false
        - foreach <[target_from].regions||<list[]>> as:target_region:
          - if <proc[drustcraftp_region_player_is_member].context[<[target_region].id>|<[target_region].world.name>|<[target_player].uuid>]>:
            - define show_disabled:true
            - foreach stop

        - debug log <[target_from].regions>
        - if <[show_disabled]>:
          - foreach <proc[drustcraftp_group_player_member_list].context[<[target_player]>].filter[starts_with[builder_]]>:
            - run drustcraftt_group_remove_member context:<[value]>|<[target_player]>

          - narrate '<proc[drustcraftp_msg_format].context[arrow|Builder tools disabled]>'
          - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to build in this region]>'
          - adjust <[target_player]> gamemode:SURVIVAL


drustcraftp_builder_isnoclip:
  type: procedure
  debug: false
  definitions: player
  script:
    - if <[player].location.add[0.4,0,0].material.name> != AIR:
      - determine true
    - if <[player].location.sub[0.4,0,0].material.name> != AIR:
      - determine true
    - if <[player].location.add[0,0,0.4].material.name> != AIR:
      - determine true
    - if <[player].location.sub[0,0,0.4].material.name> != AIR:
      - determine true
    - if <[player].location.add[0.4,1,0].material.name> != AIR:
      - determine true
    - if <[player].location.add[-0.4,1,0].material.name> != AIR:
      - determine true
    - if <[player].location.add[-0.4,1,0].material.name> != AIR:
      - determine true
    - if <[player].location.add[0,1,0.4].material.name> != AIR:
      - determine true
    - if <[player].location.add[0,1,-0.4].material.name> != AIR:
      - determine true
    - if <[player].location.add[0,1.9,0].material.name> != AIR:
      - determine true

    - determine false

drustcraftc_builder:
  type: command
  debug: false
  name: builder
  description: Enables or disables builder mode
  usage: /builder [(toggle|enable|disable)]
  permission: drustcraft.builder
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:builder
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.builder]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Builder tools not loaded. Check console for errors]>'
      - stop

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
            - narrate '<proc[drustcraftp_msg_format].context[error|Builder tools already enabled]>'
          - else:
            - define allow:false

            - if !<player.location.world.name.starts_with[workshop_]> && !<player.has_permission[drustcraft.builder.override]>:
              - foreach <player.location.regions||<list[]>> as:target_region:
                - if <proc[drustcraftp_region_player_is_member].context[<[target_region].id>|<[target_region].world.name>|<player.uuid>]||false> || <proc[drustcraftp_region_player_is_owner].context[<[target_region].id>|<[target_region].world.name>|<player.uuid>]||false>:
                  - define allow:true
                  - foreach stop

                - foreach <proc[drustcraftp_region_member_groups].context[<[target_region].id>|<[target_region].world.name>].filter[starts_with[builder_]]||<list[]>>:
                  - if <proc[drustcraftp_group_is_member].context[group_<[value].after[builder_]>|<player>]>:
                    - run drustcraftt_group_add_member def:<[value]>|<player>
                    - define allow:true
                    - foreach stop
            - else:
              - define allow:true

            - if <[allow]>:
              - adjust <player> gamemode:CREATIVE
              - narrate '<proc[drustcraftp_msg_format].context[arrow|Builder tools enabled]>'

            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to build in this region]>'
        - case disable disabled deny false:
          - if <proc[drustcraftp_region_location_gamemode].context[<player.location>]||SURVIVAL> != CREATIVE:
            - if <player.gamemode> == CREATIVE:
              - adjust <player> gamemode:SURVIVAL

              - foreach <proc[drustcraftp_group_player_member_list].context[<player>].filter[starts_with[builder_]]>:
                - run drustcraftt_group_remove_member context:<[value]>|<player>

              - narrate '<proc[drustcraftp_msg_format].context[arrow|Builder tools disabled]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|Builder tools already disabled]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|You cannot disable builder tools in a creative area]>'
        - default:
          - narrate '<proc[drustcraftp_msg_format].context[error|Unknown option. Try <queue.script.data_key[usage].parsed>]>'
    - else:
      - narrate '<&c>This command can only be run by a player'


drustcraftc_builder_nightvision:
  type: command
  debug: false
  name: nightvision
  description: Toggle night vision
  usage: /nightvision
  aliases:
    - nv
  permission: drustcraft.builder
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  script:
    - if <player.gamemode> == CREATIVE:
      - if <player.has_effect[NIGHT_VISION]>:
        - cast NIGHT_VISION remove <player>
      - else:
        - cast NIGHT_VISION duration:1639s <player> hide_particles no_icon


drustcraftc_builder_noclip:
  type: command
  debug: false
  name: noclip
  description: Toggle noclip
  usage: /noclip
  permission: drustcraft.builder
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  script:
    - if <player.gamemode> == CREATIVE:
      - if <player.has_flag[drustcraft.builder.noclip]>:
        - flag <player> drustcraft.builder.noclip:!
        - narrate '<proc[drustcraftp_msg_format].context[error|No clip has been disabled]>'
      - else:
        - flag <player> drustcraft.builder.noclip:true
        - narrate '<proc[drustcraftp_msg_format].context[error|No clip has been enabled]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|You are required to be in $e/builder $rmode to use this command]>'