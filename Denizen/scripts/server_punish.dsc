# Drustcraft - Punish
# https://github.com/drustcraft/drustcraft

# Action was action
# Rule was rule
# Incident when a player broke a rule

# TODO: Add register bans and unbans (for discord sync)

drustcraftw_punish:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_punish_load

    on script reload:
      - run drustcraftt_punish_load

    on player logs in priority:-1:
      - if !<server.has_flag[drustcraft.module.punish]>:
        - determine 'KICKED:<&e>This server is currently not available as it is starting up<&nl>Please try again in a few minutes'

    on player logs in server_flagged:drustcraft.module.punish:
      - define epoch_time:<util.time_now.epoch_millis.div[1000].round>
      - foreach <server.flag[drustcraft.punish.player.<player.uuid>].keys||<list[]>> as:id:
        - if <server.flag[drustcraft.punish.player.<player.uuid>.<[id]>.type]> == BAN && <server.flag[drustcraft.punish.player.<player.uuid>.<[id]>.active]> == 1:
          - if <server.flag[drustcraft.punish.player.<player.uuid>.<[id]>.end]> > <[epoch_time]> || <server.flag[drustcraft.punish.player.<player.uuid>.<[id]>.end]> == -1:
            - define duration:<server.flag[drustcraft.punish.player.<player.uuid>.<[id]>.end]>
            - if <[duration]> != -1:
              - define duration:<proc[drustcraftp_util_epoch_to_time].context[<server.flag[drustcraft.punish.player.<player.uuid>.<[id]>.end]>].from_now>
            - determine KICKED:<proc[drustcraftp_punish_kick_msg].context[<server.flag[drustcraft.punish.player.<player.uuid>.<[id]>.type]>|<server.flag[drustcraft.punish.player.<player.uuid>.<[id]>.rule]>|<[duration]>|<server.flag[drustcraft.punish.player.<player.uuid>.<[id]>.reason]>]>

    on player chats flagged:drustcraft.punish.muted:
      - narrate '<proc[drustcraftp_msg_format].context[error|You cannot send messages as you are currently muted]>'
      - determine CANCELLED

    on mute command server_flagged:drustcraft.module.chat:
      - determine passively FULFILLED
      - run drustcraftt_punish_mute def:<context.args>

    on unmute command server_flagged:drustcraft.module.chat:
      - determine passively FULFILLED
      - run drustcraftt_punish_unmute def:<context.args>


