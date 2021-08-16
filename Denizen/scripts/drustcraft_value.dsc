  # Drustcraft - Values
# https://github.com/drustcraft/drustcraft

drustcraftw_value:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_value_load

    on script reload:
      - run drustcraftt_value_load


drustcraftt_value_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - debug ERROR "Drustcraft Value: Drustcraft Setting module is required to be installed"
      - stop
    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR "Drustcraft Value: Drustcraft Database module is required to be installed"
      - stop

    - waituntil <server.has_flag[drustcraft.module.setting]>
    - waituntil <server.has_flag[drustcraft.module.db]>

    - define create_tables:true
    - ~run drustcraftt_db_get_version def:drustcraft.value save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> != 1:
      - if <[version]> != null:
        - debug ERROR "Drustcraft Value: Unexpected database version"
        - stop
      - else:
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>value` (`material` VARCHAR(255) NOT NULL, `value` DOUBLE NOT NULL, UNIQUE (`material`));'
        - run drustcraftt_setting_set def:drustcraft.value.currency|<list[iron_ingot|emerald|diamond|emerald_block|netherite_ingot|netherite_block]>
        - run drustcraftt_db_set_version def:drustcraft.value|1

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>

      - run drustcraftt_tabcomplete_completion def:value|get|_*materials
      - run drustcraftt_tabcomplete_completion def:value|set|_*materials|_*value
      - run drustcraftt_tabcomplete_completion def:value|currency|add|_*materials
      - run drustcraftt_tabcomplete_completion def:value|currency|rem|_*materials

    - ~run drustcraftt_setting_get def:drustcraft.value.currency save:result
    - define currency_list:<entry[result].created_queue.determination.get[1]>
    - if <[currency_list]> == null:
      - define currency_list:<list[emerald]>

    - define material_values:<map[]>
    - ~sql id:drustcraft 'query:SELECT `material`,`value` FROM `<server.flag[drustcraft.db.prefix]>value`;' save:sql_result
    - if <entry[sql_result].result.size||0> >= 1:
      - foreach <entry[sql_result].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define material_name:<[row].get[1].unescaped||<empty>>
        - define material_value:<[row].get[2]||<empty>>

        - define material_values:<[material_values].with[<[material_name]>].as[<[material_value].unescaped>]>

      - flag server drustcraft.value.material:<[material_values]>
      - flag server drustcraft.module.value:<script[drustcraftw_value].data_key[version]>
    - else:
      - debug ERROR 'Drustcraft Value: There is no materials or currencies loaded from the database'
      - stop


drustcraftp_value_item_set:
  type: task
  debug: false
  definitions: material_name|material_value
  script:
    - waituntil <server.sql_connections.contains[drustcraft]>
    - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>value`(`material`,`value`) VALUES("<[material_name]>", <[material_value]>) ON DUPLICATE KEY UPDATE `material`="<[material_name]>", `value`=<[material_value]>;'
    - if <bungee.connected||false>:
      - bungeerun <bungee.list_servers> drustcraftt_value_load
    - else:
      - run drustcraftt_value_load


drustcraftp_value_item_get:
  type: procedure
  debug: false
  definitions: material_name
  script:
    - determine <server.flag[drustcraft.value.material.<[material_name]>]||-1>


drustcraftp_value_item_to_currency:
  type: procedure
  debug: false
  definitions: item_name|factor
  script:
    - define value:<proc[drustcraftp_value_item_get].context[<[item_name]>]>
    - if <[value]> > -1:
      - define currency:<proc[drustcraftp_value_to_currency].context[<[value].mul[<[factor]||1>]>]>
      - if <[currency]> != null:
        - determine <[currency].with[value].as[<[value]>]>

    - determine null


drustcraftp_value_item_to_currency_formatted:
  type: procedure
  debug: false
  definitions: item_name|factor
  script:
    - define value:<proc[drustcraftp_value_item_get].context[<[item_name]>]>
    - if <[value]> > 0:
      - define items:<proc[drustcraftp_value_to_currency].context[<[value].mul[<[factor]||1>]>]>

      - define 'formatted:$e<[items].get[min_qty]> <[item_name]>'
      - if <[items].get[min_qty]> != 1:
        - define formatted:<[formatted]>s

      - define 'formatted:<[formatted]> $rfor $e'

      - if <[items].keys.contains[item1]> && <[items].get[item1].material.name> != air:
        - define 'formatted:<[formatted]><[items].get[item1].quantity> <[items].get[item1].material.name>'
        - if <[items].get[item1].quantity> != 1:
          - define formatted:<[formatted]>s

      - if <[items].keys.contains[item2]> && <[items].get[item2].material.name> != air:
        - if <[items].keys.contains[item1]> && <[items].get[item1].material.name> != air:
          - define 'formatted:<[formatted]> $rand $e'

        - define 'formatted:<[formatted]><[items].get[item2].quantity> <[items].get[item2].material.name>'
        - if <[items].get[item2].quantity> != 1:
          - define formatted:<[formatted]>s

      - determine <[formatted]>

    - determine null


