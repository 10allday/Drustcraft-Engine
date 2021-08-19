# Drustcraft - Chat
# https://github.com/drustcraft/drustcraft

# MOTD - Sound: ENTITY_FIREWORK_LAUNCH 1F 0.1F
# Annoucements - Chat_Sound: ENTITY_ARROW_HIT_PLAYER 1.0F 0.1F
# Private msg - #Sound: ENTITY_CHICKEN_EGG 1F 1.5F

# delete 'ignored' text
# replace ! to i
# remove non alpha characters
# check for match

#3 <Mod>
#d <Workshop>
#2 <Guild>
#e NPC
#f All
#6 SERVER
#4 RESERVED
#c RESERVED

# All
# Guild
# Clan
# Mod
# PM
# Workshop

# /chat - list joined and default channel
# /chat join <channel>
# /chat leave <channel>
# /chat <channel> - change default channel

# /r <msg>
# /pm <player> <msg>


# drustcraft.chat.disabled / player cannot chat - server
# drustcraft.chat.muted / player cannot chat - muted
# drustcraft.chat.channels / list of channels player is in
# drustcraft.chat.default_channel / players default channel

# TODO: Need option to ignore items such as the website address in URL
# TODO: /silent then rejoin did not set default channel


drustcraftw_chat:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_chat_load

    on script reload:
      - run drustcraftt_chat_load

    after player joins:
      - wait 10t
      - flag <player> drustcraft.chat.disabled:true
      - flag <player> drustcraft.chat.start_location:<player.location>
      - flag <player> drustcraft.chat.channels:!
      - flag <player> drustcraft.chat.default_channel:!

      - run drustcraftt_chat_join def:<player>|all|all
      - run drustcraftt_chat_default def:<player>|all

      - if <player.in_group[role_mod]>:
        - run drustcraftt_chat_join def:<player>|mod|mod
        - narrate '<proc[drustcraftp_msg_format].context[success|You have joined the $emod $rchat channel]>'

      - if <server.has_flag[drustcraft.chat.muted.<player.uuid>]>:
        - flag <player> drustcraft.chat.muted:true

    on player chats priority:-1 flagged:drustcraft.chat.disabled:
      - if <player.location.distance_squared[<player.flag[drustcraft.chat.start_location]>]> >= 20 || <player.location.world> != <player.flag[drustcraft.chat.start_location].world>:
        - flag player drustcraft.chat.disabled:!
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|You cannot send messages until you move some distance]>'
        - determine CANCELLED

    on player chats:
      - if <server.has_flag[drustcraft.module.chat]||false>:
        - define type:chat
        - define sender:<player.uuid>
        - define receiver:<empty>
        - define content:<context.message.sql_escaped>
        - define channel:<proc[drustcraftp_chat_default].context[<player>]>
        - define rule:<proc[drustcraftp_chat_filter].context[<[content]>]>

        - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chat_log` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'
        - if <[rule]> == <empty>:
          - define message:<context.message>

          - if <player.has_flag[drustcraft.chat.muted]>:
            - define duration:<player.flag_expiration[drustcraft.chat.muted]||<empty>>
            - if <[duration]> != <empty>:
              - narrate '<proc[drustcraftp_msg_format].context[error|You cannot sent messages as you are muted for another $e<player.flag_expiration[drustcraft.chat.muted].from_now.formatted>]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|You cannot send message as you are permanently muted]>'
            - determine CANCELLED

          - if <[channel]> != null:
            - define 'channel_title:<proc[drustcraftp_chat_channel_title_from_id].context[<player>|<[channel]>]> <&gt> '

            - if <[channel]> == all:
              - define channel_title:<empty>

            - define player_list:<server.online_players.filter_tag[<proc[drustcraftp_chat_channel_ids].context[<[filter_value]>].contains[<[channel]>]>].filter_tag[<[filter_value].has_flag[drustcraft.chat.muted].not>]>
            - if <[player_list].size> > 1:
              - if <player.has_flag[drustcraft.chat.last]> && <player.flag[drustcraft.chat.last].from_now.in_seconds> < <server.flag[drustcraft.chat.time_between]>:
                - narrate '<proc[drustcraftp_msg_format].context[error|Please wait at least $e<server.flag[drustcraft.chat.time_between]> $rseconds between messages]>'
                - determine CANCELLED
              - else:
                - flag <player> drustcraft.chat.last:<util.time_now>
                - determine passively RECIPIENTS:<[player_list]>
                - determine passively FORMAT:drustcraftf_chat
                - determine '<[channel_title]><player.chat_prefix.parse_color><player.name><&f>: <[message].strip_color>'
            - else:
              - if <[channel]> == null:
                - narrate '<proc[drustcraftp_msg_format].context[error|You are not connected to any chat channels]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|There is no online players in the chat channel $e<proc[drustcrafp_chat_channel_id_to_name].context[<player>|<[channel]>]>]>'
              - determine CANCELLED
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|You are not connected to any chat channels. Try $e/chat join all]>'
            - determine CANCELLED
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|Your message was not sent as it breaks the rule: $e<[rule]>]>'
          - if <server.has_flag[drustcraft.chat.rule_command]>:
            - execute as_server <server.flag[drustcraft.chat.rule_command].replace_text[$PLAYER$].with[<player.name>].replace_text[$RULE$].with[<[rule]>]>
          - determine CANCELLED
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|Chat is currently disabled]>'
        - determine CANCELLED

    on command priority:-1 flagged:drustcraft.chat.disabled:
      - if <player.location.distance_squared[<player.flag[drustcraft.chat.start_location]>]> >= 20 || <player.location.world> != <player.flag[drustcraft.chat.start_location].world>:
        - flag player drustcraft.chat.disabled:!
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|You cannot run commands until you move some distance]>'
        - determine CANCELLED

    on command:
      - if <server.has_flag[drustcraft.module.chat]||false> && <context.source_type> == PLAYER:
        - define type:command
        - define sender:<player.uuid>
        - define receiver:<empty>
        - define 'content:<context.command.sql_escaped> <context.raw_args.sql_escaped>'
        - define channel:<empty>
        - define rule:<empty>

        - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chat_log` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'
      - else if <context.source_type> == PLAYER:
        - narrate '<proc[drustcraftp_msg_format].context[error|Commands from players are currently disabled]>'
        - determine CANCELLED

    on player changes sign:
      - if <server.has_flag[drustcraft.module.chat]||false>:
        - define type:sign
        - define sender:<player.uuid>
        - define receiver:<context.location.x.round>,<context.location.y.round>,<context.location.z.round>,<context.location.world.name>
        - define content:<context.new>
        - define channel:<empty>
        - define rule:<proc[drustcraftp_chat_filter].context[<[content]>]>

        - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chat_log` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'
        - if <[rule]> != <empty>:
          - narrate '<proc[drustcraftp_msg_format].context[error|The sign text was not updated as it breaks the rule: $e<[rule]>]>'
          - if <server.has_flag[drustcraft.chat.rule_command]>:
            - execute as_server <server.flag[drustcraft.chat.rule_command].replace_text[$PLAYER$].with[<player.name>].replace_text[$RULE$].with[<[rule]>]>
          - determine CANCELLED
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|Chat is currently disabled]>'
        - determine CANCELLED

    on player edits book:
      - if <server.has_flag[drustcraft.module.chat]||false>:
        - define type:book
        - define sender:<player.uuid>
        - define receiver:<empty>
        - define content:<context.title>|<context.book>
        - define channel:<empty>
        - define rule:<proc[drustcraftp_chat_filter].context[<[content]>]>

        - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chat_log` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'
        - if <[rule]> != <empty>:
          - narrate '<proc[drustcraftp_msg_format].context[error|The book text was not updated as it breaks the rule: $e<[rule]>]>'
          - if <server.has_flag[drustcraft.chat.rule_command]>:
            - execute as_server <server.flag[drustcraft.chat.rule_command].replace_text[$PLAYER$].with[<player.name>].replace_text[$RULE$].with[<[rule]>]>
          - determine CANCELLED

      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|Chat is currently disabled]>'
        - determine CANCELLED


