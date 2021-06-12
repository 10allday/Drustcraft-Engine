# Drustcraft - Regions
# World Regions Utilities
# https://github.com/drustcraft/drustcraft

drustcraftw_region:
  type: world
  debug: false
  events:
    on server start:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_region.load
    
    on script reload:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_region.load
    
    after player joins:
      - adjust <player> gamemode:<proc[drustcraftp_region.gamemode].context[<player.location>]||SURVIVAL>
      - if <proc[drustcraftp_region.gamemode].context[<player.location>]> == CREATIVE:
        - adjust <player> gamemode:CREATIVE
  
    on player enters polygon:
      - run drustcraftt_region.show_title def:<context.area.note_name||<empty>>|<player>

    on player enters cuboid:
      - run drustcraftt_region.show_title def:<context.area.note_name||<empty>>|<player>
    
    # on player enters polygon:
    #   - define region_name:<context.area.note_name||<empty>>
    #   - narrate <[region_name]>__ targets:<server.online_players>

    on system time minutely every:20:
      - run drustcraftt_region.spawner.update_all

    on rg|region command:
      - define region_id:<context.args.get[2]||<empty>>
      - if <[region_id]> != <empty> && <[region_id].ends_with[*]>:
        - determine passively fulfilled
        - define region_id:<[region_id].before[*]>

        - foreach <server.list_worlds> as:target_world:
          - foreach <[target_world].list_regions> as:target_region:
            - if <[target_region].id.starts_with[<[region_id]>]>:
              - define args:<context.args.set[<[target_region].id>].at[2]>
              - if <player||<empty>> != <empty>:
                - execute as_player 'rg <[args].space_separated>'
              - else:
                - execute as_server 'rg <[args].space_separated>'
      - else:
        - define args:<context.args>
        - define world_name:<player.location.world.name||<empty>>

        # update world name if flag present
        - foreach <[args]>:
          - if <[value]> == -w:
            - define args:<[args].remove[<[loop_index]>]>
            - if <[args].size> >= <[loop_index]>:
              - define world_name:<[args].get[<[loop_index]>]>
              - define args:<[args].remove[<[loop_index]>]>
            - else:
              - narrate '<&e>World flag used, but no world name entered'
              - determine

            - foreach stop

        - if <[world_name]> == <empty>:
          - narrate 'A world name is required. Use the -w flag'
        - else:
          - choose <context.args.get[1]||<empty>>:
            - case title:
              - determine passively fulfilled

              - if <[args].size> >= 2:
                - define region_name:<[args].get[2]>
                - define region_title:<[args].remove[1|2].space_separated||<empty>>

                - if <world[<[world_name]>].list_regions.parse[id].contains[<[region_name]>]>:
                  - if <[region_title]> != <empty>:
                    - yaml id:drustcraft_regions set regions.<[world_name]>.<[region_name]>.title:<[region_title]>
                    - narrate '<&e>The title for region <&sq><[region_name]><&sq> has been updated to <&sq><[region_title]><&sq>'
                  - else:
                    - yaml id:drustcraft_regions set regions.<[world_name]>.<[region_name]>.title:!
                    - narrate '<&e>The title for region <&sq><[region_name]><&sq> has been cleared'
      
                  - ~run drustcraftt_region.save
                  - run drustcraftt_region.sync
                - else:
                  - narrate '<&c>No region could be found with the name of <&sq><[region_name]><&sq>'
              - else:
                - narrate '<&c>Too few arguments.'
                - narrate '<&c>/rg title <id> [value]'
            
            # TODO
            - case type:
              - determine passively fulfilled

              - if <[args].size> >= 2:
                - define region_name:<[args].get[2]>
                - define region_type:<[args].get[3]||<empty>>

                - if <world[<[world_name]>].list_regions.parse[id].contains[<[region_name]>]>:
                  - if <[region_type]> != <empty>:
                    - yaml id:drustcraft_regions set regions.<[world_name]>.<[region_name]>.type:<[region_type]>
                    - narrate '<&e>The region type for <&sq><[region_name]><&sq> has been updated to <&sq><[region_type]><&sq>'
                  - else:
                    - yaml id:drustcraft_regions set regions.<[world_name]>.<[region_name]>.type:!
                    - narrate '<&e>The region type for <&sq><[region_name]><&sq> has been cleared'
      
                  - ~run drustcraftt_region.save
                  - run drustcraftt_region.sync
                - else:
                  - narrate '<&c>No region could be found with the name of <&sq><[region_name]><&sq>'
              - else:
                - narrate '<&c>Too few arguments.'
                - narrate '<&c>/rg type <id> [value]'
            
            # TODO
            - case template:
              - determine passively fulfilled

              - define region_id:<context.args.get[2]>
              - define template_id:<context.args.get[3]>

              - if <yaml[drustcraft_regions].list_keys[templates].contains[<[template_id]>]>:
                - foreach <yaml[drustcraft_regions].list_keys[templates.<[template_id]>]> as:target_flag:
                  - define flag_value:<yaml[drustcraft_regions].read[templates.<[template_id]>.<[target_flag]>]>

                  - if <[flag_value]> != 'clear':
                    - define flag_value:<&sp><[flag_value]>
                  - else:
                    - define flag_value:<empty>
                  
                  - execute as_player 'rg flag <[region_id]> <[target_flag]><[flag_value]>'
              - else:
                - narrate '<&e>Template not found'

            # TODO
            - case addbiome:
              - determine passively fulfilled
              - if <context.args.size> > 2:
                - define world_name:<player.location.world.name>
                - define region_name:<context.args.get[2]>
                - define biome:<context.args.get[3]>

                - if <[region_name].after_last[_].is_integer>:
                  - define region_name:<[region_name].before_last[_]>

                # TODO: check that biome was entered and is valid

                # TODO: check that region exists
                # check for -w world flag

                - if <yaml[drustcraft_regions].read[regions.<[world_name]>.<[region_name]>.biomes].contains[<[biome]>]>:
                  - narrate '<&e>Biome already added'
                - else:
                  - yaml id:drustcraft_regions set regions.<[world_name]>.<[region_name]>.biomes:->:<[biome]>
                  - narrate '<&e>Biome added'
              
              - run drustcraftt_region.save

            # TODO
            - case rembiome:
              - determine passively fulfilled
              - if <context.args.size> > 2:
                - define world_name:<player.location.world.name>
                - define region_name:<context.args.get[2]>
                - define biome:<context.args.get[3]>

                - if <[region_name].after_last[_].is_integer>:
                  - define region_name:<[region_name].before_last[_]>

                # TODO: check that biome was entered and is valid

                # TODO: check that region exists
                # check for -w world flag

                - if <yaml[drustcraft_regions].read[regions.<[world_name]>.<[region_name]>.biomes].contains[<[biome]>]>:
                  - yaml id:drustcraft_regions set regions.<[world_name]>.<[region_name]>.biomes:<-:<[biome]>
                  - narrate '<&e>Biome removed'
                - else:
                  
                  - narrate '<&e>Biome was not listed'
              
              - run drustcraftt_region.save

            # TODO
            - case biomes:
              - determine passively fulfilled
              - if <context.args.size> > 2:
                - define world_name:<player.location.world.name>
                - define region_name:<context.args.get[2]>
                - define biome:<context.args.get[3]>

                - if <[region_name].after_last[_].is_integer>:
                  - define region_name:<[region_name].before_last[_]>

                # TODO: check that biome was entered and is valid

                # TODO: check that region exists
                # check for -w world flag

                - define biomes:<yaml[drustcraft_regions].read[regions.<[world_name]>.<[region_name]>.biomes]||<list[]>>:
                - if <[biomes].size> > 0:
                  - narrate '<&e><[biomes].separated_by[, ]>'
                - else:
                  - narrate '<&e>Regions is not confined to any biomes'

            - case define create d remove rem delete del redefine update move load reload:
              - define command:<[args].get[1]>
              - define region_name:<[args].get[2]>
              
              - if <list[define|create|move|update|redefine].contains[<[command]>]> && <player.in_group[developer]> == false:
                - define allow:false

                - foreach <player.we_selection.regions.parse[id].exclude[<[region_name]>]>:
                  - define region_id:<region[<[value]>,<player.location.world.name>]>
                  - if <player.we_selection.is_within[<[region_id].cuboid>]||false>:
                    - if <proc[drustcraftp_region.is_member].context[<[region_id]>|<player>]> || <proc[drustcraftp_region.is_owner].context[<[region_id]>|<player>]>:
                      - define allow:true

                - if <[allow]> == false:
                  - narrate '<&c>You can only create or move regions to be inside of a region you are already member or owner'
                  - determine cancelled
              
              - wait 1t

              - if <list[define|create].contains[<[args].get[1]>]>:
                - define region_name:<[args].get[2]||<empty>>
                - if <world[<[world_name]>].list_regions.parse[id].contains[<[region_name]>]>:
                  - if <server.notables[cuboids].parse[note_name].contains[drustcraft_region_<[region_name]>_<[world_name]>]> == false:
                    - execute as_server 'rg addowner <[region_name]> -w <[world_name]> <player.name>'

              - run drustcraftt_region.sync
            
            - case addmember addmem am:
              - wait 1t
              
              - define region_name:<[args].get[2]||<empty>>
              - define items:<[args].remove[1|2].filter[starts_with[g:]]||<list[]>>
              
              - if <world[<[world_name]>].has_region[<[region_name]>]||false>:
                - foreach <[items].parse[after[g:]]>:
                  - if <yaml[drustcraft_regions].read[regions.<[world_name]>.<[region_name]>.members.groups].contains[<[value]>]> == false:
                    - yaml id:drustcraft_regions set regions.<[world_name]>.<[region_name]>.members.groups:->:<[value]>

                - run drustcraftt_region.save

            - case remmember remmem rm:
              - wait 1t
              
              - define region_name:<[args].get[2]||<empty>>
              - define items:<[args].remove[1|2].filter[starts_with[g:]]||<list[]>>
              
              - if <world[<[world_name]>].has_region[<[region_name]>]||false>:
                - foreach <[items].parse[after[g:]]>:
                  - if <yaml[drustcraft_regions].read[regions.<[world_name]>.<[region_name]>.members.groups].contains[<[value]>]>:
                    - yaml id:drustcraft_regions set regions.<[world_name]>.<[region_name]>.members.groups:<-:<[value]>

                - run drustcraftt_region.save
            
            - case addowner ao:
              - wait 1t
              
              - define region_name:<[args].get[2]||<empty>>
              - define items:<[args].remove[1|2].filter[starts_with[g:]]||<list[]>>
              
              - if <world[<[world_name]>].has_region[<[region_name]>]||false>:
                - foreach <[items].parse[after[g:]]>:
                  - if <yaml[drustcraft_regions].read[regions.<[world_name]>.<[region_name]>.owners.groups].contains[<[value]>]||false> == false:
                    - yaml id:drustcraft_regions set regions.<[world_name]>.<[region_name]>.owners.groups:->:<[value]>

                - run drustcraftt_region.save

            - case remowners ro:
              - wait 1t
              
              - define region_name:<[args].get[2]||<empty>>
              - define items:<[args].remove[1|2].filter[starts_with[g:]]||<list[]>>
              
              - if <world[<[world_name]>].has_region[<[region_name]>]||false>:
                - foreach <[items].parse[after[g:]]>:
                  - if <yaml[drustcraft_regions].read[regions.<[world_name]>.<[region_name]>.owners.groups].contains[<[value]>]>:
                    - yaml id:drustcraft_regions set regions.<[world_name]>.<[region_name]>.owners.groups:<-:<[value]>

                - run drustcraftt_region.save
            
            - case info:
              - if <player.has_permission[worldguard.region.info.*]||<context.server>>:
                - wait 1t
                
                - define region_name:<empty>
                - if <[args].size> >= 2:
                  - define region_name:<[args].get[2]||<empty>>
                - else:
                  - define regions:<player.location.regions||<list[]>>
                  - if <[regions].size> == 1:
                    - define region_name:<[regions].get[1].id>
                
                - if <[region_name]> != <empty> && <world[<[world_name]>].has_region[<[region_name]>]||false>:
                  - define title:<proc[drustcraftp_region.title].context[<[world_name]>|<[region_name]>]>
                  - if <[title]> == <empty>:
                    - define title:<&c>(none)
                
                  - narrate '<&9>Title: <&7><[title]>'
                  - narrate '<&9>Biomes: <&6>Grassland'
                  - narrate '<&9>Regenerate: <&6>Gravel (1), Stone (2)'

