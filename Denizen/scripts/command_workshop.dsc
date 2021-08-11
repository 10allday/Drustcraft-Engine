# Drustcraft - Workshop
# https://github.com/drustcraft/drustcraft

# TODO: Leave chat channel when leave workshop
# TODO: Error joining workshop when in a workshop
# TODO: Annouce when players join workshop
# TODO: Dont allow players to join a workshop when in a workshop

drustcraftw_workshop:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_workshop_load

    on script reload:
      - run drustcraftt_workshop_load

    after player joins server_flagged:drustcraft.module.workshop:
      - wait 40t
      - ~run drustcraftt_setting_get def:drustcraft.workshop.<player.uuid>.return save:result
      - define location:<entry[result].created_queue.determination.get[1]>
      - if <[location]> != null:
        - teleport <player> <[location]>
        - ~run drustcraftt_setting_clear def:drustcraft.workshop.<player.uuid>.return

    on player quits server_flagged:drustcraft.module.workshop:
      - if <player.has_flag[drustcraft.workshop]>:
        - narrate '<proc[drustcraftp_msg_format].context[success|$e<player.name> $rhas left the workshop]>' targets:<server.online_players.exclude[<player>].filter_tag[<[filter_value].flag[drustcraft.workshop.name].equals[<player.flag[drustcraft.workshop.name]>]||false>].parse[name]>


drustcraftt_workshop_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - debug ERROR 'Drustcraft Workshop: Drustcraft Setting is required to be installed'
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR 'Drustcraft Workshop: Drustcraft Database is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.db]>
    - waituntil <server.sql_connections.contains[drustcraft]>
    - ~run drustcraftt_db_get_version def:drustcraft.workshop save:result
    - define version:<entry[result].created_queue.determination.get[1]>

    - if <[version]> == null:
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>workshop` (`id` INT NOT NULL, `name` VARCHAR(255) NOT NULL, `starts` INT NOT NULL, `ends` INT NOT NULL, `location` TINYTEXT, PRIMARY KEY AUTO_INCREMENT (`id`), UNIQUE (`name`));'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>workshop_user` (`id` INT NOT NULL, `workshop_id` INT NOT NULL, `uuid` VARCHAR(36) NOT NULL, `owner` INT NOT NULL DEFAULT 0, PRIMARY KEY AUTO_INCREMENT (`id`));'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>workshop_group` (`id` INT NOT NULL, `workshop_id` INT NOT NULL, `group` VARCHAR(255) NOT NULL, `owner` INT NOT NULL DEFAULT 0, PRIMARY KEY AUTO_INCREMENT (`id`));'
      - run drustcraftt_db_set_version def:drustcraft.workshop|1

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>
      # TODO: add all of tab completes
      - run drustcraftt_tabcomplete_completion def:workshop|leave
      - run drustcraftt_tabcomplete_completion 'def:workshop|?drustcraft.workshop.create create'
      - run drustcraftt_tabcomplete_completion def:workshop|_*workshops

    - waituntil <server.has_flag[drustcraft.module.setting]>
    - flag server drustcraft.module.workshop:<script[drustcraftw_workshop].data_key[version]>

    - waituntil <server.sql_connections.contains[drustcraft]>
    - ~sql id:drustcraft 'query:SELECT `id`, `name`, `starts`, `ends`, `location` FROM `<server.flag[drustcraft.db.prefix]>workshop` WHERE 1;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define id:<[row].get[1]>
      - define name:<[row].get[2].unescaped>
      - flag server drustcraft.workshop.list.<[name]>.id:<[id]>
      - flag server drustcraft.workshop.list.<[name]>.starts:<[row].get[3]>
      - flag server drustcraft.workshop.list.<[name]>.ends:<[row].get[4]>
      - flag server drustcraft.workshop.list.<[name]>.location:<[row].get[5].unescaped>
      - flag server drustcraft.workshop.list.<[name]>.members.players:<list[]>
      - flag server drustcraft.workshop.list.<[name]>.members.groups:<list[]>
      - flag server drustcraft.workshop.list.<[name]>.owners.players:<list[]>
      - flag server drustcraft.workshop.list.<[name]>.owners.groups:<list[]>

      - ~sql id:drustcraft 'query:SELECT `uuid`, `owner` FROM `<server.flag[drustcraft.db.prefix]>workshop_user` WHERE `workshop_id` = "<[id]>"' save:sql_user_result
      - foreach <entry[sql_user_result].result>:
        - define row:<[value].split[/]>
        - define uuid:<[row].get[1]||<empty>>
        - define owner:<[row].get[2]||<empty>>
        - if <[owner]>:
          - flag server drustcraft.workshop.list.<[name]>.members.players:->:<player[<[uuid]>]>
        - else:
          - flag server drustcraft.workshop.list.<[name]>.owners.players:->:<player[<[uuid]>]>

      - ~sql id:drustcraft 'query:SELECT `group`, `owner` FROM `<server.flag[drustcraft.db.prefix]>workshop_group` WHERE `workshop_id` = "<[id]>"' save:sql_user_result
      - foreach <entry[sql_user_result].result>:
        - define row:<[value].split[/]>
        - define group:<[row].get[1]||<empty>>
        - define owner:<[row].get[2]||<empty>>
        - if <[owner]>:
          - flag server drustcraft.workshop.list.<[name]>.members.groups:->:<[group]>
        - else:
          - flag server drustcraft.workshop.list.<[name]>.owners.groups:->:<[group]>

    - if <server.scripts.parse[name].contains[drustcraftw_chat]>:
      - waituntil <server.has_flag[drustcraft.module.chat]>
      - run drustcraftt_chat_register def:workshop|<&3>Workshop|drustcraftp_workshop_channel


