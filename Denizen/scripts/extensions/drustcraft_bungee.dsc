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
    - flag server drustcraft_bungee:!
    - flag server drustcraft_bungee_master:!
    - flag server drustcraft_bungee_priority:!
    
    - if <server.plugins.contains[Depenizen]> && <bungee.server||<empty>> != <empty>:
      - if <yaml.list.contains[drustcraft_bungee]>:
        - ~yaml id:drustcraft_bungee unload
      - ~yaml id:drustcraft_bungee create
    
      - run drustcraftt_bungee.challenge
      - debug log 'Drustcraft Bungee loaded'
    - else:
      - debug log 'Drustcraft Bungee did not load because this server is not connected to BungeeCord'
    
  register:
    - define bungee_cmd:<[1]||<empty>>
    - define task_name:<[2]||<empty>>
    
    - if <[bungee_cmd]> != <empty> && <[task_name]> != <empty>:
      - yaml id:drustcraft_bungee set bungee.commands.<[bungee_cmd]>:<[task_name]>
  
  run:
    - bungeerun <bungee.list_servers> _drustcraftt_bungee_run def:<queue.definition_map.exclude[raw_context].values>
  
  challenge:
    - if <server.flag[drustcraft_bungee_priority]||<empty>> == <empty>:
      - flag server drustcraft_bungee_priority
    
    - define master:true
    
    - while !<server.has_flag[drustcraft_bungee_priority]>:
      - define master:true

      - flag server drustcraft_bungee_priority:<util.random.int[1].to[1000]>
      - foreach <bungee.list_servers>:
        - ~bungeetag server:<[value]> <server.flag[drustcraft_bungee_priority]> save:drustcraft_bungee_priority
        - if <entry[drustcraft_bungee_priority].result||0> == <server.flag[drustcraft_bungee_priority]>:
          - flag server drustcraft_bungee_priority:!
        - else if <entry[drustcraft_bungee_priority]||0> < <server.flag[drustcraft_bungee_priority]>:
          - define master:false
        
        - ~bungeetag server:<[value]> <server.flag[drustcraft_bungee_master]> save:drustcraft_bungee_master
        - if <entry[drustcraft_bungee_master].result||false> != false:
          - define master:false
      
      - if <[master]>:
        - flag server drustcraft_bungee_master:true
        - debug log '<server.bungee> is now the Bungee master server'
    

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