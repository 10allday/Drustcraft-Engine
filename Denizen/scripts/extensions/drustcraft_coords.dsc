# Drustcraft - Coords
# Show player coordinates
# https://github.com/drustcraft/drustcraft

drustcraftw_coords:
  type: world
  debug: false
  version: 1
  events:
    on player walks:
      - run drustcraftt_coords.update def:<player>|<context.new_location>

    on player changes gamemode:
      - if <player.has_flag[drustcraft_coords_show]>:
        - flag player drustcraft_coords_show:!
        - sidebar remove


drustcraftt_coords:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - flag player drustcraft_coords_show:!
  
  update:
    - define target_player:<[1]>
    - define target_location:<[2]||<[target_player].location||<empty>>>
    
    - if <[target_player].has_flag[drustcraft_coords_show]> && <[target_location]> != <empty>:
      - define parsed_regions:<[target_player].location.regions.parse[id]||<element[]>>
      - define parsed_regions_str:<elemen
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
      - if <[target_player].selected_npc||<empty>> != <empty>:
        - define 'npc_selected:<&f><[target_player].selected_npc.id> (<[target_player].selected_npc.name.strip_color>)'

      - define npc_nearest:<[target_player].location.find_entities[npc].within[10].get[1]||<empty>>
      - if <[npc_nearest]> != <empty>:
        - define 'npc_nearest:<&f><[npc_nearest].id> (<[npc_nearest].name.strip_color>)'
      - else:
        - define npc_nearest:<&7>(none)
      
      - sidebar set "title:<&e><&l>Location Info" "values:|<&e>POS X: <&f><[target_location].x.round_down>  <&e>Y: <&f><[target_location].y.round_down>  <&e>Z: <&f><[target_location].z.round_down>|<&e>CUR X: <&f><[target_player].cursor_on.x.round_down||-->  <&e>Y: <&f><[target_player].cursor_on.y.round_down||-->  <&e>Z: <&f><[target_player].cursor_on.z.round_down||-->|<&e>NPC Sel: <&f><[npc_selected]>|<&e>NPC Near: <&f><[npc_nearest]>|<&e>Face: <&f><[target_location].yaw.simple>|<&e>Biome: <&f><[target_location].biome.name>|<&e>Rgn: <&f><[parsed_regions_str]>"
    


drustcraftc_coords:
  type: command
  debug: false
  name: coords
  description: Displays your coordinates
  usage: /coords
  permission: drustcraft.coords
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  aliases:
  - where
  - coord
  description: Show world coordinates
  script:
    - if <player.has_flag[drustcraft_coords_show]>:
      - flag player drustcraft_coords_show:!
      - sidebar remove
    - else:
      - if <player.gamemode> == CREATIVE:
        - flag player drustcraft_coords_show:true
        - run drustcraftt_coords.update def:<player>
      - else:
        - narrate '<proc[drustcraftp.message_format].context[error|You cannot use this command outside of $f/builder $rmode]>'