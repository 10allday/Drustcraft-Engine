# Drustcraft - Bungee Utilities
# Gives players creative mode in defined areas
# https://github.com/drustcraft/drustcraft

drustcraftw_bungee:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_bungee.load

    on script reload:
      - run drustcraftt_bungee.load


drustcraftt_bungee:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <yaml.list.contains[drustcraft_bungee]>:
      - ~yaml id:drustcraft_bungee unload
    - ~yaml id:drustcraft_bungee create
    
  register:
    - define bungee_cmd:<[1]||<empty>>
    - define task_name:<[2]||<empty>>
    
    - if <[bungee_cmd]> != <empty> && <[task_name]> != <empty>:
      - yaml id:drustcraft_bungee set bungee.commands.<[bungee_cmd]>:<[task_name]>
  
  run:
    - bungeerun <bungee.list_servers> _drustcraftt_bungee_run def:<queue.definition_map.exclude[raw_context].values>
        

_drustcraftt_bungee_run:
  type: task
  debug: false
  script:
    - if <bungee.server||<empty>> != <empty>:
      - define def_map:<queue.definition_map.exclude[raw_context]>
      - define command:<[def_map].get[1]||<empty>>
      - define def_pass:<[def_map].exclude[1].values>
      - define task_name:<yaml[drustcraft_bungee].read[bungee.commands.<[command]>]||<empty>>
      - if <[task_name]> != <empty>:
        - run <[task_name]> def:<[def_pass]>