drustcraftt_region:
  type: task
  debug: false
  script:
    - determine <empty>

  load:
    - if <yaml.list.contains[drustcraft_regions]>:
      - yaml unload id:drustcraft_regions

    - if <server.has_file[/drustcraft_data/regions.yml]>:
      - yaml load:/drustcraft_data/regions.yml id:drustcraft_regions
    - else:
      - yaml create id:drustcraft_regions
      - yaml savefile:/drustcraft_data/regions.yml id:drustcraft_regions

    - run drustcraftt_region.sync


  sync:
    - define only_permissions:<[1]||false>
    - define drustcraft_region_list:<list[]>
    
    - if <[only_permissions]> == false:
      - if <server.plugins.parse[name].contains[dynmap]>:
        - execute as_server 'dmarker deleteset id:town'
        - execute as_server 'dmarker addset id:town Towns hide:false prio:0'
        - execute as_server 'dmarker deleteset id:region'
        - execute as_server 'dmarker addset id:region Regions hide:false prio:0'
        - execute as_server 'dmarker deleteset id:creative'
        - execute as_server 'dmarker addset id:creative Creative hide:false prio:0'
        - execute as_server 'dmarker deleteset id:dungeon'
        - execute as_server 'dmarker addset id:dungeon Dungeon hide:false prio:0'
        - execute as_server 'dmarker deleteset id:battleground'
        - execute as_server 'dmarker addset id:battleground Battlegrounds hide:false prio:0'
        - execute as_server 'dmarker deleteset id:point'
        - execute as_server 'dmarker addset id:point Points hide:false prio:0'

    - foreach <server.worlds> as:target_world:
      - define wg_yml_id:<empty>
      - define path:../WorldGuard/worlds/<[target_world].name>/regions.yml
      - if <server.has_file[<[path]>]>:
        - define wg_yml_id:<util.random.duuid>
        - yaml load:<[path]> id:<[wg_yml_id]>

        - foreach <[target_world].list_regions||<list[]>> as:target_region:
          - define target_cuboid:<[target_region].area||<empty>>
          - define target_notable:<[target_cuboid]>
          - define target_poly:<list[]>
          
          # check if this is a polygon instead of a cuboid
          - if <[target_cuboid].object_type> == polygon:
            - define target_cuboid:<[target_cuboid].bounding_box>
          
          # check if this is a polygon instead of a cuboid (Old code)
