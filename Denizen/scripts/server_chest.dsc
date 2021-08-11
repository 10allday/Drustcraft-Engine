# Drustcraft - Chest
# https://github.com/drustcraft/drustcraft

drustcraftw_chest:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_chest_load

    on script reload:
      - run drustcraftt_chest_load

    on player opens inventory:
      - if <context.inventory.location||<empty>> != <empty>:
        - if !<server.flag[drustcraft.chest.stocked].contains[<context.inventory.location>]||false> && !<server.flag[drustcraft.chest.ignore].contains[<context.inventory.location>]||false>:
          - flag server drustcraft.chest.stocked:->:<context.inventory.location>
          - if <server.has_flag[drustcraft.chest.items.any]>:
            - foreach <server.flag[drustcraft.chest.items.any].keys> as:item:
              - if <util.random.decimal[0].to[1]> <= <server.flag[drustcraft.chest.items.any.<[item]>.chance]||1>:
                - give <item[<[item]>]> quantity:<util.random.int[<server.flag[drustcraft.chest.items.any.<[item]>.min_qty]||1>].to[<server.flag[drustcraft.chest.items.any.<[item]>.max_qty]||1>]> to:<context.inventory>
          - if <server.has_flag[drustcraft.chest.items.<context.inventory.location.biome.name>]>:
            - foreach <server.flag[drustcraft.chest.items.<context.inventory.location.biome.name>].keys> as:item:
              - if <util.random.decimal[0].to[1]> <= <server.flag[drustcraft.chest.items.<context.inventory.location.biome.name>.<[item]>.chance]||1>:
                - give <item[<[item]>]> quantity:<util.random.int[<server.flag[drustcraft.chest.items.<context.inventory.location.biome.name>.<[item]>.min_qty]||1>].to[<server.flag[drustcraft.chest.items.<context.inventory.location.biome.name>.<[item]>.max_qty]||1>]> to:<context.inventory>

          - waituntil <server.sql_connections.contains[drustcraft]>
          - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chest_stocked`(`server`,`location`,`day`) VALUES(NULL, "<context.inventory.location>", <server.flag[drustcraft.util.day]>);'

    on player places block:
      - if <player.gamemode> == SURVIVAL:
        - if <server.flag[drustcraft.chests.containers].contains[<context.material.name>]>:
          - flag server drustcraft.chest_restock.ignore:->:<context.location>
          - waituntil <server.sql_connections.contains[drustcraft]>
          - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>chest_ignore`(`server`,`location`) VALUES(NULL,"<context.location>"); INSERT INTO `<server.flag[drustcraft.db.prefix]>chest_ignore`(`server`,`location`) VALUES(NULL,"<context.location>");'

    on player breaks block:
      - if <player.gamemode> == SURVIVAL:
        - flag server drustcraft.chest.ignore:<-:<context.location>
        - waituntil <server.sql_connections.contains[drustcraft]>
        - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>chest_ignore`(`server`,`location`) VALUES(NULL,"<context.location>");'


drustcraftt_chest_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - debug ERROR "Drustcraft Chest: Drustcraft Setting module is required to be installed"
      - stop
    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR "Drustcraft Chest: Drustcraft Database module is required to be installed"
      - stop

    - waituntil <server.has_flag[drustcraft.module.db]>

    - define create_tables:true
    - ~run drustcraftt_db_get_version def:drustcraft.chest save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> != 1:
      - if <[version]> != null:
        - debug ERROR "Drustcraft Chest: Unexpected database version"
        - stop
      - else:
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>chest_ignore` (`id` INT NOT NULL AUTO_INCREMENT, `server` TEXT, `location` TEXT NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>chest_stocked` (`id` INT NOT NULL AUTO_INCREMENT, `server` TEXT, `location` TEXT NOT NULL, `day` INT NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>chest_items` (`id` INT NOT NULL AUTO_INCREMENT, `item` TEXT NOT NULL, `biome` TEXT, `chance` DOUBLE NOT NULL, `min_qty` INT NOT NULL, `max_qty` INT NOT NULL, PRIMARY KEY (`id`));'
        - ~run drustcraftt_setting_set def:<list[chest.containers].include_single[<list[ANVIL|BARREL|BEACON|BEE_NEST|BEEHIVE|BLACK_SHULKER_BOX|BLAST_FURNACE|BLUE_SHULKER_BOX|BREWING_STAND|BROWN_SHULKER_BOX|CAMPFIRE|CARTOGRAPHY_TABLE|CHEST|CHIPPED_ANVIL|COMPOSTER|CYAN_SHULKER_BOX|DAMAGED_ANVIL|DISPENSER|DROPPER|ENCHANTING_TABLE|ENDER_CHEST|FLETCHING_TABLE|FURNACE|GRAY_SHULKER_BOX|GREEN_SHULKER_BOX|GRINDSTONE|HOPPER|JUKEBOX|LECTERN|LIGHT_BLUE_SHULKER_BOX|LIGHT_GRAY_SHULKER_BOX|LIME_SHULKER_BOX|LOOM|MAGENTA_SHULKER_BOX|ORANGE_SHULKER_BOX|PINK_SHULKER_BOX|PURPLE_SHULKER_BOX|RED_SHULKER_BOX|SHULKER_BOX|SMITHING_TABLE|SMOKER|SOUL_CAMPFIRE|STONECUTTER|TRAPPED_CHEST|WHITE_SHULKER_BOX|YELLOW_SHULKER_BOX]>]>
        - run drustcraftt_db_set_version def:drustcraft.chest|1

    - ~run drustcraftt_setting_get def:chest.containers|null|yaml save:result
    - flag server drustcraft.chests.containers:<entry[result].created_queue.determination.get[1]>

    - ~sql id:drustcraft 'query:SELECT `location` FROM `<server.flag[drustcraft.db.prefix]>chest_ignore` WHERE `server`=NULL;' save:sql_result
    - if <entry[sql_result].result.size||0> >= 1:
      - foreach <entry[sql_result].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define location:<[row].get[1].unescaped||<empty>>
        - flag server drustcraft.chest.ignore:->:<[location]>

    - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>chest_stocked` WHERE `server`=NULL  AND `day` <&lt> <server.flag[drustcraft.util.day]>;'
    - ~sql id:drustcraft 'query:SELECT `location` FROM `<server.flag[drustcraft.db.prefix]>chest_stocked` WHERE `server`=NULL  AND `day` = <server.flag[drustcraft.util.day]>;' save:sql_result
    - if <entry[sql_result].result.size||0> >= 1:
      - foreach <entry[sql_result].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define location:<[row].get[1].unescaped||<empty>>
        - flag server drustcraft.chest.stocked:->:<[location]>

    - ~sql id:drustcraft 'query:SELECT `item`, `biome`, `chance`, `min_qty`, `max_qty` FROM `<server.flag[drustcraft.db.prefix]>chest_items`;' save:sql_result
    - if <entry[sql_result].result.size||0> >= 1:
      - foreach <entry[sql_result].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define item:<[row].get[1].unescaped||<empty>>
        - define biome:<[row].get[2].unescaped||<empty>>
        - define chance:<[row].get[3]||<empty>>
        - define min_qty:<[row].get[4]||<empty>>
        - define max_qty:<[row].get[5]||<empty>>

        - if <[biome]> == null:
          - define biome:any

        - flag server drustcraft.chest.items.<[biome]>.<[item]>.chance:<[chance]>
        - flag server drustcraft.chest.items.<[biome]>.<[item]>.min_qty:<[min_qty]>
        - flag server drustcraft.chest.items.<[biome]>.<[item]>.max_qty:<[max_qty]>

    - flag server drustcraft.module.value:<script[drustcraftw_value].data_key[version]>