drustcraftc_workshop:
  type: command
  debug: false
  name: workshop
  description: Enters or exits a workshop
  usage: /workshop
  permission: drustcraft.workshop
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:workshop
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.workshop]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Workshop tools not loaded. Check console for errors]>'
      - stop

    - if <player||<empty>> != <empty>:
      - choose <context.args.get[1]||null>:
        # create
        - case create:
          - define name:<context.args.get[2]||<empty>>
          - if <[name]> != <empty>:
            - if !<list[create|edit|remove|leave].include[<server.flag[drustcraft.workshop.list]||<list[]>>].contains[<[name]>]>:
              - waituntil <server.sql_connections.contains[drustcraft]>

              - define location:NULL
              - define workshop_id:0

              - if !<context.server||false>:
                - define location:"<player.location.round>"

              - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>workshop`(`name`, `starts`, `ends`, `location`) VALUES("<[name]>", 0, 0, <[location]>);'
              - ~sql id:drustcraft 'query:SELECT LAST_INSERT_ID();' save:sql_result
              - define workshop_id:<entry[sql_result].result.get[1].split[/].get[1]>

              - flag server drustcraft.workshop.list.<[name]>.id:<[workshop_id]>
              - flag server drustcraft.workshop.list.<[name]>.starts:0
              - flag server drustcraft.workshop.list.<[name]>.ends:0
              - flag server drustcraft.workshop.list.<[name]>.location:<tern[<[location].equals[NULL]>].pass[NULL].fail[<[location].replace["]>]>
              - flag server drustcraft.workshop.list.<[name]>.members.players:<list[]>
              - flag server drustcraft.workshop.list.<[name]>.members.groups:<list[]>
              - flag server drustcraft.workshop.list.<[name]>.owners.players:<list[]>
              - flag server drustcraft.workshop.list.<[name]>.owners.groups:<list[]>

              - if !<context.server||false>:
                - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>workshop_user`(`workshop_id`, `uuid`, `owner`) VALUES(<[workshop_id]>, "<player.uuid>", 1);'
                - flag server drustcraft.workshop.list.<[name]>.owners.players:->:<player>

              - narrate '<proc[drustcraftp_msg_format].context[success|The workshop $e<[name]> $rhas been created]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The workshop name $e<[name]> $ris already used or reserved]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|No workshop name was entered]>'

        # edit
        - case edit:
          - define name:<context.args.get[2]||<empty>>
          - define command:<context.args.get[3]||<empty>>
          - define data:<context.args.get[4]||<empty>>

          - narrate '<proc[drustcraftp_msg_format].context[error|NOT IMPLEMENTED]>'

        # remove
        - case remove:
          - define name:<context.args.get[2]||<empty>>
          - if <[name]> != <empty>:
            - if <server.has_flag[drustcraft.workshop.list.<[name]>]>:
              - if <server.flag[drustcraft.workshop.list.<[name]>.owners.players].contains[<player>]> || <player.groups.contains_any[<server.flag[drustcraft.workshop.list.<[name]>.owners.groups]>]>:
                - define id:<server.flag[drustcraft.workshop.list.<[name]>.id]>
                - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>workshop_user` WHERE `workshop_id` = <[id]>;'
                - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>workshop_group` WHERE `workshop_id` = <[id]>;'
                - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>workshop` WHERE `id` = <[id]>;'
                - flag server drustcraft.workshop.list:<-:<[name]>
                - narrate '<proc[drustcraftp_msg_format].context[success|The workshop $e<[name]> has been removed]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to remove the workshop $e<[name]>]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The workshop $e<[name]> $rwas not found]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|No workshop name was entered]>'

        # leave
        - case leave:
          - if <player.has_flag[drustcraft.workshop]>:
            - ~run drustcraftt_setting_get def:drustcraft.workshop.<player.uuid>.return save:result
            - define location:<entry[result].created_queue.determination.get[1]>
            - if <[location]> != null:
              - teleport <player> <[location]>
              - ~run drustcraftt_setting_clear def:drustcraft.workshop.<player.uuid>.return

            - if <server.has_flag[drustcraft.module.chat]>:
              - run drustcraftt_chat_join def:<player>|all|all
              - if <proc[drustcraftp_chat_default].context[<player>]> == workshop:
                - run drustcraftt_chat_default def:<player>|all|all
              - run drustcraftt_chat_leave def:<player>|workshop|false

            - narrate '<proc[drustcraftp_msg_format].context[warning|You have left the workshop]>'
            - narrate '<proc[drustcraftp_msg_format].context[warning|$e<player.name> $rhas left the workshop]>' targets:<server.online_players.exclude[<player>].filter_tag[<[filter_value].flag[drustcraft.workshop.name].equals[<player.flag[drustcraft.workshop.name]>]||false>].parse[name]>
            - flag <player> drustcraft.workshop:!
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|You are not in a workshop]>'

        # none
        - case null:
          - if <player.has_flag[drustcraft.workshop]>:
            - narrate '<proc[drustcraftp_msg_format].context[arrow|You have been in the $e<player.flag[drustcraft.workshop.name]> $rworkshop for $e<util.time_now.duration_since[<player.flag[drustcraft.workshop.entered]>].formatted>$r.]>'
            - define player_list:<server.online_players.exclude[<player>].filter_tag[<[filter_value].flag[drustcraft.workshop.name].equals[<player.flag[drustcraft.workshop.name]>]||false>].parse[name]>
            - narrate '<proc[drustcraftp_msg_format].context[arrow|There are $e<[player_list].size> $rother player<tern[<[player_list].size.equals[1]>].pass[].fail[s]> in the workshop<tern[<[player_list].size.equals[0]>].pass[.].fail[: $e<[player_list].separated_by[$r, $e]>]>]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|No workshop was entered]>'

        # default
        - default:
          - define name:<context.args.get[1]||<empty>>
          - if <[name]> != <empty>:
            - if <server.has_flag[drustcraft.workshop.list.<[name]>]>:
              - if <server.flag[drustcraft.workshop.list.<[name]>.owners.players].contains[<player>]> || <player.groups.contains_any[<server.flag[drustcraft.workshop.list.<[name]>.owners.groups]>]> || <server.flag[drustcraft.workshop.list.<[name]>.members.players].contains[<player>]> || <player.groups.contains_any[<server.flag[drustcraft.workshop.list.<[name]>.members.groups]>]>:
                - define location:<server.flag[drustcraft.workshop.list.<[name]>.location]>
                - if <[location]> != null:
                  - ~run drustcraftt_setting_set def:drustcraft.workshop.<player.uuid>.return|<player.location>
                  - teleport <player> <[location]>

                  - if <server.has_flag[drustcraft.module.chat]>:
                    - run drustcraftt_chat_join def:<player>|workshop|workshop-<[name]>|false
                    - run drustcraftt_chat_default def:<player>|workshop|false
                    - run drustcraftt_chat_leave def:<player>|all|false

                  - flag <player> drustcraft.workshop.name:<[name]>
                  - flag <player> drustcraft.workshop.entered:<util.time_now>
                  - narrate '<proc[drustcraftp_msg_format].context[success|You have joined the workshop]>'
                  - narrate '<proc[drustcraftp_msg_format].context[success|$e<player.name> $rhas joined the workshop]>' targets:<server.online_players.exclude[<player>].filter_tag[<[filter_value].flag[drustcraft.workshop.name].equals[<player.flag[drustcraft.workshop.name]>]||false>].parse[name]>
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|This workshop has no location defined yet]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to join this workshop]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The workshop $e<[name]> $rwas not found]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|No workshop name was entered]>'

    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|This command can only be run by a player]>'


drustcraftp_workshop_channel:
  type: procedure
  debug: false
  definitions: player|name
  script:
    - determine workshop-abc


drustcraftp_tabcomplete_workshops:
  type: procedure
  debug: false
  script:
    - determine <server.flag[drustcraft.workshop.list].keys||<list[]>>