#           - if <[target_cuboid]> == <empty> && <yaml[<[wg_yml_id]>].read[regions.<[target_region].id>.type]||<empty>> == poly2d:
#             - define target_poly:<yaml[<[wg_yml_id]>].read[regions.<[target_region].id>.points]||<list[]>>
#             
#             - if <[target_poly].size> >= 3:
#               - define min_y:<yaml[<[wg_yml_id]>].read[regions.<[target_region].id>.min-y]||0>
#               - define max_y:<yaml[<[wg_yml_id]>].read[regions.<[target_region].id>.max-y]||120>
#               - define poly:<list[<location[<[target_poly].get[1].as_map.get[x]>,<[min_y]>,<[target_poly].get[1].as_map.get[z]>]>,<[target_world].name>].to_polygon.include_y[<[max_y]>]>
# 
#               - foreach <yaml[<[wg_yml_id]>].read[regions.<[target_region].id>.points].remove[1]||<list[]>>:
#                 - define loc:<location[<[value].as_map.get[x]>,<[min_y]>,<[value].as_map.get[z]>,<[target_world].name>]>
#                 - define poly:<[poly].with_corner[<[loc]>].include_y[<[min_y]>]>
#                 
#               - define target_cuboid:<[poly].bounding_box>
#               - define target_notable:<[poly]>
                # - note remove as:<[target_region].id>_polygon
                # - note <[poly]> as:<[target_region].id>_polygon
          
          - if <[target_cuboid]> != <empty>:
            - if <[only_permissions]> == false:
              # - note <[target_region].cuboid> as:drustcraft_region_<[target_region].id>_<[target_world].name>
              - note <[target_notable]> as:drustcraft_region_<[target_region].id>_<[target_world].name>
              
              - define region_title:<yaml[drustcraft_regions].read[regions.<[target_world].name>.<[target_region].id>.title]||<empty>>
              - define region_type:<yaml[drustcraft_regions].read[regions.<[target_world].name>.<[target_region].id>.type]||pin>

              - if <[region_title]> != <empty>:
                - choose <[region_type]>:
                  - case town:
                    - define region_map_set:town
                    - define region_map_icon:tower
                  - case creative:
                    - define region_map_set:creative
                    - define region_map_icon:hammer
                  - case dungeon:
                    - define region_map_set:dungeon
                    - define region_map_icon:skull
                  - case region:
                    - define region_map_set:region
                    - define region_map_icon:tree
                  - case battleground:
                    - define region_map_set:battleground
                    - define region_map_icon:theater
                  - default:
                    - define region_map_set:point
                    - define region_map_icon:pin

                # - if <server.plugins.parse[name].contains[dynmap]>:
                #   - if <[target_poly].size> >= 3:
                #     - execute as_server 'dmarker clearcorners'
                #     - foreach <[target_poly]||<list[]>>:
                #       - execute as_server 'dmarker addcorner <[value].as_map.get[x]> 64 <[value].as_map.get[z]> <[target_world].name>'
                #     - execute as_server 'dmarker addarea id:<[target_region].id>_<[target_world].name> "<[region_title]>" icon:<[region_map_icon]>'
                #   - else:
                - execute as_server 'dmarker add id:<[target_region].id>_<[target_world].name> "<[region_title]>" icon:<[region_map_icon]> set:<[region_map_set]> x:<[target_cuboid].center.x.round> y:64 z:<[target_cuboid].center.z.round> world:<[target_cuboid].center.world.name>'
                

              - define drustcraft_region_list:->:drustcraft_region_<[target_region].id>_<[target_world].name>

            - define member_list:<yaml[<[wg_yml_id]>].read[regions.<[target_region].id>.members.groups]||<list[]>>
            - yaml id:drustcraft_regions set regions.<[target_world].name>.<[target_region].id>.members.groups:!
            - foreach <[member_list]>:
              - yaml id:drustcraft_regions set regions.<[target_world].name>.<[target_region].id>.members.groups:->:<[value]>

            - define owner_list:<yaml[<[wg_yml_id]>].read[regions.<[target_region].id>.owners.groups]||<list[]>>
            - yaml id:drustcraft_regions set regions.<[target_world].name>.<[target_region].id>.owners.groups:!
            - foreach <[owner_list]>:
              - yaml id:drustcraft_regions set regions.<[target_world].name>.<[target_region].id>.owners.groups:->:<[value]>

            - define gamemode:<yaml[<[wg_yml_id]>].read[regions.<[target_region].id>.flags].get[game-mode]||<empty>>
            - if <[gamemode]> != <empty>:
              - yaml id:drustcraft_regions set regions.<[target_world].name>.<[target_region].id>.gamemode:<[gamemode]>
            - else:
              - yaml id:drustcraft_regions set regions.<[target_world].name>.<[target_region].id>.gamemode:!
						
						# to keep the entry around if it doesn't have any data
            - yaml id:drustcraft_regions set regions.<[target_world].name>.<[target_region].id>.id:<[target_region].id>
              

        - if <[wg_yml_id]> != <empty>:
          - yaml unload id:<[wg_yml_id]>

    - if <[only_permissions]> == false:
      - foreach <server.notables[cuboids].parse[note_name].filter[starts_with[drustcraft_region_]].exclude[<[drustcraft_region_list]>]||<list[]>>:
        - note remove as:<[value]>
        - yaml id:drustcraft_regions set regions.<[value].after_last[_]>.<[value].before_last[_]>:!
    
    - run drustcraftt_region.save

  save:
    - yaml id:drustcraft_regions savefile:/drustcraft_data/regions.yml

  show_title:
    - define region_name:<[1]>
    - define target_player:<[2]>
    - if <[region_name]> != <empty> && <[region_name].starts_with[drustcraft_region_]>:
      - define world_name:<[region_name].after_last[_]>
      - define region_id:<[region_name].after[drustcraft_region_].before_last[_]>

      - if <[region_id].after_last[_].is_integer>:
        - define region_name:<[region_id].before_last[_]>
      - else:
        - define region_name:<[region_id]>
      
      - define show_title:true

      - if <[show_title]>:
        - define title:<proc[drustcraftp_region.title].context[<[world_name]>|<[region_name]>]>
        
        - if <[title]> != <empty>:
          - define subtitle:<element[]>
          - define type:<proc[drustcraftp_region.is_type].context[<[world_name]>|<[region_name]>]>
          - define prefix:<&f>

          - choose <[type]>:
            - case town:
              - define prefix:<&e>
              - if <[target_player].flag[drustcraft_firstspawn_region_info_town]||1> < 3:
                - narrate '<&e>You are entering a town. You cannot modify blocks or PVP in this region' targets:<[target_player]>
                - flag <[target_player]> drustcraft_firstspawn_region_info_town:++
            - case creative:
              - define prefix:<&2>
              - define 'subtitle:Creative area'
            - case dungeon:
              - define prefix:<&c>
              - define subtitle:Dungeon
              - if <[target_player].flag[drustcraft_firstspawn_region_info_dungeon]||1> < 3:
                - narrate '<&c>You are entering a dungeon area. You cannot modify blocks in this region' targets:<[target_player]>
                - flag <[target_player]> drustcraft_firstspawn_region_info_dungeon:++              
            - case battleground:
              - playsound <[target_player].location> sound:UI_TOAST_CHALLENGE_COMPLETE
              - define prefix:<&6>
              - define subtitle:Battleground
              #- narrate '<&f><[target_player].name> <[prefix]>has entered the battleground <&f><[title]>' targets:<server.online_players.exclude[<[target_player]>]>
              - if <[target_player].flag[drustcraft_firstspawn_region_info_battleground]||1> < 3:
                - narrate '<[prefix]>You are entering a battleground area. Earn rewards for PVP kills in this region' targets:<[target_player]>
                - flag <[target_player]> drustcraft_firstspawn_region_info_battleground:++
          
          - if <player.name.starts_with[*]>:
            - actionbar '<[prefix]><[title]>: <[subtitle]>'
          - else:
            - title subtitle:<[prefix]><[title]>
            - actionbar <[prefix]><[subtitle]>


  spawner:
    add:
      # TODO
      - narrate NA

    remove:
      # TODO
      - narrate NA

    edit:
      # TODO
      - narrate NA
      
    update_all:
      - foreach <yaml[drustcraft_regions].list_keys[regions]> as:target_world:
        - foreach <yaml[drustcraft_regions].list_keys[regions.<[target_world]>]> as:target_region:
          - foreach <yaml[drustcraft_regions].read[regions.<[target_world]>.<[target_region]>.spawner]||<map[]>>:
            - define quantity:10
            - define rate:3
            
            - define values:<[value].split[@]>
            - if <[values].size> > 1:
              - define rate:<[values].get[2]>
            - define quantity:<[values].get[1]>
            
            - define cuboid:<region[<[target_region]>,<[target_world]>].cuboid||<empty>>
            - if <[cuboid]> != <empty>:
              - define current:<region[<[target_region]>,<[target_world]>].cuboid.blocks[<[key]>].size||9999>
              
              - if <[current]> < <[quantity]>:
                - if <[quantity].sub[<[current]>]> < <[rate]>:
                  - define rate:<[quantity].sub[<[current]>]>
                  
                - define attempts:10
                - define max_y:<[cuboid].max.y>
                - while <[attempts]> >= 0 && <[rate]> > 0:
                  - define x:<util.random.int[<[cuboid].min.x>].to[<[cuboid].max.x>]>
                  - define y:<[cuboid].min.y>
                  - define z:<util.random.int[<[cuboid].min.z>].to[<[cuboid].max.z>]>
    
                  - while <[y]> < <[max_y]>:
                    - define loc:<location[<[x]>,<[y]>,<[z]>,<[target_world]>]>
                    - if <[loc].material.name> == air:
                      - modifyblock <location[<[x]>,<[y]>,<[z]>,<[target_world]>]> <[key]>
                      - define rate:--
                      - while stop
                    - else:
                      - define y:++
                  
                  - define attempts:--
                  
  update_spawns:
    - foreach <yaml[drustcraft_regions].list_keys[regions]>:
      - define region_id:<[value]>
      - foreach <yaml[drustcraft_regions].list_keys[regions.<[region_id]>.spawn.materials]||<list[]>>:
        - define material:<[value]>
        - define target_quantity:<yaml[drustcraft_regions].read[regions.<[region_id]>.spawn.materials.<[material]>]||0>
        - define region_cuboid:<yaml[drustcraft_regions].read[regions.<[region_id]>.cuboid]>
        - define quantity:<[region_cuboid].blocks[<[material]>].size>
        
        - if <[quantity]> < <[target_quantity]> && <[region_cuboid].players.size> == 0:
          - define count:<[target_quantity].sub[<[quantity]>]>
          
          - if <[count]> > 3:
            - define count:3
          
          - while <[count]> > 0:
            - define x:<util.random.int[<[region_cuboid].min.x>].to[<[region_cuboid].max.x>]>
            - define y:<[region_cuboid].min.y>
            - define max_y:<[region_cuboid].max.y>
            - define z:<util.random.int[<[region_cuboid].min.z>].to[<[region_cuboid].max.z>]>

            - while <[y]> < <[max_y]>:
              - define loc:<location[<[x]>,<[y]>,<[z]>,<[region_cuboid].world.name>]>
              - if <[loc].material.name> == air && <[loc].find_entities.within[1].size> == 0:
                - modifyblock <location[<[x]>,<[y]>,<[z]>,<[region_cuboid].world.name>]> <[material]>
                - define count:--
                - while stop
              - else:
                - define y:++

