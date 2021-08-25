# Drustcraft - Traders
# https://github.com/drustcraft/drustcraft

drustcraftw_job_trader:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_job_trader_load

    on script reload:
      - run drustcraftt_job_trader_load


drustcraftt_job_trader_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_npc]>:
      - debug ERROR 'Drustcraft Job Trader: Drustcraft NPC is required to be installed'
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR 'Drustcraft Job Trader: Drustcraft DB is required to be installed'
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_value]>:
      - debug ERROR 'Drustcraft Job Trader: Drustcraft Value is required to be installed'
      - stop

    - waituntil <server.sql_connections.contains[drustcraft]>
    - define create_tables:true
    - ~run drustcraftt_db_get_version def:drustcraft.job_trader save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> != 1:
      - if <[version]> != null:
        - debug ERROR "Drustcraft Job Trader: Unexpected database version. Ignoring DB storage"
      - else:
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_trader_type` (`trader_id` VARCHAR(128) NOT NULL, `title` VARCHAR(128) NOT NULL, `owner` VARCHAR(36) NOT NULL, PRIMARY KEY (`trader_id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_trader_item` (`id` INT NOT NULL AUTO_INCREMENT, `trader_id` VARCHAR(128) NOT NULL, `item` VARCHAR(128) NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_trader_npc` (`npc_id` INT NOT NULL, `trader_id` VARCHAR(128) NOT NULL, `sell_range` VARCHAR(9) NOT NULL DEFAULT "3-8", `sell_price_factor` VARCHAR(7) NOT NULL DEFAULT "1-1.4", `buy_range` VARCHAR(9) NOT NULL DEFAULT "3-8", `buy_price_factor` VARCHAR(7) NOT NULL DEFAULT "0.8-1", PRIMARY KEY (`npc_id`));'
        - run drustcraftt_db_set_version def:drustcraft.job_trader|1

    - waituntil <server.has_flag[drustcraft.module.npc]>

    - ~sql id:drustcraft 'query:SELECT `trader_id`,`title`,`owner` FROM `<server.flag[drustcraft.db.prefix]>job_trader_type`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/].unescaped||<list[]>>
      - define trader_id:<[row].get[1]||<empty>>
      - define title:<[row].get[2]||<empty>>
      - define owner:<[row].get[3]||<empty>>

      - flag server drustcraft.job_trader.traders.<[trader_id]>.title:<[title]>
      - flag server drustcraft.job_trader.traders.<[trader_id]>.owner:<[owner]>
      - flag server drustcraft.job_trader.traders.<[trader_id]>.items:<list[]>
      - flag server drustcraft.job_trader.traders.<[trader_id]>.npcs:<list[]>

    - ~sql id:drustcraft 'query:SELECT `trader_id`,`item` FROM `<server.flag[drustcraft.db.prefix]>job_trader_item`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/].unescaped||<list[]>>
      - define trader_id:<[row].get[1]||<empty>>
      - define item:<[row].get[2]||<empty>>
      - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>]>:
        - flag server drustcraft.job_trader.traders.<[trader_id]>.items:->:<[item]>

    - ~sql id:drustcraft 'query:SELECT `trader_id`,`npc_id`, `sell_range`, `sell_price_factor`, `buy_range`, `buy_price_factor` FROM `<server.flag[drustcraft.db.prefix]>job_trader_npc`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/].unescaped||<list[]>>
      - define trader_id:<[row].get[1]||<empty>>
      - define npc_id:<[row].get[2]||<empty>>
      - define sell_range:<[row].get[3]||<empty>>
      - define sell_price_factor:<[row].get[4].unescaped||<empty>>
      - define buy_range:<[row].get[5]||<empty>>
      - define buy_price_factor:<[row].get[6].unescaped||<empty>>
      - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>]> && <server.npcs.parse[id].contains[<[npc_id]>]>:
        - flag server drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.sell_range:<[sell_range]>
        - flag server drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.sell_price_factor:<[sell_price_factor]>
        - flag server drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.buy_range:<[buy_range]>
        - flag server drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.buy_price_factor:<[buy_price_factor]>
        - flag <npc[<[npc_id]>]> drustcraft.job_trader.trader_id:<[trader_id]>

    - run drustcraftt_npc_job_register def:trader|drustcraftt_job_trader|Trader
    - flag server drustcraft.module.job_trader:<script[drustcraftw_job_trader].data_key[version]>
    - run drustcraftt_job_trader_update

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>
      - run drustcraftt_tabcomplete_completion def:trader|list
      - run drustcraftt_tabcomplete_completion def:trader|create
      - run drustcraftt_tabcomplete_completion def:trader|remove|_*traders
      - run drustcraftt_tabcomplete_completion def:trader|info|_*traders
      - run drustcraftt_tabcomplete_completion def:trader|title|_*traders
      - run drustcraftt_tabcomplete_completion def:trader|owner|_*traders
      - run drustcraftt_tabcomplete_completion def:trader|npcs|_*traders
      - run drustcraftt_tabcomplete_completion def:trader|addnpc|_*traders|_*trader_npcs
      - run drustcraftt_tabcomplete_completion def:trader|remnpc|_*trader_active_npcs
      - run drustcraftt_tabcomplete_completion def:trader|items|_*traders
      - run drustcraftt_tabcomplete_completion def:trader|additem|_*traders|_*materials
      - run drustcraftt_tabcomplete_completion def:trader|remitem|_*traders|_*materials
      - run drustcraftt_tabcomplete_completion def:trader|restock|_*traders
      - run drustcraftt_tabcomplete_completion def:trader|restock|_*trader_active_npcs

      - run drustcraftt_tabcomplete_completion def:npc|job|trader|_*traders


