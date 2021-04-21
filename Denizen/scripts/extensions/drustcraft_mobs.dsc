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

    on entity death:
      - if <context.damager.object_type||<empty>> == PLAYER:
        - define exp:0
        - define drop_list:<list[]>

        - foreach <yaml[drustcraft_mobs].list_keys[drops.<context.entity.name>]> as:index:
          - define conditions:<yaml[drustcraft_mobs].read[drops.<context.entity.name>.<[index]>.conditions]||<map[]>>
          - define drops:<yaml[drustcraft_mobs].read[drops.<context.entity.name>.<[index]>.drops]||<map[]>>
          
          - define pass:true
          
          - if <[conditions].size> > 0:
            - foreach <[conditions]>:
              - choose <[key]>:
                - case onfire:
                  - if <context.entity.on_fire||false> != <[value]>:
                    - define pass:false
                - case sheared:
                  - if <context.entity.is_sheared||false> != <[value]>:
                    - define pass:false
                - case baby:
                  - if <context.entity.is_baby||false> != <[value]>:
                    - define pass:false
                - case event:
                  - if <proc[drustcraftp_event.is_running].context[<[value]>]> == false:
                    - define pass:false
          
          - if <[pass]>:
            - foreach <[drops]>:
              - define range:<[value].before[<&sp>]>
              - define percentage:<[value].after[<&sp>]>
              
              - if <[percentage]> == <empty> || <util.random.int[0].to[100].is_less_than_or_equal_to[<[percentage]>]>:
                - define qty:0
            
                - if <[range].contains_text[-]>:
                  - define min:<[range].before[-]>
                  - define max:<[range].after[-]>
                  - define qty:<util.random.int[<[min]>].to[<[max]>]>
                - else if <[range].is_integer>:
                  - define qty:<[range]>
  
                - if <[key]> != exp:
                  - define item:<item[<[key]>[quantity=<[qty]>]]||<empty>>
                  - if <[item]> != <empty>:
                    - define drop_list:->:<[item]>
                - else:
                  - define exp:+:<[qty]>
        
        - if <[exp]> > 0:
          - determine passively <[exp]>
        - else:
          - determine passively NO_XP
        
        - determine <[drop_list]>
    
      - determine NO_DROPS_OR_XP


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
