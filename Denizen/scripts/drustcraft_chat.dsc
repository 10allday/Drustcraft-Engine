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
        - define channel:<empty>
        - define rule:<proc[drustcraftp_chat_filter].context[<[content]>]>

        - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chat_log` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'
        - if <[rule]> == <empty>:
          - define message:<context.message>

          - if <player.has_flag[drustcraft.chat.muted]>:
            - narrate '<proc[drustcraftp_msg_format].context[error|You are currently muted for $e<player.flag_expiration[drustcraft.chat.muted].from_now.formatted>]>'
            - determine CANCELLED

          - if <player.has_flag[drustcraft.chat.default_channel]>:
            - define channel:<proc[drustcraftp_chat_default].context[<player>]>
            - define 'channel_title:<proc[drustcraftp_chat_channel_title_from_id].context[<player>|<[channel]>]> <&gt> '

            - if <[channel]> == all:
              - define channel_title:<empty>

            - define player_list:<server.online_players.filter_tag[<proc[drustcraftp_chat_channel_ids].context[<[filter_value]>].contains[<[channel]>]>]>
            - if <[player_list].size> > 1:
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
          # - narrate '<proc[drustcraftp_msg_format].context[warning|<server.flag[drustcraft.chat.registrations.mod.title]> <&gt> $e<player.name> $rbroke the chat rule $e<[rule]> $rby saying "$e<[content]>$r"]>' targets:<server.online_players.filter[has_flag[drustcraft.chat.channels.names.mod]]>
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
          # - narrate '<proc[drustcraftp_msg_format].context[warning|<server.flag[drustcraft.chat.registrations.mod.title]> <&gt> $e<player.name> $rbroke the chat rule $e<[rule]> $rby putting "$e<[content]>$r" on a sign]>' targets:<server.online_players.filter[has_flag[drustcraft.chat.channels.names.mod]]>
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
          # - narrate '<proc[drustcraftp_msg_format].context[warning|$e<player.name> $rbroke the chat rule $e<[rule]> $rby writing "$e<[content]>$r" in a book]>' targets:<server.online_players.filter[has_flag[drustcraft.chat.channels.names.mod]]>
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

        - flag server drustcraft.chat.muted.<[uuid]>:true expire:<proc[drustcraftp_util_epoch_to_time].context[<[until]>].duration_since[<util.time_now>]>

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
      - run drustcraftt_tabcomplete_completion def:mute|_*players|_*duration|_*reason
      - run drustcraftt_tabcomplete_completion def:unmute|_*mutedplayers

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


# drustcraftt_chat_send_message_to_channel:
#   type: task
#   debug: false
#   definitions: channel_id|channel_title|from|message
#   script:

#             - define player_list:<server.online_players.filter_tag[<proc[drustcraftp_chat_channel_ids].context[<[filter_value]>].contains[<[channel]>]>]>
#             - if <[player_list].size> > 1:
#               - determine passively RECIPIENTS:<[player_list]>
#               - determine 'RAW_FORMAT:<[channel_title]><player.chat_prefix.parse_color><player.name><&f>: <[message].strip_color>'
#             - else:
#               - narrate '<proc[drustcraftp_msg_format].context[error|There is no online players in the chat channel $e<proc[drustcraft_chat_channel_id_to_name].context[<player>|<[channel]>]>]>'
#               - determine CANCELLED


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
                # - narrate '<proc[drustcraftp_msg_format].context[success|You have joined the $e<[name]> $rchat channel]>'
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
                # - narrate '<proc[drustcraftp_msg_format].context[warning|You have left the $e<[name]> $rchat channel]>'
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
          - define 'type:private message'
          - define sender:<player.uuid>
          - define receiver:<[target_player].uuid>
          - define content:<[message]>
          - define channel:<empty>
          - define rule:<proc[drustcraftp_chat_filter].context[<[content]>]>

          - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chat_log` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'

          - if <[rule]> == <empty>:
            - narrate '<&7>You <&gt> <[target_player].name><&f>: <[message].strip_color>'

            - playsound <[target_player]> sound:ENTITY_CHICKEN_EGG volume:1.0 pitch:1.5
            - narrate '<&7><player.name> <&gt> You<&f>: <[message].strip_color>' targets:<[target_player]>
            - flag <[target_player]> drustcraft.chat.last_pm:<player>
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|You message was not sent as it breaks the rule: $e<[rule]>]>'
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
            - define 'type:private message'
            - define sender:<player.uuid>
            - define receiver:<[target_player].uuid>
            - define content:<[message]>
            - define channel:<empty>
            - define rule:<proc[drustcraftp_chat_filter].context[<[content]>]>

            - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>chat_log` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'

            - if <[rule]> == <empty>:
              - narrate '<&7>You <&gt> <[target_player].name><&f>: <[message].strip_color>'

              - playsound <[target_player]> sound:ENTITY_CHICKEN_EGG volume:1.0 pitch:1.5
              - narrate '<&7><player.name> <&gt> You<&f>: <[message].strip_color>' targets:<[target_player]>
              - flag <[target_player]> drustcraft.chat.last_pm:<player>
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|You message was not sent as it breaks the rule: $e<[rule]>]>'
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

