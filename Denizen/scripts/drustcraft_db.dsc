# Drustcraft - Database
# https://github.com/drustcraft/drustcraft

drustcraftw_db:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_db_load

    on script reload:
      - run drustcraftt_db_load

    on system time minutely server_flagged:drustcraft.module.db:
      - if !<server.sql_connections.contains[drustcraft]>:
        - run drustcraftt_db_load


drustcraftt_db_load:
  type: task
  debug: false
  script:
    - if <server.sql_connections.contains[drustcraft]>:
      - ~sql id:drustcraft disconnect

    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - debug ERROR "Drustcraft DB: Drustcraft Setting module is required to be installed"
      - stop

    - waituntil <server.has_flag[drustcraft.module.setting]>

    - ~run drustcraftt_setting_get def:database.server|null|yaml save:result
    - define sql_server:<entry[result].created_queue.determination.get[1]>
    - ~run drustcraftt_setting_get def:database.database|null|yaml save:result
    - define sql_database:<entry[result].created_queue.determination.get[1]>
    - ~run drustcraftt_setting_get def:database.username|null|yaml save:result
    - define sql_username:<entry[result].created_queue.determination.get[1]>
    - ~run drustcraftt_setting_get def:database.password|null|yaml save:result
    - define sql_password:<entry[result].created_queue.determination.get[1]>
    - ~run drustcraftt_setting_get def:database.table_prefix|null|yaml save:result
    - define sql_table_prefix:<entry[result].created_queue.determination.get[1]>

    - flag server drustcraft.db.prefix:<[sql_table_prefix]>

    - if <[sql_server]> != null && <[sql_database]> != null && <[sql_username]> != null && <[sql_password]> != null:
      - ~sql id:drustcraft connect:<[sql_server]>/<[sql_database]> username:<[sql_username]> password:<[sql_password]>

      - define create_tables:true
      - ~sql id:drustcraft 'query:SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = "<[sql_database]>" AND TABLE_NAME = "<server.flag[drustcraft.db.prefix]>version";' save:sql_result
      - if <entry[sql_result].result.size||0> == 1:
        # update previous versioning name
        - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>version` SET `name`="drustcraft.db" WHERE `name`="drustcraft_schema";'

        - ~sql id:drustcraft 'query:SELECT `version` FROM `<server.flag[drustcraft.db.prefix]>version` WHERE `name`="drustcraft.db";' save:sql_result
        - if <entry[sql_result].result.size||0> >= 1:
          - define row:<entry[sql_result].result.get[1].split[/].get[1].unescaped||0>
          - define create_tables:false
          - if <[row]> >= 2:
            # Database version is newer than this script supports
            - ~sql id:drustcraft disconnect
            - debug ERROR "Drustcraft DB: Database version is higher than supported by this module"
            - stop
          - else if <[row]> < 1:
            # Database version is unexpected, escape!
            - ~sql id:drustcraft disconnect
            - debug ERROR "Drustcraft DB: Unexpected database version"
            - stop

      - if <[create_tables]>:
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>version` (`name` VARCHAR(255) NOT NULL, `version` DOUBLE NOT NULL, UNIQUE (`name`));'
        - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>version`(`name`,`version`) VALUES("drustcraft.db", 1);'

      - flag server drustcraft.module.db:<script[drustcraftw_db].data_key[version]>
    - else:
      - ~run drustcraftt_setting_exists def:database.server|yaml save:result
      - if !<entry[result].created_queue.determination.get[1]>:
        - run drustcraftt_setting_set def:database.server||yaml
      - ~run drustcraftt_setting_exists def:database.database|yaml save:result
      - if !<entry[result].created_queue.determination.get[1]>:
        - run drustcraftt_setting_set def:database.database||yaml
      - ~run drustcraftt_setting_exists def:database.username|yaml save:result
      - if !<entry[result].created_queue.determination.get[1]>:
        - run drustcraftt_setting_set def:database.username||yaml
      - ~run drustcraftt_setting_exists def:database.password|yaml save:result
      - if !<entry[result].created_queue.determination.get[1]>:
        - run drustcraftt_setting_set def:database.password||yaml
      - ~run drustcraftt_setting_exists def:database.table_prefix|yaml save:result
      - if !<entry[result].created_queue.determination.get[1]>:
        - run drustcraftt_setting_set def:database.table_prefix||yaml

      - debug LOG "No database settings defined in Drustcraft settings"

drustcraftt_db_get_version:
  type: task
  debug: false
  definitions: name
  script:
    - waituntil <server.sql_connections.contains[drustcraft]>
    - ~sql id:drustcraft 'query:SELECT `version` FROM `<server.flag[drustcraft.db.prefix]>version` WHERE `name`="<[name]>";' save:sql_result
    - if <entry[sql_result].result.size||0> >= 1:
      - determine <entry[sql_result].result.get[1].split[/].get[1].unescaped||null>
    - determine null

drustcraftt_db_set_version:
  type: task
  debug: false
  definitions: name|version
  script:
    - waituntil <server.sql_connections.contains[drustcraft]>
    - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>version`(`name`,`version`) VALUES("<[name]>",<[version]>) ON DUPLICATE KEY UPDATE `name`="<[name]>", `version`=<[version]>;'

drustcraftt_db_clear_version:
  type: task
  debug: false
  definitions: name
  script:
    - waituntil <server.sql_connections.contains[drustcraft]>
    - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>version` WHERE `name`="<[name]>";'
