# Drustcraft - Player
# Player Management
# https://github.com/drustcraft/drustcraft

drustcraftw_player:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_player.load
      
    on script reload:
      - run drustcraftt_player.load

    on player death:
      - determine passively KEEP_INV
      - determine passively NO_DROPS

      - foreach <player.inventory.map_slots> as:item:
        - define skip:false
        - foreach <yaml[drustcraft_player].read[no_death_drop]||<list[]>> as:check_proc:
          - if <proc[<[check_proc]>].context[<[item]>]>:
            - define skip:true
            - foreach stop
          
        - if <[skip]> == false:
          - take <[item]> quantity:<[item].quantity> from:<player.inventory>
          - drop <[item]> <cuboid[<player.location.add[-2,-2,-2]>|<player.location.add[2,2,2]>].spawnable_blocks.random>
      
      
drustcraftt_player:
  type: task
  debug: false
  script:
    - determine <empty>
    
  load:
    - if <yaml.list.contains[drustcraft_player]>:
      - ~yaml unload id:drustcraft_player
    - yaml create id:drustcraft_player
  
  register_no_death_drop:
    - yaml id:drustcraft_player set no_death_drop:|:<[1]>