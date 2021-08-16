# Drustcraft - God
# https://github.com/drustcraft/drustcraft

drustcraftw_god:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_god_load

    on script reload:
      - run drustcraftt_god_load

    on entity damaged server_flagged:drustcraft.module.god:
      - if <player.exists>:
        - if <context.entity> == <player>:
          - if <context.damager.exists>:
            - hurt 1000 <context.damager>
          - determine 0
        - else:
          - if <context.damager.exists> && <context.damager> == <player>:
            - determine 1000

    on system time secondly every:5 server_flagged:drustcraft.module.god:
      - foreach <server.online_players.filter[has_flag[drustcraft.god]]> as:player:
        - heal <[player]>

    on player quits server_flagged:drustcraft.module.god:
      - if <player.has_flag[drustcraft.god]>:
        - bossbar remove <player.uuid>_god
        - flag player drustcraft.god:!


drustcraftt_god_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - flag server drustcraft.module.god:<script[drustcraftw_god].data_key[version]>


drustcraftc_god:
  type: command
  debug: false
  name: god
  description: Toggles God Mode
  usage: /god
  permission: drustcraft.god
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:god
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.god]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Drustcraft module not yet loaded. Check console for any errors]>'
      - stop

    - if !<context.server||false>:
      - if <player.has_flag[drustcraft.god]>:
        - flag player drustcraft.god:!
        - bossbar remove <player.uuid>_god
        - narrate '<proc[drustcraftp_msg_format].context[success|God mode disabled]>'
      - else:
        - flag player drustcraft.god:true
        - bossbar create <player.uuid>_god color:green players:<player> 'title:God Mode'
        - narrate '<proc[drustcraftp_msg_format].context[success|God mode enabled]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|This command can only be run by players]>'