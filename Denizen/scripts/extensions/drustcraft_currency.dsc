# Drustcraft - Currency
# Show player coordinates
# https://github.com/drustcraft/drustcraft

drustcraftw_currency:
  type: world
  debug: false
  events:
    on server starts:
      - run drustcraftt_currency.load
          
    on script reload:
      - run drustcraftt_currency.load
      
    # chests
    on player closes inventory server_flagged:drustcraft_currency:
      - define type:chest
      - define location:<context.inventory.location.round||<empty>>
      - define server:<empty>
      
      - if <[location]> == <empty>:
        - define location:<context.inventory.note_name||<empty>>
        - define server:NULL
        
      - if <[location]> != <empty>:
        # chest
        - define netherite_block:<context.inventory.quantity_item[netherite_block]||0>
        - define netherite_ingot:<context.inventory.quantity_item[netherite_ingot]||0>
        - define diamond:<context.inventory.quantity_item[diamond]||0>
        - define emerald:<context.inventory.quantity_item[emerald]||0>
        - define iron_ingot:<context.inventory.quantity_item[iron_ingot]||0>
        
        - define bucks:0
        - define bucks:+:<[netherite_block].mul[117]>
        - define bucks:+:<[netherite_ingot].mul[13]>
        - define bucks:+:<[diamond]>
        - define bucks:+:<[emerald]>
        - define bucks:+:<[iron_ingot].mul[0.25]>
        
        - ~sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_currency` WHERE `server`="<[server]>" AND `type`="<[type]>" AND `location`="<[location]>";'
        
        - if <[bucks]> > 0:
          - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_currency` (`server`,`type`,`location`,`amount`) VALUES ("<[server]>", "<[type]>", "<[location]>", <[bucks]>);'
        
    on player quits server_flagged:drustcraft_currency:
      - define netherite_block:<player.inventory.quantity_item[netherite_block]||0>
      - define netherite_ingot:<player.inventory.quantity_item[netherite_ingot]||0>
      - define diamond:<player.inventory.quantity_item[diamond]||0>
      - define emerald:<player.inventory.quantity_item[emerald]||0>
      - define iron_ingot:<player.inventory.quantity_item[iron_ingot]||0>
      
      - define bucks:0
      - define bucks:+:<[netherite_block].mul[117]>
      - define bucks:+:<[netherite_ingot].mul[13]>
      - define bucks:+:<[diamond]>
      - define bucks:+:<[emerald]>
      - define bucks:+:<[iron_ingot].mul[0.25]>
      
      - define type:player
      - define location:<player.uuid>
      - ~sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_currency` WHERE `type`="<[type]>" AND `location`="<[location]>";'
      - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_currency`(`type`,`location`,`amount`) VALUES ("<[type]>", "<[location]>", <[bucks]>);'


    on block drops item from breaking:
      - ~sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_currency` WHERE `server`="<bungee.server>" AND location`="<context.location>";'
      


drustcraftt_currency:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - flag server drustcraft_currency:!

    - wait 2t
    - waituntil <yaml.list.contains[drustcraft_server]>

    - if <server.scripts.parse[name].contains[drustcraftw_sql]>:
      - waituntil <server.sql_connections.contains[drustcraft_database]>
  
      - define create_tables:true
      - ~sql id:drustcraft_database 'query:SELECT version FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_version WHERE name="drustcraft_currency";' save:sql_result
      - if <entry[sql_result].result.size||0> >= 1:
        - define row:<entry[sql_result].result.get[1].split[/]||0>
        - define create_tables:false
        - if <[row]> >= 2 || <[row]> < 1:
          # Weird version error
          - debug log 'Drustcraft Currency is not enabled as database structure is for a later version'
  
      - if <[create_tables]>:
        - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` (`name`,`version`) VALUES ("drustcraft_currency",'1');'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_currency` (`id` INT NOT NULL AUTO_INCREMENT, `server` VARCHAR(255), `type` VARCHAR(255) NOT NULL, `location` VARCHAR(255) NOT NULL, `amount` DOUBLE NOT NULL, PRIMARY KEY (`id`));'
        
      - flag server drustcraft_currency:true
    - else:
      - debug log 'Drustcraft Currency requires the Drustcraft SQL script installed'
