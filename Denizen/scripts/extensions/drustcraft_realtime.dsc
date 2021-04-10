# Drustcraft - Realtime Time
# Adjusts the worlds time to server time
# https://github.com/drustcraft/drustcraft

drustcraftw_realtime:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_realtime.load

      
    on script reload:
      - run drustcraftt_realtime.load

    
    on system time secondly server_flagged:drustcraft_realtime_enabled every:5:
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


drustcraftt_realtime:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - flag server drustcraft_realtime_enabled:true
    
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - waituntil <yaml.list.contains[drustcraft_tab_complete]>

      - run drustcraftt_tab_complete.completions def:realtime|_*bool


drustcraftc_realtime:
  type: command
  debug: false
  name: realtime
  description: Enables or disabled realtime game time
  usage: /realtime <&lt>true|false<&gt>
  permission: drustcraft.realtime
  permission message: <&8><&l>[<&4><&l>x<&8><&l>] <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:realtime
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case true:
        - flag server drustcraft_realtime_enabled:true
        - narrate '<&8><&l>[<&a><&l>+<&8><&l>] <&r><&2>Realtime game time is <&f>ENABLED'
      - case false:
        - flag server drustcraft_realtime_enabled:!
        - narrate '<&8><&l>[<&a><&l>+<&8><&l>] <&r><&2>Realtime game time is <&f>DISABLED'
      - default:
        - narrate '<&8><&l>[<&4><&l>x<&8><&l>] <&r><&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
