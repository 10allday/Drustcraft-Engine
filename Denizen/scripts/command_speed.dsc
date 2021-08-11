# Drustcraft - Speed
# https://github.com/drustcraft/drustcraft

drustcraftw_speed:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_speed_load

    on script reload:
      - run drustcraftt_speed_load

    after player logs in:
      - wait 10t
      - if <server.online_players.contains[<player>]>:
        - adjust <player> fly_speed:<server.flag[drustcraft.speed.default_fly]>
        - adjust <player> walk_speed:<server.flag[drustcraft.speed.default_walk]>

    on player changes gamemode to SURVIVAL:
      - adjust <player> fly_speed:<server.flag[drustcraft.speed.default_fly]>
      - adjust <player> walk_speed:<server.flag[drustcraft.speed.default_walk]>


drustcraftt_speed_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - flag server drustcraft.speed.default_walk:0.2
    - flag server drustcraft.speed.default_fly:0.1

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>
      - run drustcraftt_tabcomplete_completion def:speed|_*int
      - run drustcraftt_tabcomplete_completion def:speed|reset

    - flag server drustcraft.module.speed:<script[drustcraftw_speed].data_key[version]>


drustcraftc_speed:
  type: command
  debug: false
  name: speed
  description: Changes player speed
  usage: /speed (number|reset)
  permission: drustcraft.speed
  permission message: <&8>[<&c>!<&8>] <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:speed
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.speed]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Drustcraft module not yet loaded. Check console for any errors]>'
      - stop

    - if !<context.server||false>:
      - define default_speed:<tern[<player.is_flying>].pass[<server.flag[drustcraft.speed.default_fly]>].fail[<server.flag[drustcraft.speed.default_walk]>]>
      - define max_speed:1.0
      - define user_speed:<context.args.get[1]||<empty>>
      - define speed:<[default_speed]>

      - if <[user_speed].is_decimal>:
        - if <[user_speed]> < 1:
          - define speed:<[default_speed].mul[<[user_speed]>]>
        - else:
          - define ratio:<[user_speed].sub[1].div[9].mul[<[max_speed].sub[<[default_speed]>]>]>
          - define speed:<[ratio].add[<[default_speed]>]>

      - if <[user_speed]> == <empty>:
        - if <player.is_flying>:
          - adjust <player> fly_speed:<[speed]>
          - narrate '<proc[drustcraftp_msg_format].context[arrow|Your fly speed is set to $e<player.fly_speed>]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[arrow|Your walk speed is set to $e<player.walk_speed>]>'
      - else:
        - if <player.is_flying>:
          - adjust <player> fly_speed:<[speed]>
          - narrate '<proc[drustcraftp_msg_format].context[arrow|Your fly speed now changed to $e<player.fly_speed>]>'
        - else:
          - adjust <player> walk_speed:<[speed]>
          - narrate '<proc[drustcraftp_msg_format].context[arrow|Your walk speed now changed to $e<player.walk_speed>]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|This command can only be run by players]>'