drustcraftp_value_to_currency:
  type: procedure
  debug: false
  definitions: value
  script:
    - define item_value_mod:0

    - define netherite_blocks:0
    - define netherite_ingots:0
    - define emeralds:0
    - define diamond:0
    - define copper_ingots:0
    - define iron_ingots:0
    - define min_qty:1

    - if <[value]> < 2:
      - define mod_list:<list[0|0.03|0.06|0.13|0.25|0.38|0.5|0.63|0.75|0.88|1|1.13|1.25|1.38|1.5|1.63|1.75|1.88|2]>
      - define min_items_list:<list[1|8|4|2|1|2|1|2|1|2|1|2|1|2|1|2|1|2|1]>
      - define iron_ingots_list:<list[0|1|1|1|1|3|2|5|3|7|4|9|5|11|6|13|7|15|8]>
      - define index:<[mod_list].filter[is[or_less].than[<[value]>]].size>

      - define min_qty:<[min_items_list].get[<[index]>]>
      - define iron_ingots:<[iron_ingots_list].get[<[index]>]>
    - else:
      - define netherite_blocks:<[value].div[117].round_down>
      - define value:<[value].sub[<[netherite_blocks].mul[117]>]>
      - define netherite_ingots:<[value].div[13].round_down>
      - define value:<[value].sub[<[netherite_ingots].mul[13]>]>
      - define item_value_mod:<[value].mod[1].round_to[2]>
      - define emeralds:<[value].round_down>
      - define iron_ingots:<[item_value_mod].round_to_precision[0.25].div[0.25].round_down>

    - if <[netherite_blocks]> <= 7 && <[netherite_blocks].mul[9].add[<[netherite_ingots]>]> <= 64:
      - define netherite_ingots:<[netherite_ingots].add[<[netherite_blocks].mul[9]>]>
      - define netherite_blocks:0
    - if <[netherite_ingots]> <= 4 && <[netherite_ingots].mul[13].add[<[emeralds]>]> <= 64:
      - define emeralds:<[emeralds].add[<[netherite_ingots].mul[13]>]>
      - define netherite_ingots:0
    - if <[iron_ingots]> > 0:
      - if <[iron_ingots].mod[4]> == 0 || <[netherite_blocks].add[<[netherite_ingots]>]> == 0:
        - define emeralds:<[emeralds].add[<[iron_ingots].div[4].round_down>]>
        - define iron_ingots:<[iron_ingots].mod[4].round_down>

    # 15% chance change iron ingots (if even) to copper ingot
    - if <[iron_ingots]> > 0 && <[iron_ingots].mod[2]> == 0:
      - if <util.random.int[0].to[100]> < 15:
        - define copper_ingots:<[iron_ingots].div[2]>
        - define iron_ingots:0

    # 33% change, change emeralds to copper ingots (if doesnt exceed 64 ingots)
    - if <util.random.int[0].to[100]> < 33:
      - if <[emeralds]> > 0 && <[emeralds]> < 33:
        - if <[copper_ingots].add[<[emeralds].mul[2]>]> <= 64:
          - define copper_ingots:<[copper_ingots].add[<[emeralds].mul[2]>]>
          - define emeralds:0

    # 15% chance, change emeralds to diamonds
    - if <[emeralds]> > 0:
      - if <util.random.int[0].to[100]> < 15:
        - define diamond:<[emeralds]>
        - define emeralds:0

    - define currency_list:<list[air|0|air|0]>
    - if <[iron_ingots]> > 0:
      - if <[iron_ingots]> > 64:
        - define currency_list:<[currency_list].include[iron_ingot|<[iron_ingots].sub[64]>|iron_ingot|64]>
      - else:
        - define currency_list:<[currency_list].include[iron_ingot|<[iron_ingots]>]>
    - if <[copper_ingots]> > 0:
      - if <[copper_ingots]> > 64:
        - define currency_list:<[currency_list].include[copper_ingot|<[copper_ingots].sub[64]>|copper_ingot|64]>
      - else:
        - define currency_list:<[currency_list].include[copper_ingot|<[copper_ingots]>]>
    - if <[emeralds]> > 0:
      - if <[emeralds]> > 64:
        - define currency_list:<[currency_list].include[emerald|<[emeralds].sub[64]>|emerald|64]>
      - else:
        - define currency_list:<[currency_list].include[emerald|<[emeralds]>]>
    - if <[diamond]> > 0:
      - if <[diamond]> > 64:
        - define currency_list:<[currency_list].include[diamond|<[diamond].sub[64]>|diamond|64]>
      - else:
        - define currency_list:<[currency_list].include[diamond|<[diamond]>]>
    - if <[netherite_ingots]> > 0:
      - if <[netherite_ingots]> > 64:
        - define currency_list:<[currency_list].include[netherite_ingot|<[netherite_ingots].sub[64]>|netherite_ingot|64]>
      - else:
        - define currency_list:<[currency_list].include[netherite_ingot|<[netherite_ingots]>]>
    - if <[netherite_blocks]> > 0:
      - if <[netherite_blocks]> > 64:
        - define currency_list:<[currency_list].include[netherite_block|<[netherite_blocks].sub[64]>|netherite_block|64]>
      - else:
        - define currency_list:<[currency_list].include[netherite_block|<[netherite_blocks]>]>

    - define currency_map:<map[].with[min_qty].as[<[min_qty]>]>
    - define item1qty:<[currency_list].get[<[currency_list].size>]>
    - define item1name:<[currency_list].get[<[currency_list].size.sub[1]>]>
    - define item2qty:<[currency_list].get[<[currency_list].size.sub[2]>]>
    - define item2name:<[currency_list].get[<[currency_list].size.sub[3]>]>

    - if <[item1name]> != air:
      - define currency_map:<map[<[currency_map]>].with[item1].as[<item[<[item1name]>[quantity=<[item1qty]>]]>]>
    - else:
      - if <[item2name]> == air:
        - determine null
      - else:
        - define currency_map:<map[<[currency_map]>].with[item1].as[<item[air]>]>

    - if <[item2name]> != air:
      - define currency_map:<map[<[currency_map]>].with[item2].as[<item[<[item2name]>[quantity=<[item2qty]>]]>]>
    - else:
      - define currency_map:<map[<[currency_map]>].with[item2].as[<item[air]>]>

    - determine <[currency_map]>


