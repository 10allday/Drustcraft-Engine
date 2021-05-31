# Drustcraft - Mobs
# Mobs
# https://github.com/drustcraft/drustcraft

drustcraftw_mobs:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_mobs.load
    
    on script reload:
      - run drustcraftt_mobs.load

    on entity damaged by player:
      - define loc:<context.entity.location.left[<list[-1|1].random>]>
      - fakespawn 'armor_stand[visible=false;custom_name=<&c><context.final_damage.round_down>;custom_name_visibility=true;gravity=false]' <[loc]> save:newhologram d:2s players:<context.entity.location.find.players.within[20]>

drustcraftt_mobs:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <yaml.list.contains[drustcraft_mobs]>:
      - ~yaml unload id:drustcraft_mobs

    - if <server.has_file[/drustcraft_data/mobs.yml]>:
      - yaml load:/drustcraft_data/mobs.yml id:drustcraft_mobs
    - else:
      - yaml create id:drustcraft_mobs
      - yaml savefile:/drustcraft_data/mobs.yml id:drustcraft_mobs