drustcraftt_punish_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR "Drustcraft Punish: Drustcraft Database module is required to be installed"
      - stop

    - waituntil <server.has_flag[drustcraft.module.db]>

    - define create_tables:true
    - ~run drustcraftt_db_get_version def:drustcraft.punish save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> != 1:
      - if <[version]> != null:
        - debug ERROR "Drustcraft Punish: Unexpected database version"
        - stop
      - else:
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>punish_rule` (`rule` VARCHAR(255) NOT NULL, `title` VARCHAR(255) NOT NULL, UNIQUE (`rule`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>punish_action` (`id` INT NOT NULL AUTO_INCREMENT, `rule` VARCHAR(255) NOT NULL, `sort` INT NOT NULL, `type` VARCHAR(32) NOT NULL, `duration` VARCHAR(32) NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>punish_item` (`id` INT NOT NULL AUTO_INCREMENT, `uuid` VARCHAR(36) NOT NULL, `rule` VARCHAR(255), `issuer` VARCHAR(36) NOT NULL, `reason` VARCHAR(255), `type` VARCHAR(32) NOT NULL, `start` INT NOT NULL, `end` INT NOT NULL, `active` INT DEFAULT 1, `cancel_uuid` VARCHAR(36), `cancel_reason` VARCHAR(255), `cancel_time` INT, RIMARY KEY (`id`));'
        - run drustcraftt_db_set_version def:drustcraft.punish|1

    # load rules
    - ~sql id:drustcraft 'query:SELECT `rule`,`title` FROM `<server.flag[drustcraft.db.prefix]>punish_rule`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/].unescaped||<list[]>>
      - define rule:<[row].get[1].unescaped||<empty>>
      - define title:<[row].get[2].unescaped||<empty>>
      - flag server drustcraft.punish.rule.<[rule]>:<[title]>

    # load penalties
    - ~sql id:drustcraft 'query:SELECT `id`,`rule`,`sort`,`type`,`duration` FROM `<server.flag[drustcraft.db.prefix]>punish_action`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/].unescaped||<list[]>>
      - define id:<[row].get[1]||<empty>>
      - define rule:<[row].get[2]||<empty>>
      - define sort:<[row].get[3]||<empty>>
      - define type:<[row].get[4]||<empty>>
      - define duration:<[row].get[5]||<empty>>

      - flag server drustcraft.punish.action.<[rule]>.<[sort]>.id:<[id]>
      - flag server drustcraft.punish.action.<[rule]>.<[sort]>.type:<[type]>
      - flag server drustcraft.punish.action.<[rule]>.<[sort]>.duration:<[duration]>

    # load items
    - ~sql id:drustcraft 'query:SELECT `id`,`uuid`,`rule`,`issuer`,`reason`,`type`,`start`,`end`,`active`,`cancel_uuid`,`cancel_reason`,`cancel_time` FROM `<server.flag[drustcraft.db.prefix]>punish_item`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/].unescaped||<list[]>>
      - define id:<[row].get[1]||<empty>>
      - define uuid:<[row].get[2]||<empty>>
      - define rule:<[row].get[3]||<empty>>
      - define issuer:<[row].get[4]||<empty>>
      - define reason:<[row].get[5].unescaped||<empty>>
      - define type:<[row].get[6].unescaped||<empty>>
      - define start:<[row].get[7]||<empty>>
      - define end:<[row].get[8]||<empty>>
      - define active:<[row].get[9]||<empty>>
      - define cancel_uuid:<[row].get[10]||<empty>>
      - define cancel_reason:<[row].get[11].unescaped||<empty>>
      - define cancel_time:<[row].get[12]||<empty>>

      - flag server drustcraft.punish.player.<[uuid]>.<[id]>.rule:<[rule]>
      - flag server drustcraft.punish.player.<[uuid]>.<[id]>.issuer:<[issuer]>
      - flag server drustcraft.punish.player.<[uuid]>.<[id]>.reason:<[reason]>
      - flag server drustcraft.punish.player.<[uuid]>.<[id]>.type:<[type]>
      - flag server drustcraft.punish.player.<[uuid]>.<[id]>.start:<[start]>
      - flag server drustcraft.punish.player.<[uuid]>.<[id]>.end:<[end]>
      - flag server drustcraft.punish.player.<[uuid]>.<[id]>.active:<[active]>
      - flag server drustcraft.punish.player.<[uuid]>.<[id]>.cancel_uuid:<[cancel_uuid]>
      - flag server drustcraft.punish.player.<[uuid]>.<[id]>.cancel_reason:<[cancel_reason]>
      - flag server drustcraft.punish.player.<[uuid]>.<[id]>.cancel_time:<[cancel_time]>

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>

      - run drustcraftt_tabcomplete_completion def:kick|_*onlineplayers|_*punish_rules

      - run drustcraftt_tabcomplete_completion def:ban|_*players|_*durations_perm|_*punish_rules
      - run drustcraftt_tabcomplete_completion def:unban|_*punish_bannedplayers

      - run drustcraftt_tabcomplete_completion def:warn|_*players|_*punish_rules

      - run drustcraftt_tabcomplete_completion def:note|add|_*players
      - run drustcraftt_tabcomplete_completion def:note|view|_*players
      - run drustcraftt_tabcomplete_completion def:note|remove|_*punish_noteids

      - run drustcraftt_tabcomplete_completion def:unpunish|_*punish_activeids

      - run drustcraftt_tabcomplete_completion def:punish|list
      - run drustcraftt_tabcomplete_completion def:punish|banlist

      - run drustcraftt_tabcomplete_completion def:punish|history|_*players
      - run drustcraftt_tabcomplete_completion def:punish|info|_*punish_activeids

      - run drustcraftt_tabcomplete_completion def:punish|title|_*punish_rules
      - run drustcraftt_tabcomplete_completion def:punish|incidents|_*punish_rules

      - run drustcraftt_tabcomplete_completion def:punish|addrule
      - run drustcraftt_tabcomplete_completion def:punish|remrule|_*punish_rules
      - run drustcraftt_tabcomplete_completion def:punish|editrule|_*punish_rules

      - run drustcraftt_tabcomplete_completion def:punish|actions|_*punish_rules
      - run drustcraftt_tabcomplete_completion def:punish|addaction|_*punish_rules|_*int_nozero|kick
      - run drustcraftt_tabcomplete_completion def:punish|addaction|_*punish_rules|_*int_nozero|warn
      - run drustcraftt_tabcomplete_completion def:punish|addaction|_*punish_rules|_*int_nozero|mute|_*durations_perm
      - run drustcraftt_tabcomplete_completion def:punish|addaction|_*punish_rules|_*int_nozero|ban|_*durations_perm
      - run drustcraftt_tabcomplete_completion def:punish|remaction|_*punish_rules|_*int_nozero
      - run drustcraftt_tabcomplete_completion def:punish|editaction|_*punish_rules|_*int_nozero|_*int_nozero|kick
      - run drustcraftt_tabcomplete_completion def:punish|editaction|_*punish_rules|_*int_nozero|_*int_nozero|warn
      - run drustcraftt_tabcomplete_completion def:punish|editaction|_*punish_rules|_*int_nozero|_*int_nozero|mute|_*durations_perm
      - run drustcraftt_tabcomplete_completion def:punish|editaction|_*punish_rules|_*int_nozero|_*int_nozero|ban|_*durations_perm

    # Load into Chat
    - if <server.scripts.parse[name].contains[drustcraftw_chat]>:
      - waituntil <server.has_flag[drustcraft.module.chat]>
      - flag server 'drustcraft.chat.rule_command:warn $PLAYER$ $RULE$'

      # hijack mute cmd
      - run drustcraftt_tabcomplete_remove def:mute
      - run drustcraftt_tabcomplete_remove def:unmute
      - run drustcraftt_tabcomplete_completion def:mute|_*onlineplayers|_*durations_perm|_*punish_rules
      - run drustcraftt_tabcomplete_completion def:unmute|_*punish_mutedplayers

    - flag server drustcraft.module.punish:<script[drustcraftw_punish].data_key[version]>


drustcraftt_punish_add:
  type: task
  debug: false
  definitions: target_player|issuer|type|rule|duration|reason
  script:
    - waituntil <server.sql_connections.contains[drustcraft]>
    - if <list[perm|NULL].contains[<[duration]>]>:
      - define ends:-1
    - else:
      - define ends:<util.time_now.add[<[duration]>].epoch_millis.div[1000].round>

    - define issuer_uuid:<tern[<[issuer].equals[console]>].pass[console].fail[<[issuer].uuid>]>

    - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>punish_item`(`uuid`,`rule`,`issuer`,`reason`,`type`,`start`,`end`) VALUES("<[target_player].uuid>", "<[rule]>", "<[issuer].uuid>", <tern[<[reason].exists>].pass["<[reason]>"].fail[NULL]>, "<[type]>", <util.time_now.epoch_millis.div[1000].round>, <[ends]>);'
    - ~sql id:drustcraft 'query:SELECT LAST_INSERT_ID();' save:sql_result
    - define id:<entry[sql_result].result.get[1].split[/].get[1]>

    - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.rule:<[rule]>
    - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.issuer:<[issuer_uuid]>
    - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.reason:<[reason]||null>
    - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.type:<[type]>
    - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.start:<util.time_now.epoch_millis.div[1000].round>
    - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.end:<[ends]>
    - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.active:1
    - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.cancel_uuid:NULL
    - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.cancel_time:NULL
    - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.cancel_reason:NULL
    - determine <[id]>


drustcraftp_punish_kick_msg:
  type: procedure
  debug: false
  definitions: type|rule|duration|message
  script:
    - if <list[KICK|BAN].contains[<[type]>]>:
      - define 'type_text:Kicked from Drustcraft'
      - define 'reason:<&nl><&nl><&c>Reason <&8>» <&7><server.flag[drustcraft.punish.rule.<[rule]>]>'
      - define duration_text:<empty>
      - if <[message].exists> && <[message]> != <empty> && <[message]> != NULL:
        - define message:<&e><[message]><&nl><&nl>
      - else:
        - define message:<empty>

      - if <[type]> == BAN:
        - if <duration[<[duration]>].exists>:
          - define 'type_text:Temporarily Banned'
          - define 'duration_text:<&nl><&c>Duration <&8>» <&7><duration[<[duration]>].formatted>'
        - else:
          - define 'type_text:Permanently Banned'

      - determine '<&e><&l><[type_text]><[reason]><[duration_text]><&nl><&nl><[message]><&7>Visit <&e>www.drustcraft.com.au <&7>for more info'
    - determine null


drustcraftt_punish_mute:
  type: task
  debug: false
  definitions: player|duration|rule
  script:
    - if !<server.has_flag[drustcraft.module.punish]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Punish tools not loaded. Check console for errors]>'
      - stop

    - define message:<queue.definition_map.get[raw_context].remove[1|2|3].space_separated>

    - if <[player]> == confirm:
      - if <player.has_flag[drustcraft.punish.confirm.mute]>:
        - define found_player:<player.flag[drustcraft.punish.confirm.mute.player]>
        - define duration:<player.flag[drustcraft.punish.confirm.mute.duration]>
        - define rule:<player.flag[drustcraft.punish.confirm.mute.rule]>
        - define message:<player.flag[drustcraft.punish.confirm.mute.message]>

        - run drustcraftt_punish_add def:<[found_player]>|<player||console>|MUTE|<[rule]>|<[duration]>|<[message]>
        - if <server.has_flag[drustcraft.module.chat]>:
          - run drustcraftt_chat_mute_player def:<[found_player]>|<[duration]>
        - else:
          - if <[duration]> == perm:
            - flag <[found_player]> drustcraft.punish.muted
          - else:
            - flag <[found_player]> drustcraft.punish.muted expire:<util.time_now.add[<[duration]>]>

        - if <[duration]> == perm:
          - narrate '<proc[drustcraftp_msg_format].context[success|The player $e<[found_player].name> $rhas been permanently muted]>'
          - narrate '<proc[drustcraftp_msg_format].context[warning|You have been permanently muted]>' targets:<[found_player]>
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[success|The player $e<[found_player].name> $rhas been muted for $e<[duration]>]>'
          - narrate '<proc[drustcraftp_msg_format].context[warning|You have been muted for $e<[duration]>]>' targets:<[found_player]>

        - flag player drustcraft.punish.confirm.mute:!
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|There is nothing to confirm for this command]>'
      - stop

    - define found_player:<server.match_offline_player[<[player]>]>
    - if <[found_player].exists> && <[found_player].name> == <[player]>:
      - if <duration[<[duration]>].exists> || <[duration]> == perm:
        - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]||false>:
          - flag player drustcraft.punish.confirm.mute.player:<[found_player]> expires:<util.time_now.add[10s]>
          - flag player drustcraft.punish.confirm.mute.duration:<[duration]> expires:<util.time_now.add[10s]>
          - flag player drustcraft.punish.confirm.mute.rule:<[rule]> expires:<util.time_now.add[10s]>
          - flag player drustcraft.punish.confirm.mute.message:<[message]> expires:<util.time_now.add[10s]>

          - narrate '<proc[drustcraftp_msg_format].context[warning|The mute command is reserved for direct cases. Moderators should use the $e/warn $rcommand instead]>'
          - narrate '<proc[drustcraftp_msg_format].context[warning|To confirm the use of this command, enter $e/mute confirm $rwithin the next 10 seconds]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The rule id $e<[rule]> $ris not valid]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|The duration $e<[duration]> $ris not valid]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[player]> $rwas not found]>'


