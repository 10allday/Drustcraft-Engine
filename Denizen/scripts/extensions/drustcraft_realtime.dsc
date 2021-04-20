# Drustcraft - Realtime Time
# Adjusts the worlds time to server time
# https://github.com/drustcraft/drustcraft

drustcraftw_realtime:
  type: world
  debug: false
  version: 1
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
      
  enable:
    - flag server drustcraft_realtime_enabled:true
  
  disable:
    - flag server drustcraft_realtime_enabled:false


drustcraftp_realtime:
  type: procedure
  debug: false

  enabled:
    - determine <server.flag[drustcraft_realtime_enabled]||false>


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
        - run drustcraftt_realtime.enable
        - narrate '<&8><&l>[<&a><&l>+<&8><&l>] <&r><&2>Realtime game time is now <&f>ENABLED'
      - case false:
        - run drustcraftt_realtime.disable
        - narrate '<&8><&l>[<&a><&l>+<&8><&l>] <&r><&2>Realtime game time is now <&f>DISABLED'
      - case <empty>:
        - if <proc[drustcraftp_realtime.enabled]>:
          - narrate '<&8><&l>[<&a><&l>+<&8><&l>] <&r><&2>Realtime game time is currently <&f>ENABLED'
        - else:
          - narrate '<&8><&l>[<&a><&l>+<&8><&l>] <&r><&2>Realtime game time is currently <&f>DISABLED'
      - default:
        - narrate '<&8><&l>[<&4><&l>x<&8><&l>] <&r><&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
