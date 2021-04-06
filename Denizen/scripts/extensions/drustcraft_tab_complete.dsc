# Drustcraft - Tab Complete
# Provides a Tab Complete engine for Commands
# https://github.com/drustcraft/drustcraft

drustcraftw_tab_complete:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_tab_complete.load


    on script reload:
      - run drustcraftt_tab_complete.load


drustcraftt_tab_complete:
  type: task
  debug: false
  script:
    - determine <empty>
  
  
  load:
    - if <yaml.list.contains[drustcraft_tab_complete]>:
      - ~yaml unload id:drustcraft_tab_complete
    - yaml create id:drustcraft_tab_complete

  completions:
    - yaml id:drustcraft_tab_complete set <queue.definition_map.exclude[raw_context].values.separated_by[.]>:end


drustcraftp_tab_complete:
  type: procedure
  debug: false
  definitions: command|raw_args
  script:
    - define raw_args:<[raw_args]||<empty>>
    - define path:<[command]>
    - define 'args:|:<[raw_args].split[ ]>'
    - if <[args].get[1]||<empty>> == <empty>:
      - define args:!|:<[args].remove[1]>
    - define argsSize:<[args].size>
    - define newArg:<[raw_args].ends_with[<&sp>].or[<[raw_args].is[==].to[<empty>]>]>
    - if <[newArg]>:
      - define argsSize:+:1
    - repeat <[argsSize].sub[1]> as:index:
      - define value:<[args].get[<[index]>]>
      - define keys:!|:<yaml[drustcraft_tab_complete].list_keys[<[path]>]||<list[]>>
      - define permLockedKeys:!|:<[keys].filter[starts_with[?]]> 
      - define keys:<-:<[permLockedKeys]>
      - if <[value]> == <empty>:
        - foreach next
      - if <[keys].contains[<[value]>]>:
        - define path:<[path]>.<[value]>
      - else if <[keys].contains[*]>:
        - define path:<[path]>.*  
      - else:
        - if <[permLockedKeys].size> > 0:
          - define permMap:'<[permLockedKeys].parse[after[ ]].map_with[<[permLockedKeys].parse[before[ ]]>]>'
          - define perm:<[permMap].get[<[value]>]||null>
          - if <[perm]> != null && <player.has_permission[<[perm].after[?]>]>:
            - define path:'<[path]>.<[perm]> <[value]>'
            - repeat next
        - define default <[keys].filter[starts_with[_]].get[1]||null>
        - if <[default]> == null:
          - determine <list[]>
        - define path:<[path]>.<[default]>
      - if <yaml[drustcraft_tab_complete].read[<[path]>]> == end:
        - determine <list[]>
    
    - foreach <yaml[drustcraft_tab_complete].list_keys[<[path]>]||<list[]>>:
      - if <[value].starts_with[_]>:
        - define value:<[value].after[_]>
        - if <[value].starts_with[*]>:
          - define ret:|:<proc[drustcraftp_tab_complete_<[value].after[*]>].context[<[args]>]>
        - if <[value].starts_with[&]>:
          - if <[raw_args].ends_with[,]>:
            - define parg:<[args].get[<[argsSize].sub[1]>]>
            - define clist:<proc[drustcraftp_tab_complete_<[value].after[&]>].context[<[args]>]>
            - foreach <[clist]>:
              - define ret:|:<[parg]><[value]>
          - else:
            - define ret:|:<proc[drustcraftp_tab_complete_<[value].after[&]>].context[<[args]>]>
        - if <[value].starts_with[^]>:
          - if <[raw_args].ends_with[,]>:
            - define parg:<[args].get[<[argsSize].sub[1]>]>
            - define pitems:<[parg].split[,]>
            - define clist:<proc[drustcraftp_tab_complete_<[value].after[^]>].context[<[args]>]>
            - foreach <[clist]>:
              - if <[pitems].contains[<[value]>]> == false:
                - define ret:|:<[parg]><[value]>
          - else:
            - define ret:|:<proc[drustcraftp_tab_complete_<[value].after[^]>].context[<[args]>]>
      - else if <[value].starts_with[?]>:
        - define perm:'<[value].before[ ].after[?]>'
        - if <player.has_permission[<[perm]>]>:
          - define 'ret:|:<[value].after[ ]>'
      - else:
        - define ret:->:<[value]>
    - if !<definition[ret].exists>:
      - determine <list[]>
    - if <[newArg]>:
      - determine <[ret]>
    - determine <[ret].filter[starts_with[<[args].last>]]>


drustcraftp_tab_complete_int:
  type: procedure
  debug: false
  script:
    - determine <list[0|1|2|3|4|5|6|7|8|9]>


drustcraftp_tab_complete_materials:
  type: procedure
  debug: false
  script:
    - determine <server.material_types.parse[name]>


drustcraftp_tab_complete_groups:
  type: procedure
  debug: false
  script:
    - determine <server.permission_groups>


drustcraftp_tab_complete_durations:
  type: procedure
  debug: false
  script:
    - determine <list[5m|10m|15m|30m|1h|2h|4h|1d|2d|3d|1w|2w|4w]>


drustcraftp_tab_complete_pageno:
  type: procedure
  debug: false
  script:
    - determine <list[1|2|3|4|5|6|7|8|9]>


drustcraftp_tab_complete_players:
  type: procedure
  debug: false
  script:
    - determine <server.players.parse[name]>


drustcraftp_tab_complete_npcs:
  type: procedure
  debug: false
  script:
    - determine <server.npcs.parse[id]>
