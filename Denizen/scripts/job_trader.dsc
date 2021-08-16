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

    - define create_tables:true
    - ~run drustcraftt_db_get_version def:drustcraft.job_trader save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> != 1:
      - if <[version]> != null:
        - debug ERROR "Drustcraft Job Trader: Unexpected database version. Ignoring DB storage"
      - else:
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_trader_type` (`trader_id` VARCHAR(128) NOT NULL, `title` VARCHAR(128) NOT NULL, `owner` VARCHAR(36) NOT NULL, PRIMARY KEY (`trader_id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_trader_item` (`id` INT NOT NULL AUTO_INCREMENT, `trader_id` VARCHAR(128) NOT NULL, `item` VARCHAR(128) NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_trader_npc` (`npc_id` INT NOT NULL, `trader_id` VARCHAR(128) NOT NULL, `sell_range` VARCHAR(9) NOT NULL DEFAULT "3-8", `sell_price_factor` VARCHAR(7) NOT NULL DEFAULT "1-1.4", `buy_range` VARCHAR(9) NOT NULL DEFAULT "3-8", `buy_price_factor` VARCHAR(7) NOT NULL DEFAULT "1-1.4", PRIMARY KEY (`npc_id`));'
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

    - run drustcraftt_job_trader_update
    - run drustcraftt_npc_job_register def:trader|drustcraftt_job_trader|Trader
    - flag server drustcraft.module.job_trader:<script[drustcraftw_job_trader].data_key[version]>

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>
      - run drustcraftt_tabcomplete_completion def:trader|list
      - run drustcraftt_tabcomplete_completion def:trader|create
      - run drustcraftt_tabcomplete_completion def:trader|remove|_*traders
      - run drustcraftt_tabcomplete_completion def:trader|info|_*traders

      - run drustcraftt_tabcomplete_completion def:npc|job|trader|_*traders

        # - run drustcraftt_tab_complete.completions def:shop|list
        # - run drustcraftt_tab_complete.completions def:shop|create
        # - run drustcraftt_tab_complete.completions def:shop|remove|_*shop_names
        # - run drustcraftt_tab_complete.completions def:shop|info|_*shop_names
        # - run drustcraftt_tab_complete.completions def:shop|setowner|_*shop_names|_*players
        # - run drustcraftt_tab_complete.completions def:shop|npc|_*shop_names|list
        # - run drustcraftt_tab_complete.completions def:shop|npc|_*shop_names|add|_*npcs
        # - run drustcraftt_tab_complete.completions def:shop|npc|_*shop_names|rem|_*npcs
        # - run drustcraftt_tab_complete.completions def:shop|item|_*shop_names|list
        # - run drustcraftt_tab_complete.completions def:shop|item|_*shop_names|add|_*materials
        # - run drustcraftt_tab_complete.completions def:shop|item|_*shop_names|rem|_*materials


