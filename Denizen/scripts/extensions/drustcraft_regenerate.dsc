# Drustcraft - Regenerate
# Block regeneration, decay player build blocks and regenerate the original world for other players to explore
# https://github.com/drustcraft/drustcraft

drustcraftw_regenerate:
  type: world
  debug: false
  events:
    on server start:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_regenerate.load

    on script reload:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_regenerate.load
    
    on system time hourly:
      - run drustcraftt_regenerate.update
    
    on player places block server_flagged:drustcraft_regenerate:
      - if <player.gamemode> == SURVIVAL && <server.sql_connections.contains[drustcraft_database]> && <server.flag[drustcraft_regenerate_blocks].contains[<context.material.name>]>:
        - sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_regenerate` WHERE server="<bungee.server>" AND action="movement" AND world="<context.location.world.name>" AND x=<context.location.x.round> AND y=<context.location.y.round> AND z=<context.location.z.round>;'
        - sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_regenerate` (`server`, `action`, `world`, `x`, `y`, `z`, `material`, `date`) VALUES ("<bungee.server>", "place", "<context.location.world.name>", <context.location.x.round>, <context.location.y.round>, <context.location.z.round>, "<context.material.name>", <util.time_now.epoch_millis.div[1000].round>);'

    on player breaks block server_flagged:drustcraft_regenerate:
      - if <player.gamemode> == SURVIVAL && <server.sql_connections.contains[drustcraft_database]> && <server.flag[drustcraft_regenerate_blocks].contains[<context.material.name>]>:
        - sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_regenerate` WHERE server="<bungee.server>" AND action="place" AND world="<context.location.world.name>" AND x=<context.location.x.round> AND y=<context.location.y.round> AND z=<context.location.z.round>;'
        - ~sql id:drustcraft_database 'query:SELECT id FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_regenerate WHERE server="<bungee.server>" AND action="break" AND world="<context.location.world.name>" AND x=<context.location.x.round> AND y=<context.location.y.round> AND z=<context.location.z.round>;' save:sql_result
        - define action:movement
        - if <entry[sql_result].result.size||0> == 0:
          - define action:break
        - sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_regenerate` (`server`, `action`, `world`, `x`, `y`, `z`, `material`, `date`) VALUES ("<bungee.server>", "<[action]>", "<context.location.world.name>", <context.location.x.round>, <context.location.y.round>, <context.location.z.round>, "<context.material.name>", <util.time_now.epoch_millis.div[1000].round>);'


