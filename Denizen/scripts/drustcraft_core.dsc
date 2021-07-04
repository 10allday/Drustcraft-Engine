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
  debug: true
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
  
  script_exists:
    - define script_name:<[1]||<empty>>
    
    - if <[script_name]> != <empty>:
      - define script_key:<[script_name].after[.]>
      - define script_name:<[script_name].before[.]>
      
      - if <server.scripts.parse[name].contains[<[script_name]>]>:
        - if <[script_key].length> == 0 || <script[<[script_name]>].list_keys.contains[<[script_key]>]>:
          - determine TRUE
    
    - determine FALSE
  
  determine_map:
    - define determine_list:<queue.definition[raw_context]||<empty>>
    - define determine_map:<map[]>
    
    - if <[determine_list].object_type> == LIST:
      - foreach <[determine_list]>:
        - define key:<[value].before[:]>
        - define val:<[value].after[:]>
        
        - if <[val].length> == 0:
          - define val:true
        
        - define determine_map:<[determine_map].with[<[key]>].as[<[val]>]>
    
    - determine <[determine_map]>
