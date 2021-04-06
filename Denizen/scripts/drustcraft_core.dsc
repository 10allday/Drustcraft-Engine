# Drustcraft - Core
# The bare core of Drustcraft
# https://github.com/drustcraft/drustcraft

drustcraftw:
  type: world
  debug: false
  events:
    on server start:
      - ~run drustcraftt.load      
      - foreach <yaml[drustcraft_server].read[drustcraft.run.startup]||<list[]>>:
        - execute as_server <[value]>

    on script reload:
      - ~run drustcraftt.load
      - foreach <yaml[drustcraft_server].read[drustcraft.run.reload]||<list[]>>:
        - execute as_server <[value]>

drustcraftt:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <yaml.list.contains[drustcraft_server]>:
      - ~yaml unload id:drustcraft_server

    - if <server.has_file[/drustcraft_data/server.yml]>:
      - yaml load:/drustcraft_data/server.yml id:drustcraft_server
    - else:
      - yaml create id:drustcraft_server
      - yaml savefile:/drustcraft_data/server.yml id:drustcraft_server
    
    - foreach <server.notables>:
      - note remove as:<[value].note_name>
