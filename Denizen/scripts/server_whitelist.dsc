# Drustcraft - Whitelist
# https://github.com/drustcraft/drustcraft

drustcraftw_whitelist:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_whitelist_load

    on script reload:
      - run drustcraftt_whitelist_load

    on player logs in priority:-50:
      - if <server.has_flag[drustcraft.module.whitelist]>:
        - if !<server.flag[drustcraft.whitelist.players].contains[<player.uuid>]||false>:
          - define linking_code:<server.flag[drustcraft.whitelist.linking_codes.<player.uuid>]||<empty>>
          - if <[linking_code]> == <empty>:
            - waituntil <server.has_flag[drustcraft.whitelist.next_linking_code]>
            - define linking_code:<server.flag[drustcraft.whitelist.next_linking_code]>
            - run drustcraftt_whitelist_update_player_linking_code def:<player>

          - determine 'KICKED:<&nl><&nl><&e>You are not whitelisted to play on this server.<&nl><&nl>Register at <&f>drustcraft.com.au <&e>and use linking code <&f><&l><[linking_code]>'
        - else:
          - waituntil <server.sql_connections.contains[drustcraft]>
          - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>whitelist` SET `playername` = "<player.name>" WHERE `uuid` = "<player.uuid>";'
      - else:
        - determine 'KICKED:<&e>This server is currently not available as it is loading<&nl>Please try again in a few minutes'


drustcraftt_whitelist_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR "Drustcraft Whitelist: Drustcraft Database module is required to be installed"
      - stop

    - waituntil <server.has_flag[drustcraft.module.db]>

    - define create_tables:true
    - ~run drustcraftt_db_get_version def:drustcraft.whitelist save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> == null:
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>whitelist` (`uuid` VARCHAR(36), `playername` VARCHAR(255), `added_date` INT NOT NULL, PRIMARY KEY(`uuid`));'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>whitelist_linking_code` (`uuid` VARCHAR(36), `playername` TINYTEXT NOT NULL, `linking_code` VARCHAR(6), UNIQUE(`uuid`));'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>whitelist_reset_code` (`uuid` VARCHAR(36),  `playername` TINYTEXT NOT NULL, `reset_code` VARCHAR(6), `timeout` INT NOT NULL, UNIQUE(`uuid`));'
      - run drustcraftt_db_set_version def:drustcraft.whitelist|3
      - define version:3

    - if <[version]> == 1:
      - debug ERROR 'Drustcraft whitelist, cannot upgrade database from version 1'
      - stop

    - if <[version]> == 2:
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>whitelist_linking_code` (`uuid` VARCHAR(36), `playername` TINYTEXT NOT NULL, `linking_code` VARCHAR(6), UNIQUE(`uuid`));'
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>whitelist_reset_code` (`uuid` VARCHAR(36), `reset_code` VARCHAR(6), `timeout` INT NOT NULL, UNIQUE(`uuid`));'

      # remove duplicate uuids
      - ~sql id:drustcraft 'query:SELECT `uuid`, `playername`, `added_date`, `linking_code`, `reset_code`, `reset_code_timeout` FROM `<server.flag[drustcraft.db.prefix]>whitelist` ORDER BY `added_date` ASC;' save:sql_result
      - foreach <entry[sql_result].result>:
        - define row:<[value].split[/]||<list[]>>
        - define uuid:<[row].get[1]||<empty>>
        - define playername:<[row].get[2]||<empty>>
        - define added_date:<[row].get[3]||<empty>>
        - define linking_code:<[row].get[4]||<empty>>
        - define reset_code:<[row].get[5]||<empty>>
        - define reset_code_timeout:<[row].get[6]||<empty>>

        - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>whitelist` WHERE `uuid` = "<[uuid]>" AND `added_date` != <[added_date]>;'
        - if <[linking_code]> != <empty>:
          - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>whitelist_linking_code` (`uuid`, `playername`, `linking_code`) VALUES("<[uuid]>", "<[playername]>", "<[linking_code]>");'
        - if <[reset_code]> != <empty> && <[reset_code_timeout]> > <server.current_time_millis.div[1000].round_down>:
          - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>whitelist_reset_code` (`uuid`, `reset_code`, `timeout`) VALUES("<[uuid]>", "<[reset_code]>", <[reset_code_timeout]>);'

      - ~sql id:drustcraft 'update:ALTER TABLE `<server.flag[drustcraft.db.prefix]>whitelist` ADD CONSTRAINT UNIQUE (`uuid`);'
      - ~sql id:drustcraft 'update:ALTER TABLE `<server.flag[drustcraft.db.prefix]>whitelist` DROP COLUMN `linking_code`, `reset_code`, `reset_code_timeout`;'

      - run drustcraftt_db_set_version def:drustcraft.whitelist|3
      - define version:3

    - if <[version]> != 3:
      - debug ERROR "Drustcraft Whitelist: Unexpected database version"
      - stop

    - run drustcraftt_whitelist_reload
    - flag server drustcraft.module.whitelist:<script[drustcraftw_whitelist].data_key[version]>

    - if <server.scripts.parse[name].contains[drustcraftw_webconnector]>:
      - waituntil <server.has_flag[drustcraft.module.webconnector]>
      - run drustcraftt_webconnector_command def:whitelist_reload|drustcraftt_whitelist_reload


