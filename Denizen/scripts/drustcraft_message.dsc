# Drustcraft - Message
# https://github.com/drustcraft/drustcraft

drustcraftw_msg:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_msg_load

    on script reload:
      - run drustcraftt_msg_load

    on player receives message:
      - if <context.system_message>:
        # the following is required due to weirdness from FAWE
        - define message:<context.raw_json.from_raw_json.strip_color||<empty>>

        - if '<[message].starts_with[(FAWE) You are lacking the permission node]>':
          - determine 'MESSAGE:<&e>WorldEdit commands are not available outside of <&f>/builder<&e> mode'
        - else if '<[message].starts_with[Hey! Sorry]>':
          - determine 'MESSAGE:<&e><[message].after[Hey! ]>'


drustcraftt_msg_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - flag server "drustcraft.msg.no_permission:<proc[drustcraftp_msg_format].context[error|I'm sorry, you do not have permission to perform this command]>"
    - flag server "drustcraft.msg.unknown_options:<proc[drustcraftp_msg_format].context[error|Invalid options where used in this command]>"

    - flag server drustcraft.module.msg:<script[drustcraftw_msg].data_key[version]>

drustcraftp_msg_format:
  type: procedure
  debug: false
  script:
    - define type:<[1]>
    - define message:<[2]>
    - define prefix:<element[]>
    - define base_colour:e

    - choose <[type]>:
      - case error:
        - define base_colour:c
        - define 'prefix:<&8>[<&c><&l>!<&8>] <&c>'
      - case warning:
        - define 'prefix:<&8>[<&c>-<&8>] <&e>'
      - case success:
        - define 'prefix:<&8>[<&a>+<&8>] <&e>'
      - case arrow info:
        - define 'prefix:<&8>[<&d><&gt><&8>] <&e>'
      - default:
        - define prefix:<&e>

    - determine <[prefix]><[message].replace_text[$e].with[<&f>].replace_text[$r].with[<element[&<[base_colour]>]>].parse_color>