drustcraftt_job_trader_update:
  type: task
  debug: false
  script:
    - waituntil <server.has_flag[drustcraft.module.value]>
    - foreach <server.flag[drustcraft.job_trader.traders].keys||<list[]>> as:trader_id:
      - foreach <server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs].keys||<list[]>> as:npc_id:
        - run drustcraftt_job_trader_update_npc def:<npc[<[npc_id]>]>


drustcraftt_job_trader_update_npc:
  type: task
  debug: false
  definitions: npc
  script:
    - flag <[npc]> drustcraft.job_trader.items:!
    - define trader_id:<[npc].flag[drustcraft.job_trader.trader_id]>

    # sell
    - define sell_item_count:<util.random.int[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc].id>.sell_range].before[-]>].to[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc].id>.sell_range].after[-]>]>
    - define item_list:<server.flag[drustcraft.job_trader.traders.<[trader_id]>.items]>

    - define count_offset:<[npc].flag[drustcraft.job_trader.items].keys.highest||0>
    - repeat <[sell_item_count]>:
      - define item:<[item_list].random>
      - define item_list:<-:<[item]>

      - define currency:<proc[drustcraftp_value_item_to_currency].context[<[item]>|<util.random.decimal[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc].id>.sell_price_factor].before[-]>].to[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc].id>.sell_price_factor].after[-]>].round_to[1]>]>
      - if <[currency]> != null:
        - define item:<item[<[item]>]>
        - adjust def:item quantity:<[currency].get[min_qty]>
        - define item_map:<map[].with[inputs].as[<list[<[currency].get[item1]>|<[currency].get[item2]>]>].with[result].as[<[item]>].with[max_uses].as[<proc[drustcraftp_job_trader_value_to_max_uses].context[<[currency].get[value]>]>]>

        - flag <[npc]> drustcraft.job_trader.items.<[value].add[<[count_offset]>]>:<[item_map]>

    # buy
    - define buy_item_count:<util.random.int[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc].id>.buy_range].before[-]>].to[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc].id>.buy_range].after[-]>]>
    - define item_list:<server.flag[drustcraft.job_trader.traders.<[trader_id]>.items]>

    - define count_offset:<[npc].flag[drustcraft.job_trader.items].keys.highest||0>
    - repeat <[buy_item_count]>:
      - define item:<[item_list].random>
      - define item_list:<-:<[item]>

      - define currency:<proc[drustcraftp_value_item_to_currency].context[<[item]>|<util.random.decimal[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc].id>.buy_price_factor].before[-]>].to[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc].id>.buy_price_factor].after[-]>].round_to[1]>]>
      - if <[currency]> != null:
        - define item:<item[<[item]>]>
        - adjust def:item quantity:<[currency].get[min_qty]>
        - define item_map:<map[].with[inputs].as[<list[<[item]>|<item[air]>]>].with[result].as[<[currency].get[item1]>].with[max_uses].as[<proc[drustcraftp_job_trader_value_to_max_uses].context[<[currency].get[value]>]>]>

        - flag <[npc]> drustcraft.job_trader.items.<[value].add[<[count_offset]>]>:<[item_map]>