drustcraftf_chat:
  type: format
  format: <text>


drustcraftt_chat_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - debug ERROR 'Drustcraft Chat requires Drustcraft Setting installed'
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR 'Drustcraft Chat requires Drustcraft DB installed'
      - stop

    - define create_tables:true
    - ~run drustcraftt_db_get_version def:drustcraft.chat save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> != 1:
      - if <[version]> == null:
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>chat_log` (`id` INT NOT NULL AUTO_INCREMENT, `server` VARCHAR(255) NOT NULL, `world` VARCHAR(255) NOT NULL, `date` INT NOT NULL, `type` VARCHAR(255) NOT NULL, `sender` VARCHAR(255) NOT NULL, `receiver` VARCHAR(255) NOT NULL, `content` TEXT NOT NULL, `channel` VARCHAR(255) NOT NULL, `rule` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`)) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>chat_rule` (`id` INT NOT NULL AUTO_INCREMENT, `rule` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`)) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>chat_filter` (`id` INT NOT NULL AUTO_INCREMENT, `text` VARCHAR(255) NOT NULL, `rule_id` INT NOT NULL, PRIMARY KEY (`id`)) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>chat_ignore` (`id` INT NOT NULL AUTO_INCREMENT, `text` VARCHAR(255) NOT NULL, `rule_id` INT NOT NULL, PRIMARY KEY (`id`)) CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>chat_muted` (`id` INT NOT NULL AUTO_INCREMENT, `uuid` VARCHAR(255) NOT NULL, `until` INT NOT NULL, PRIMARY KEY (`id`));'
        - run drustcraftt_db_set_version def:drustcraft.chat|1

    # load filter
    - ~sql id:drustcraft 'query:SELECT `text`,`rule` FROM `<server.flag[drustcraft.db.prefix]>chat_filter` LEFT JOIN `<server.flag[drustcraft.db.prefix]>chat_rule` ON `<server.flag[drustcraft.db.prefix]>chat_filter`.`rule_id` = `<server.flag[drustcraft.db.prefix]>chat_rule`.`id`;' save:sql_result
    - if <entry[sql_result].result.size||0> >= 1:
      - foreach <entry[sql_result].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define text:<[row].get[1].unescaped||<empty>>
        - define rule:<[row].get[2].unescaped||<empty>>

        - flag server drustcraft.chat.filter.<[rule]>.filter:->:<[text]>

    - ~sql id:drustcraft 'query:SELECT `text`,`rule` FROM `<server.flag[drustcraft.db.prefix]>chat_ignore` LEFT JOIN `<server.flag[drustcraft.db.prefix]>chat_rule` ON `<server.flag[drustcraft.db.prefix]>chat_ignore`.`rule_id` = `<server.flag[drustcraft.db.prefix]>chat_rule`.`id`;' save:sql_result
    - if <entry[sql_result].result.size||0> >= 1:
      - foreach <entry[sql_result].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define text:<[row].get[1].unescaped||<empty>>
        - define ignore:<[row].get[2].unescaped||<empty>>

        - flag server drustcraft.chat.filter.<[rule]>.ignore:->:<[text]>

    # load mutes
    - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>chat_muted` WHERE `until` <&lt> <server.current_time_millis.div[1000].round_down>;'
    - ~sql id:drustcraft 'query:SELECT `uuid`,`until` FROM `<server.flag[drustcraft.db.prefix]>chat_muted`;' save:sql_result
    - if <entry[sql_result].result.size||0> >= 1:
      - foreach <entry[sql_result].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define uuid:<[row].get[1]||<empty>>
        - define until:<[row].get[2]||<empty>>

        - if <[until]> != -1:
          - flag server drustcraft.chat.muted.<[uuid]>:true expire:<proc[drustcraftp_util_epoch_to_time].context[<[until]>].duration_since[<util.time_now>]>
        - else:
          - flag server drustcraft.chat.muted.<[uuid]>:true

    - if <server.has_flag[drustcraft.chat.muted]>:
      - foreach <server.online_players>:
        - if <server.has_flag[drustcraft.chat.muted.<[value].uuid>]>:
          - flag <player> drustcraft.chat.muted:true expire:<server.flag_expiration[drustcraft.chat.muted.<[value].uuid>]>

    - flag server drustcraft.chat.channels.all.title:<&7>All

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>

      - run drustcraftt_tabcomplete_completion def:pm|_*onlineplayers
      - run drustcraftt_tabcomplete_completion def:chat|join|_*channels
      - run drustcraftt_tabcomplete_completion def:chat|leave|_*channels
      - run drustcraftt_tabcomplete_completion def:chat|default|_*channels
      - run drustcraftt_tabcomplete_completion def:chat|_*channels
      - run drustcraftt_tabcomplete_completion def:mute|_*players|_*durations
      - run drustcraftt_tabcomplete_completion def:unmute|_*mutedplayers

    - waituntil <server.has_flag[drustcraft.module.setting]>
    - ~run drustcraftt_setting_get def:drustcraft.chat.time_between|2 save:result
    - flag server drustcraft.chat.time_between:<entry[result].created_queue.determination.get[1]>

    - flag server drustcraft.module.chat:<script[drustcraftw_chat].data_key[version]>
    - run drustcraftt_chat_register def:all|<&7>All|drustcraftp_chat_channel_all
    - run drustcraftt_chat_register def:mod|<&2>Mod|drustcraftp_chat_channel_mod


