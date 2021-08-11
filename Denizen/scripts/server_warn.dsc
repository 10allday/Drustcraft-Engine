# Drustcraft - Warn
# https://github.com/drustcraft/drustcraft

drustcraftw_warn:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_warn_load

    on script reload:
      - run drustcraftt_warn_load

    on player logs in priority:-1:
      - if !<server.has_flag[drustcraft.module.warn]>:
        - determine 'KICKED:<&e>This server is currently not available as it is loading<&nl>Please try again in a few minutes'

    on player logs in server_flagged:drustcraft.module.warn:
      - define epoch_time:<util.time_now.epoch_millis.div[1000].round>
      - foreach <server.flag[drustcraft.warn.players.<player.uuid>].keys||<list[]>> as:id:
        - if <server.flag[drustcraft.warn.players.<player.uuid>.<[id]>.end]> < <[epoch_time]> && <server.flag[drustcraft.warn.players.<player.uuid>.<[id]>.type]> == BAN:
          - determine KICKED:<proc[drustcraftp_warn_kick_msg].context[<player.uuid>|<[id]>]>


drustcraftt_warn_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR "Drustcraft Warn: Drustcraft Database module is required to be installed"
      - stop

    - waituntil <server.has_flag[drustcraft.module.db]>

    - define create_tables:true
    - ~run drustcraftt_db_get_version def:drustcraft.warn save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> != 1:
      - if <[version]> != null:
        - debug ERROR "Drustcraft Warn: Unexpected database version"
        - stop
      - else:
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>warn_track` (`track` VARCHAR(255) NOT NULL, `title` VARCHAR(255) NOT NULL, UNIQUE (`track`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>warn_penalty` (`id` INT NOT NULL AUTO_INCREMENT, `track` VARCHAR(255) NOT NULL, `sort` INT NOT NULL, `type` VARCHAR(32) NOT NULL, `duration` VARCHAR(32) NOT NULL, PRIMARY_KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>warn_player` (`id` INT NOT NULL AUTO_INCREMENT, `uuid` VARCHAR(36) NOT NULL, `track` VARCHAR(255) NOT NULL, `issuer` VARCHAR(36) NOT NULL, `reason` VARCHAR(255), `type` VARCHAR(32) NOT NULL, `start` INT NOT NULL, `end` INT NOT NULL, PRIMARY_KEY (`id`));'
        - run drustcraftt_db_set_version def:drustcraft.warn|1

    # load tracks
    - ~sql id:drustcraft 'query:SELECT `track`,`title` FROM `<server.flag[drustcraft.db.prefix]>warn_track`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/].unescaped||<list[]>>
      - define track:<[row].get[1].unescaped||<empty>>
      - define title:<[row].get[2].unescaped||<empty>>
      - flag server drustcraft.warn.tracks.<[track]>:<[title]>

    # load penalties
    - ~sql id:drustcraft 'query:SELECT `id`,`track`,`sort`,`type`,`duration` FROM `<server.flag[drustcraft.db.prefix]>warn_penalty`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/].unescaped||<list[]>>
      - define id:<[row].get[1]||<empty>>
      - define track:<[row].get[2]||<empty>>
      - define sort:<[row].get[3]||<empty>>
      - define type:<[row].get[4]||<empty>>
      - define duration:<[row].get[5]||<empty>>

      - flag server drustcraft.warn.penalty.<[track]>.id:<[id]>
      - flag server drustcraft.warn.penalty.<[track]>.sort:<[sort]>
      - flag server drustcraft.warn.penalty.<[track]>.type:<[type]>
      - flag server drustcraft.warn.penalty.<[track]>.duration:<[duration]>

    # load players
    - ~sql id:drustcraft 'query:SELECT `id`,`uuid`,`track`,`issuer`,`reason`,`starts`,`ends` FROM `<server.flag[drustcraft.db.prefix]>warn_player`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/].unescaped||<list[]>>
      - define id:<[row].get[1]||<empty>>
      - define uuid:<[row].get[2]||<empty>>
      - define track:<[row].get[3]||<empty>>
      - define issuer:<[row].get[4]||<empty>>
      - define track:<[row].get[5]||<empty>>
      - define reason:<[row].get[6].unescaped||<empty>>
      - define type:<[row].get[7]||<empty>>
      - define start:<[row].get[8]||<empty>>
      - define end:<[row].get[9]||<empty>>

      - flag server drustcraft.warn.players.<[uuid]>.<[id]>.track:<[track]>
      - flag server drustcraft.warn.players.<[uuid]>.<[id]>.issuer:<[issuer]>
      - flag server drustcraft.warn.players.<[uuid]>.<[id]>.reason:<[reason]>
      - flag server drustcraft.warn.players.<[uuid]>.<[id]>.type:<[type]>
      - flag server drustcraft.warn.players.<[uuid]>.<[id]>.start:<[start]>
      - flag server drustcraft.warn.players.<[uuid]>.<[id]>.end:<[end]>

    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>
      - run drustcraftt_tabcomplete_completion def:warn|_*players|_*tracks

    - flag server drustcraft.module.warn:<script[drustcraftw_warn].data_key[version]>


drustcraftc_warn:
  type: command
  debug: false
  name: warn
  description: Warns a player and applies a track
  usage: /warn <&lt>player<&gt> <&lt>track<&gt>
  permission: drustcraft.warn
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:warn
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - define target_player:<context.args.get[1]||<empty>>
    - define track:<context.args.get[2]||<empty>>

    - if <[target_player]> != <empty>:
      - define found_player:<server.match_offline_player[<[target_player]>]||<empty>>
      - if <[found_player].name||<empty>> == <[target_player]>:
        - define target_player:<[found_player]>

        - if <[track]> != <empty>:
          - if <yaml[drustcraft_warn].read[tracks].contains[<[track]>]>:
            - define next_row:<yaml[drustcraft_warn].read[players.<[target_player].uuid>.tracks.<[track]>].keys.highest.add[1]||1>

            - define track_data:<yaml[drustcraft_warn].read[tracks.<[track]>].get[<[next_row]>]||warning>
            - define action:<[track_data].before[:]>
            - define timeframe:perm
            - if <[track_data].after[:]> != perm:
              - define timeframe:<util.time_now.add[<[track_data].after[:].as_duration||0s>].epoch_millis.div[1000].round||perm>

            - choose <[action]>:
              - case mute:
                - narrate <&e>MUTE
              - case kick:
                - if !<[target_player].has_permission[drustcraft.warn.override]>:
                  - kick <[target_player]> reason:<proc[drustcraftp_warn.generate_msg].context[<[track]>]>
                - else:
                  - narrate 'WARN: <proc[drustcraftp_warn.generate_msg].context[<[track]>]>'
              - case ban:
                - if !<[target_player].has_permission[drustcraft.warn.override]>:
                  - yaml id:drustcraft_warn set players.<[target_player].uuid>.banned_track:<[track]>
                  - if <[timeframe]> == perm:
                    - yaml id:drustcraft_warn set players.<[target_player].uuid>.banned_until:perm
                  - else:
                    - if <yaml[drustcraft_warn].read[players.<[target_player].uuid>.banned_until]||0> < <[timeframe]>:
                      - yaml id:drustcraft_warn set players.<[target_player].uuid>.banned_until:<[timeframe]>
                    - else:
                      - define timeframe:<yaml[drustcraft_warn].read[players.<[target_player].uuid>.banned_until]||0>

                  - kick <[target_player]> reason:<proc[drustcraftp_warn.generate_msg].context[<[track]>|<[timeframe]>]>
                - else:
                  - narrate 'WARN: <proc[drustcraftp_warn.generate_msg].context[<[track]>]>'
              - default:
                - narrate '<&e>You have received a WARNING for <[track]>'

            - if !<[target_player].has_permission[drustcraft.warn.override]>:
              - yaml id:drustcraft_warn set players.<[target_player].uuid>.tracks.<[track]>.<[next_row]>.time:<util.time_now.epoch_millis.div[1000].round>
              - yaml id:drustcraft_warn set players.<[target_player].uuid>.tracks.<[track]>.<[next_row]>.by:<player.uuid||console>
              - if <context.args.size> > 2:
                - yaml id:drustcraft_warn set players.<[target_player].uuid>.tracks.<[track]>.<[next_row]>.reason:<context.args.remove[1|2].space_separated>

              - run drustcraftt_warn.save
          - else:
            - narrate '<&e>The track <[track]> was not found'
        - else:
          - narrate '<&e>A track is needed to warn a player'
      - else:
        - narrate '<&e>The player <[target_player]> was not found'
    - else:
      - narrate '<&e>A player is needed to warn'


drustcraftp_warn_kick_msg:
  type: procedure
  debug: false
  definitions: uuid|id
  script:
    - if <list[kick|ban].contains[<server.flag[drustcraft.warn.players.<[uuid]>.<[id]>.type]>]>:
      - define 'type:Kicked from Drustcraft'
      - define 'reason:<&nl><&nl><&c>Reason <&8>» <&7><server.flag[drustcraft.warn.players.<[uuid]>.<[id]>.reason]>'
      - define duration:<empty>

      - if <server.flag[drustcraft.warn.players.<[uuid]>.<[id]>.type]> == BAN:
        - if <server.flag[drustcraft.warn.players.<player.uuid>.<[id]>.end]> > 0:
          - define 'type:Temporarily Banned'
          - define 'duration:<&nl><&c>Duration <&8>» <&7><proc[drustcraftp_util_epoch_to_time].context[<server.flag[drustcraft.warn.players.<player.uuid>.<[id]>.end]>].from_now.formatted>'
        - else:
          - define 'type:Parmanently Banned'

      - determine '<&nl><&7><&l><[type]><[reason]><[duration]><&nl><&nl><&7>Visit <&e>www.drustcraft.com.au <&7>for more info'
    - determine null


drustcraftp_tabcomplete_tracks:
  type: procedure
  debug: false
  script:
    - determine <server.flag[drustcraft.warn.tracks].keys||<list[]>>
#159