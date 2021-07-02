# Drustcraft - Chests
# Chests restock
# https://github.com/drustcraft/drustcraft

drustcraftw_chest:
  type: world
  debug: false
  events:
    on server starts:
      - run drustcraftt_chest.load
          
    on script reload:
      - run drustcraftt_chest.load
    
    on player opens inventory:
      - if <context.inventory.location||<empty>> != <empty>:
        - if !<yaml[drustcraft_chest].contains[restocked_chests]> || !<yaml[drustcraft_chest].read[restocked_chests].contains[<context.inventory.location>]||true>:
          - if !<yaml[drustcraft_chest].contains[ignored_chests]> || !<yaml[drustcraft_chest].read[ignored_chests].contains[<context.inventory.location>]||true>:
            - yaml id:drustcraft_chest set restocked_chests:->:<context.inventory.location>
            - if <context.inventory.quantity_item> < 10:
              - repeat <util.random.int[1].to[3]>:
                - define random_item:<yaml[drustcraft_chest].list_keys[restock_items].random>
                - define random_item_chance:<yaml[drustcraft_chest].read[restock_items.<[random_item]>]>
                
                - if <util.random.decimal> <= <[random_item_chance]>:
                  - define max_amount:1
                  
                  - if <[random_item_chance]> > 0.3:
                    - define max_amount:8
                  - else if <[random_item_chance]> > 0.09:
                    - define max_amount:4
                  
                  - give <[random_item]> quantity:<util.random.int[1].to[<[max_amount]>]> to:<context.inventory>
    
    on player places block:
      - if <player.gamemode> == SURVIVAL:
        - if <yaml[drustcraft_chest].read[containers].contains[<context.material>]||true>:
          - yaml id:drustcraft_chest set ignored_chests:->:<context.location>
    
    on player breaks block:
      - if <player.gamemode> == SURVIVAL:
        - if <yaml[drustcraft_chest].read[containers].contains[<context.material>]||true>:
          - if <yaml[drustcraft_chest].read[ignored_chests].contains[<context.location>]>:
            - yaml id:drustcraft_chest set ignored_chests:<-:<context.location>
    
    on system time minutely every:5:
      - run drustcraftt_chest.save


drustcraftt_chest:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <yaml.list.contains[drustcraft_chest]>:
      - ~yaml unload id:drustcraft_chest

    - if <server.has_file[/drustcraft_data/chests.yml]>:
      - ~yaml load:/drustcraft_data/chests.yml id:drustcraft_chest
    - else:
      - yaml create id:drustcraft_chest
      - ~yaml savefile:/drustcraft_data/chests.yml id:drustcraft_chest
    
    - yaml id:drustcraft_chest set restocked_chests:!
    
  save:
    - if <yaml.list.contains[drustcraft_chest]> && <yaml[drustcraft_chest].has_changes>:
      - yaml savefile:/drustcraft_data/chests.yml id:drustcraft_chest