drustcraftp_tabcomplete_channels:
  type: procedure
  debug: false
  script:
    - determine <server.flag[drustcraft.chat.registrations].keys>


drustcraftp_chat_filter:
  type: procedure
  debug: false
  definitions: text
  script:
    - foreach <server.flag[drustcraft.chat.filter].keys||<list[]>> as:rule:
      - foreach <server.flag[drustcraft.chat.filter.<[rule]>.ignore]||<list[]>> as:ignore:
        - if <[text].contains_text[<[ignore]>]>:
          - determine <empty>

      - foreach <server.flag[drustcraft.chat.filter.<[rule]>.filter]||<list[]>> as:filter:
        - if <[text].contains_text[<[filter]>]>:
          - determine <[rule]>

    - determine <empty>


drustcraftt_chat_register:
  type: task
  debug: false
  definitions: name|title|task_name
  script:
    - flag server drustcraft.chat.registrations.<[name]>.task:<[task_name]>
    - flag server drustcraft.chat.registrations.<[name]>.title:<[title]>


drustcraftp_chat_channel_all:
  type: procedure
  debug: false
  definitions: player|name
  script:
    - determine all


drustcraftp_chat_channel_mod:
  type: procedure
  debug: false
  definitions: player|name
  script:
    - if <player.in_group[role_mod]>:
      - determine mod
    - determine null


