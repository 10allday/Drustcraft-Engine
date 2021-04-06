# Drustcraft - SQL Database
# Modifies system messages to the player for consistency
# https://github.com/drustcraft/drustcraft

drustcraftw_sql:
  type: world
  debug: false
  events:
    on server starts:
      - run drustcraftt_sql.load

    on script reload:
      - run drustcraftt_sql.load
      
    on system time minutely:
      - if <server.sql_connections.contains[drustcraft_database]> == false:
        - run drustcraftt_sql.load

    on player logs in:
      - waituntil <server.sql_connections.contains[drustcraft_database]>
      - sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_players` (`uuid`,`name`) VALUES("<player.uuid>","<player.name>") ON DUPLICATE KEY UPDATE `name`="<player.name>";'


drustcraftt_sql:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <server.sql_connections.contains[drustcraft_database]>:
      - ~sql id:drustcraft_database disconnect

    - wait 2t
    - waituntil <yaml.list.contains[drustcraft_server]>

    - define sql_server:<yaml[drustcraft_server].read[server.sql.server]||<empty>>
    - define sql_database:<yaml[drustcraft_server].read[server.sql.database]||<empty>>
    - define sql_username:<yaml[drustcraft_server].read[server.sql.username]||<empty>>
    - define sql_password:<yaml[drustcraft_server].read[server.sql.password]||<empty>>
    - define sql_table_prefix:<yaml[drustcraft_server].read[server.sql.table_prefix]||<empty>>
    
    - flag server drustcraft_database_table_prefix:<[sql_table_prefix]>

    - if <[sql_server]> != <empty> && <[sql_database]> != <empty> && <[sql_username]> != <empty> && <[sql_password]> != <empty>:
        
      - ~sql id:drustcraft_database connect:<[sql_server]>/<[sql_database]> username:<[sql_username]> password:<[sql_password]>

      - define create_tables:true
      - ~sql id:drustcraft_database 'query:SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = "<[sql_database]>" AND TABLE_NAME = "<[sql_table_prefix]>drustcraft_version";' save:sql_result
      - if <entry[sql_result].result.size||0> == 1:
        - ~sql id:drustcraft_database 'query:SELECT `version` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` WHERE `name`="drustcraft_schema";' save:sql_result
        - if <entry[sql_result].result.size||0> >= 1:
          - define row:<entry[sql_result].result.get[1].split[/]||0>
          - define create_tables:false
          - if <[row]> >= 2:
            # Database version is newer than this script supports
            - ~sql id:drustcraft_database disconnect
          - else if <[row]> < 1:
            # Database version is unexpected, escape!
            - ~sql id:drustcraft_database disconnect
        
      - if <[create_tables]>:                    
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` (`name` VARCHAR(255) NOT NULL,`version` DOUBLE NOT NULL);'
        - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` (`name`,`version`) VALUES ("drustcraft_schema",'1');'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_flags` (`name` VARCHAR(255) NOT NULL,`value` VARCHAR(255) NOT NULL);'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_players` (`uuid` VARCHAR(255) NOT NULL,`name` VARCHAR(255) NOT NULL, UNIQUE (`uuid`));'
  