drustcraftt_punish_unmute:
  type: task
  debug: false
  definitions: player_name
  script:
    - if !<server.has_flag[drustcraft.module.punish]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Punish tools not loaded. Check console for errors]>'
      - stop

    - define message:<queue.definition_map.get[raw_context].remove[1].space_separated||<element[]>>
    - define epoch:<util.time_now.epoch_millis.div[1000].round>
    - define found:false

    - if <[player_name].exists>:
      - define target_player:<server.match_offline_player[<[player_name]>]>
      - if <[target_player].exists> && <[target_player].name> == <[player_name]>:
        - flag <[target_player]> drustcraft.punish.muted:!
        - if <server.has_flag[drustcraft.module.chat]>:
          - run drustcraftt_chat_unmute_player def:<[target_player]>

        - foreach <server.flag[drustcraft.punish.player.<[target_player].uuid>].keys> as:id:
          - if <server.flag[drustcraft.punish.player.<[target_player].uuid>.<[id]>.type]> == BAN && <server.flag[drustcraft.punish.player.<[target_player].uuid>.<[id]>.active]> == 1:
            - if <server.flag[drustcraft.punish.player.<[target_player].uuid>.<[id]>.end]> > <[epoch]> || <server.flag[drustcraft.punish.player.<[target_player].uuid>.<[id]>.end]> == -1:
              - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.active:0
              - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.cancel_uuid:<player.uuid||console>
              - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.cancel_time:<[epoch]>
              - define found:true

        - if <[found]>:
          - narrate '<proc[drustcraftp_msg_format].context[success|The player $e<[target_player].name> $rhas been unmuted]>'
          - narrate '<proc[drustcraftp_msg_format].context[warning|You have been unmuted]>' targets:<[target_player]>
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[player_name]> $ris not muted]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[player_name]> $rwas not found on the server]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|No player name was entered]>'


drustcraftc_punish_mute:
  type: command
  debug: false
  name: mute
  description: Mutes a player for a duration
  usage: /mute
  permission: drustcraft.mute
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:mute
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - run drustcraftt_punish_mute def:<context.args>


drustcraftc_punish_unmute:
  type: command
  debug: false
  name: unmute
  description: Unmutes a player that has been muted
  usage: /unmute
  permission: drustcraft.mute
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:unmute
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - run drustcraftt_punish_unmute def:<context.args>


drustcraftc_kick:
  type: command
  debug: false
  name: kick
  description: Kicks a player from the server
  usage: /kick <&lt>player<&gt> <&lt>reason<&gt> (message)
  permission: drustcraft.punish
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:kick
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.punish]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Punish tools not loaded. Check console for errors]>'
      - stop

    - define target_player:<context.args.get[1]||<empty>>
    - define rule:<context.args.get[2]||<empty>>
    - define message:<context.args.remove[1|2].space_separated>

    - if <[target_player]> == confirm:
      - if <player.has_flag[drustcraft.punish.confirm.kick]>:
        - define found_player:<player.flag[drustcraft.punish.confirm.kick.player]>
        - define rule:<player.flag[drustcraft.punish.confirm.kick.rule]>
        - define message:<player.flag[drustcraft.punish.confirm.kick.message]>

        - define reason:<proc[drustcraftp_punish_kick_msg].context[KICK|<[rule]>|0|<[message]>]>
        - kick <[found_player]> reason:<[reason]>
        - narrate '<&7><[found_player].name> was kicked from Drustcraft for <server.flag[drustcraft.punish.rule.<[rule]>]>' targets:<server.online_players>
        - run drustcraftt_punish_add def:<[found_player]>|<player||console>|KICK|<[rule]>|0|<[message]>

        - flag player drustcraft.punish.confirm.kick:!
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|There is nothing to confirm for this command]>'
      - stop

    - if <[target_player]> != <empty>:
      - define found_player:<server.match_player[<[target_player]>]||<empty>>
      - if <[found_player].name||<empty>> == <[target_player]>:
        - define target_player:<[found_player]>

        - if <[rule]> != <empty>:
          - define reason:null
          - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]||false>:
            - flag player drustcraft.punish.confirm.kick.player:<[found_player]> expires:<util.time_now.add[10s]>
            - flag player drustcraft.punish.confirm.kick.rule:<[rule]> expires:<util.time_now.add[10s]>
            - flag player drustcraft.punish.confirm.kick.message:<[message]> expires:<util.time_now.add[10s]>

            - narrate '<proc[drustcraftp_msg_format].context[warning|The kick command is reserved for direct cases. Moderators should use the $e/warn $rcommand instead]>'
            - narrate '<proc[drustcraftp_msg_format].context[warning|To confirm the use of this command, enter $e/kick confirm $rwithin the next 10 seconds]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The reason $e<[rule]> is not a valid reason]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No reason was entered to kick the player]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[target_player]> $rwas not found online]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|You need to enter a player to kick]>'


