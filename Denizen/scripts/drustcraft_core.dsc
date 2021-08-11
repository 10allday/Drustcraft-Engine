# Drustcraft - Core
# https://github.com/drustcraft/drustcraft

drustcraftw_core:
  type: world
  debug: false
  version: 1
  events:
    on server start priority:-100:
      - ~run drustcraftt_core_load def:startup

    on script reload priority:-100:
      - ~run drustcraftt_core_load def:reload

    on player joins  priority:-100:
      - flag player drustcraft:!


drustcraftt_core_load:
  type: task
  debug: false
  definitions: mode
  script:
    - flag server drustcraft:!

    - foreach <server.notes.parse[note_name].filter[starts_with[drustcraft]]> as:note_name:
      - note remove as:<[note_name]>

    - if !<server.scripts.parse[name].contains[drustcraftp_util_to_version]>:
      - debug ERROR 'Drustcraft Core requires Drustcraft Utils version 1.0 or higher installed'
      - stop
    - if !<server.scripts.parse[name].contains[drustcraftw_chatgui]>:
      - debug ERROR 'Drustcraft Core requires Drustcraft ChatGUI version 1.0 or higher installed'
      - stop

    - flag server drustcraft.module.core:<script[drustcraftw_core].data_key[version]>
    - wait 2t

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>
      - run drustcraftt_tabcomplete_completion def:drustcraft|version

    - if <server.scripts.parse[name].contains[drustcraftw_setting]>:
      - waituntil <server.has_flag[drustcraft.module.setting]>
      - ~run drustcraftt_setting_get def:run.<[mode]>|null|yaml save:result
      - if <entry[result].created_queue.determination.get[1].object_type> == LIST:
        - foreach <entry[result].created_queue.determination.get[1]>:
          - debug LOG 'Running <[mode]> command "<[value]>"'
          - execute as_server <[value]>


drustcraftc_drustcraft:
  type: command
  debug: false
  name: drustcraft
  description: Returns Drustcraft Data
  usage: /drustcraft <&lt>version<&gt>
  permission: drustcraft.core
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:drustcraft
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case version:
        - ~run drustcraftt_chatgui_clear
        - foreach <server.flag[drustcraft.module]> as:version key:module:
          - define line:<proc[drustcraftp_chatgui_option].context[<[module]>]>
          - define line:<[line]><proc[drustcraftp_chatgui_value].context[<proc[drustcraftp_util_to_version].context[<[version]>]>]>

          - ~run drustcraftt_chatgui_item def:<[line]>
        - ~run drustcraftt_chatgui_render 'def:drustcraft version|Drustcraft Modules|<context.args.get[2]||1>'

      - default:
        - narrate '<proc[drustcraftp_msg_format].context[error|Unknown option. Try <queue.script.data_key[usage].parsed>]>'