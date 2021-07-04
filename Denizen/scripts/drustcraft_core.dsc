# Drustcraft - Core
# The bare core of Drustcraft
# https://github.com/drustcraft/drustcraft

drustcraftw:
  type: world
  debug: false
  version: 1
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

drustcraftp:
  type: procedure
  debug: false
  script:
    - determine <empty>
  
  message_format:
    - define type:<[1]||<empty>>
    - define message:<[2]||<empty>>
    
    - choose <[type]>:
      - case warning:
        - define 'prefix:<&8><&l>[<&c><&l>-<&8><&l>] <&e>'
      - case error:
        - define 'prefix:<&8><&l>[<&c><&l>!<&8><&l>] <&c>'
      - case announcement:
        - define 'prefix:<&8><&l>[<&6><&l>!!!<&8><&l>] <&6>'
      - default:
        - define 'prefix:<&8><&l>[<&a><&l>+<&8><&l>] <&e>'
      
      - determine <[prefix]><[message].replace_text[%f].with[<&f>].replace_text[%r].with[<&e>]>
