# Drustcraft - Chat
# Player Chat 
# https://github.com/drustcraft/drustcraft

# MOTD - Sound: ENTITY_FIREWORK_LAUNCH 1F 0.1F
# Annoucements - Chat_Sound: ENTITY_ARROW_HIT_PLAYER 1.0F 0.1F
# Private msg - #Sound: ENTITY_CHICKEN_EGG 1F 1.5F   


drustcraftf_chat:
  type: format
  format: <&7>[<name>] <&f><text>


drustcraftw_chat:
  type: world
  debug: false
  events:
    on server start:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_chat.load

    on script reload:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_chat.load
      
    on bungee player joins network:
      - wait 60t
      - narrate '<&8>[<&a>+<&8>] <&e><player.name> <&f>joined Drustcraft' targets:<server.online_players.exclude[<player>]>
  
    on bungee player leaves network:
      - narrate '<&8>[<&c>-<&8>] <&e><player.name> <&f>left Drustcraft' targets:<server.online_players.exclude[<player>]>

    on player chats:
      - if <server.flag[drustcraft_chat]||false>:
        - define type:chat
        - define sender:<player.uuid>
        - define receiver:<empty>
        - define content:<context.message>
        - define channel:<empty>
        - define rule:<proc[drustcraftp_chat.apply_rules].context[<[content]>]>
        
        - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_chat` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'
        - if <[rule]> == <empty>:
          - determine passively RECIPIENTS:<player.location.world.players>
          - determine passively FORMAT:drustcraftf_chat
        - else:
          - narrate '<&8><&l>[<&c><&l>!<&8><&l>] <&c>You message was not sent as it breaks the rule: <[rule]>'
          - determine CANCELLED
      - else:
        - narrate '<&8><&l>[<&c><&l>!<&8><&l>] <&c>Chat is currently disabled'
        - determine CANCELLED
        
    on player changes sign:
      - if <server.flag[drustcraft_chat]||false>:
        - define type:sign
        - define sender:<player.uuid>
        - define receiver:<context.location.x.round>,<context.location.y.round>,<context.location.z.round>,<context.location.world.name>,
        - define content:<context.new>
        - define channel:<empty>
        - define rule:<proc[drustcraftp_chat.apply_rules].context[<[content]>]>
        
        - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_chat` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'
        - if <[rule]> != <empty>:
          - narrate '<&8><&l>[<&c><&l>!<&8><&l>] <&c>You message was not sent as it breaks the rule: <[rule]>'
          - determine CANCELLED
          
      - else:
        - narrate '<&8><&l>[<&c><&l>!<&8><&l>] <&c>Chat is currently disabled'
        - determine CANCELLED

    on player edits book:
      - if <server.flag[drustcraft_chat]||false>:
        - define type:book
        - define sender:<player.uuid>
        - define receiver:<empty>,
        - define content:<context.title>|<context.book>
        - define channel:<empty>
        - define rule:<proc[drustcraftp_chat.apply_rules].context[<[content]>]>
        
        - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_chat` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'
        - if <[rule]> != <empty>:
          - narrate '<&8><&l>[<&c><&l>!<&8><&l>] <&c>You message was not sent as it breaks the rule: <[rule]>'
          - determine CANCELLED

      - else:
        - narrate '<&8><&l>[<&c><&l>!<&8><&l>] <&c>Chat is currently disabled'
        - determine CANCELLED


drustcraftt_chat:
  type: task
  debug: false
  script:
    - determine <empty>
    
  load:
    - flag server drustcraft_chat:!

    - if <server.has_file[/drustcraft_data/chat.yml]>:
      - yaml load:/drustcraft_data/chat.yml id:drustcraft_chat
    - else:
      - yaml create id:drustcraft_chat
      - yaml savefile:/drustcraft_data/chat.yml id:drustcraft_chat


    - if <server.scripts.parse[name].contains[drustcraftw_sql]>:
      - waituntil <server.sql_connections.contains[drustcraft_database]>
  
      - define create_tables:true
      - ~sql id:drustcraft_database 'query:SELECT version FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_version WHERE name="drustcraft_chat";' save:sql_result
      - if <entry[sql_result].result.size||0> >= 1:
        - define row:<entry[sql_result].result.get[1].split[/]||0>
        - define create_tables:false
        - if <[row]> >= 2 || <[row]> < 1:
          # Weird version error
          - stop
  
      - if <[create_tables]>:
        - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` (`name`,`version`) VALUES ("drustcraft_chat",'1');'
        - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_chat` (`id` INT NOT NULL AUTO_INCREMENT, `server` VARCHAR(255) NOT NULL, `world` VARCHAR(255) NOT NULL, `date` INT NOT NULL, `type` VARCHAR(255) NOT NULL, `sender` VARCHAR(255) NOT NULL, `receiver` VARCHAR(255) NOT NULL, `content` VARCHAR(255) NOT NULL, `channel` VARCHAR(255) NOT NULL, `rule` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`));'
      
      - flag server drustcraft_chat:true

      - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
        - wait 2t
        - waituntil <yaml.list.contains[drustcraft_tab_complete]>
        
        - run drustcraftt_tab_complete.completions def:tell|_*players
      
      
    - else:
      - debug log 'Drustcraft Chat requires the Drustcraft SQL script installed'
    

