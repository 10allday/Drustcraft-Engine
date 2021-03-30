# Drustcraft - Coords
# Show player coordinates
# https://github.com/drustcraft/drustcraft

drustcraftw_coords:
  type: world
  debug: false
  events:
    on player walks:
      - if <player.has_flag[drustcraft_coords_show]>:
        - define parsed_regions:<player.location.regions.parse[id].comma_separated||<element[]>>
        - if <[parsed_regions].length> == 0:
          - define parsed_regions:<&7>(none)
        
        - actionbar "<&e>X: <&f><context.new_location.x.round_down>   <&e>Y: <&f><context.new_location.y.round_down>   <&e>Z: <&f><context.new_location.z.round_down>   <&e>Face: <&f><context.new_location.yaw.simple>   <&e>Biome: <&f><context.new_location.biome.name>   <&e>Rgn: <&f><[parsed_regions]>"
      - else if <player.has_flag[drustcraft_coords_pointer]>:
        - actionbar "<&e>X: <&f><player.cursor_on.x.round_down>   <&e>Y: <&f><player.cursor_on.y.round_down>   <&e>Z: <&f><player.cursor_on.z.round_down>"


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
    - else:
      - flag player drustcraft_coords_show:true
      - flag player drustcraft_coords_pointer:!


drustcraftc_coords_pointer:
    type: command
    debug: false
    name: pointer
    description: Displays the coordinates you are looking at
    usage: /pointer
    permission: drustcraft.coords
    permission message: <&c>I'm sorry, you do not have permission to perform this command
    script:
      - if <player.has_flag[drustcraft_coords_pointer]>:
        - flag player drustcraft_coords_pointer:!
      - else:
        - flag player drustcraft_coords_pointer:true
        - flag player drustcraft_coords_show:!