drustcraftc_ban:
  type: command
  debug: false
  name: ban
  description: Bans a player from the server
  usage: /ban <&lt>player<&gt> <&lt>duration<&gt> <&lt>reason<&gt> (message)
  permission: drustcraft.punish
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:ban
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.punish]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Punish tools not loaded. Check console for errors]>'
      - stop

    - define target_player:<context.args.get[1]||<empty>>
    - define duration:<context.args.get[2]||<empty>>
    - define rule:<context.args.get[3]||<empty>>
    - define message:<context.args.remove[1|2|3].space_separated>

    - if <[target_player]> == confirm:
      - if <player.has_flag[drustcraft.punish.confirm.ban]>:
        - define found_player:<player.flag[drustcraft.punish.confirm.ban.player]>
        - define duration:<player.flag[drustcraft.punish.confirm.ban.duration]>
        - define rule:<player.flag[drustcraft.punish.confirm.ban.rule]>
        - define message:<player.flag[drustcraft.punish.confirm.ban.message]>

        - define type:BAN
        - define reason:<proc[drustcraftp_punish_kick_msg].context[<[type]>|<[rule]>|<[duration]>|<[message]>]>
        - kick <[found_player]> reason:<[reason]>
        - run drustcraftt_punish_add def:<[found_player]>|<player||console>|<[type]>|<[rule]>|<[duration]>|<[message]>

        - if <[duration]> == perm:
          - narrate '<&7><[found_player].name> was banned from Drustcraft for <server.flag[drustcraft.punish.rule.<[rule]>]>' targets:<server.online_players>
        - else:
          - narrate '<&7><[found_player].name> was banned for <[duration]> from Drustcraft for <server.flag[drustcraft.punish.rule.<[rule]>]>' targets:<server.online_players>

        - flag player drustcraft.punish.confirm.ban:!
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|There is nothing to confirm for this command]>'
      - stop

    - if <[target_player]> != <empty>:
      - define found_player:<server.match_offline_player[<[target_player]>]||<empty>>
      - if <[found_player].name||<empty>> == <[target_player]>:
        - define target_player:<[found_player]>

        - if <[duration]> != <empty>:
          - if <[rule]> != <empty>:
            - define reason:null
            - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]||false>:
              - flag player drustcraft.punish.confirm.ban.player:<[found_player]> expires:<util.time_now.add[10s]>
              - flag player drustcraft.punish.confirm.ban.duration:<[duration]> expires:<util.time_now.add[10s]>
              - flag player drustcraft.punish.confirm.ban.rule:<[rule]> expires:<util.time_now.add[10s]>
              - flag player drustcraft.punish.confirm.ban.message:<[message]> expires:<util.time_now.add[10s]>

              - narrate '<proc[drustcraftp_msg_format].context[warning|The ban command is reserved for direct cases. Moderators should use the $e/warn $rcommand instead]>'
              - narrate '<proc[drustcraftp_msg_format].context[warning|To confirm the use of this command, enter $e/ban confirm $rwithin the next 10 seconds]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The reason $e<[rule]> is not a valid reason]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|No reason was entered to ban the player]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No duration was entered to ban the player]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[target_player]> $rwas not found]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|You need to enter a player to ban]>'


drustcraftc_punish_unban:
  type: command
  debug: false
  name: unban
  description: Unbans a player that has been banned
  usage: /unban player reason
  permission: drustcraft.punish
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:unmute
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.punish]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Punish tools not loaded. Check console for errors]>'
      - stop

    - define player_name:<context.args.get[1]||<empty>>
    - define message:<queue.definition_map.get[raw_context].remove[1].space_separated||<element[]>>

    - if <[player_name]> != <empty>:
      - define epoch:<util.time_now.epoch_millis.div[1000].round>
      - define found:false

      - define target_player:<server.match_offline_player[<[player_name]>]>
      - if <[target_player].exists> && <[target_player].name> == <[player_name]>:
        - foreach <server.flag[drustcraft.punish.player.<[target_player].uuid>].keys> as:id:
          - if <server.flag[drustcraft.punish.player.<[target_player].uuid>.<[id]>.type]> == BAN && <server.flag[drustcraft.punish.player.<[target_player].uuid>.<[id]>.active]> == 1:
            - if <server.flag[drustcraft.punish.player.<[target_player].uuid>.<[id]>.end]> > <[epoch]> || <server.flag[drustcraft.punish.player.<[target_player].uuid>.<[id]>.end]> == -1:
              - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.active:0
              - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.cancel_uuid:<player.uuid||console>
              - flag server drustcraft.punish.player.<[target_player].uuid>.<[id]>.cancel_time:<[epoch]>
              - waituntil <server.sql_connections.contains[drustcraft]>
              - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>punish_item` SET `active` = 0, `cancel_uuid` = "<player.uuid||console>", `cancel_time` = <[epoch]>, `cancel_reason` = "<[message].sql_escaped>" WHERE `id` = <[id]>;'
              - define found:true

        - if <[found]>:
          - narrate '<proc[drustcraftp_msg_format].context[success|The player $e<[player_name]> $rhas been unbanned]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[player_name]> $ris not banned]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[player_name]> $rwas not found on the server]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|No player name was entered]>'


drustcraftc_warn:
  type: command
  debug: false
  name: warn
  description: Warns a player and applies a rule
  usage: /warn <&lt>player<&gt> <&lt>rule<&gt>
  permission: drustcraft.punish
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:warn
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.punish]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Punish tools not loaded. Check console for errors]>'
      - stop

    - define target_player:<context.args.get[1]||<empty>>
    - define rule:<context.args.get[2]||<empty>>
    - define reason:<context.args.remove[1|2].space_separated>

    - if <[target_player]> != <empty>:
      - define found_player:<server.match_offline_player[<[target_player]>]||<empty>>
      - if <[found_player].name||<empty>> == <[target_player]>:
        - define target_player:<[found_player]>

        - if <[rule]> != <empty>:
          - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]||false>:
            - define count:0
            - foreach <server.flag[drustcraft.punish.player.<[found_player].uuid>].keys> as:id:
              - if <server.flag[drustcraft.punish.player.<[found_player].uuid>.<[id]>.rule]> == <[rule]>:
                - define count:++
            - define rule_num:<server.flag[drustcraft.punish.action.<[rule]>].keys.numerical.get[<[count]>]||-1>
            - if <[rule_num]> == -1:
              - define rule_num:<server.flag[drustcraft.punish.action.<[rule]>].keys.numerical.last||-1>
            - if <[rule_num]> == -1:
              - narrate '<proc[drustcraftp_msg_format].context[error|The rule $e<[rule]> $rdoes not have any actions listed]>'
              - stop

            - choose <server.flag[drustcraft.punish.action.<[rule]>.<[rule_num]>.type]>:
              - case MUTE:
                - define duration:<server.flag[drustcraft.punish.action.<[rule]>.<[rule_num]>.duration]>
                - flag player drustcraft.punish.confirm.mute.player:<[found_player]> expires:<util.time_now.add[10s]>
                - flag player drustcraft.punish.confirm.mute.duration:<[duration]> expires:<util.time_now.add[10s]>
                - flag player drustcraft.punish.confirm.mute.rule:<[rule]> expires:<util.time_now.add[10s]>
                - flag player drustcraft.punish.confirm.mute.message:<[reason]> expires:<util.time_now.add[10s]>
                - ~run drustcraftt_punish_add def:<[found_player]>|<player||console>|MUTE|<[rule]>|<[duration]>|<[reason]>
                - run drustcraftt_punish_mute def:confirm

              - case WARN:
                - run drustcraftt_punish_add def:<[found_player]>|<player||console>|WARN|<[rule]>|0|<[reason]>
                - playsound <[found_player]> sound:ENTITY_ARROW_HIT_PLAYER volume:1.0 pitch:0.1
                - wait 5t
                - narrate '<&6>[<&6>!!!<&6>] <&6>You are warned for <&f><server.flag[drustcraft.punish.rule.<[rule]>]> <[reason]>' targets:<server.online_players>
                - playsound <server.online_players> sound:ENTITY_ARROW_HIT_PLAYER volume:1.0 pitch:0.1
                - wait 5t
                - playsound <server.online_players> sound:ENTITY_ARROW_HIT_PLAYER volume:1.0 pitch:0.1
                - wait 5t
                - narrate '<&7><[found_player].name> was warned for <server.flag[drustcraft.punish.rule.<[rule]>]>' targets:<server.online_players.exclude[<[found_player]>]>

              - case KICK:
                - define kick_msg:<proc[drustcraftp_punish_kick_msg].context[KICK|<[rule]>|0|<[reason]>]>
                - run drustcraftt_punish_add def:<[found_player]>|<player||console>|KICK|<[rule]>|0|<[reason]>
                - kick <[found_player]> reason:<[kick_msg]>
                - narrate '<&7><[found_player].name> was kicked from Drustcraft for <server.flag[drustcraft.punish.rule.<[rule]>]>' targets:<server.online_players>

              - case BAN:
                - define duration:<server.flag[drustcraft.punish.action.<[rule]>.<[rule_num]>.duration]>
                - define kick_msg:<proc[drustcraftp_punish_kick_msg].context[BAN|<[rule]>|<[duration]>|<[reason]>]>
                - run drustcraftt_punish_add def:<[found_player]>|<player||console>|BAN|<[rule]>|<[duration]>|<[reason]>
                - kick <[found_player]> reason:<[kick_msg]>
                - if <[duration]> == perm:
                  - narrate '<&7><[found_player].name> was banned from Drustcraft for <server.flag[drustcraft.punish.rule.<[rule]>]>' targets:<server.online_players>
                - else:
                  - narrate '<&7><[found_player].name> was banned for <[duration]> from Drustcraft for <server.flag[drustcraft.punish.rule.<[rule]>]>' targets:<server.online_players>
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The punishment rule $e<[rule]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No punishment rule was entered]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[target_player]> $rwas not found]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|No player was not entered]>'


drustcraftc_note:
  type: command
  debug: false
  name: note
  description: Creates or edits a player note
  usage: /note [add|view|remove] [<&lt>player<&gt>]
  permission: drustcraft.punish
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:note
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.punish]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Punish tools not loaded. Check console for errors]>'
      - stop

    - choose <context.args.get[1]||<empty>>:
      - case add:
        - if <context.args.get[2]||<empty>> != <empty>:
          - define found_player:<server.match_offline_player[<context.args.get[2]>]>
          - if <[found_player].exists> && <[found_player].name> == <context.args.get[2]>:
            - if <context.args.size> >= 3:
              - ~run drustcraftt_punish_add def:<[found_player]>|<player||console>|NOTE|NULL|NULL|<context.args.remove[1|2].space_separated>
              - narrate '<proc[drustcraftp_msg_format].context[success|Your note was save against $e<context.args.get[2]>]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|No note was entered to save against $e<context.args.get[2]>]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[2]> $rwas not found on the server]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No player was entered]>'

      - case view:
        - if <context.args.get[2]||<empty>> != <empty>:
          - define found_player:<server.match_offline_player[<context.args.get[2]>]>
          - if <[found_player].exists> && <[found_player].name> == <context.args.get[2]>:
            - ~run drustcraftt_chatgui_clear
            - foreach <server.flag[drustcraft.punish.player.<[found_player].uuid>].keys.numerical||<list[]>> as:id:
              - if <server.flag[drustcraft.punish.player.<[found_player].uuid>.<[id]>.type]> == NOTE:
                - define line:<proc[drustcraftp_chatgui_option].context[<[id]>]>
                - define 'time:<proc[drustcraftp_util_epoch_to_time].context[<server.flag[drustcraft.punish.player.<[found_player].uuid>.<[id]>.start]>].format[yyyy/MM/dd h:mma]>'
                - define issuer_name:<tern[<server.flag[drustcraft.punish.player.<[found_player].uuid>.<[id]>.issuer].equals[console]>].pass[console].fail[<player[<server.flag[drustcraft.punish.player.<[found_player].uuid>.<[id]>.issuer]>].name||Unknown>]>
                - define 'line:<[line]><&e><[time]> <&2><[issuer_name]>: <&7><server.flag[drustcraft.punish.player.<[found_player].uuid>.<[id]>.reason]>'
                - ~run drustcraftt_chatgui_item def:<[line]>

            - ~run drustcraftt_chatgui_render 'def:note view|<[found_player].name> Notes|<context.args.get[3]||1>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[2]> $rwas not found on the server]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No player was entered]>'

      - case remove:
        - if <context.args.get[2]||<empty>> != <empty>:
          - if <context.args.get[2].is_integer> && <context.args.get[2]> > 0:
            - define id:<context.args.get[2]>
            - foreach <server.flag[drustcraft.punish.player].keys||<list[]>> as:player_uuid:
              - if <server.has_flag[drustcraft.punish.player.<[player_uuid]>.<[id]>]>:
                - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.type]> == NOTE:
                  - waituntil <server.sql_connections.contains[drustcraft]>
                  - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>punish_item` WHERE `id` = <[id]>;'
                  - flag server drustcraft.punish.player.<[player_uuid]>.<[id]>:!
                  - narrate '<proc[drustcraftp_msg_format].context[success|The note ID $e<[id]> $ragainst player $e<player[<[player_uuid]>].name> $rwas removed]>'
                  - stop
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|The incident ID $e<[id]> $ris not a note]>'
                  - stop
            - narrate '<proc[drustcraftp_msg_format].context[error|The note ID $e<[id]> $rwas not found]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The note ID entered is not correct]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No note ID was entered]>'

      - default:
        - narrate '<proc[drustcraftp_msg_format].context[error|Unknown option. Try <queue.script.data_key[usage].parsed>]>'


