# Drustcraft - Realtime
# https://github.com/drustcraft/drustcraft

drustcraftw_realtime:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_realtime_load

    on script reload:
      - run drustcraftt_realtime_load

    on system time secondly server_flagged:drustcraft.realtime.enabled every:5:
      - define time:<util.time_now>

      - if <server.has_flag[drustcraft.util.timezone]>:
        - define time:<[time].to_zone[<server.flag[drustcraft.util.timezone]>]>

      - define hr:<[time].hour>
      - define world_time:0

      - if <[hr]> < 6:
        - define world_time:<[hr].add[18].mul[1000]>
      - else:
        - define world_time:<[hr].sub[6].mul[1000]>

      - define secs:<[time].minute.mul[60].add[<[time].second>].div[3.6].round_down>
      - define world_time:<[world_time].add[<[secs]>]>
      - foreach <server.flag[drustcraft.realtime.server_enabled]||<list[]>>:
        - adjust <world[<[value]>]> time:<[world_time]>


drustcraftt_realtime_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - debug ERROR 'Drustcraft Realtime: Drustcraft Setting is required'
      - stop
    - if !<server.scripts.parse[name].contains[drustcraftw_chatgui]>:
      - debug ERROR 'Drustcraft Realtime: Drustcraft ChatGUI is required'
      - stop

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>
      - run drustcraftt_tabcomplete_completion def:realtime|info|_*worlds
      - run drustcraftt_tabcomplete_completion def:realtime|add|_*worlds
      - run drustcraftt_tabcomplete_completion def:realtime|remove|_*worlds
      - run drustcraftt_tabcomplete_completion def:realtime|enable|_*worlds
      - run drustcraftt_tabcomplete_completion def:realtime|disable|_*worlds

    - waituntil <server.has_flag[drustcraft.module.setting]>

    - ~run drustcraftt_setting_get def:drustcraft.realtime.worlds save:result
    - flag server drustcraft.realtime.worlds:<entry[result].created_queue.determination.get[1]||<list[]>>
    - if <server.flag[drustcraft.realtime.worlds]> == null:
      - flag server drustcraft.realtime.worlds:<list[]>

    - run drustcraftt_realtime_update def:<list[].include_single[<server.flag[drustcraft.realtime.worlds]>].include_single[<server.flag[drustcraft.realtime.worlds]>]>

    - flag server drustcraft.module.realtime:<script[drustcraftw_realtime].data_key[version]>


drustcraftt_realtime_save:
  type: task
  debug: false
  script:
    - run drustcraftt_setting_set def:<list[drustcraft.realtime.worlds].include_single[<server.flag[drustcraft.realtime.worlds]>]>


drustcraftt_realtime_update:
  type: task
  debug: false
  definitions: world_list|enabled_list
  script:
    - flag server drustcraft.realtime.worlds:<[world_list]>
    - flag server drustcraft.realtime.enabled:<[enabled_list]>
    - flag server drustcraft.realtime.server_enabled:<server.flag[drustcraft.realtime.enabled].as_list.shared_contents[<server.worlds.parse[name]>]>


