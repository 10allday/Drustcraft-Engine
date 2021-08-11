# Drustcraft - Coords
# Show player coordinates
# https://github.com/drustcraft/drustcraft

drustcraftw_coords:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_coords_load

    on script reload:
      - run drustcraftt_coords_load

    on player walks:
      - run drustcraftt_coords_update def:<player>|<context.new_location>

    on player changes gamemode:
      - if <player.has_flag[drustcraft.coords]>:
        - flag player drustcraft.coords:!
        - sidebar remove

    on player quits:
      - if <player.has_flag[drustcraft.coords]>:
        - flag player drustcraft.coords:!
        - sidebar remove

    on npc command:
      - wait 5t
      - run drustcraftt_coords_update def:<player>


drustcraftt_coords_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - flag server drustcraft.module.coords:<script[drustcraftw_coords].data_key[version]>


drustcraftt_coords_update:
  type: task
  debug: false
  definitions: player|location
  script:
    - define location:<[location]||<[player].location||<empty>>>

    - if <[player].has_flag[drustcraft.coords]> && <[location]> != <empty>:
      - define parsed_regions:<[player].location.regions.parse[id]||<element[]>>
      - define parsed_regions_str:<element[]>
      - if <[parsed_regions].size> == 0:
        - define parsed_regions_str:<&7>(none)
      - else:
        - define parsed_regions_str:<[parsed_regions].get[1]>
        - foreach <[parsed_regions].remove[1]>:
          - if <[value].length.add[<[parsed_regions_str].length>]> > 14:
            - define parsed_regions_str:<[parsed_regions_str]>,|<[value]>
          - else:
            - define 'parsed_regions_str:<[parsed_regions_str]>, <[value]>'

      - define npc_selected:<&7>(none)
      - if <[player].selected_npc||<empty>> != <empty>:
        - define 'npc_selected:<&f><[player].selected_npc.id> (<[player].selected_npc.name.strip_color>)'

      - define npc_nearest:<[player].location.find_entities[npc].within[10].get[1]||<empty>>
      - if <[npc_nearest]> != <empty>:
        - define 'npc_nearest:<&f><[npc_nearest].id> (<[npc_nearest].name.strip_color>)'
      - else:
        - define npc_nearest:<&7>(none)

      - sidebar set "title:<&e><&l>Location Info" "values:|<&e>POS X: <&f><[location].x.round_down>  <&e>Y: <&f><[location].y.round_down>  <&e>Z: <&f><[location].z.round_down>|<&e>CUR X: <&f><[player].cursor_on.x.round_down||-->  <&e>Y: <&f><[player].cursor_on.y.round_down||-->  <&e>Z: <&f><[player].cursor_on.z.round_down||-->|<&e>NPC Sel: <&f><[npc_selected]>|<&e>NPC Near: <&f><[npc_nearest]>|<&e>Face: <&f><[location].yaw.simple>|<&e>Biome: <&f><[location].biome.name>|<&e>Rgn: <&f><[parsed_regions_str]>"


drustcraftc_coords:
  type: command
  debug: false
  name: coords
  description: Displays your coordinates
  usage: /coords
  permission: drustcraft.coords
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:coords
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.coords]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Drustcraft module not yet loaded. Check console for any errors]>'
      - stop

    - if !<context.server||false>:
      - if <player.has_flag[drustcraft.coords]>:
        - flag player drustcraft.coords:!
        - sidebar remove
      - else:
        - if <player.gamemode> == CREATIVE:
          - flag player drustcraft.coords:true
          - run drustcraftt_coords_update def:<player>
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|You cannot use this command outside of $e/builder $rmode]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|This command can only be run by players]>'