drustcraftc_unpunish:
  type: command
  debug: false
  name: unpunish
  description: Removes a punishment action
  usage: /unpunish [<&lt>incident-id<&gt>]
  permission: drustcraft.punish
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:unpunish
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.punish]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Punish tools not loaded. Check console for errors]>'
      - stop

    - define id:<context.args.get[1]||<empty>>
    - define reason:<context.args.remove[1].space_separated>

    - if <[id]> != <empty>:
      - if <[id].is_integer> && <[id]> > 0:
        - foreach <server.flag[drustcraft.punish.player].keys||<list[]>> as:player_uuid:
          - if <server.has_flag[drustcraft.punish.player.<[player_uuid]>.<[id]>]>:
            - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.type]> != NOTE:
              - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.active]> == 1:
                - define uuid:<player.uuid||console>
                - define time:<util.time_now.epoch_millis.div[1000].round>

                - waituntil <server.sql_connections.contains[drustcraft]>
                - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>punish_item` SET `active` = 0, `cancel_uuid` = "<[uuid]>", `cancel_time` = <[time]>, `cancel_reason` = "<[reason].sql_escaped>" WHERE `id` = <[id]>;'

                - flag server drustcraft.punish.player.<[player_uuid]>.<[id]>.active:0
                - flag server drustcraft.punish.player.<[player_uuid]>.<[id]>.cancel_uuid:<[uuid]>
                - flag server drustcraft.punish.player.<[player_uuid]>.<[id]>.cancel_time:<[time]>
                - flag server drustcraft.punish.player.<[player_uuid]>.<[id]>.cancel_reason:<[reason]>

                - narrate '<proc[drustcraftp_msg_format].context[success|The incident ID $e<[id]> $rwas removed]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The incident ID $e<[id]> $rwas already removed]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The incident ID $e<[id]> $rcannot be unpunished as it is a note]>'
            - stop

        - narrate '<proc[drustcraftp_msg_format].context[error|The incident ID $e<[id]> $rwas not found]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|The incident ID $e<[id]> $ris an invalid format]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|Unknown option. Try <queue.script.data_key[usage].parsed>]>'


drustcraftc_punish:
  type: command
  debug: false
  name: punish
  description: Creates or edits a rule
  usage: /punish <&lt>list|<&gt> <&lt>rule<&gt>
  permission: drustcraft.punish
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:punish
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.punish]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Punish tools not loaded. Check console for errors]>'
      - stop

    - define epoch:<util.time_now.epoch_millis.div[1000].round>

    - choose <context.args.get[1]||null>:
      - case list:
        - ~run drustcraftt_chatgui_clear
        - foreach <server.flag[drustcraft.punish.rule].keys||<list[]>> as:rule:
          - define active:0
          - define total:0
          - foreach <server.flag[drustcraft.punish.player].keys||<list[]>> as:player_uuid:
            - foreach <server.flag[drustcraft.punish.player.<[player_uuid]>].keys> as:id:
              - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.rule]> == <[rule]>:
                - define total:++
              - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.active]> == 1 && <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.end]> > <[epoch]>:
                - define active:++

          - define line:<proc[drustcraftp_chatgui_option].context[<[rule]>]>
          - define 'line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.punish.rule.<[rule]>]> <&7>(<server.flag[drustcraft.punish.action.<[rule]>].keys.size||0> penalties <proc[drustcraftp_chatgui_button].context[add|View|punish actions <[rule]>|Show details about this rule|RUN_COMMAND]>, <[active]>/<[total]> incidents <proc[drustcraftp_chatgui_button].context[add|View|punish info <[rule]>|Show details about this rule|RUN_COMMAND]>)]>'
          - ~run drustcraftt_chatgui_item def:<[line]>

        - ~run drustcraftt_chatgui_render 'def:rule list|Punishment rules|<context.args.get[2]||1>'

      - case banlist:
        - ~run drustcraftt_chatgui_clear
        - foreach <server.flag[drustcraft.punish.player].keys||<list[]>> as:player_uuid:
          - foreach <server.flag[drustcraft.punish.player.<[player_uuid]>].keys> as:id:
            - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.type]> == BAN && <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.active]> == 1 && <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.end]> > <[epoch]>:
              - define line:<proc[drustcraftp_chatgui_option].context[<[id]>]>
              - define line:<[line]><proc[drustcraftp_chatgui_value].context[<player[<[player_uuid]>].name>]>
              - define 'line:<[line]> <proc[drustcraftp_chatgui_value].context[<&6><server.flag[drustcraft.punish.rule.<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.rule]>]>]>'
              - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.end]> == -1:
                - define 'line:<[line]> <proc[drustcraftp_chatgui_value].context[(permanently)]>'
              - else:
                - define 'line:<[line]> <proc[drustcraftp_chatgui_value].context[(until <proc[drustcraftp_util_epoch_to_time].context[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.end]>].format[yyyy/MM/dd h:mma]>)]>'
              - ~run drustcraftt_chatgui_item def:<[line]>
        - ~run drustcraftt_chatgui_render 'def:punish banlist|Current Bans|<context.args.get[2]||1>'

      - case history:
        - if <context.args.get[2]||<empty>> != <empty>:
          - define found_player:<server.match_offline_player[<context.args.get[2]>]>
          - if <[found_player].exists> && <[found_player].name> == <context.args.get[2]>:
            - ~run drustcraftt_chatgui_clear
            - foreach <server.flag[drustcraft.punish.player.<[found_player].uuid>].keys.numerical.reverse> as:id:
              - define line:<proc[drustcraftp_chatgui_option].context[<[id]>]>
              - define 'line:<[line]><proc[drustcraftp_chatgui_value].context[<proc[drustcraftp_util_epoch_to_time].context[<server.flag[drustcraft.punish.player.<[found_player].uuid>.<[id]>.start]>].format[yyyy/MM/dd h:mma]>]>'
              - define 'line:<[line]> <proc[drustcraftp_chatgui_value].context[<&6><server.flag[drustcraft.punish.player.<[found_player].uuid>.<[id]>.type]>]>'
              - define 'line:<[line]> <proc[drustcraftp_chatgui_value].context[<&c><server.flag[drustcraft.punish.rule.<server.flag[drustcraft.punish.player.<[found_player].uuid>.<[id]>.rule]>]||<empty>>]> <proc[drustcraftp_chatgui_button].context[view|View|punish info <[id]>|Show incident information|RUN_COMMAND]>'
              - ~run drustcraftt_chatgui_item def:<[line]>
            - ~run drustcraftt_chatgui_render 'def:punish history|<[found_player].name> history|<context.args.get[3]||1>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[2]> $rwas not found on the server]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No player was entered]>'

      - case info:
        - if <context.args.get[2]||<empty>> != <empty>:
          - define id:<context.args.get[2]>
          - if <[id].is_integer> && <[id]> > 0:
            - foreach <server.flag[drustcraft.punish.player].keys||<list[]>> as:player_uuid:
              - if <server.has_flag[drustcraft.punish.player.<[player_uuid]>.<[id]>]>:
                - ~run drustcraftt_chatgui_clear
                - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.type]> != NOTE:
                  - ~run drustcraftt_chatgui_item def:<proc[drustcraftp_chatgui_option].context[For]><proc[drustcraftp_chatgui_value].context[<player[<[player_uuid]>].name>]>
                  - ~run drustcraftt_chatgui_item 'def:<proc[drustcraftp_chatgui_option].context[Active]><proc[drustcraftp_chatgui_value].context[<tern[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.active].equals[1]>].pass[Active].fail[Not Active]>]>'
                  - ~run drustcraftt_chatgui_item def:<proc[drustcraftp_chatgui_option].context[Rule]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.punish.rule.<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.rule]>]>]>
                  - ~run drustcraftt_chatgui_item def:<proc[drustcraftp_chatgui_option].context[Action]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.type]>]>
                  - ~run drustcraftt_chatgui_item 'def:<proc[drustcraftp_chatgui_option].context[Issued by]><proc[drustcraftp_chatgui_value].context[<player[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.issuer]>].name>]>'
                  - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.reason]> == NULL:
                    - ~run drustcraftt_chatgui_item def:<proc[drustcraftp_chatgui_option].context[Reason]><proc[drustcraftp_chatgui_value].context[]>
                  - else:
                    - ~run drustcraftt_chatgui_item def:<proc[drustcraftp_chatgui_option].context[Reason]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.reason]>]>
                  - ~run drustcraftt_chatgui_item 'def:<proc[drustcraftp_chatgui_option].context[Started]><proc[drustcraftp_chatgui_value].context[<proc[drustcraftp_util_epoch_to_time].context[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.start]>].format[yyyy/MM/dd h:mma]>]>'
                  - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.end]> == -1:
                    - ~run drustcraftt_chatgui_item def:<proc[drustcraftp_chatgui_option].context[Ends]><proc[drustcraftp_chatgui_value].context[permanently]>
                  - else:
                    - ~run drustcraftt_chatgui_item 'def:<proc[drustcraftp_chatgui_option].context[Ends]><proc[drustcraftp_chatgui_value].context[<proc[drustcraftp_util_epoch_to_time].context[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.end]>].format[yyyy/MM/dd h:mma]>]>'
                  - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.active]> == 0:
                    - ~run drustcraftt_chatgui_item 'def:<proc[drustcraftp_chatgui_option].context[Cancelled by]><proc[drustcraftp_chatgui_value].context[<tern[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.cancel_uuid].equals[console]>].pass[console].fail[<player[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.cancel_uuid]>].name>]>]>'
                    - ~run drustcraftt_chatgui_item 'def:<proc[drustcraftp_chatgui_option].context[Cancelled at]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.cancel_time]>]>'
                    - ~run drustcraftt_chatgui_item 'def:<proc[drustcraftp_chatgui_option].context[Cancelled reason]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.cancel_reason]>]>'
                - else:
                  - ~run drustcraftt_chatgui_item def:<proc[drustcraftp_chatgui_option].context[By]><proc[drustcraftp_chatgui_value].context[<player[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.issuer]>].name>]>
                  - ~run drustcraftt_chatgui_item def:<proc[drustcraftp_chatgui_option].context[Note]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.reason]>]>
                  - ~run drustcraftt_chatgui_item 'def:<proc[drustcraftp_chatgui_option].context[Logged at]><proc[drustcraftp_chatgui_value].context[<proc[drustcraftp_util_epoch_to_time].context[<server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.start]>].format[yyyy/MM/dd h:mma]>]>'
                - ~run drustcraftt_chatgui_render 'def:punish info <[id]>|Incident <[id]>|<context.args.get[3]||1>'
                - stop
            - narrate '<proc[drustcraftp_msg_format].context[error|The incident ID $e<context.args.get[2]> $rwas not found]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The incident ID $e<context.args.get[2]> $ris not correct]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No incident ID was entered]>'

      - case title:
        - define rule:<context.args.get[2]||<empty>>
        - if <[rule]> != <empty>:
          - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]||false>:
            - define title:<context.args.remove[1|2].space_separated||<empty>>
            - if <[title]> != <empty>:
              - flag server drustcraft.punish.rule.<[rule]>:<[title]>
              - waituntil <server.sql_connections.contains[drustcraft]>
              - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>punish_rule` SET `title` = "<[title]>" WHERE `rule` = "<[rule]>";'
              - narrate '<proc[drustcraftp_msg_format].context[success|The title for rule id $e<[rule]> $rwas changed to $e<[title]>]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|No title was entered]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The rule id $e<[rule]> $rdoes not exist]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No rule id was entered]>'

      - case incidents:
        - define rule:<context.args.get[2]||<empty>>
        - if <[rule]> != <empty>:
          - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]>:
            - ~run drustcraftt_chatgui_clear
            - define incidents_map:<map[]>
            - foreach <server.flag[drustcraft.punish.player].keys||<list[]>> as:player_uuid:
              - foreach <server.flag[drustcraft.punish.player.<[player_uuid]>].keys||<list[]>> as:id:
                - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.rule]> == <[rule]>:
                  - define incidents_map:<[incidents_map].with[<[id]>].as[<[player_uuid]>]>

            - foreach <[incidents_map].keys.numerical.reverse>:
              - ~run drustcraftt_chatgui_item 'def:<proc[drustcraftp_chatgui_option].context[<[value]>]><proc[drustcraftp_chatgui_value].context[<player[<[incidents_map].get[<[value]>]>].name>]> <proc[drustcraftp_chatgui_button].context[view|View|punish info <[value]>|RUN_COMMAND]>'

            - ~run drustcraftt_chatgui_render 'def:punish incidents <[rule]>|Incidents for <[rule]>|<context.args.get[3]||1>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The rule id $e<[rule]> $rdoes not exist]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No rule id was entered]>'

      - case addrule:
        - define rule:<context.args.get[2]||<empty>>
        - if <[rule]> != <empty>:
          - if !<server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]||false>:
            - define title:<[rule]>
            - if <context.args.get[3]||<empty>> != <empty>:
              - define title:<context.args.get[3]>

            - flag server drustcraft.punish.rule.<[rule]>:<[title]>
            - waituntil <server.sql_connections.contains[drustcraft]>
            - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>punish_rule`(`rule`,`title`) VALUES("<[rule]>", "<[title]>");'
            - narrate '<proc[drustcraftp_msg_format].context[success|The rule id $e<[rule]> $rwas created with the title $e<[rule]>]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The rule id $e<[rule]> $ralready exists]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No rule id was entered]>'

      - case remrule:
        - define rule:<context.args.get[2]||<empty>>
        - if <[rule]> != <empty>:
          - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]||false>:
            - flag server drustcraft.punish.rule.<[rule]>:!
            - waituntil <server.sql_connections.contains[drustcraft]>
            - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>punish_rule` WHERE `rule` = "<[rule]>";'
            - narrate '<proc[drustcraftp_msg_format].context[success|The rule id $e<[rule]> $rwas removed]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The rule id $e<[rule]> $rdoes not exist]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No rule id was entered]>'

      - case editrule:
        - define rule:<context.args.get[2]||<empty>>
        - if <[rule]> != <empty>:
          - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]||false>:
            - define new_rule:<context.args.get[3]||<empty>>
            - if <[new_rule]> != <empty>:
              - if !<server.flag[drustcraft.punish.rule].keys.contains[<[new_rule]>]||false>:
                - flag server drustcraft.punish.rule.<[new_rule]>:<server.flag[drustcraft.punish.rule.<[rule]>]>
                - flag server drustcraft.punish.rule.<[rule]>:!
                - waituntil <server.sql_connections.contains[drustcraft]>
                - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>punish_rule` SET `rule` = "<[new_rule]>" WHERE `rule` = "<[rule]>";'
                - narrate '<proc[drustcraftp_msg_format].context[success|The rule id $e<[rule]> $rwas renamed to $e<[new_rule]>]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The new rule id $e<[rule]> $ralready exists]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|No new rule id was entered]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The rule id $e<[rule]> $rdoes not exist]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No rule id was entered]>'

      - case actions:
        - define rule:<context.args.get[2]||<empty>>
        - if <[rule]> != <empty>:
          - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]>:
            - if <server.flag[drustcraft.punish.action.<[rule]>].keys.size> > 0:
              - ~run drustcraftt_chatgui_clear
              - foreach <server.flag[drustcraft.punish.action.<[rule]>].keys.numerical> as:sort:
                - define line:<proc[drustcraftp_chatgui_option].context[<[sort]>]>

                - define type:<server.flag[drustcraft.punish.action.<[rule]>.<[sort]>.type]>
                - define duration:<server.flag[drustcraft.punish.action.<[rule]>.<[sort]>.duration]>

                - if <[duration]> == -1:
                  - define duration:perm

                - if <list[kick|warn].contains[<[type]>]>:
                  - define duration:<empty>
                - else:
                  - define 'duration: <[duration]>'

                - define line:<[line]><proc[drustcraftp_chatgui_value].context[<[type]><&7><[duration]>]>
                - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[edit|Edit|punish editaction <[rule]> <[sort]>|Edit details of this action|SUGGEST_COMMAND]>'
                - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[rem|Rem|punish remaction <[rule]> <[sort]>|Remove this action|RUN_COMMAND]>'
                - ~run drustcraftt_chatgui_item def:<[line]>

              - ~run drustcraftt_chatgui_render 'def:rule actions|<server.flag[drustcraft.punish.rule.<[rule]>]> Penalties|<context.args.get[3]||1>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The rule id $e<[rule]> $rdoes not contain any penalties]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The rule id $e<[rule]> $rdoes not exist]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No rule id was entered]>'

      - case addaction:
        - define rule:<context.args.get[2]||<empty>>
        - if <[rule]> != <empty>:
          - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]||false>:
            - define sort:<context.args.get[3]||<empty>>
            - if <[sort]> != <empty> && <[sort].is_integer> && <[sort]> > 0:
              - if !<server.has_flag[drustcraft.punish.action.<[rule]>.<[sort]>]>:
                - define type:<context.args.get[4]||<empty>>
                - if <[type]> != <empty>:
                  - if <proc[drustcraftp_tabcomplete_punish_types].contains[<[type]>]>:
                    - define duration:<empty>
                    - if <list[mute|ban].contains[<[type]>]>:
                      - if <context.args.get[5]||<empty>> != <empty>:
                        - if <duration[<context.args.get[5]>].exists> || <context.args.get[5]> == perm:
                          - define duration:<context.args.get[5]>
                        - else:
                          - narrate '<proc[drustcraftp_msg_format].context[error|The action duration of $e<[type]> $ris not valid]>'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|No action duration was entered]>'
                    - else:
                      - define duration:-1

                    - if <[duration]> != <empty>:
                      - waituntil <server.sql_connections.contains[drustcraft]>
                      - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>punish_action`(`rule`,`sort`,`type`,`duration`) VALUES("<[rule]>", <[sort]>, "<[type]>", "<[duration]>");'
                      - ~sql id:drustcraft 'query:SELECT LAST_INSERT_ID();' save:sql_result
                      - define id:<entry[sql_result].result.get[1].split[/].get[1]>
                      - flag server drustcraft.punish.action.<[rule]>.<[sort]>.id:<[id]>
                      - flag server drustcraft.punish.action.<[rule]>.<[sort]>.type:<[type]>
                      - flag server drustcraft.punish.action.<[rule]>.<[sort]>.duration:<[duration]>
                      - narrate '<proc[drustcraftp_msg_format].context[success|The action has been added to rule id $e<[rule]>]>'
                  - else:
                    - narrate '<proc[drustcraftp_msg_format].context[error|The action type of $e<[type]> $ris not valid]>'
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|No action type was entered]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The action order of $e<[sort]> $ralready exists]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The action order of $e<[sort]> $rmust be a whole number and greator than 0]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The rule id $e<[rule]> $rdoes not exist]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No rule id was entered]>'

      - case remaction:
        - define rule:<context.args.get[2]||<empty>>
        - if <[rule]> != <empty>:
          - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]||false>:
            - define sort:<context.args.get[3]||<empty>>
            - if <[sort]> != <empty> && <[sort].is_integer> && <[sort]> > 0:
              - if <server.has_flag[drustcraft.punish.action.<[rule]>.<[sort]>]>:
                - flag server drustcraft.punish.action.<[rule]>.<[sort]>:!
                - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>punish_action` WHERE `rule` = "<[rule]>" AND `sort` = <[sort]>;'
                - narrate '<proc[drustcraftp_msg_format].context[success|The action has been removed from rule id $e<[rule]>]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The action order of $e<[sort]> $rdoes not exist]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The action order of $e<[sort]> $rmust be a whole number and greator than 0]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The rule id $e<[rule]> $rdoes not exist]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No rule id was entered]>'

      - case editaction:
        - define rule:<context.args.get[2]||<empty>>
        - if <[rule]> != <empty>:
          - if <server.flag[drustcraft.punish.rule].keys.contains[<[rule]>]||false>:
            - define sort:<context.args.get[3]||<empty>>
            - if <[sort]> != <empty> && <[sort].is_integer> && <[sort]> > 0:
              - if <server.has_flag[drustcraft.punish.action.<[rule]>.<[sort]>]>:
                - define new_sort:<context.args.get[4]||<empty>>
                - if <[new_sort]> == <[sort]> || !<server.has_flag[drustcraft.punish.action.<[rule]>.<[new_sort]>]>:
                  - define type:<context.args.get[5]||<empty>>
                  - if <[type]> != <empty>:
                    - if <proc[drustcraftp_tabcomplete_punish_types].contains[<[type]>]>:
                      - define duration:<empty>
                      - if <list[mute|ban].contains[<[type]>]>:
                        - if <context.args.get[6]||<empty>> != <empty>:
                          - if <duration[<context.args.get[6]>].exists> || <context.args.get[6]> == perm:
                            - define duration:<context.args.get[6]>
                          - else:
                            - narrate '<proc[drustcraftp_msg_format].context[error|The action duration of $e<[type]> $ris not valid]>'
                        - else:
                          - narrate '<proc[drustcraftp_msg_format].context[error|No action duration was entered]>'
                      - else:
                        - define duration:-1

                      - if <[duration]> != <empty>:
                        - waituntil <server.sql_connections.contains[drustcraft]>
                        - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>punish_action` SET `sort` = <[new_sort]>, `type` = "<[type]>", `duration` = "<[duration]>" WHERE `rule` = "<[rule]>" AND `sort` = <[sort]>;'
                        - define id:<server.flag[drustcraft.punish.action.<[rule]>.<[sort]>.id]>
                        - flag server drustcraft.punish.action.<[rule]>.<[sort]>:!
                        - flag server drustcraft.punish.action.<[rule]>.<[new_sort]>.id:<[id]>
                        - flag server drustcraft.punish.action.<[rule]>.<[new_sort]>.type:<[type]>
                        - flag server drustcraft.punish.action.<[rule]>.<[new_sort]>.duration:<[duration]>
                        - narrate '<proc[drustcraftp_msg_format].context[success|The action has been modified for rule id $e<[rule]>]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|The action type of $e<[type]> $ris not valid]>'
                  - else:
                    - narrate '<proc[drustcraftp_msg_format].context[error|No action type was entered]>'
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|The new action order of $e<[new_sort]> $ralready exists]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The action order of $e<[sort]> $rdoes not exists]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The action order of $e<[sort]> $rmust be a whole number and greator than 0]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The rule id $e<[rule]> $rdoes not exist]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No rule id was entered]>'

      - case null:
        - narrate '<proc[drustcraftp_msg_format].context[error|No option entered for command. Try <queue.script.data_key[usage].parsed>]>'

      - default:
        - narrate '<proc[drustcraftp_msg_format].context[error|Unknown option. Try <queue.script.data_key[usage].parsed>]>'