worldc_realtime:
  type: command
  debug: false
  name: realtime
  description: Sets, unsets, enables or disables realtime for worlds
  usage: /realtime <&lt>add|remove|enable|disable|info<&gt> [world]
  permission: drustcraft.realtime
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:realtime
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||info>:
      - case info:
        - define world:<context.args.get[2]||<empty>>
        - if <[world]> != <empty> || <[world]> == -a:
          - if !<server.worlds.parse[name].contains[<[world]>]>:
            - narrate '<proc[drustcraftp_msg_format].context[error|The world $e<[world]> $rwas not found on this server]>'
            - stop
          - else:
            - if <server.flag[drustcraft.realtime.worlds].contains[<[world]>]>:
              - if <server.flag[drustcraft.realtime.enabled].contains[<[world]>]>:
                - define 'line:<proc[drustcraftp_msg_format].context[|Realtime is $eenabled $rfor world $e<[world]> <proc[drustcraftp_chatgui_button].context[rem|Dis|realtime disable <[world]>|Disable realtime for this world]>]>'
              - else:
                - define 'line:<proc[drustcraftp_msg_format].context[|Realtime is $edisabled $rfor world $e<[world]> <proc[drustcraftp_chatgui_button].context[add|En|realtime enable <[world]>|Enable realtime for this world]>]>'
              - narrate '<[line]> <proc[drustcraftp_chatgui_button].context[rem|Rem|realtime remove <[world]>|Remove realtime for this world]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[|Realtime is not used for world $e<[world]> <proc[drustcraftp_chatgui_button].context[add|Add|realtime add <[world]>|Add realtime for this world]>]>'
        - else:
          - ~run drustcraftt_chatgui_clear
          - foreach <server.worlds.parse[name]> as:world:
            - define line:<proc[drustcraftp_chatgui_option].context[<[world]>]>
            - if <server.flag[drustcraft.realtime.worlds].contains[<[world]>]>:
              - if <server.flag[drustcraft.realtime.enabled].contains[<[world]>]>:
                - define line:<[line]><proc[drustcraftp_chatgui_value].context[Enabled]>
                - define 'line:<[line]><proc[drustcraftp_chatgui_button].context[rem|Dis|realtime disable <[world]>|Disable realtime for this world]>'
              - else:
                - define line:<[line]><proc[drustcraftp_chatgui_value].context[Disabled]>
                - define 'line:<[line]><proc[drustcraftp_chatgui_button].context[add|En|realtime enable <[world]>|Enable realtime for this world]>'

              - define 'line:<[line]><proc[drustcraftp_chatgui_button].context[rem|Rem|realtime remove <[world]>|Remove realtime for this world]>'
            - else:
              - define 'line:<[line]><proc[drustcraftp_chatgui_value].context[(not set)]>'
              - define 'line:<[line]><proc[drustcraftp_chatgui_button].context[add|Add|realtime add <[world]>|Add realtime for this world]>'

            - ~run drustcraftt_chatgui_item def:<[line]>
          - ~run drustcraftt_chatgui_render 'def:realtime info -a|Realtime Info|<context.args.get[3]||1>'

      - case add:
        - define world:<context.args.get[2]||<empty>>
        - if <[world]> != <empty>:
          - if !<server.flag[drustcraft.realtime.worlds].contains[<[world]>]>:
            - flag server drustcraft.realtime.worlds:->:<[world]>
            - if !<server.flag[drustcraft.realtime.enabled].contains[<[world]>]>:
              - flag server drustcraft.realtime.enabled:->:<[world]>
            - run drustcraftt_realtime_save
            - run drustcraftt_realtime_update def:<list[].include_single[<server.flag[drustcraft.realtime.worlds]>].include_single[<server.flag[drustcraft.realtime.enabled]>]>
            - narrate '<proc[drustcraftp_msg_format].context[success|The world $e<[world]> $ris set to realtime]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The world $e<[world]> $rwas not set to use realtime]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|A world name is required]>'

      - case remove:
        - define world:<context.args.get[2]||<empty>>
        - if <[world]> != <empty>:
          - if <server.flag[drustcraft.realtime.worlds].contains[<[world]>]>:
            - flag server drustcraft.realtime.worlds:<-:<[world]>
            - flag server drustcraft.realtime.enabled:<-:<[world]>
            - run drustcraftt_realtime_save
            - run drustcraftt_realtime_update def:<list[].include_single[<server.flag[drustcraft.realtime.worlds]>].include_single[<server.flag[drustcraft.realtime.enabled]>]>
            - narrate '<proc[drustcraftp_msg_format].context[success|The world $e<[world]> $ris no longer set for realtime]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The world $e<[world]> $rwas not set to use realtime]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|A world name is required]>'

      - case enable:
        - define world:<context.args.get[2]||<empty>>
        - if <[world]> != <empty>:
          - if !<server.worlds.parse[name].contains[<[world]>]>:
            - narrate '<proc[drustcraftp_msg_format].context[error|The world $e<[world]> $rwas not found on this server]>'
            - stop
          - else:
            - if <server.flag[drustcraft.realtime.enabled].contains[<[world]>]>:
              - narrate '<proc[drustcraftp_msg_format].context[error|Realtime already $eenabled $rfor $e<[world]>]>'
            - else:
              - flag server drustcraft.realtime.enabled:->:<[world]>
              - run drustcraftt_realtime_update def:<list[].include_single[<server.flag[drustcraft.realtime.worlds]>].include_single[<server.flag[drustcraft.realtime.enabled]>]>
              - narrate '<proc[drustcraftp_msg_format].context[success|Realtime $eenabled $rfor $e<[world]>]>'
        - else:
          - flag server drustcraft.realtime.enabled:<server.flag[drustcraft.realtime.worlds]>
          - narrate '<proc[drustcraftp_msg_format].context[success|Realtime $eenabled $rfor all worlds set to use realtime]>'

      - case disable:
        - define world:<context.args.get[2]||<empty>>
        - if <[world]> != <empty>:
          - if !<server.worlds.parse[name].contains[<[world]>]>:
            - narrate '<proc[drustcraftp_msg_format].context[error|The world $e<[world]> $rwas not found on this server]>'
            - stop
          - else:
            - if <server.flag[drustcraft.realtime.enabled].contains[<[world]>]>:
              - flag server drustcraft.realtime.enabled:<-:<[world]>
              - run drustcraftt_realtime_update def:<list[].include_single[<server.flag[drustcraft.realtime.worlds]>].include_single[<server.flag[drustcraft.realtime.enabled]>]>
              - narrate '<proc[drustcraftp_msg_format].context[success|Realtime $edisabled $rfor $e<[world]>]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|Realtime already $edisabled $rfor $e<[world]>]>'
        - else:
          - flag server drustcraft.realtime.enabled:<list[]>
          - narrate '<proc[drustcraftp_msg_format].context[success|Realtime $edisabled $rfor all worlds set to use realtime]>'

      - default:
        - narrate '<proc[drustcraftp_msg_format].context[error|Unknown option. Try <queue.script.data_key[usage].parsed>]>'
