# Drustcraft - Regenerate
# https://github.com/drustcraft/drustcraft

drustcraftw_regenerate:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_regenerate_load

    on script reload:
      - run drustcraftt_regenerate_load

    on system time hourly server_flagged:drustcraft.module.regenerate:
      - run drustcraftt_regenerate_update

    on player places block server_flagged:drustcraft.module.regenerate:
      - if <player.gamemode> == SURVIVAL && <context.material.block_strength> > 0:
        - waituntil <server.sql_connections.contains[drustcraft]>
        - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>regenerate` WHERE server IS NULL AND action="movement" AND world="<context.location.world.name>" AND x=<context.location.x.round> AND y=<context.location.y.round> AND z=<context.location.z.round>;'
        - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>regenerate` (`server`, `action`, `world`, `x`, `y`, `z`, `material`, `date`) VALUES (NULL, "place", "<context.location.world.name>", <context.location.x.round>, <context.location.y.round>, <context.location.z.round>, "<context.material.name>", <util.time_now.epoch_millis.div[1000].round>);'

    on player breaks block server_flagged:drustcraft.module.regenerate:
      - if <player.gamemode> == SURVIVAL && <context.material.block_strength> > 0:
        - waituntil <server.sql_connections.contains[drustcraft]>
        - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>regenerate` WHERE server IS NULL AND action="place" AND world="<context.location.world.name>" AND x=<context.location.x.round> AND y=<context.location.y.round> AND z=<context.location.z.round>;'
        - ~sql id:drustcraft 'query:SELECT id FROM <server.flag[drustcraft.db.prefix]>regenerate WHERE server IS NULL AND action="break" AND world="<context.location.world.name>" AND x=<context.location.x.round> AND y=<context.location.y.round> AND z=<context.location.z.round>;' save:sql_result
        - define action:movement
        - if <entry[sql_result].result.size||0> == 0:
          - define action:break
        - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>regenerate` (`server`, `action`, `world`, `x`, `y`, `z`, `material`, `date`) VALUES (NULL, "<[action]>", "<context.location.world.name>", <context.location.x.round>, <context.location.y.round>, <context.location.z.round>, "<context.material.name>", <util.time_now.epoch_millis.div[1000].round>);'

    on entity explodes server_flagged:drustcraft.module.regenerate:
      - waituntil <server.sql_connections.contains[drustcraft]>
      - foreach <context.blocks>:
        - define target_material:<[value]>
        - if <[target_material].block_strength||0> > 0:
          - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>regenerate` WHERE server IS NULL AND action="place" AND world="<context.location.world.name>" AND x=<context.location.x.round> AND y=<context.location.y.round> AND z=<context.location.z.round>;'
          - ~sql id:drustcraft 'query:SELECT id FROM <server.flag[drustcraft.db.prefix]>regenerate WHERE server IS NULL AND action="break" AND world="<context.location.world.name>" AND x=<context.location.x.round> AND y=<context.location.y.round> AND z=<context.location.z.round>;' save:sql_result
          - define action:movement
          - if <entry[sql_result].result.size||0> == 0:
            - define action:break
          - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>regenerate` (`server`, `action`, `world`, `x`, `y`, `z`, `material`, `date`) VALUES (NULL, "<[action]>", "<context.location.world.name>", <context.location.x.round>, <context.location.y.round>, <context.location.z.round>, "<[target_material].name>", <util.time_now.epoch_millis.div[1000].round>);'


