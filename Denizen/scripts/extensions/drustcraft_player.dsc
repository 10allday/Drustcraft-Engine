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
          - take slot:<[key]> quantity:<[item].quantity>
          - drop <[item]> <player.location.add[-2,-2,-2].to_cuboid[<player.location.add[2,2,2]>].spawnable_blocks.random||<player.location>>
    
    after player joins:
      - define time_now:<util.time_now>
      - define cake_day:false
      - flag player drustcraft_player_cakeday:false
      
      - if <player.first_played_time.month> == <[time_now].month> && <player.first_played_time.year> == <[time_now].year>:
        - if <[time_now].month> == 2 && <[time_now].day> == 28 && <[time_now].days_in_month> != 29 && <player.first_played_time.day> == 29:
          - define cake_day:true
        - else:
          - if <player.first_played_time.day> == <[time_now].day>:
            - define cake_day:true
        
        - if <[cake_day]>:
          - if <player.first_played_time.year> != <[time_now].year>:
            - flag player drustcraft_player_cakeday:true
            
            - narrate '<&2>★<&3>★<&4>★<&5>★<&6>★ <&f>Today is <player.name> cake day! <&6>★<&5>★<&4>★<&3>★<&2>★' targets:<server.online_players>
            - playsound <server.online_players> sound:ENTITY_FIREWORK_ROCKET_LAUNCH sound_category:AMBIENT
            - wait 1s
            - playsound <server.online_players> sound:ENTITY_FIREWORK_ROCKET_LAUNCH sound_category:AMBIENT
            - wait 0.5s
            - playsound <server.online_players> sound:ENTITY_FIREWORK_ROCKET_LAUNCH sound_category:AMBIENT
            - wait 0.5s
            - playsound <server.online_players> sound:ENTITY_FIREWORK_ROCKET_TWINKLE sound_category:AMBIENT
            - wait 0.5s
            - playsound <server.online_players> sound:ENTITY_FIREWORK_ROCKET_TWINKLE sound_category:AMBIENT
            - wait 0.2s
            - playsound <server.online_players> sound:ENTITY_FIREWORK_ROCKET_TWINKLE sound_category:AMBIENT
            
            - if <player.has_flag[drustcraft_player_cakeday_<[time_now].year>_received]> == false:
              - flag player drustcraft_player_cakeday_<[time_now].year>_received:true
    
    on player teleports:
      - if <context.origin.world> != <context.destination.world>:
        - define drustcraft_last_locations:<player.flag[drustcraft_last_locations]||<map[]>>        
        - flag player drustcraft_last_locations:<[drustcraft_last_locations].with[<context.origin.world.name>].as[<context.origin>]>
    
    on entity death:
      - if <context.entity.is_player||false> || <context.entity.is_npc||false>:
        - if <context.damager.is_player||false>:
          - foreach <context.entity.location.regions||<list[]>>:
            - if <proc[drustcraftp_region.is_type].context[<[value].world.name>|<[value].id>]||<empty>> == battleground:
              - drop <item[player_head[skull_skin=<context.entity.skull_skin>|<context.entity.name>]]> <context.entity.location.random_offset[3,0,3]> quantity:1


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