drustcraftt_chat_join:
  type: task
  debug: false
  definitions: player|name|id|silent
  script:
    - flag <[player]> drustcraft.chat.channels.ids.<[id]>:<server.flag[drustcraft.chat.registrations.<[name]>.title]||<[id]>>
    - flag <[player]> drustcraft.chat.channels.names.<[name]>:<[id]>
    - if <[silent].exists> && !<[silent]>:
      - narrate '<proc[drustcraftp_msg_format].context[success|You have joined the $e<[name]> $rchat channel]>' targets:<[player]>

    - if !<[player].has_flag[drustcraft.chat.default_channel]> || <[player].flag[drustcraft.chat.default_channel]> == null:
      - flag <[player]> drustcraft.chat.default_channel:<[id]>
      - if <[silent].exists> && !<[silent]>:
        - narrate '<proc[drustcraftp_msg_format].context[success|Your default channel is now $e<[name]>]>' targets:<[player]>


drustcraftt_chat_leave:
  type: task
  debug: false
  definitions: player|name|silent
  script:
    - if <[player].has_flag[drustcraft.chat.channels.names.<[name]>]>:
      - if <[silent].exists> && !<[silent]>:
        - narrate '<proc[drustcraftp_msg_format].context[warning|You have left the $e<[name]> $rchat channel]>'

      - define id:<[player].flag[drustcraft.chat.channels.names.<[name]>]>
      - flag <[player]> drustcraft.chat.channels.names.<[name]>:!
      - flag <[player]> drustcraft.chat.channels.ids.<[id]>:!

      - if <[player].has_flag[drustcraft.chat.default_channel]> && <[player].flag[drustcraft.chat.default_channel]> == <[id]>:
        - if <[player].has_flag[drustcraft.chat.channels.ids.all]>:
          - flag <[player]> drustcraft.chat.default_channel:all
        - else if <[player].has_flag[drustcraft.chat.channels.ids]>:
          - flag <[player]> drustcraft.chat.default_channel:<[player].flag[drustcraft.chat.channels.ids].get[1]||null>
        - else:
          - flag <[player]> drustcraft.chat.default_channel:!


