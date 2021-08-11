# Drustcraft - Report
# https://github.com/drustcraft/drustcraft

drustcraftw_report:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_report_load

    on script reload:
      - run drustcraftt_report_load


drustcraftt_report_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>
      - run drustcraftt_tabcomplete_completion def:report|bug
      - run drustcraftt_tabcomplete_completion def:report|player|_*players


drustcraftc_report:
  type: command
  debug: false
  name: report
  description: Reports a player or bug
  usage: /report [player|bug] [player]
  permission: drustcraft.report
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:report
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if <context.args.get[1]||<empty>> == PLAYER:
      - if <context.args.get[2]||<empty>> != <empty>:
        - define target_player:<server.match_offline_player[<context.args.get[2]>]>
        - if <[target_player].exists> && <[target_player].name> == <context.args.get[2]>:
          - if <context.args.size> >= 3:
            - ~webget https://api.drustcraft.com.au/game/report/player data:{"reporter":"<player.uuid>","player":"<[target_player].uuid>","report":"<context.args.remove[1|2].space_separated>"} headers:<map.with[Content-Type].as[application/json]> save:request
            - if <entry[request].status> == 200:
              - narrate '<proc[drustcraftp_msg_format].context[success|Your report has been sent to an Game Master]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|There was an error sending the request to the server]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|You need to enter details on what you are reporting!]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[2]> $rwas not found on this server]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|No player name was entered]>'
    - else if <context.args.get[1]||<empty>> == BUG:
      - if <context.args.size> >= 2:
        - ~webget https://api.drustcraft.com.au/game/report/bug data:{"reporter":"<player.uuid>","report":"<context.args.remove[1].space_separated>"} headers:<map.with[Content-Type].as[application/json]> save:request
        - if <entry[request].status> == 200:
          - narrate '<proc[drustcraftp_msg_format].context[success|Your report has been sent to an Game Master]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|There was an error sending the request to the server]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|You need to enter details on what you are reporting!]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|The first option must be either $eplayer $ror $ebug]>'