drustcraftt_job_trader_update:
  type: task
  debug: false
  script:
    - waituntil <server.has_flag[drustcraft.module.value]>
    - foreach <server.flag[drustcraft.job_trader.traders].keys||<list[]>> as:trader_id:
      - foreach <server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs].keys||<list[]>> as:npc_id:
        - define target_npc:<npc[<[npc_id]>]>
        - flag <[target_npc]> drustcraft.job_trader.items:!

        # sell
        - define sell_item_count:<util.random.int[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.sell_range].before[-]>].to[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.sell_range].after[-]>]>
        - define item_list:<server.flag[drustcraft.job_trader.traders.<[trader_id]>.items]>

        - repeat <[sell_item_count]>:
          - define item:<[item_list].random>
          - define item_list:<-:<[item]>

          - define currency:<proc[drustcraftp_value_item_to_currency].context[<[item]>|<util.random.decimal[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.sell_price_factor].before[-]>].to[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.sell_price_factor].after[-]>].round_to[1]>]>
          - if <[currency]> != null:
            - define item:<item[<[item]>]>
            - adjust def:item quantity:<[currency].get[min_qty]>
            - define item_map:<map[].with[inputs].as[<list[<[currency].get[item1]>|<[currency].get[item2]>]>].with[result].as[<[item]>].with[max_uses].as[<proc[drustcraftp_job_trader_value_to_max_uses].context[<[currency].get[value]>]>]>

            - flag <[target_npc]> drustcraft.job_trader.items.<[value]>:<[item_map]>

        # buy
        - define buy_item_count:<util.random.int[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.buy_range].before[-]>].to[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.buy_range].after[-]>]>
        - define item_list:<server.flag[drustcraft.job_trader.traders.<[trader_id]>.items]>

        - repeat <[buy_item_count]>:
          - define item:<[item_list].random>
          - define item_list:<-:<[item]>

          - define currency:<proc[drustcraftp_value_item_to_currency].context[<[item]>|<util.random.decimal[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.buy_price_factor].before[-]>].to[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs.<[npc_id]>.buy_price_factor].after[-]>].round_to[1]>]>
          - if <[currency]> != null:
            - define item:<item[<[item]>]>
            - adjust def:item quantity:<[currency].get[min_qty]>
            - define item_map:<map[].with[inputs].as[<list[<[item]>|<item[air]>]>].with[result].as[<[currency].get[item1]>].with[max_uses].as[<proc[drustcraftp_job_trader_value_to_max_uses].context[<[currency].get[value]>]>]>

            - flag <[target_npc]> drustcraft.job_trader.items.<[value]>:<[item_map]>


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
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:trader
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case list:
        - ~run drustcraftt_chatgui_clear
        - foreach <server.flag[drustcraft.job_trader.traders].keys> as:trader_id:
          - define line:<proc[drustcraftp_chatgui_option].context[<[trader_id]>]>
          - define 'line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_trader.traders.<[trader_id]>.title]> (<server.flag[drustcraft.job_trader.traders.<[trader_id]>.items].size> items, <server.flag[drustcraft.job_trader.traders.<[trader_id]>.npcs].size> NPCs)]>'
          - define 'line:<[line]><proc[drustcraftp_chatgui_button].context[edit|Info|trader info <[trader_id]>|Show details about this trader]>'
          - ~run drustcraftt_chatgui_item def:<[line]>

        - ~run drustcraftt_chatgui_render 'def:trader list|Trader types|<context.args.get[3]||1>'

      - case create:
        - define trader_id:<context.args.get[2]||<empty>>
        - if <[trader_id]> != <empty>:
          - if !<server.flag[drustcraft.job_trader.traders].keys.contains[<[trader_id]>]>:
            - waituntil <server.sql_connections.contains[drustcraft]>
            - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_trader_type(`trader_id`, `title`, `owner`) VALUES("<[trader_id]>", "<[trader_id].to_sentence_case>", "<player.uuid||console>");'
            - flag server drustcraft.job_trader.traders.<[trader_id]>.title:<[trader_id]>
            - flag server drustcraft.job_trader.traders.<[trader_id]>.owner:<player.uuid||console>
            - flag server drustcraft.job_trader.traders.<[trader_id]>.items:<list[]>
            - flag server drustcraft.job_trader.traders.<[trader_id]>.npcs:<list[]>
            - narrate '<proc[drustcraftp_msg_format].context[success|The trader type $e<[trader_id]> $ras been added]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The trader id $e<[trader_id]> $ris already used]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|You need to enter a unique trader id]>'

#       - case remove delete del:
#         - define name:<context.args.get[2]||<empty>>
#         - if <[name]> != <empty>:
#           - if <yaml[drustcraft_shop].list_keys[shop].contains[<[name]>]||false>:
#             - yaml id:drustcraft_shop set shop.<[name]>:!
#             - run drustcraftt_shop.save
#             - narrate '<&e>The shop <&f><[name]> <&e>was deleted'
#           - else:
#             - narrate '<&e>The shop <&f><[name]> <&e>was not found'
#         - else:
#           - narrate '<&e>A shop name is required when deleting a shop'

#       - case info:
#         - define shop_name:<context.args.get[2]||<empty>>
#         - if <[shop_name]> != <empty>:
#           - run drustcraftt_chat_gui.title 'def:Shop: <[shop_name]>'

#           - define shop_info:<proc[drustcraftp_shop.info].context[<[shop_name]>]>
#           - if <[shop_info]> != <empty>:

#             # Owner
#             - define owner:<[shop_info].get[owner]||<empty>>
#             - define owner:<player[<[owner]>].name||<&c>(none)>
#             - define 'row:<&9>Owner: <&6><[owner]> <element[<&7><&lb>Edit<&rb>].on_click[/shop setowner <[shop_name]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
#             - narrate <[row]>

#             # NPCs
#             - define npc_list:<yaml[drustcraft_shop].read[npc].filter_tag[<[filter_value].equals[<[shop_name]>]>].keys||<list[]>>

#             - define 'row:<&9>NPCs: <&6><[npc_list].size> NPCs <element[<&7><&lb>View<&rb>].on_click[/shop npc <[shop_name]> list].on_hover[Click to view]> <element[<&a><&lb>Add<&rb>].on_click[/shop npc <[shop_name]> add ].type[SUGGEST_COMMAND].on_hover[Click to add]>'
#             - narrate <[row]>

#             # Items
#             - define item_list:<yaml[drustcraft_shop].read[shop.<[shop_name]>.items]||<list[]>>