drustcraftp_tabcomplete_punish_rules:
  type: procedure
  debug: false
  script:
    - determine <server.flag[drustcraft.punish.rule].keys||<list[]>>


drustcraftp_tabcomplete_punish_types:
  type: procedure
  debug: false
  script:
    - determine <list[mute|warn|kick|ban]>


drustcraftp_tabcomplete_punish_mutedplayers:
  type: procedure
  debug: false
  script:
    - determine <server.players.parse[name]>


drustcraftp_tabcomplete_punish_bannedplayers:
  type: procedure
  debug: false
  script:
    - determine <server.players.parse[name]>


drustcraftp_tabcomplete_punish_noteids:
  type: procedure
  debug: false
  script:
    - define ids:<list[]>
    - foreach <server.flag[drustcraft.punish.player].keys||<list[]>> as:player_uuid:
      - foreach <server.flag[drustcraft.punish.player.<[player_uuid]>].keys||<list[]>> as:id:
        - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.type]> == NOTE:
          - define ids:->:<[id]>

    - determine <[ids]>


drustcraftp_tabcomplete_punish_activeids:
  type: procedure
  debug: false
  script:
    - define ids:<list[]>
    - foreach <server.flag[drustcraft.punish.player].keys||<list[]>> as:player_uuid:
      - foreach <server.flag[drustcraft.punish.player.<[player_uuid]>].keys||<list[]>> as:id:
        - if <server.flag[drustcraft.punish.player.<[player_uuid]>.<[id]>.active]> == 1:
          - define ids:->:<[id]>

    - determine <[ids]>