drustcraftt_whitelist_reload:
  type: task
  debug: false
  script:
    - waituntil <server.sql_connections.contains[drustcraft]>
    - flag server drustcraft.whitelist:!

    - ~sql id:drustcraft 'query:SELECT `uuid`, `linking_code` FROM `<server.flag[drustcraft.db.prefix]>whitelist_linking_code`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define uuid:<[row].get[1]||<empty>>
      - define linking_code:<[row].get[2]||<empty>>
      - flag server drustcraft.whitelist.linking_codes.<[uuid]>:<[linking_code]>

    - define code:<proc[drustcraftp_whitelist_generate_code]>
    - if <server.has_flag[drustcraft.whitelist.linking_codes]>:
      - while <server.flag[drustcraft.whitelist.linking_codes].values.contains[<[code]>]>:
        - define code:<proc[drustcraftp_whitelist_generate_code]>

    - flag server drustcraft.whitelist.next_linking_code:<[code]>

    - ~sql id:drustcraft 'query:SELECT `uuid` FROM `<server.flag[drustcraft.db.prefix]>whitelist`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define uuid:<[row].get[1]||<empty>>
      - flag server drustcraft.whitelist.players:->:<[uuid]>


drustcraftt_whitelist_update_player_linking_code:
  type: task
  debug: false
  definitions: player
  script:
    - waituntil <server.sql_connections.contains[drustcraft]>
    - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>whitelist_linking_code`(`uuid`,`playername`,`linking_code`) VALUES("<[player].uuid>", "<[player].name>", "<server.flag[drustcraft.whitelist.next_linking_code]>");'
    - run drustcraftt_whitelist_reload


drustcraftp_whitelist_generate_code:
  type: procedure
  debug: false
  script:
    - define characters:<list[3|4|6|7|8|9|A|B|C|D|E|F|G|H|J|K|M|N|P|Q|R|T|W|X|Y]>
    - determine <[characters].random><[characters].random><[characters].random><[characters].random><[characters].random><[characters].random>


drustcraftc_whitelist_resetpassword:
  type: command
  debug: false
  name: resetpassword
  description: Resets your Drustcraft website password
  usage: /resetpassword
  aliases:
  - resetpw
  - resetpwd
  - resetpass
  script:
    - if !<server.has_flag[drustcraft.module.whitelist]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Whitelist not yet loaded. Check console for errors]>'
      - stop

    - if !<context.console||false>:
        - waituntil <server.sql_connections.contains[drustcraft]>

        - define reset_code:<util.random.int[100000].to[999999]>
        - define timeout:<util.time_now.epoch_millis.div[1000].round_down.add[259200]>

        - narrate 'VALUES("<player.uuid>", "<player.name>", "<[reset_code]>", <[timeout]>)'
        - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>whitelist_reset_code` WHERE `uuid` = "<player.uuid>";'
        - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>whitelist_reset_code` (`uuid`, `playername`, `reset_code`, `timeout`) VALUES("<player.uuid>", "<player.name>", "<[reset_code]>", <[timeout]>);'

        - narrate '<proc[drustcraftp_msg_format].context[success|Your website password reset code is $e<[reset_code]>]>'
        - narrate '<proc[drustcraftp_msg_format].context[arrow|DO NOT share this code with anyone else they will have access to your account. This code is valid for 72 hours]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|This command is only available for players]>'