#             - define 'row:<&9>Items: <&6><[item_list].size> items <element[<&7><&lb>View<&rb>].on_click[/shop item <[shop_name]> list].on_hover[Click to view]> <element[<&a><&lb>Add<&rb>].on_click[/shop item <[shop_name]> add ].type[SUGGEST_COMMAND].on_hover[Click to add]>'
#             - narrate <[row]>

#           - else:
#             - narrate '<&e>There was an error getting the shop information'
#         - else:
#           - narrate '<&e>No shop name was entered'

#       - case setowner:
#         - define shop_name:<context.args.get[2]||<empty>>
#         - if <[shop_name]> != <empty>:
#           - if <yaml[drustcraft_shop].list_keys[shop].contains[<[shop_name]>]||false>:
#             - define player_name:<context.args.get[3]||<empty>>
#             - if <[player_name]> != <empty>:
#               - define target_player:<server.match_offline_player[<[player_name]>]>
#               - if <[target_player].object_type> == Player && <[target_player].name> == <[player_name]>:
#                 - yaml id:drustcraft_shop set shop.<[shop_name]>.owner:<[target_player].uuid>
#                 - run drustcraftt_shop.save
#                 - narrate '<&e>The shop owner was updated'
#               - else:
#                 - narrate '<&e>The player <&f><[player_name]> <&e>was not found on this server'
#             - else:
#               - narrate '<&e>A new owner is required to be entered'
#           - else:
#             - narrate '<&e>The shop <&f><[shop_name]> <&e>was not found'
#         - else:
#           - narrate '<&e>No shop name was entered'

#       - case npc:
#         - define shop_name:<context.args.get[2]||<empty>>
#         - if <[shop_name]> != <empty>:
#           - if <yaml[drustcraft_shop].list_keys[shop].contains[<[shop_name]>]||false>:
#             - choose <context.args.get[3]||<empty>>:
#               - case list:
#                 - define page_no:<context.args.get[4]||1>
#                 - define npc_list:<yaml[drustcraft_shop].read[npc].filter_tag[<[filter_value].equals[<[shop_name]>]>].keys||<list[]>>

#                 - define npc_map:<map[]>
#                 - foreach <[npc_list]>:
#                   - define npc_map:<[npc_map].with[<[value]>].as[<npc[<[value]>].name||<&7>(not<&sp>found)>]>

#                 - run drustcraftt_chat_paginate 'def:<list[Shop <[shop_name]> NPCs|<[page_no]>].include_single[<[npc_map]>].include[shop npc <[shop_name]> list|<empty>|true|<empty>|shop npc <[shop_name]> rem]>'

#               - case add:
#                 - define npc_id:<context.args.get[4]||<empty>>
#                 - if <[npc_id]> != <empty>:
#                   - if <[npc_id].is_integer>:
#                     - if <server.npcs.parse[id].contains[<[npc_id]>]>:
#                       - yaml id:drustcraft_shop set npc.<[npc_id]>:<[shop_name]>
#                       - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_shop_interactor

#                       - ~run drustcraftt_shop.save
#                       - run drustcraftt_shop.update_inventories
#                       - narrate '<&e>The NPC now sells items from the shop <&f><[shop_name]>'
#                     - else:
#                       - narrate '<&e>The NPC Id was not found on this server'
#                   - else:
#                     - narrate '<&e>The NPC Id is invalid'
#                 - else:
#                   - if <player.selected_npc||<empty>> != <empty>:
#                     - yaml id:drustcraft_shop set npc.<player.selected_npc.id>:<[shop_name]>
#                     - run drustcraftt_npc.interactor def:<player.selected_npc.id>|drustcraftt_shop_interactor
#                     - run drustcraftt_shop.save
#                     - narrate '<&e>The NPC now sells items from the shop <&f><[shop_name]>'
#                   - else:
#                     - narrate '<&e>You require to enter a NPC Id or have an NPC selected'

#               - case del delete rem remove:
#                 - define npc_id:<context.args.get[4]||<empty>>
#                 - if <[npc_id]> != <empty>:
#                   - if <[npc_id].is_integer>:
#                     - if <server.npcs.parse[id].contains[<[npc_id]>]>:
#                       - yaml id:drustcraft_shop set npc.<[npc_id]>:!
#                       - run drustcraftt_npc.interactor def:<[npc_id]>|<empty>
#                       - run drustcraftt_shop.save