drustcraftp_region:
  type: procedure
  debug: false
  script:
    - determine <empty>

  is_member:
    - define target_region:<[1]||<empty>>
    - define target_player:<[2]||<empty>>
    
    - if <[target_region].members.contains[<[target_player]>]>:
      - determine true

    - foreach <yaml[drustcraft_regions].read[regions.<[target_region].world.name>.<[target_region].id>.members.groups]||<list[]>>:
      - if <proc[drustcraftp_group.in_group].context[<[value]>|<[target_player]>]>:
        - determine true
    
    - determine false
      
  is_owner:
    - define target_region:<[1]||<empty>>
    - define target_player:<[2]||<empty>>
    
    - if <[target_region].owners.contains[<[target_player]>]>:
      - determine true

    - foreach <yaml[drustcraft_regions].read[regions.<[target_region].world.name>.<[target_region].id>.owners.groups]||<list[]>>:
      - if <proc[drustcraftp_group.in_group].context[<[value]>|<[target_player]>]>:
          - determine true

    - determine false

  find_map:
    - define target_location:<[1]||<empty>>
    - define found_regions:<map.with[__global__].as[-1]>

    - if <[target_location]> != <empty> && <[target_location].object_type> == Location:
      - foreach <[target_location].regions>:
        - define found_regions:<[found_regions].with[<[value].id>].as[<yaml[drustcraft_regions].read[regions.<[target_location].world.name>.<[value].id>.priority]||0>]>
      
      # sort found regions by priority (high to low)
      - define found_regions:<[found_regions].sort_by_value>
      
      - define found_regions:<[found_regions].get_subset[<[found_regions].keys.reverse>]>
      
      # iterate regions, set target_region what should be the first region by biome settings
      - define target_region:<empty>
      - foreach <[found_regions].keys>:
        - define biomes:<yaml[drustcraft_regions].read[regions.<[target_location].world.name>.<[value]>.biomes]||<list[]>>
        - if <[biomes].size> > 0:
          - if <[biomes].contains[<[target_location].biome.name>]>:
            - define target_region:<[value]>
            - foreach stop
        - else:
          - define target_region:<[value]>
          - foreach stop

      # first region in found_regions is not the first region by biome, so change it!
      - if <[target_region]> != <empty> && <[target_region]> != <[found_regions].keys.get[1]||<empty>>:
        - define sort_list:<[found_regions].keys.exclude[<[target_region]>].insert[<[target_region]>].at[1]>
        - define found_regions:<[found_regions].get_subset[<[sort_list]>]>
  
    - determine <[found_regions]>

  find:
    - define target_location:<[1]||<empty>>
    - define region_map:<proc[drustcraftp_region.find_map].context[<[target_location]>]>

    - if <[region_map].size> > 0:
      - determine <[region_map].keys.get[1]||<empty>>

    - determine __global__

  gamemode:
    - define target_location:<[1]||<empty>>
    - define region_name:<[2]||<empty>>

    - if <[target_location]> != <empty>:
      - define world_name:<empty>
      
      - if <[target_location].object_type> == location:
        - define region_name:<proc[drustcraftp_region.find].context[<[target_location]>]>
        - define world_name:<[target_location].world.name||<empty>>
      - else:
        - define world_name:<[target_location]>
      
      - determine <yaml[drustcraft_regions].read[regions.<[world_name]>.<[region_name]>.gamemode]||SURVIVAL>
    
    - determine SURVIVAL

  list:
    - define target_world:<[1]||<empty>>
    - define regions:<list[]>
    
    - if <[target_world]> == <empty>:
      - foreach <yaml[drustcraft_regions].list_keys[regions]||<list[]>>:
        - define regions:<[regions].include[<yaml[drustcraft_regions].list_keys[regions.<[value]>]||<list[]>>]>
    - else:
      - define regions:<yaml[drustcraft_regions].list_keys[regions.<[target_world]>]||<list[]>>
    
    - determine <[regions]>
        
  title:
    - define target_world:<[1]||<empty>>
    - define target_region:<[2]||<empty>>
    
    - if <[target_world]> != <empty> && <[target_region]> != <empty>:
      - determine <yaml[drustcraft_regions].read[regions.<[target_world]>.<[target_region]>.title]||<empty>>
    - determine <empty>

  is_type:
    - define target_world:<[1]||<empty>>
    - define target_region:<[2]||<empty>>
    
    - if <[target_world]> != <empty> && <[target_region]> != <empty> && <yaml[drustcraft_regions].read[regions.<[target_world]>.<[target_region]>.title]||<empty>> != <empty>:
      - determine <yaml[drustcraft_regions].read[regions.<[target_world]>.<[target_region]>.type]||pin>
    - determine <empty>