drustcraftt_chat_default:
  type: task
  debug: false
  definitions: player|name|silent
  script:
    - if <[player].has_flag[drustcraft.chat.channels.names.<[name]>]>:
      - define id:<[player].flag[drustcraft.chat.channels.names.<[name]>]>
      - flag <[player]> drustcraft.chat.default_channel:<[id]>
      - if <[silent].exists> && !<[silent]>:
        - narrate '<proc[drustcraftp_msg_format].context[success|Your default channel is now $e<[name]>]>' targets:<[player]>


drustcraftp_chat_default:
  type: procedure
  debug: false
  definitions: player
  script:
    - determine <[player].flag[drustcraft.chat.default_channel]||null>


drustcraftp_chat_channel_names:
  type: procedure
  debug: false
  definitions: player
  script:
    - determine <[player].flag[drustcraft.chat.channels.names].keys||<list[]>>


drustcraftp_chat_channel_ids:
  type: procedure
  debug: false
  definitions: player
  script:
    - determine <[player].flag[drustcraft.chat.channels.ids].keys||<list[]>>


drustcraftp_chat_channel_title_from_id:
  type: procedure
  debug: false
  definitions: player|id
  script:
    - determine <[player].flag[drustcraft.chat.channels.ids.<[id]>]||<[id]>>


drustcrafp_chat_channel_id_to_name:
  type: procedure
  debug: false
  definitions: player|id
  script:
    - define channels:<[player].flag[drustcraft.chat.channels.names].filter_tag[<[filter_value].equals[<[id]>]>]>
    - if <[channels].size> >= 1:
      - determine <[channels].invert.get[<[id]>]||null>
    - determine null


drustcraftt_chat_mute_player:
  type: task
  debug: false
  definitions: player|duration
  script:
    - if <[duration].exists> && <[duration]> != -1 && <[duration]> != perm:
      - flag <[player]> drustcraft.chat.muted:true expires:<util.time_now.add[<[duration]>]>
    - else:
      - flag <[player]> drustcraft.chat.muted:true


drustcraftt_chat_unmute_player:
  type: task
  debug: false
  definitions: player
  script:
    - flag <[player]> drustcraft.chat.muted:!


