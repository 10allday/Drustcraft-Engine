# Drustcraft - Setting
# https://github.com/drustcraft/drustcraft

drustcraftw_setting:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_setting_load

    on script reload:
      - run drustcraftt_setting_load

    on system time minutely every:10 server_flagged:drustcraft.module.setting:
      - if <yaml[drustcraft_setting].has_changes>:
        - yaml savefile:/drustcraft.yml id:drustcraft_setting


drustcraftt_setting_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if <yaml.list.contains[drustcraft_setting]>:
      - ~yaml unload id:drustcraft_setting

    - if <server.has_file[/drustcraft.yml]>:
      - yaml load:/drustcraft.yml id:drustcraft_setting
    - else:
      - yaml create id:drustcraft_setting
      - yaml savefile:/drustcraft.yml id:drustcraft_setting

    - flag server drustcraft.setting.use_db:<server.scripts.parse[name].contains[drustcraftw_db]>
    - flag server drustcraft.module.setting:<script[drustcraftw_db].data_key[version]>

    - if <server.flag[drustcraft.setting.use_db]>:
      - waituntil <server.has_flag[drustcraft.module.db]>

      - define create_tables:true
      - ~run drustcraftt_db_get_version def:drustcraft.setting save:result
      - define version:<entry[result].created_queue.determination.get[1]>
      - if <[version]> != 1:
        - if <[version]> != null:
          - debug ERROR "Drustcraft DB: Unexpected database version. Ignoring DB storage"
        - else:
          - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>setting` (`name` VARCHAR(255) NOT NULL, `value` TEXT NOT NULL, UNIQUE (`name`));'
          - run drustcraftt_db_set_version def:drustcraft.setting|1

    - flag server drustcraft.module.setting:<script[drustcraftw_setting].data_key[version]>


drustcraftt_setting_exists:
  type: task
  debug: false
  definitions: name|storage
  script:
    - if <[storage]||DB> == DB && <server.flag[drustcraft.setting.use_db]>:
      - waituntil <server.sql_connections.contains[drustcraft]>
      - ~sql id:drustcraft 'query:SELECT `value` FROM `<server.flag[drustcraft.db.prefix]>setting` WHERE `name`="<[name]>";' save:sql_result
      - if <entry[sql_result].result.size||0> >= 1:
        - determine true
    - else:
      - determine <yaml[drustcraft_setting].contains[name]>

    - determine false

drustcraftt_setting_get:
  type: task
  debug: false
  definitions: name|default|storage
  script:
    - define default:<[default]||null>
    - if <[storage]||DB> == DB && <server.flag[drustcraft.setting.use_db]>:
      - waituntil <server.sql_connections.contains[drustcraft]>
      - ~sql id:drustcraft 'query:SELECT `value` FROM `<server.flag[drustcraft.db.prefix]>setting` WHERE `name`="<[name]>";' save:sql_result
      - if <entry[sql_result].result.size||0> >= 1:
        - determine <entry[sql_result].result.get[1].split[/].get[1].unescaped||<[default]>>
    - else:
      - determine <yaml[drustcraft_setting].read[<[name]>]||<[default]>>

    - determine <[default]>

drustcraftt_setting_set:
  type: task
  debug: false
  definitions: name|value|storage
  script:
    - if <[storage]||DB> == DB && <server.flag[drustcraft.setting.use_db]>:
      - waituntil <server.sql_connections.contains[drustcraft]>
      - if !<[value].is_decimal>:
        - define value:<&dq><[value].sql_escaped><&dq>
      - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>setting`(`name`,`value`) VALUES("<[name]>",<[value]>) ON DUPLICATE KEY UPDATE `name`="<[name]>", `value`=<[value]>;'
    - else:
      - yaml id:drustcraft_setting set <[name]>:<[value]>

drustcraftt_setting_clear:
  type: task
  debug: false
  definitions: name|storage
  script:
    - if <[storage]||DB> == DB && <server.flag[drustcraft.setting.use_db]>:
      - waituntil <server.sql_connections.contains[drustcraft]>
      - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>setting` WHERE `name`="<[name]>";'
    - else:
      - yaml id:drustcraft_setting set <[name]>:!