drustcraftc_value:
  type: command
  debug: false
  name: value
  description: Gets or sets item values
  usage: /value <&lt>get|set<&gt> <&lb>material<&rb>
  permission: drustcraft.value
  permission message: <&8>[<&c>!<&8>] <&c>I'm sorry, you do not have permission to perform this comman
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:value
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.value]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Drustcraft module not yet loaded. Check console for any errors]>'
      - stop

    - choose <context.args.get[1]||<empty>>:
      - case set:
        - define material:<context.args.get[2]||<empty>>
        - define value:<context.args.get[3]||0>

        - getmythicitems save:mythicitems

        - if <server.material_types.parse[name].contains[<[material]>]> || <entry[mythicitems].mythicitems.parse[type].contains[<[material]>]>:
          - if <[value].is_decimal>:
            - run drustcraftp_value_item_set def:<[material]>|<[value]>
            - narrate '<proc[drustcraftp_msg_format].context[success|The material/item $e<[material]> $rnow has a value of $e<[value]> $remeralds]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|A material/item value is required to be a decimal number]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The material/item $e<[material]> $rwas not found on this server]>'

      - default:
        - define material:<context.args.get[1]||<empty>>
        - if <[material]> == get:
          - define material:<context.args.get[2]||<empty>>

        - getmythicitems save:mythicitems

        - if <server.material_types.parse[name].contains[<[material]>]> || <entry[mythicitems].mythicitems.parse[type].contains[<[material]>]>:
          - define value:<proc[drustcraftp_value_item_get].context[<[material]>]>
          - if <[value]> > 0:
            - define formatted:<proc[drustcraftp_value_item_to_currency_formatted].context[<[material]>]>
            - define material:<[material].replace[_].with[<&sp>].to_sentence_case>
            - narrate '<proc[drustcraftp_msg_format].context[arrow|The material/item $e<[material]> $rhas a value of <[formatted]>]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[arrow|The material/item $e<[material]> $rhas no value]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The material/item $e<[material]> $rwas not found on this server]>'


drustcraftp_tab_complete_value:
  type: procedure
  debug: false
  script:
    - determine <list[0.05|0.1|0.2|0.5|1|2|3|5|10|15|20]>
