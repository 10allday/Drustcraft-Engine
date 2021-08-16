# Drustcraft - Web Connectgor
# https://github.com/drustcraft/drustcraft

drustcraftw_webconnector:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_webconnector_load

    on script reload:
      - run drustcraftt_webconnector_load

    on POST request:
      - determine passively code:401
      - determine passively type:text/plain
      - determine '401 Unauthorized'

    ON GET request:
      - narrate 'GET request from <context.address> for <context.request> data <context.query_map>'

      - if <list[103.11.207.105|122.199.1.210|110.232.112.78|110.145.102.167|].contains[<context.address.after[/].before[:]>]>:
        - define request:<context.request.after[/]>
        - define request_items:<context.request.after[/].split[&]>
        - define request_map:<map[]>

        - determine passively code:200
        - determine passively type:text/json
        - define result:<map[]>

        - if <context.query_map.contains[cmd]>:
          - if <yaml[drustcraft_webconnector].list_keys[commands].contains[<context.query_map.get[cmd]>]>:
            - run <yaml[drustcraft_webconnector].read[commands.<context.query_map.get[cmd]>]> def:<context.query_map> save:result
            - define result:<entry[result].created_queue.determination.get[1]||<map[]>>
          - else:
            - define "result:<[result].with[error].as[Unknown Command]>"

          - if !<[result].keys.contains[state]>:
            - if <[result].keys.contains[error]>:
              - define result:<[result].with[state].as[error]>
            - else:
              - define result:<[result].with[state].as[success]>
        - else:
          - define "result:<[result].with[error].as[Command missing]>"

        - determine <[result].to_json>
      - else:
        - narrate 'GET request denied due to IP address restriction'
        - determine passively code:401
        - determine passively type:text/plain
        - determine '401 Unauthorized'


drustcraftt_webconnector_load:
  type: task
  debug: false
  script:
    - web stop
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - debug ERROR 'Drustcraft Webconnector: Drustcraft Setting is required'
      - stop

    - ~run drustcraftt_setting_get def:drustcraft.webconnector.port|10921|yaml save:result
    - flag server drustcraft.webconnector.port:<entry[result].created_queue.determination.get[1]>

    - ~run drustcraftt_setting_get def:drustcraft.webconnector.permitted||yaml save:result
    - flag server drustcraft.webconnector.permitted:<entry[result].created_queue.determination.get[1]>

    - if <yaml.list.contains[drustcraft_webconnector]>:
      - ~yaml id:drustcraft_webconnector unload
    - yaml id:drustcraft_webconnector create

    - run drustcraftt_webconnector_command def:query|drustcraftt_webconnector_query

    - web start port:<server.flag[drustcraft.webconnector.port]>

    - flag server drustcraft.module.webconnector:<script[drustcraftw_webconnector].data_key[version]>


drustcraftt_webconnector_command:
  type: task
  debug: false
  definitions: command|task_name
  script:
    - yaml id:drustcraft_webconnector set commands.<[command]>:<[task_name]>


drustcraftt_webconnector_query:
  type: task
  debug: false
  definitions: command|task_name
  script:
    - define result:<map[]>
    - define result:<[result].with[players].as[<server.online_players.size>]>
    - define result:<[result].with[max_players].as[<server.max_players>]>
    - define result:<[result].with[tps].as[<server.recent_tps.get[1].round>]>
    - define result:<[result].with[state].as[success]>
    - determine <[result]>
