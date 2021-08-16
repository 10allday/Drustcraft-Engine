# Drustcraft - Player Time
# https://github.com/drustcraft/drustcraft

drustcraftw_ptime:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_ptime_load

    on script reload:
      - run drustcraftt_ptime_load

    after player logs in:
      - wait 10t
      - if <server.online_players.contains[<player>]>:
        - time player reset

    on player changes gamemode:
      - time player reset


drustcraftt_ptime_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>
      - run drustcraftt_tabcomplete_completion def:ptime|_*ptimes|freeze
      - run drustcraftt_tabcomplete_completion def:ptime|reset

    - flag server drustcraft.module.ptime:<script[drustcraftw_ptime].data_key[version]>


drustcraftc_ptime:
  type: command
  debug: false
  name: ptime
  description: Changes player time
  usage: /ptime (number|reset)
  permission: drustcraft.ptime
  permission message: <&8>[<&c>!<&8>] <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:ptime
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.ptime]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Drustcraft module not yet loaded. Check console for any errors]>'
      - stop

    - if !<context.server||false>:
      - choose <context.args.get[1]||null>:
        - case null:
          - narrate '<proc[drustcraftp_msg_format].context[error|No time was entered]>'
        - case reset:
          - narrate '<proc[drustcraftp_msg_format].context[arrow|Your time has been reset to world time]>'
          - time player reset
          - stop
        - case day:
          - if <context.args.get[2]||null> == freeze:
            - time player 8000t freeze
          - else:
            - time player 8000t
        - case night:
          - if <context.args.get[2]||null> == freeze:
            - time player 1000t freeze
          - else:
            - time player 1000t
        - case midday noon:
          - if <context.args.get[2]||null> == freeze:
            - time player 18000t freeze
          - else:
            - time player 18000t
        - case midnight:
          - if <context.args.get[2]||null> == freeze:
            - time player 4000t freeze
          - else:
            - time player 4000t
        - case dawn sunrise:
          - if <context.args.get[2]||null> == freeze:
            - time player 9000t freeze
          - else:
            - time player 9000t
        - case dusk sunset:
          - if <context.args.get[2]||null> == freeze:
            - time player 23000t freeze
          - else:
            - time player 23000t
        - default:
          - if <context.args.get[1].is_integer>:
            - if <context.args.get[2]||null> == freeze:
              - time player <context.args.get[1]>t freeze
            - else:
              - time player <context.args.get[1]>t
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|$e<context.args.get[1]> $ris an invalid time]>'
            - stop

      - if <context.args.get[2]||null> == freeze:
        - narrate '<proc[drustcraftp_msg_format].context[arrow|Your time has been set to $e<context.args.get[1]> $rand frozen]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[arrow|Your time has been set to $e<context.args.get[1]>]>'

    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|This command can only be run by players]>'


drustcraftp_tabcomplete_ptimes:
  type: procedure
  debug: false
  script:
    - determine <list[day|night|midday|noon|midnight|dawn|dusk|sunrise|sunset]>