drustcraftc_chat:
  type: command
  debug: false
  name: chat
  description: Announces text across the network
  usage: /chat (join|leave|channel) (channel)
  permission: drustcraft.chat
  permission message: <&8>[<&c>!<&8>] <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:chat
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||null>:
      - case join:
        - define name:<context.args.get[2]||<empty>>
        - if <[name]> != <empty>:
          - if <server.has_flag[drustcraft.chat.registrations.<[name]>.task]>:
            - define id:<proc[<server.flag[drustcraft.chat.registrations.<[name]>.task]>].context[<player>|<[name]>]>
            - if <[id]> != null:
              - if !<proc[drustcraftp_chat_channel_ids].context[<player>].contains[<[id]>]>:
                - run drustcraftt_chat_join def:<player>|<[name]>|<[id]>|false
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You are already connected to this chat channel]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|You are not permitted to join this chat channel]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The chat channel $e<[id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|A chat channel is required]>'

      - case leave:
        - define name:<context.args.get[2]||<empty>>
        - if <[name]> != <empty>:
          - if <server.has_flag[drustcraft.chat.registrations.<[name]>.task]>:
            - define id:<proc[<server.flag[drustcraft.chat.registrations.<[name]>.task]>].context[<player>|<[name]>]>
            - if <[id]> != null:
              - if <proc[drustcraftp_chat_channel_ids].context[<player>].contains[<[id]>]>:
                - run drustcraftt_chat_leave def:<player>|<[name]>|false
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You are not connected to this chat channel]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|You are not permitted to leave this chat channel]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The channel $e<[name]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|A chat channel is required]>'

      - case default:
        - define name:<context.args.get[2]||<empty>>
        - if <[name]> != <empty>:
          - if <server.has_flag[drustcraft.chat.registrations.<[name]>.task]>:
            - define id:<proc[<server.flag[drustcraft.chat.registrations.<[name]>.task]>].context[<player>|<[name]>]>
            - if <[id]> != null && <proc[drustcraftp_chat_channel_ids].context[<player>].contains[<[id]>]>:
              - run drustcraftt_chat_default def:<player>|<[name]>|false
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|You are not connected to this chat channel]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The chat channel $e<[id]> $rwas not found]>'
        - else:
          - if <player.has_flag[drustcraft.chat.default_channel]>:
            - narrate '<proc[drustcraftp_msg_format].context[info|Your default channel is $e<player.flag[drustcraft.chat.channels.<player.flag[drustcraft.chat.default_channel]>]>]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[info|You are not connected to any chat channels]>'

      - case null:
        - define channels:<player.flag[drustcraft.chat.channels.ids]>
        - define default_channel:<proc[drustcraftp_chat_default].context[<player>]>

        - if <[channels].keys.contains[<[default_channel]>]>:
          - define channels:<[channels].with[<[default_channel]>].as[<[channels].get[<[default_channel]>]>*]>
        - if <[channels].values.size> > 0:
          - narrate '<proc[drustcraftp_msg_format].context[info|You are connected to the following chat channels: <[channels].values.separated_by[<&f>,<&sp>]>]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[info|You are not connected to any chat channels]>'

      - default:
        - narrate '<proc[drustcraftp_msg_format].context[error|Unknown option. Try <queue.script.data_key[usage].parsed>]>'


drustcraftc_chat_announce:
  type: command
  debug: false
  name: announce
  description: Announces text across the network
  usage: /announce <&lt>text<&gt>
  permission: drustcraft.announce
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:announce
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if <context.args.size||0> > 0:
      - playsound <server.online_players> sound:ENTITY_ARROW_HIT_PLAYER volume:1.0 pitch:0.1
      - narrate '<&6>[!!!] <context.args.space_separated>' targets:<server.online_players>
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|No message was entered]>'