drustcraftp_chat:
  type: procedure
  debug: false
  script:
    - determine <empty>
  
  apply_rules:
    - define content:<[1]||<empty>>
    
    - foreach <yaml[drustcraft_chat].list_keys[chat.filters]||<list[]>> as:filter_id:
      - foreach <yaml[drustcraft_chat].read[chat.filters.<[filter_id]>.ignore]||<list[]>> as:ignore_text:
        - define content:<[content].replace_text[<[ignore_text]>]>

      - foreach <yaml[drustcraft_chat].read[chat.filters.<[filter_id]>.match.regex]||<list[]>> as:match_regex:
        - if <[content].contains_text[<[match_regex]>]>:
          - determine <[filter_id]>

      - foreach <yaml[drustcraft_chat].read[chat.filters.<[filter_id]>.match.text]||<list[]>> as:match_text:
        - if <[content].contains_text[<[match_text]>]>:
          - determine <[filter_id]>
    
    - determine <empty>
  
  get_reason:
    - define filter_id:<[1]||<empty>>
    
    - determine <yaml[drustcraft_chat].read[chat.filters.<[filter_id]>.reason]||<empty>>
    
  
drustcraftt_chat_announce:
  type: task
  debug: false
  script:
    - define message:<[1]||<empty>>

    - if <[message]> != <empty>>:
      - playsound <server.online_players> sound:ENTITY_ARROW_HIT_PLAYER volume:1.0 pitch:0.1
      - wait 5t
      - narrate '<&6> ' targets:<server.online_players>
      - narrate '<&6>[<&6>!!!<&6>] <&6><[message]>' targets:<server.online_players>
      - narrate '<&6> ' targets:<server.online_players>
      - playsound <server.online_players> sound:ENTITY_ARROW_HIT_PLAYER volume:1.0 pitch:0.1
      - wait 5t
      - playsound <server.online_players> sound:ENTITY_ARROW_HIT_PLAYER volume:1.0 pitch:0.1
      - wait 5t

drustcraftt_chat_message:
  type: task
  debug: false
  script:
    - define player_uuid_from:<[1]||<empty>>
    - define player_name_from:<[2]||<empty>>
    - define player_uuid_to:<[3]||<empty>>
    - define message:<[4]||<empty>>

    - if <[message]> != <empty>:
      - if <[player_uuid_to]> != <empty> && <[player_name_from]> != <empty>:
        - if <server.online_players.parse[uuid].contains[<[player_uuid_to]>]>:
          - playsound <player[<[player_uuid_to]>]> sound:ENTITY_CHICKEN_EGG volume:1.0 pitch:1.5
          - narrate '<&7>[<[player_name_from]> <&gt> You] <&f><[message]>' targets:<player[<[player_uuid_to]>]>
          - flag <player[<[player_uuid_to]>]> drustcraft_chat_reply:<[player_uuid_from]>