#                       - narrate '<&e>The NPC no longer sells items from the shop <&f><[shop_name]>'
#                     - else:
#                       - narrate '<&e>The NPC Id was not found on this server'
#                   - else:
#                     - narrate '<&e>The NPC Id is invalid'
#                 - else:
#                   - if <player.selected_npc||<empty>> != <empty>:
#                     - yaml id:drustcraft_shop set npc.<player.selected_npc.id>:!
#                     - run drustcraftt_npc.interactor def:<player.selected_npc.id>|<empty>
#                     - run drustcraftt_shop.save
#                     - narrate '<&e>The NPC no longer sells items from the shop <&f><[shop_name]>'
#                   - else:
#                     - narrate '<&e>You require to enter a NPC Id or have an NPC selected'

#               - default:
#                 - narrate '<&e>The shop npc action is unknown. Try <&lt>list|add|rem<&gt>'
#           - else:
#             - narrate '<&e>The shop <&f><[shop_name]> <&e>was not found'
#         - else:
#           - narrate '<&e>No shop name was entered'

#       - case item:
#         - define shop_name:<context.args.get[2]||<empty>>
#         - if <[shop_name]> != <empty>:
#           - if <yaml[drustcraft_shop].list_keys[shop].contains[<[shop_name]>]||false>:
#             - choose <context.args.get[3]||<empty>>:
#               - case list:
#                 - define page_no:<context.args.get[4]||1>
#                 - define item_list:<yaml[drustcraft_shop].read[shop.<[shop_name]>.items]||<list[]>>

#                 - run drustcraftt_chat_paginate 'def:<list[Shop <[shop_name]> Items|<[page_no]>].include_single[<[item_list]>].include[shop item <[shop_name]> list|<empty>|true|<empty>|shop item <[shop_name]> rem]>'

#               - case add:
#                 - define item:<context.args.get[4]||<empty>>
#                 - if <[item]> != <empty>:
#                   - if <server.material_types.parse[name].contains[<[item]>]>:
#                     - if <yaml[drustcraft_shop].read[shop.<[shop_name]>.items].contains[<[item]>]||false> == false:
#                       - yaml id:drustcraft_shop set shop.<[shop_name]>.items:->:<[item]>
#                       - run drustcraftt_shop.save
#                       - narrate '<&e>The shop <&f><[shop_name]> <&e>now sells <&f><[item]>'
#                     - else:
#                       - narrate '<&e>The item <&f><[item]> <&e>is already added to this shop'
#                   - else:
#                     - narrate '<&e>The item <&f><[item]> <&e>was not found on this server'
#                 - else:
#                   - narrate '<&e>You require to enter a item to add to the shop'

#               - case del delete rem remove:
#                 - define item:<context.args.get[4]||<empty>>
#                 - if <[item]> != <empty>:
#                   - if <server.material_types.parse[name].contains[<[item]>]>:
#                     - if <yaml[drustcraft_shop].read[shop.<[shop_name]>.items].contains[<[item]>]||false>:
#                       - yaml id:drustcraft_shop set shop.<[shop_name]>.items:<-:<[item]>
#                       - run drustcraftt_shop.save
#                       - narrate '<&e>The shop <&f><[shop_name]> <&e>no longer sells <&f><[item]>'
#                     - else:
#                       - narrate '<&e>The item <&f><[item]> <&e>is not listed in this shop'
#                   - else:
#                     - narrate '<&e>The item <&f><[item]> <&e>was not found on this server'
#                 - else:
#                   - narrate '<&e>You require to enter a item to remove from the shop'

#               - default:
#                 - narrate '<&e>The shop npc action is unknown. Try <&lt>list|add|rem<&gt>'
#           - else:
#             - narrate '<&e>The shop <&f><[shop_name]> <&e>was not found'
#         - else:
#           - narrate '<&e>No shop name was entered'

      - default:
        - narrate '<proc[drustcraft_msg_format].context[error|Unknown option. Try <queue.script.data_key[usage].parsed>]>'


drustcraftt_job_trader:
  type: task
  debug: false
  definitions: action|npc|player|data
  script:
    - choose <[action]>:
      - case init:
        - run drustcraftt_npc_title def:<[npc]>|<proc[drustcraftp_job_trader_find_npc_trader_type].context[<[npc]>]>

      - case click:
        - if <[npc].has_flag[drustcraft.job_trader.items]>:
          - define trade_items:<list[]>

          - foreach <[npc].flag[drustcraft.job_trader.items].keys> as:trade_item_id:
            - if <[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.max_uses]||9999> > 0:
              - define trade_items:|:trade[inputs=<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.inputs].get[1]||<item[air]>>|<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.inputs].get[2]||<item[air]>>;result=<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.result]>;max_uses=<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.max_uses]||9999>]
              - narrate inputs=<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.inputs].get[1]||<item[air]>>|<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.inputs].get[2]||<item[air]>>;result=<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.result]>;max_uses=<[npc].flag[drustcraft.job_trader.items.<[trade_item_id]>.max_uses]||9999>

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
