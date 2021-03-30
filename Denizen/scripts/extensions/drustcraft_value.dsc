# Drustcraft - Values
# Value of items
# https://github.com/drustcraft/drustcraft

drustcraftw_value:
  type: world
  debug: false
  events:
    on server starts:
      - run drustcraftt_value.load
    
    on script reload:
      - run drustcraftt_value.load


drustcraftt_value:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <yaml.list.contains[drustcraft_value]>:
      - ~yaml unload id:drustcraft_value

    - if <server.has_file[/drustcraft_data/value.yml]>:
      - yaml load:/drustcraft_data/value.yml id:drustcraft_value
    - else:
      - yaml create id:drustcraft_value
      - yaml savefile:/drustcraft_data/value.yml id:drustcraft_value

    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_tab_complete]>

      - run drustcraftt_tab_complete.completions def:value|get|_*materials
      - run drustcraftt_tab_complete.completions def:value|set|_*materials|_*value
  
  save:
    - if <yaml.list.contains[drustcraft_value]>:
      - yaml savefile:/drustcraft_data/value.yml id:drustcraft_value


drustcraftp_value:
  type: procedure
  debug: false
  script:
    - determine <empty>
  
  get:
    - define material:<[1]||<empty>>
    - determine <yaml[drustcraft_value].read[materials.<[material]>.value]||0>
    

drustcraftc_value:
  type: command
  debug: false
  name: value
  description: Gets or sets item values
  usage: /value <&lt>get|set<&gt> <&lb>material<&rb>
  permission: drustcraft.value
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:value
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case get:
        - define material:<context.args.get[2]||<empty>>
        - if <server.material_types.parse[name].contains[<[material]>]>:
          - define value:<yaml[drustcraft_value].read[materials.<[material]>.value]||0>
          - narrate '<&e>The material <&f><[material]> <&e>has a value of <&f><[value]> <&e>emeralds'
        - else:
          - narrate '<&e>The material <&f><[material]> <&e>was not found on this server'
      
      - case set:
        - define material:<context.args.get[2]||<empty>>
        - define value:<context.args.get[3]||0>
        - if <server.material_types.parse[name].contains[<[material]>]>:
          - if <[value].is_decimal>:
            - yaml id:drustcraft_value set materials.<[material]>.value:<[value]>
            - run drustcraftt_value.save
            
            - narrate '<&e>The material <&f><[material]> <&e>now has a value of <&f><[value]> <&e>emeralds'
          - else:
            - narrate '<&e>The value <&f><[value]> <&e>is required to be a decimal number'
        - else:
          - narrate '<&e>The material <&f><[material]> <&e>was not found on this server'
      
      - default:
        - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
  

drustcraftp_tab_complete_value:
  type: procedure
  debug: false
  script:
    - determine <list[0.05|0.1|0.2|0.5|1|2|3|5|10|15|20]>