drustcraftt_regenerate:
  type: task
  debug: false
  script:
    - determine <empty>
    
  load:
    - flag server drustcraft_regenerate:!
    - if <server.scripts.parse[name].contains[drustcraftw_sql]>:
      - waituntil <server.sql_connections.contains[drustcraft_database]>
  
      - define create_tables:true
      - ~sql id:drustcraft_database 'query:SELECT version FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_version WHERE name="drustcraft_regenerate";' save:sql_result
      - if <entry[sql_result].result.size||0> >= 1:
        - define row:<entry[sql_result].result.get[1].split[/]||0>
        - define create_tables:false
        - if <[row]> >= 2 || <[row]> < 1:
          # Weird version error
          - stop
  
      - if <[create_tables]>:
        - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` (`name`,`version`) VALUES ("drustcraft_regenerate",'1');'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_regenerate` (`id` INT NOT NULL AUTO_INCREMENT, `server` VARCHAR(255) NOT NULL, `action` VARCHAR(255) NOT NULL, `world` VARCHAR(255) NOT NULL, `x` INT NOT NULL, `y` INT NOT NULL, `z` INT NOT NULL, `material` VARCHAR(255) NOT NULL, `date` INT NOT NULL, PRIMARY KEY (`id`));'
  
      - if <yaml[drustcraft_server].contains[drustcraft.regenerate.blocks]> == false:
        - yaml id:drustcraft_server set drustcraft.regenerate.blocks:<list[ancient_debris|andesite|basalt|bedrock|blackstone|clay|coal_ore|coarse_dirt|cobblestone|copper_ore|diamond_ore|diorite|dirt|emerald_ore|end_stone|gilded_blackstone|glowstone|gold_ore|granite|grass_block|grass_path|gravel|ice|iron_ore|lapis_ore|lava|magma_block|mossy_cobblestone|mycelium|nether_gold_ore|nether_quartz_ore|netherrack|obsidian|packed_ice|podzol|redstone_ore|sand|sandstone|smooth_stone|smooth_stone|soul_sand|stone|stone_bricks|mossy_stone_bricks|cracked_stone_bricks|white_terracotta|orange_terracotta|magenta_terracotta|light_blue_terracotta|yellow_terracotta|lime_terracotta|pink_terracotta|gray_terracotta|light_gray_terracotta|cyan_terracotta|purple_terracotta|blue_terracotta|brown_terracotta|green_terracotta|red_terracotta|black_terracotta]>
      - if <yaml[drustcraft_server].contains[drustcraft.regenerate.radius]> == false:
        - yaml id:drustcraft_server set drustcraft.regenerate.radius:20
      - if <yaml[drustcraft_server].contains[drustcraft.regenerate.chance]> == false:
        - yaml id:drustcraft_server set drustcraft.regenerate.chance:0.05
      - if <yaml[drustcraft_server].contains[drustcraft.regenerate.restore_delay]> == false:
        - yaml id:drustcraft_server set drustcraft.regenerate.restore_delay:1209600
      - if <yaml[drustcraft_server].contains[drustcraft.regenerate.decay_delay]> == false:
        - yaml id:drustcraft_server set drustcraft.regenerate.decay_delay:3628800
      
      - flag server drustcraft_regenerate_blocks:<yaml[drustcraft_server].read[drustcraft.regenerate.blocks]||<list[]>>
      - flag server drustcraft_regenerate:true
    - else:
      - debug log 'Drustcraft Regenerate requires the Drustcraft SQL script installed'
    
  update:
    - define now:<util.time_now.epoch_millis.div[1000].round>
    - define restore_time:<[now].sub[<yaml[drustcraft_server].read[drustcraft.regenerate.restore_delay]>]>
    - define decay_time:<[now].sub[<yaml[drustcraft_server].read[drustcraft.regenerate.decay_delay]>]>
    - define chance:<yaml[drustcraft_server].read[drustcraft.regenerate.chance]>
    - define radius:<yaml[drustcraft_server].read[drustcraft.regenerate.radius]>
    
    # find all the rows with action=break and the date > drustcraft.regenerate.restore_delay or action=place and date > drustcraft.regenerate.decay_delay
    #- ~sql id:drustcraft_database 'query:SELECT id,server,action,world,x,y,z,material,date FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_regenerate WHERE (server="<bungee.server>" AND action="break" AND date < <[restore_time]>) OR (action="place" AND date < <[decay_time]>);' save:sql_result
    - ~sql id:drustcraft_database 'query:SELECT id,server,action,world,x,y,z,material,date FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_regenerate WHERE (server="<bungee.server>" AND action="break" AND date <&lt> <[restore_time]>) OR (action="place" AND date <&lt> <[decay_time]>);' save:sql_result
    - foreach <entry[sql_result].result>:
      # if random < chance 
      - if <util.random.decimal[0].to[1]> <= <[chance]>:
        - define row:<[value].split[/]>
        - define id:<[row].get[1]>
        - define server:<[row].get[2]>
        - define action:<[row].get[3]>
        - define world:<[row].get[4]>
        - define x:<[row].get[5]>
        - define y:<[row].get[6]>
        - define z:<[row].get[7]>
        - define material:<[row].get[8]>
        - define date:<[row].get[9]>

        # if the action is NOT break, or if at least 1 block around the location is not air
        - if <[action]> != "break" || <location[<[x]>,<[y]>,<[z]>,<[world]>].find.blocks[].within[1].parse[material.name].deduplicate.exclude[air].size||0> >= 1:
          - define delay:<[restore_time]>
          - if <[action]> != "break":
            - define delay:<[decay_time]>
          
          # find rows where x~10 and y~10 and z~10 and server=same and world=same and action=place or action=modify and date > $delay
          - ~sql id:drustcraft_database 'query:SELECT id FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_regenerate WHERE date><[delay]> AND server="<bungee.server>" AND world="<[world]>" AND (x<&gt>=<[x].sub[<[radius]>]> AND x<&lt>=<[x].add[<[radius]>]>) AND (y<&gt>=<[y].sub[<[radius]>]> AND x<&lt>=<[y].add[<[radius]>]>) AND (z<&gt>=<[z].sub[<[radius]>]> AND x<&lt>=<[z].add[<[radius]>]>) LIMIT 1;' save:change_result
          - if <entry[change_result].result.size||0> == 0:
            - if <[action]> == "break":
              - modifyblock <location[<[x]>,<[y]>,<[z]>,<[world]>]> <[material]>
            - else:
              - modifyblock <location[<[x]>,<[y]>,<[z]>,<[world]>]> air
            - sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_regenerate` WHERE id=<[id]>;'
