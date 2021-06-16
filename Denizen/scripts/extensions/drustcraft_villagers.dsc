# Drustcraft - Villages
# Villager repopulation
# https://github.com/drustcraft/drustcraft

drustcraftw_villagers:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_villagers.load
      - run drustcraftt_villagers.spawner
    
    on script reload:
      - run drustcraftt_villagers.load
      
    

drustcraftt_villagers:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <server.has_file[/drustcraft_data/villagers.yml]>:
      - yaml load:/drustcraft_data/villagers.yml id:drustcraft_villagers
    - else:
      - yaml create id:drustcraft_villagers
      - yaml savefile:/drustcraft_data/villagers.yml id:drustcraft_villagers

    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_tab_complete]>
      
      - run drustcraftt_tab_complete.completions def:warn|_*players|_*warn_tracks
      
      
  save:
    - yaml id:drustcraft_villagers savefile:/drustcraft_data/villagers.yml
    
  spawner:
    - foreach <yaml[drustcraft_villagers].read[villages]||<list[]>> as:target_location:
      - define area:<[target_location].sub[50,0,50].to_cuboid[<[target_location].add[50,0,50]>]>
      - ~chunkload <[area].chunks> duration:5m
        
      - if <[target_location].round.find_entities[villager].within[100].size> < 2:
        - if <util.random.int[1].to[3]> == 1:
          - define amount:<util.random.int[2].to[5]>
          - repeat <[amount]>:
            - spawn villager <[target_location].highest> persistent


drustcraftc_villagers:
  type: command
  debug: false
  name: village
  description: Defines or clears a village
  usage: /village <&lt>define|clear<&gt>
  permission: drustcraft.village
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:warn
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case clear:
        - narrate 'not implemented'
      - case define:
        - yaml id:drustcraft_villagers set villages:->:<player.location.round>
        - run drustcraftt_villagers.save