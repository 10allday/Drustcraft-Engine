# Drustcraft - Web Connectgor
# Web connector utility
# https://github.com/drustcraft/drustcraft

drustcraftw_web_connector:
  type: world
  debug: false
  events:
    on server start:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_web_connector.load
      
    on script reload:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_web_connector.load
      
    on POST request:
      - determine passively 'code:401'
      - determine passively 'type:text/plain'
      - determine '401 Unauthorized'
    
    ON GET request:
      - narrate 'GET request from <context.address> for <context.request>'
      
      - if <list[103.11.207.105|122.199.1.210].contains[<context.address.after[/].before[:]>]>:
        - narrate 'GET request permitted due to IP address'
        
        - define request:<context.request.after[/]>
        - define request_items:<context.request.after[/].split[&]>
        - define request_map:<map[]>

        - determine passively 'code:200'
        - determine passively 'type:text/json'
        - define result:<map[]>
      
        - foreach <[request_items]>:
          - define item:<[value].split[=]>
          
          - if <[item].size> < 2:
            - define item:<[item].insert[true].at[2]>
          
          - define request_map:<[request_map].with[<[item].get[1].url_decode>].as[<[item].get[2].url_decode>]>

          - if <[request_map].contains[cmd]>:
            - choose <[request_map].get[cmd]>:
              - case query:
                - define result:<[result].with[players].as[<server.online_players.size>]>
                - define result:<[result].with[tps].as[<server.recent_tps.get[1].round>]>
                - define result:<[result].with[state].as[ok]>
              - case whitelist_sync:
                - ~run drustcraftt_bungee.run def:whitelist_sync
                - define result:<[result].with[state].as[ok]>
              - default:
                - define "result:<[result].with[error].as[Unknown Command]>"
          - else:
            - define "result:<[result].with[error].as[Command missing]>"

          - determine <[result].to_json>
      - else:
        - narrate 'GET request denied due to IP address restriction'
        - determine passively 'code:401'
        - determine passively 'type:text/plain'
        - determine '401 Unauthorized'


drustcraftt_web_connector:
  type: task
  debug: false
  script:
    - determine <empty>
  
  
  load:
    - web stop
    - define port:<yaml[drustcraft_server].read[drustcraft.webconnector.port]||<empty>>
    - define password:<yaml[drustcraft_server].read[drustcraft.webconnector.password]||<empty>>
    - if <[port]> != <empty> && <[password]> != <empty>:
      - if <yaml.list.contains[drustcraft_web_connector]>:
        - ~yaml id:drustcraft_web_connector unload
      
      - yaml id:drustcraft_web_connector create
      
      - flag server drustcraft_web_connector_password:<[password]>
      - web start port:<[port]>
    - else:
      - debug log 'Drustcraft Web Connector did not load because no port or password is defined in the configuration'