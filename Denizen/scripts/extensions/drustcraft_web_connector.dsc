# Drustcraft - Web Connectgor
# Web connector utility
# https://github.com/drustcraft/drustcraft

drustcraftw_web_connector:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_web_connector.load
      
    on script reload:
      - run drustcraftt_web_connector.load
      
    on POST request:
      - define post_key:<context.query_map.get[key]||<empty>>
      - if <[post_key]> == <server.flag[drustcraft_web_connector_password]>:
        - determine passively 'code:200'
        - determine passively 'type:text/json'
        - define result:<map[]>
        
        - define post_cmd:<context.query_map.get[cmd]||<empty>>
        - waituntil <yaml.list.contains[drustcraft_web_connector]>
        - if <yaml[drustcraft_web_connector].list_keys[commands].contains[<[post_cmd]>]>:
          - define params:<context.query_map.get[key].exclude[key]||<map[]>>
          - ~run <yaml[drustcraft_web_connector].read[commands.<[post_cmd]>]> def:<[params]> save:result
          - define response:<entry[result].created_queue.determination.get[1]||<map[]>>

          - if <[response].object_type> == MAP && <[response].size> > 0:
            - define result:<[result].include[<[response]>]>

        - else:
          - define 'result:<[result].with[error].as[Unknown Command]>'

        - determine <[result].to_json>

      - determine passively 'code:401'
      - determine passively 'type:text/plain'
      - determine '401 Unauthorized'
    
    ON GET request:
      - determine passively 'code:401'
      - determine passively 'type:text/plain'
      - determine '401 Unauthorized'


drustcraftt_web_connector:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <yaml.list.contains[drustcraft_web_connector]>:
      - ~yaml id:drustcraft_web_connector unload
    - web stop

    - wait 2t
    - waituntil <yaml.list.contains[drustcraft_server]>

    - define port:<yaml[drustcraft_server].read[drustcraft.webconnector.port]||<empty>>
    - define password:<yaml[drustcraft_server].read[drustcraft.webconnector.password]||<empty>>
    - if <[port]> != <empty> && <[password]> != <empty>:
      
      - yaml id:drustcraft_web_connector create
      
      - flag server drustcraft_web_connector_password:<[password]>
      - web start port:<[port]>
      
      - run drustcraftt_web_connector.command def:query|drustcraftt_web_connector_command
      
    - else:
      - debug log 'Drustcraft Web Connector did not load because no port or password is defined in the configuration'
  
  command:
    - define cmd_name:<[1]||<empty>>
    - define task_name:<[2]||<empty>>
    
    - if <[cmd_name]> != <empty> && <[task_name]> != <empty>:
      - waituntil <yaml.list.contains[drustcraft_web_connector]>
      - yaml id:drustcraft_web_connector set commands.<[cmd_name]>:<[task_name]>
      

drustcraftt_web_connector_command:
  type: task
  debug: false
  script:
    - define param_map:<[1]||<map[]>>
    - define command:<[param_map].get[cmd]||<empty>>
    - define result:<map[]>
    
    - choose <[command]>:
      - case query:
        - define 'result:<[result].with[players].as[<server.online_players.size]>'
        - define 'result:<[result].with[tps].as[<server.recent_tps.get[1].round_down]>'

      - default:
        - determine <[result]>
    
    - determine <[result]>