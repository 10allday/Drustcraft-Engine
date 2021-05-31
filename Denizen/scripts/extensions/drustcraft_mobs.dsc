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