drustcraftc_chat_pm:
  type: command
  debug: false
  name: pm
  aliases:
    - t
    - tell
    - msg
  description: Sends a message to a player
  usage: /pm <&lt>player<&gt> <&lt>text<&gt>
  permission: drustcraft.pm
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:pm
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if <context.args.size||0> == 0:
      - narrate '<proc[drustcraftp_msg_format].context[error|No player was entered to message]>'
    - else if <context.args.size||0> == 1:
      - narrate '<proc[drustcraftp_msg_format].context[error|No message was entered]>'
    - else:
      - define target_player:<context.args.get[1]||<empty>>
      - define message:<context.args.remove[1].space_separated>

      - define target_player:<server.match_player[<[target_player]>]||<empty>>
      - if <[target_player].object_type> == PLAYER && <[target_player].name> == <context.args.get[1]>:
        - if <server.has_flag[drustcraft.module.chat]||false>:
          - if !<player.has_flag[drustcraft.chat.muted]>:
            - if !<[target_player].has_flag[drustcraft.chat.muted]> || <player.has_permission[drustcraft.mute.override]>:
              - define 'type:private message'
              - define sender:<player.uuid>
              - define receiver:<[target_player].uuid>
              - define content:<[message]>
              - define channel:<empty>
              - define rule:<proc[drustcraftp_chat_filter].context[<[content]>]>

              - waituntil <server.sql_connections.contains[drustcraft]>
              - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chat_log` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'

              - if <[rule]> == <empty>:
                - narrate '<&7>You <&gt> <[target_player].name><&f>: <[message].strip_color>'

                - playsound <[target_player]> sound:ENTITY_CHICKEN_EGG volume:1.0 pitch:1.5
                - narrate '<&7><player.name> <&gt> You<&f>: <[message].strip_color>' targets:<[target_player]>
                - flag <[target_player]> drustcraft.chat.last_pm:<player>
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You message was not sent as it breaks the rule: $e<[rule]>]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[target_player].name> $rcannot receive messages as they are muted]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|You cannot send messages as you are muted]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|Chat is currently disabled]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[1]> $rwas not found online]>'


drustcraftc_chat_reply:
  type: command
  debug: false
  name: r
  aliases:
    - reply
  description: Replies to the last message from a player
  usage: /r <&lt>text<&gt>
  permission: drustcraft.pm
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:r
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if <context.args.size||0> == 0:
      - narrate '<proc[drustcraftp_msg_format].context[error|No message was entered]>'
    - else:
      - if <player.has_flag[drustcraft.chat.last_pm]>:
        - if <server.online_players.contains[<player.flag[drustcraft.chat.last_pm]>]>:
          - define target_player:<player.flag[drustcraft.chat.last_pm]>
          - define message:<context.args.space_separated>

          - if <server.has_flag[drustcraft.module.chat]||false>:
            - if !<player.has_flag[drustcraft.chat.muted]>:
              - if !<[target_player].has_flag[drustcraft.chat.muted]> || <player.has_permission[drustcraft.mute.override]>:
                - define 'type:private message'
                - define sender:<player.uuid>
                - define receiver:<[target_player].uuid>
                - define content:<[message]>
                - define channel:<empty>
                - define rule:<proc[drustcraftp_chat_filter].context[<[content]>]>

                - waituntil <server.sql_connections.contains[drustcraft]>
                - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chat_log` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'

                - if <[rule]> == <empty>:
                  - narrate '<&7>You <&gt> <[target_player].name><&f>: <[message].strip_color>'

                  - playsound <[target_player]> sound:ENTITY_CHICKEN_EGG volume:1.0 pitch:1.5
                  - narrate '<&7><player.name> <&gt> You<&f>: <[message].strip_color>' targets:<[target_player]>
                  - flag <[target_player]> drustcraft.chat.last_pm:<player>
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|You message was not sent as it breaks the rule: $e<[rule]>]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[target_player].name> $rcannot receive messages as they are muted]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|You cannot send messages as you are muted]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|Chat is currently disabled]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|$e<player.flag[drustcraft.chat.last_pm].name> $ris no longer online]>'
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|No one has recently messaged you]>'


drustcraftc_chat_all:
  type: command
  debug: false
  name: all
  description: Sets your default chat channel to all
  usage: /all
  aliases:
    - mod
  script:
    - if !<context.server||false>:
      - define channel:<context.alias||all>
      - define message:<context.args.space_separated>

      - if <[message].length> > 0:
        - define id:<proc[<server.flag[drustcraft.chat.registrations.<[channel]>.task]>].context[<player>|<[channel]>]>
        - if <[id]> != null:
          - define channel_title:<server.flag[drustcraft.chat.registrations.<[channel]>.title]||<[channel]>>
          - define player_list:<server.online_players.filter_tag[<proc[drustcraftp_chat_channel_ids].context[<[filter_value]>].contains[<[id]>]>]>
          - if <[player_list].size> > 1:
            - if <[channel]> == all:
              - define channel_title:<empty>
            - else:
              - define 'channel_title:<[channel_title]> <&gt> '

            - narrate '<[channel_title]><player.chat_prefix.parse_color><player.name><&f>: <[message].strip_color>' targets:<[player_list]>
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|There is no online players in the chat channel $e<[channel]>]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|You are not permitted to send messages to this chat channel]>'

      - else:
        - if !<proc[drustcraftp_chat_channel_ids].context[<player>].contains[<[channel]>]>:
          - run drustcraftt_chat_join def:<player>|<[channel]>|<[channel]>|false

        - if <proc[drustcraftp_chat_default].context[<player>]> != <[channel]>:
          - run drustcraftt_chat_default def:<player>|<[channel]>|<[channel]>|false
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[arrow|Your default chat channel is already set to $e<[channel]>]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|This command is only available to players]>'


