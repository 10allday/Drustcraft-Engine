# Drustcraft - Realtime Time
# Adjusts the worlds time to server time
# https://github.com/drustcraft/drustcraft

drustcraftw_realtime:
  type: world
  debug: false
  events:
    on system time secondly every:5:
      - define hr:<util.time_now.hour>
      - define world_time:0
      
      - if <[hr]> < 6:
        - define world_time:<[hr].add[18].mul[1000]>
      - else:
        - define world_time:<[hr].sub[6].mul[1000]>
      
      - define secs:<util.time_now.minute.mul[60].add[<util.time_now.second>].div[3.6].round_down>
      - define world_time:<[world_time].add[<[secs]>]>
      - foreach <server.worlds>:
        - adjust <world[<[value]>]> time:<[world_time]>
