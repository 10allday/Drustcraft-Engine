# Drustcraft - Weather
# https://github.com/drustcraft/drustcraft

drustcraftw_weather:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_weather_load

    on script reload:
      - run drustcraftt_weather_load

    on player changes gamemode:
      - weather player reset


drustcraftt_weather_load:
  type: task
  debug: false
  script:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>
      - run drustcraftt_tabcomplete_completion def:weather|_*weather|_*worlds
      - run drustcraftt_tabcomplete_completion def:pweather|_*weather
      - run drustcraftt_tabcomplete_completion def:pweather|reset

    - flag server drustcraft.module.weather:<script[drustcraftw_weather].data_key[version]>



drustcraftc_weather_player:
  type: command
  debug: false
  name: pweather
  description: Changes players weather
  usage: /pweather <&lt>sunny|storm|thunder|reset<&gt>
  permission: drustcraft.pweather
  permission message: <&8>[<&c>!<&8>] <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:pweather
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.weather]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Drustcraft module not yet loaded. Check console for any errors]>'
      - stop

    - if !<context.server||false>:
      - if <context.args.size> >= 1:
        - if <list[sunny|storm|thunder|reset].contains[<context.args.get[1]>]>:
          - weather player <context.args.get[1]>
          - if <context.args.get[1]> == reset:
            - narrate '<proc[drustcraftp_msg_format].context[arrow|Player weather reset to world weather]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[arrow|Player weather $rchanged to $e<context.args.get[1]>]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The weather type entered is not valid]>'
      - else:
        - if !<player.weather.exists>:
          - narrate '<proc[drustcraftp_msg_format].context[arrow|You are experiencing world weather]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[arrow|You are experiencing $e<player.weather> $rweather]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|This command can only be run by players]>'


drustcraftc_weather:
  type: command
  debug: false
  name: weather
  description: Changes world weather
  usage: /weather <&lt>sunny|storm|thunder<&gt> (world)
  permission: drustcraft.weather
  permission message: <&8>[<&c>!<&8>] <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:weather
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.weather]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Drustcraft module not yet loaded. Check console for any errors]>'
      - stop

    - if <context.args.size> >= 1:
      - if <list[sunny|storm|thunder].contains[<context.args.get[1]>]>:
        - if !<context.server||false>:
          - weather <context.args.get[1]> <player.world>
          - narrate '<proc[drustcraftp_msg_format].context[arrow|The weather for $e<player.world.name> $rchanged to $e<context.args.get[1]>]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|A world must be entered when run from the console]>'
      - else:
        - if <server.flag[drustcraft.bungee.worlds].contains[<context.args.get[1]>]>:
          - define name:<context.args.get[1]>
          - define weather:sunny

          - if <bungee.connected>:
            - foreach <bungee.list_servers>:
              - ~bungeetag server:<[value]> <world[<[name]>].has_storm> save:storm_result
              - ~bungeetag server:<[value]> <world[<[name]>].thundering> save:thunder_result

              - if <entry[storm_result].result||<empty>> != <empty>:
                - if <entry[storm_result].result>:
                  - define weather:stormy
                  - foreach stop
                - else:
                  - ~bungeetag server:<[value]> <world[<[name]>].thundering> save:thunder_result
                  - if <entry[thunder_result].result>:
                    - define weather:thunderstorms
                    - foreach stop
          - else:
            - define weather:sunny
            - if <world[name].has_storm>:
              - define weather:stormy
            - else if <world[name].thundering>:
              - define weather:thunderstorms

          - narrate '<proc[drustcraftp_msg_format].context[arrow|The weather for $e<[name]> $ris $e<[weather]>]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The weather type entered is not valid]>'
    - else:
      - if !<context.server||false>:
        - define world:<player.world>
        - define weather:sunny
        - if <[world].has_storm>:
          - define weather:stormy
        - else if <[world].thundering>:
          - define weather:thunderstorms
        - narrate '<proc[drustcraftp_msg_format].context[|The weather for $e<[world].name> $ris $e<[weather]>]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|A world must be entered when run from the console]>'


drustcraftp_tabcomplete_weather:
  type: procedure
  debug: false
  script:
    - determine <list[sunny|storm|thunder]>