drustcraftc_chat_silent:
  type: command
  debug: false
  name: silent
  description: Removes you from all channels
  usage: /silent
  script:
    - if !<context.server||false>:
      - foreach <proc[drustcraftp_chat_channel_names].context[<player>]> as:channel_name:
        - run drustcraftt_chat_leave def:<player>|<[channel_name]>
      - narrate '<proc[drustcraftp_msg_format].context[arrow|You have left all chat channels and can only be contacted by $e/pm]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|This command is only available to players]>'


drustcraftc_chat_mute:
  type: command
  debug: false
  name: mute
  description: Mutes a player for a duration
  usage: /mute
  permission: drustcraft.mute
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:mute
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - define target_player:<context.args.get[1]||<empty>>
    - define duration:<context.args.get[2]||<empty>>

    - define found_player:<server.match_offline_player[<[target_player]>]>
    - if <[found_player].exists> && <[found_player].name> == <[target_player]>:
      - if <[duration]> == perm || <duration[<[duration]>].exists>:
        - waituntil <server.sql_connections.contains[drustcraft]>
        - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>chat_muted` WHERE `uuid` = "<[found_player].uuid>";'
        - if <[duration]> == perm:
          - flag <[found_player]> drustcraft.chat.muted:true
          - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chat_muted`(`uuid`,`until`) VALUES("<[found_player].uuid>", -1);'
          - narrate '<proc[drustcraftp_msg_format].context[success|The player $e<[found_player].name> $rhas been permanently muted]>'
          - narrate '<proc[drustcraftp_msg_format].context[warning|You have been permanently muted]>' targets:<[found_player]>
        - else:
          - define expires:<util.time_now.add[<[duration]>]>
          - flag <[found_player]> drustcraft.chat.muted:true expire:<[expires]>
          - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chat_muted`(`uuid`,`until`) VALUES("<[found_player].uuid>", <[expires].epoch_millis.div[1000].round>);'
          - narrate '<proc[drustcraftp_msg_format].context[success|The player $e<[found_player].name> $rhas been muted for $e<[duration]>]>'
          - narrate '<proc[drustcraftp_msg_format].context[warning|You have been muted for $e<[duration]>]>' targets:<[found_player]>
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|The duration $e<[duration]> $ris not valid]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[target_player]> $rwas not found]>'


drustcraftc_chat_unmute:
  type: command
  debug: false
  name: unmute
  description: Unmutes a player for a duration
  usage: /unmute
  permission: drustcraft.mute
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:unmute
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - define target_player:<context.args.get[1]||<empty>>
    - define duration:<context.args.get[2]||<empty>>

    - define found_player:<server.match_offline_player[<[target_player]>]>
    - if <[found_player].exists> && <[found_player].name> == <[target_player]>:
      - if <[found_player].has_flag[drustcraft.chat.muted]>:
        - waituntil <server.sql_connections.contains[drustcraft]>
        - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>chat_muted` WHERE `uuid` = "<[found_player].uuid>";'
        - narrate '<proc[drustcraftp_msg_format].context[success|The player $e<[found_player].name> $rhas been unmuted]>'
        - narrate '<proc[drustcraftp_msg_format].context[warning|You have been unmuted]>' targets:<[found_player]>
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[found_player].name> $ris not muted]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[target_player]> $rwas not found]>'
