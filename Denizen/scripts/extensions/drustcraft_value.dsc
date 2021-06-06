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
    - define change:<[2]||1>
    - define single:<[3]||false>
    - determine <proc[drustcraftp_value.convert_value].context[<yaml[drustcraft_value].read[materials.<[material]>.value]||0>|<[change]>|<[single]>]>
    
  convert_value:
    - define lookup_value:<[1]>
    - define change:<[2]||1>
    - define single:<[3]||false>
    - define item_value:<[lookup_value]>
    - define item_value_mod:0
    - define netherite_blocks:0
    - define netherite_ingots:0
    - define emeralds:0
    - define iron_ingots:0
    - define min_items:1
    - define qty:1

    - while true: 
      - define item_value:<[lookup_value].mul[<[qty]>].mul[<[change]>]>

      - define netherite_blocks:0
      - define netherite_ingots:0
      - define emeralds:0
      - define gold_ingots:0
      - define iron_ingots:0
      - define min_items:1
 
      - if <[lookup_value]> < 2:
        - define mod_list:<list[0|0.03|0.06|0.13|0.25|0.38|0.5|0.63|0.75|0.88|1|1.13|1.25|1.38|1.5|1.63|1.75|1.88|2]>
        - define min_items_list:<list[1|8|4|2|1|2|1|2|1|2|1|2|1|2|1|2|1|2|1]>
        - define iron_ingots_list:<list[0|1|1|1|1|3|1|5|3|7|4|9|5|11|6|13|7|15|8]>
        - foreach <[mod_list]>:
          - if <[item_value]> <= <[value]>:
            - define min_items:<[min_items_list].get[<[loop_index]>]>
            - define iron_ingots:<[iron_ingots_list].get[<[loop_index]>]>
            - foreach stop
      - else:
        - define netherite_blocks:<[item_value].div[117].round_down>
        - define item_value:<[item_value].sub[<[netherite_blocks].mul[117]>]>
        - define netherite_ingots:<[item_value].div[13].round_down>
        - define item_value:<[item_value].sub[<[netherite_ingots].mul[13]>]>
        - define item_value_mod:<[item_value].mod[1].round_to[2]>
        - define emeralds:<[item_value].round_down>
        - define iron_ingots:<[item_value_mod].round_to_precision[0.25].div[0.25].round_down>

      - if <[netherite_blocks]> <= 7 && <[netherite_blocks].mul[9].add[<[netherite_ingots]>]> <= 64:
        - define netherite_ingots:<[netherite_ingots].add[<[netherite_blocks].mul[9]>]>
        - define netherite_blocks:0
      - if <[netherite_ingots]> <= 4 && <[netherite_ingots].mul[13].add[<[emeralds]>]> <= 64:
        - define emeralds:<[emeralds].add[<[netherite_ingots].mul[13]>]>
        - define netherite_ingots:0
      - if <[iron_ingots]> > 0:
        - if <[iron_ingots].mod[4]> == 0 || <[netherite_blocks].add[<[netherite_ingots]>]> == 0:
          - define emeralds:<[emeralds].add[<[iron_ingots].div[4].round_down>]>
          - define iron_ingots:<[iron_ingots].mod[4].round_down>
      
      - if <[emeralds]> > 0 && <[emeralds].mod[2]> == 0:
        - define gold_ingots:<[emeralds]>
        - define emeralds:0  
      
      
      - if <[single]>:
        - if <list[<[netherite_blocks]>|<[netherite_ingots]>|<[emeralds]>|<[gold_ingots]>|<[iron_ingots]>].filter[equals[0].not].size> <= 1:
          - define min_items:<[min_items].mul[<[qty]>]>
          - while stop
        - else:
          - define qty:++
      - else:
        - while stop
    
    - determine <map[].with[min_qty].as[<[min_items]>].with[value].as[<[lookup_value]>].with[netherite_blocks].as[<[netherite_blocks]>].with[netherite_ingots].as[<[netherite_ingots]>].with[emeralds].as[<[emeralds]>].with[gold_ingots].as[<[gold_ingots]>].with[iron_ingots].as[<[iron_ingots]>]>    
    

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
          - define value:<proc[drustcraftp_value.get].context[<[material]>]>
          
          - narrate '<&e>The material <&f><[material]> <&e>has a value of <&f><[value].get[value]> <&e>Emeralds'
          - narrate '<&e>Min Quantity: <&f><[value].get[min_qty]>'
          - narrate '<&e>Netherite Blocks: <&f><[value].get[netherite_blocks]>'
          - narrate '<&e>Netherite Ingots: <&f><[value].get[netherite_ingots]>'
          - narrate '<&e>Emeralds: <&f><[value].get[emeralds]>'
          - narrate '<&e>Iron Ingots: <&f><[value].get[iron_ingots]>'
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