drustcraftc_chat_announce:
  type: command
  debug: false
  name: announce
  description: Announces text across the network
  usage: /annouce <&lt>text<&gt>
  permission: drustcraft.announce
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:announce
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if <context.args.size||0> > 0:
      - bungeerun <bungee.list_servers> drustcraftt_chat_announce def:<context.args.space_separated>


drustcraftc_chat_tell:
  type: command
  debug: false
  name: tell
  aliases:
    - t
    - pm
    - msg
  description: Sends a message to a player
  usage: /tell <&lt>player<&gt> <&lt>text<&gt>
  permission: drustcraft.tell
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:tell
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if <context.args.size||0> == 0:
      - narrate '<&c>No player was entered to message'
    - else if <context.args.size||0> == 1:
      - narrate '<&c>No message was entered'
    - else:
      - define target_player:<context.args.get[1]||<empty>>
      - define message:<context.args.remove[1].space_separated>
    
      - define target_player:<server.match_player[<[target_player]>]||<empty>>

      - if <server.flag[drustcraft_chat]||false>:
        - define 'type:private message'
        - define sender:<player.uuid>
        - define receiver:<[target_player].uuid>
        - define content:<[message]>
        - define channel:<empty>
        - define rule:<proc[drustcraftp_chat.apply_rules].context[<[content]>]>
        
        - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_chat` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'

        - if <[rule]> == <empty>:
          - narrate '<&7>[You <&gt> <[target_player].name>] <&f><[message]>'
          - bungeerun <bungee.list_servers> drustcraftt_chat_message def:<player.uuid>|<player.name>|<[target_player].uuid>|<[message]>
        - else:
          - narrate '<&8><&l>[<&c><&l>!<&8><&l>] <&c>You message was not sent as it breaks the rule: <[rule]>'
          - determine CANCELLED
      - else:
        - narrate '<&8><&l>[<&c><&l>!<&8><&l>] <&c>Chat is currently disabled'
        - determine CANCELLED


drustcraftc_chat_reply:
  type: command
  debug: false
  name: reply
  aliases:
    - r
  description: Replies to the last message from a player
  usage: /r <&lt>text<&gt>
  permission: drustcraft.tell
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:reply
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if <context.args.size||0> == 0:
      - narrate '<&c>No message was entered'
    - else:
      - if <player.has_flag[drustcraft_chat_reply]>:
        - define target_player:<player[<player.flag[drustcraft_chat_reply]>]>
        - define message:<context.args.space_separated>
      
        - if <server.flag[drustcraft_chat]||false>:
          - define 'type:private message'
          - define sender:<player.uuid>
          - define receiver:<[target_player].uuid>
          - define content:<[message]>
          - define channel:<empty>
          - define rule:<proc[drustcraftp_chat.apply_rules].context[<[content]>]>
          
          - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_chat` (`server`,`world`,`date`,`type`,`sender`,`receiver`,`content`,`channel`,`rule`) VALUES ("<bungee.server||<empty>>", "<player.location.world.name>", <util.time_now.epoch_millis.div[1000].round>, "<[type]>", "<[sender]>", "<[receiver]>", "<[content]>", "<[channel]>", "<[rule]>");'
  
          - if <[rule]> == <empty>:
            - narrate '<&7>[You <&gt> <[target_player].name>] <&f><[message]>'
            - bungeerun <bungee.list_servers> drustcraftt_chat_message def:<player.uuid>|<player.name>|<[target_player].uuid>|<[message]>
          - else:
            - narrate '<&8><&l>[<&c><&l>!<&8><&l>] <&c>You message was not sent as it breaks the rule: <[rule]>'
            - determine CANCELLED
        - else:
          - narrate '<&8><&l>[<&c><&l>!<&8><&l>] <&c>Chat is currently disabled'
          - determine CANCELLED
      - else:
        - narrate '<&c>No one has recently messaged you'