drustcraftp_job_trader_value_to_max_uses:
  type: procedure
  debug: false
  definitions: value
  script:
    - if <[value]> < 5:
      - determine 9999
    - else if <[value]> <= 5:
      - determine <util.random.int[1].to[40]>
    - else if <[value]> <= 20:
      - determine <util.random.int[1].to[20]>
    - else if <[value]> <= 40:
      - determine <util.random.int[1].to[10]>

    - determine <util.random.int[1].to[5]>


drustcraftp_job_trader_find_npc_trader_type:
  type: procedure
  debug: false
  definitions: npc
  script:
    - foreach <server.flag[drustcraft.job_trader.traders].keys> as:trader_id:
      - if <server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs].contains[<[npc].id>]>:
        - determine <server.flag[drustcraft.job_trader.traders.<[trader_id]>.title]>
    - determine Trader


drustcraftc_job_trader:
  type: command
  debug: false
  name: trader
  description: Modifies NPC trader
  usage: /trader
  permission: drustcraft.trader
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:trader
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.job_trader]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Job Trader module not loaded. Check console for errors]>'
      - stop

    - choose <context.args.get[1]||<empty>>:
      - case list:
        - ~run drustcraftt_chatgui_clear
        - foreach <server.flag[drustcraft.job_trader.traders].keys> as:trader_id:
          - define line:<proc[drustcraftp_chatgui_option].context[<[trader_id]>]>
          - define 'line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.title]> <&7>(<server.flag[drustcraft.job_trader.traders.<[trader_id]>.items].size> items, <server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs].size> NPCs)]>'
          - define 'line:<[line]><proc[drustcraftp_chatgui_button].context[add|Info|trader info <[trader_id]>|Show details about this trader|RUN_COMMAND]>'
          - ~run drustcraftt_chatgui_item def:<[line]>

        - ~run drustcraftt_chatgui_render 'def:trader list|Trader types|<context.args.get[2]||1>'

      - case create:
        - define trader_id:<context.args.get[2]||<empty>>
        - if <[trader_id]> != <empty>:
          - if !<server.flag[drustcraft.job_trader.traders].keys.contains[<[trader_id]>]>:
            - waituntil <server.sql_connections.contains[drustcraft]>
            - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_trader_type`(`trader_id`, `title`, `owner`) VALUES("<[trader_id]>", "<[trader_id].to_sentence_case>", "<player.uuid||console>");'
            - flag server drustcraft.job_trader.traders.<[trader_id]>.title:<[trader_id]>
            - flag server drustcraft.job_trader.traders.<[trader_id]>.owner:<player.uuid||console>
            - flag server drustcraft.job_trader.traders.<[trader_id]>.items:<list[]>
            - flag server drustcraft.job_trader.traders.<[trader_id]>.npcs:<list[]>
            - narrate '<proc[drustcraftp_msg_format].context[success|The trader type $e<[trader_id]> $ras been added]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader id $e<[trader_id]> $ris already used]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|You need to enter a unique trader id]>'

      - case remove delete del:
        - define name:<context.args.get[2]||<empty>>
        - if <[trader_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>]>:
            - if !<server.has_flag[drustcraft.job_trader.traders.<[trader_id]>.owner]> || <server.flag[drustcraft.job_trader.traders.<[trader_id]>.owner]> == <player.uuid||console> || <context.server||false> || <player.has_permission[drustcraft.trader.override]||false>:
              - foreach <server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs]||<list[]>> as:npc:
                - run drustcraftt_npc_job_clear def:<[npc]>
              - waituntil <server.sql_connections.contains[drustcraft]>
              - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_trader_type` WHERE `trader_id` = "<[trader_id]>";'
              - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_trader_item` WHERE `trader_id` = "<[trader_id]>";'
              - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_trader_npc` WHERE `trader_id` = "<[trader_id]>";'
              - flag server drustcraft.job_trader.traders.<[trader_id]>:!
              - narrate '<proc[drustcraftp_msg_format].context[success|The trader type $e<[trader_id]> $rwas deleted]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to remove this trader type]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader $e<[trader_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|You need to enter a trader id]>'

      - case info:
        - define trader_id:<context.args.get[2]||<empty>>
        - if <[trader_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>]>:
            - ~run drustcraftt_chatgui_clear
            - narrate '<proc[drustcraftp_chatgui_title].context[Trader: <[trader_id]>]>'

            # title
            - narrate '<proc[drustcraftp_chatgui_option].context[Title]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.title]||<&4>(none)>]><proc[drustcraftp_chatgui_button].context[add|Set|trader title <[trader_id]> |Set trader type title|]>'

            # Owner
            - narrate '<proc[drustcraftp_chatgui_option].context[Owner]><proc[drustcraftp_chatgui_value].context[<player[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.owner]>].name||console>]><proc[drustcraftp_chatgui_button].context[add|Set|trader owner <[trader_id]> |Set trader type owner]>'

            # NPCs
            - narrate '<proc[drustcraftp_chatgui_option].context[NPCs]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs].size||0>]><proc[drustcraftp_chatgui_button].context[view|View|trader npcs <[trader_id]> |View trader type npcs|RUN_COMMAND]><proc[drustcraftp_chatgui_button].context[add|Add|trader addnpc <[trader_id]> |Change NPC trader type]>'

            # Items
            - narrate '<proc[drustcraftp_chatgui_option].context[Items]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.items].size||0>]><proc[drustcraftp_chatgui_button].context[view|View|trader items <[trader_id]> |View trader type items|RUN_COMMAND]><proc[drustcraftp_chatgui_button].context[add|Add|trader additem <[trader_id]> |Add item to trader type]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader type $e<[trader_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No trader ID was entered]>'

      - case title:
        - define trader_id:<context.args.get[2]||<empty>>
        - if <[trader_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>]>:
            - if <context.args.size> == 2:
              - narrate '<proc[drustcraftp_msg_format].context[arrow|The title of trader type $e<[trader_id]> $ris $e<server.flag[drustcraft.job_trader.traders.<[trader_id]>.title]>]>'
            - else:
              - if !<server.has_flag[drustcraft.job_trader.traders.<[trader_id]>.owner]> || <server.flag[drustcraft.job_trader.traders.<[trader_id]>.owner]> == <player.uuid||console> || <context.server||false> || <player.has_permission[drustcraft.trader.override]||false>:
                - flag server drustcraft.job_trader.traders.<[trader_id]>.title:<context.args.get[3]>
                - waituntil <server.sql_connections.contains[drustcraft]>
                - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_trader_type` SET `title` = "<context.args.get[3]>" WHERE `trader_id` = "<[trader_id]>";'
                - foreach <server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs].keys||<list[]>> as:npc_id:
                  - run drustcraftt_npc_title def:<npc[npc_id]>|<context.args.get[3]>
                - narrate '<proc[drustcraftp_msg_format].context[success|Trader type title updated]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this trader type]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader type $e<[trader_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No trader ID was entered]>'

      - case owner:
        - define trader_id:<context.args.get[2]||<empty>>
        - if <[trader_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>]>:
            - if <context.args.size> == 2:
              - narrate '<proc[drustcraftp_msg_format].context[arrow|The owner of trader type $e<[trader_id]> $ris $e<player[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.owner]>].name||console>]>'
            - else:
              - if !<server.has_flag[drustcraft.job_trader.traders.<[trader_id]>.owner]> || <server.flag[drustcraft.job_trader.traders.<[trader_id]>.owner]> == <player.uuid||console> || <context.server||false> || <player.has_permission[drustcraft.trader.override]||false>:
                - define owner:<server.match_offline_player[<context.args.get[3]>]>
                - if !<[owner].exists> && <[owner].name> == <context.args.get[3]>:
                  - flag server drustcraft.job_trader.traders.<[trader_id]>.owner:<[owner].uuid>
                  - waituntil <server.sql_connections.contains[drustcraft]>
                  - ~sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_trader_type` SET `owner` = "<[owner].uuid>" WHERE `trader_id` = "<[trader_id]>";'
                  - narrate '<proc[drustcraftp_msg_format].context[success|Trader type owner updated]>'
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[3]> $rwas not found]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this trader type]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader type $e<[trader_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No trader ID was entered]>'

      - case npcs:
        - define trader_id:<context.args.get[2]||<empty>>
        - if <[trader_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>]>:
            - define editable:false
            - if !<server.has_flag[drustcraft.job_trader.traders.<[trader_id]>.owner]> || <server.flag[drustcraft.job_trader.traders.<[trader_id]>.owner]> == <player.uuid||console> || <context.server||false> || <player.has_permission[drustcraft.trader.override]||false>:
              - define editable:true

            - ~run drustcraftt_chatgui_clear
            - foreach <server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs].keys||<list[]>> as:npc_id:
              - define line:<proc[drustcraftp_chatgui_option].context[<[npc_id]>]>
              - define 'line:<[line]><proc[drustcraftp_chatgui_value].context[<npc[<[npc_id]>].name> <&7>(Sell <server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.sell_range]> @ x<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.sell_price_factor]>, Buy <server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.buy_range]> @ x<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.buy_price_factor]>)]>'

              - if <[editable]>:
                - define 'line:<[line]><proc[drustcraftp_chatgui_button].context[rem|Rem|trader remnpc <[npc_id]>|Remove this NPC as a trader]>'
              - ~run drustcraftt_chatgui_item def:<[line]>

            - ~run drustcraftt_chatgui_render 'def:trader npcs|Trader type NPCs|<context.args.get[3]||1>'

          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader type $e<[trader_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No trader ID was entered]>'

      - case addnpc:
        - define trader_id:<context.args.get[2]||<empty>>
        - if <[trader_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>]>:
            - define npc_id:<context.args.get[3]||<empty>>
            - if <[npc_id]> != <empty>:
              - if <server.npcs.parse[id].contains[<[npc_id]>]> && <proc[drustcraftp_npc_job_get].context[<npc[<[npc_id]>]>]> == trader:
                - if <npc[<[npc_id]>].has_flag[drustcraft.job_trader.trader_id]>:
                  - flag server drustcraft.job_trader.traders.<npc[<[npc_id]>].flag[drustcraft.job_trader.trader_id]>.npcs.<[npc_id]>:!

                - flag <npc[<[npc_id]>]> drustcraft.job_trader.trader_id:<[trader_id]>
                - define default_npc_data:<map[].with[sell_range].as[3-8].with[sell_price_factor].as[1-1.4].with[buy_range].as[3-8].with[buy_price_factor].as[0.8-1]>
                - flag server drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>:<[default_npc_data]>
                - waituntil <server.sql_connections.contains[drustcraft]>
                - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_trader_npc` WHERE `npc_id` = <[npc_id]>;'
                - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_trader_npc`(`npc_id`, `trader_id`) VALUES(<[npc_id]>, "<[trader_id]>");'
                - run drustcraftt_npc_title def:<npc[<[npc_id]>]>|<proc[drustcraftp_job_trader_find_npc_trader_type].context[<npc[<[npc_id]>]>]>
                - run drustcraftt_job_trader_update_npc def:<npc[<[npc_id]>]>
                - narrate '<proc[drustcraftp_msg_format].context[success|NPC $e<[npc_id]> $ris now the trader type $e<[trader_id]>]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The NPC id $e<[npc_id]> $rdoes not exist or is not set to the job $etrader]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|You did not enter a NPC id]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader type $e<[trader_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No trader ID was entered]>'

      - case remnpc:
        - define npc_id:<context.args.get[2]||<empty>>
        - if <[npc_id]> != <empty>:
          - if <server.npcs.parse[id].contains[<[npc_id]>]> && <proc[drustcraftp_npc_job_get].context[<npc[<[npc_id]>]>]> == trader:
            - if <npc[<[npc_id]>].has_flag[drustcraft.job_trader.trader_id]>:
              - flag server drustcraft.job_trader.traders.<npc[<[npc_id]>].flag[drustcraft.job_trader.trader_id]>.npcs.<[npc_id]>:!

            - flag <npc[<[npc_id]>]> drustcraft.job_trader.trader_id:!
            - waituntil <server.sql_connections.contains[drustcraft]>
            - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_trader_npc` WHERE `npc_id` = <[npc_id]>;'
            - run drustcraftt_npc_title def:<npc[<[npc_id]>]>|<proc[drustcraftp_job_trader_find_npc_trader_type].context[<npc[<[npc_id]>]>]>
            - run drustcraftt_job_trader_update_npc def:<npc[<[npc_id]>]>
            - narrate '<proc[drustcraftp_msg_format].context[success|NPC $e<[npc_id]> $ris now an empty trader]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The NPC id $e<[npc_id]> $rdoes not exist or is not set to the job $etrader]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No NPC id was entered]>'

      - case items:
        - define trader_id:<context.args.get[2]||<empty>>
        - if <[trader_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>]>:
            - define editable:false
            - if !<server.has_flag[drustcraft.job_trader.traders.<[trader_id]>.owner]> || <server.flag[drustcraft.job_trader.traders.<[trader_id]>.owner]> == <player.uuid||console> || <context.server||false> || <player.has_permission[drustcraft.trader.override]||false>:
              - define editable:true

            - ~run drustcraftt_chatgui_clear
            - foreach <server.flag[drustcraft.job_trader.traders.<[trader_id]>.items].alphanumeric||<list[]>> as:item_id:
              - define line:<proc[drustcraftp_chatgui_value].context[<[item_id]>]>

              - if <[editable]>:
                - define 'line:<[line]><proc[drustcraftp_chatgui_button].context[rem|Rem|trader remitem <[trader_id]> <[item_id]>|Remove this item from the trader type]>'
              - ~run drustcraftt_chatgui_item def:<[line]>

            - ~run drustcraftt_chatgui_render 'def:trader items|Trader type items|<context.args.get[3]||1>'

          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader type $e<[trader_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No trader ID was entered]>'

      - case additem:
        - define trader_id:<context.args.get[2]||<empty>>
        - if <[trader_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>]>:
            - define item_id:<context.args.get[3]||<empty>>
            - if <[item_id]> != <empty>:
              - if <proc[drustcraftp_value_item_get].context[<[item_id]>]> > 0:
                - if !<server.flag[drustcraft.job_trader.traders.<[trader_id]>.items].contains[<[item_id]>]>:
                  - flag server drustcraft.job_trader.traders.<[trader_id]>.items:|:<[item_id]>
                  - waituntil <server.sql_connections.contains[drustcraft]>
                  - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_trader_item`(`trader_id`,`item`) VALUES("<[trader_id]>", "<[item_id]>");'
                  - narrate '<proc[drustcraftp_msg_format].context[success|The item $e<[item_id]> $ris now the traded by type $e<[trader_id]>]>'
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|The item id $e<[item_id]> $ris already traded by this type]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The item id $e<[item_id]> $rdoes not exist or does not have a value]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|You did not enter an item id]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader type $e<[trader_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No trader ID was entered]>'

      - case remitem:
        - define trader_id:<context.args.get[2]||<empty>>
        - if <[trader_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>]>:
            - define item_id:<context.args.get[3]||<empty>>
            - if <[item_id]> != <empty>:
              - if <server.flag[drustcraft.job_trader.traders.<[trader_id]>.items].contains[<[item_id]>]>:
                - flag server drustcraft.job_trader.traders.<[trader_id]>.items:<-:<[item_id]>
                - waituntil <server.sql_connections.contains[drustcraft]>
                - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_trader_item` WHERE `trader_id` = "<[trader_id]>" AND `item` = "<[item_id]>";'
                - narrate '<proc[drustcraftp_msg_format].context[success|The item $e<[item_id]> $ris no longer traded by type $e<[trader_id]>]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The item id $e<[item_id]> $ris not traded by this type]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|You did not enter an item id]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader type $e<[trader_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No trader ID was entered]>'

      - case restock:
        - define item_id:<context.args.get[2]||<empty>>
        - if <[item_id]> != <empty>:
          - if <[item_id].is_integer>:
            - if <server.npcs.parse[id].contains[<[item_id]>]>:
              - if <proc[drustcraftp_npc_job_get].context[<npc[<[item_id]>]>]> == trader:
                - run drustcraftt_job_trader_update_npc def:<npc[<[item_id]>]>
                - narrate '<proc[drustcraftp_msg_format].context[success|Restocking trader NPC $e<[item_id]>]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The NPC id $e<[item_id]> $ris not a trader]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The NPC id $e<[item_id]> $rwas not found]>'
          - else:
            - if <server.has_flag[drustcraft.job_trader.traders.<[item_id]>]>:
              - foreach <server.flag[drustcraft.job_trader.traders.<[item_id]>.npcs].keys||<list[]>> as:npc_id:
                - run drustcraftt_job_trader_update_npc def:<npc[<[npc_id]>]>
              - narrate '<proc[drustcraftp_msg_format].context[success|Restocking all $e<[item_id]> $rtraders]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The trader type $e<[item_id]> $rwas not found]>'
        - else:
          - ~run drustcraftt_job_trader_update
          - narrate '<proc[drustcraftp_msg_format].context[success|Restocking all traders]>'

      - default:
        - narrate '<proc[drustcraftp_msg_format].context[error|Unknown option. Try <queue.script.data_key[usage].parsed>]>'


drustcraftt_job_trader:
  type: task
  debug: false
  definitions: action|npc|player|data
  script:
    - choose <[action]>:
      - case add:
        - if <[data].size> >= 1:
          - if <server.has_flag[drustcraft.Job_trader.traders.<[data].get[1]>]>:
            - define default_npc_data:<map[].with[sell_range].as[3-8].with[sell_price_factor].as[1-1.4].with[buy_range].as[3-8].with[buy_price_factor].as[0.8-1]>
            - flag server drustcraft.job_trader.traders.<[data].get[1]>.npcs.<[npc].id>:<[default_npc_data]>
            - flag <[npc]> drustcraft.job_trader.trader_id:<[data].get[1]>
            - waituntil <server.sql_connections.contains[drustcraft]>
            - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_trader_npc` WHERE `npc_id` = <[npc].id>;'
            - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_trader_npc`(`npc_id`, `trader_id`) VALUES(<[npc].id>, "<[data].get[1]>");'
            - run drustcraftt_npc_title def:<[npc]>|<proc[drustcraftp_job_trader_find_npc_trader_type].context[<[npc]>]>
            - run drustcraftt_job_trader_update_npc def:<[npc]>
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader type $e<[data].get[1]> $rwas not found]>'

      - case remove:
        - define trader_id:<proc[drustcraftp_job_trader_find_npc_trader_type].context[<[npc]>]>
        - if <server.has_flag[drustcraft.job_trader.traders.<[trader_id]>.npcs]>:
          - flag server drustcraft.job_trader.traders.<[trader_id]>.npcs:<-:<[npc]>
        - waituntil <server.sql_connections.contains[drustcraft]>
        - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_trader_npc` WHERE `npc_id` = <[npc].id>;'

      - case init:
        - run drustcraftt_npc_title def:<[npc]>|<proc[drustcraftp_job_trader_find_npc_trader_type].context[<[npc]>]>

      - case click:
        - if <[npc].has_flag[drustcraft.job_trader.items]>:
          - define trade_items:<list[]>

          - foreach <[npc].flag[drustcraft.job_trader.items].keys> as:trade_item_id:
            - if <[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.max_uses]||9999> > 0:
              - define trade_items:|:trade[inputs=<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.inputs].get[1]||<item[air]>>|<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.inputs].get[2]||<item[air]>>;result=<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.result]>;max_uses=<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.max_uses]||9999>]

          - if <[trade_items].size> > 0:
            - opentrades <[trade_items]>
            - determine true

        - random:
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|I have nothing left to sell today]>'
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|Nothing left]>'
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|I<&sq>ve got nothing today]>'
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|I<&sq>m all cleaned out]>'

      - case close:
        - if <[npc].has_flag[drustcraft.job_trader.items]>:
          - foreach <[data].trades> as:trade:
            - if <[trade].uses> > 0:
              - foreach <[npc].flag[drustcraft.job_trader.items].keys> as:npc_trade_item_id:
                - if <[trade].inputs.get[1]||<item[air]>> == <[npc].flag[drustcraft.job_trader.items.<[npc_trade_item_id]>.inputs].get[1]||<item[air]>> && <[trade].inputs.get[2]||<item[air]>> == <[npc].flag[drustcraft.job_trader.items.<[npc_trade_item_id]>.inputs].get[2]||<item[air]>> && <[trade].result||<item[air]>> == <[npc].flag[drustcraft.job_trader.items.<[npc_trade_item_id]>.result]||<item[air]>>:
                  - flag <[npc]> drustcraft.job_trader.items.<[npc_trade_item_id]>.max_uses:-:<[trade].uses>
                  - foreach stop


drustcraftp_tabcomplete_traders:
  type: procedure
  debug: false
  script:
    - determine <server.flag[drustcraft.job_trader.traders].keys>


drustcraftp_tabcomplete_trader_npcs:
  type: procedure
  debug: false
  script:
    - determine <server.npcs.filter_tag[<proc[drustcraftp_npc_job_get].context[<[filter_value]>].equals[trader]>].parse[id]>


drustcraftp_tabcomplete_trader_active_npcs:
  type: procedure
  debug: false
  definitions: args
  script:
    - define npc_list:<list[]>
    - foreach <server.flag[drustcraft.job_trader.traders].keys||<list[]>> as:trader_id:
      - define npc_list:|:<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs].keys||<list[]>>
    - determine <[npc_list]>