drustcraftt_regenerate_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - debug ERROR "Drustcraft Regenerate: Drustcraft Setting module is required to be installed"
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR 'Drustcraft Regenerate: Drustcraft DB is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.db]>

    - define create_tables:true
    - ~run drustcraftt_db_get_version def:drustcraft.regenerate save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> != 1:
      - if <[version]> != null:
        - debug ERROR "Drustcraft Job Trader: Unexpected database version. Ignoring DB storage"
      - else:
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>regenerate` (`id` INT NOT NULL AUTO_INCREMENT, `server` VARCHAR(255), `action` VARCHAR(255) NOT NULL, `world` VARCHAR(255) NOT NULL, `x` INT NOT NULL, `y` INT NOT NULL, `z` INT NOT NULL, `material` VARCHAR(255) NOT NULL, `date` INT NOT NULL, PRIMARY KEY (`id`));'
        - run drustcraftt_db_set_version def:drustcraft.regenerate|1

    - waituntil <server.has_flag[drustcraft.module.setting]>

    - ~run drustcraftt_setting_get def:regenerate.radius|20|yaml save:result
    - flag server drustcraft.regenerate.radius:<entry[result].created_queue.determination.get[1]>
    - ~run drustcraftt_setting_get def:regenerate.chance|0.05|yaml save:result
    - flag server drustcraft.regenerate.chance:<entry[result].created_queue.determination.get[1]>
    - ~run drustcraftt_setting_get def:regenerate.restore_delay|1209600|yaml save:result
    - flag server drustcraft.regenerate.restore_delay:<entry[result].created_queue.determination.get[1]>
    - ~run drustcraftt_setting_get def:regenerate.decay_delay|3628800|yaml save:result
    - flag server drustcraft.regenerate.decay_delay:<entry[result].created_queue.determination.get[1]>

    - flag server drustcraft.module.regenerate:<script[drustcraftw_regenerate].data_key[version]>


drustcraftt_regenerate_update:
  type: task
  debug: false
  script:
    - define now:<util.time_now.epoch_millis.div[1000].round>
    - define restore_time:<[now].sub[<server.flag[drustcraft.regenerate.restore_delay]>]>
    - define decay_time:<[now].sub[<server.flag[drustcraft.regenerate.decay_delay]>]>
    - define chance:<server.flag[drustcraft.regenerate.chance]>
    - define radius:<server.flag[drustcraft.regenerate.radius]>

    # find all the rows with action=break and the date > drustcraft.regenerate.restore_delay or action=place and date > drustcraft.regenerate.decay_delay
    - ~sql id:drustcraft 'query:SELECT id,server,action,world,x,y,z,material,date FROM <server.flag[drustcraft.db.prefix]>regenerate WHERE (server IS NULL AND action="break" AND date <&lt> <[restore_time]>) OR (action="place" AND date <&lt> <[decay_time]>);' save:sql_result
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

        - if <server.worlds.parse[name].contains[<[world]>]>:
          # if the action is NOT break, or if at least 1 block around the location is not air
          - if <[action]> != break || <location[<[x]>,<[y]>,<[z]>,<[world]>].find_blocks.within[1].parse[material.name].deduplicate.exclude[air].size||0> >= 1:
            - define delay:<[restore_time]>
            - if <[action]> != break:
              - define delay:<[decay_time]>

            # find rows where x~10 and y~10 and z~10 and server=same and world=same and action=place or action=modify and date > $delay
            - ~sql id:drustcraft 'query:SELECT id FROM <server.flag[drustcraft.db.prefix]>regenerate WHERE date <&gt> <[delay]> AND server IS NULL AND world = "<[world]>" AND (x <&gt>= <[x].sub[<[radius]>]> AND x <&lt>= <[x].add[<[radius]>]>) AND (y <&gt>= <[y].sub[<[radius]>]> AND x <&lt>= <[y].add[<[radius]>]>) AND (z <&gt>= <[z].sub[<[radius]>]> AND x <&lt>= <[z].add[<[radius]>]>) LIMIT 1;' save:change_result
            - if <entry[change_result].result.size||0> == 0:
              - if <[action]> == break:
                - modifyblock <location[<[x]>,<[y]>,<[z]>,<[world]>]> <[material]>
              - else:
                - modifyblock <location[<[x]>,<[y]>,<[z]>,<[world]>]> air
              - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>regenerate` WHERE id=<[id]>;'
