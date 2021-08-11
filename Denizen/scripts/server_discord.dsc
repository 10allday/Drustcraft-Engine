# Drustcraft - Discord
# https://github.com/drustcraft/drustcraft

drustcraftw_discord:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - ~run drustcraftt_discord_load
      - ~discordmessage id:drustcraft channel:<server.flag[drustcraft.discord.channel]> ':white_check_mark: **Server has started**'

    on shutdown:
      - ~discordmessage id:drustcraft channel:<server.flag[drustcraft.discord.channel]> ':octagonal_sign: **Server has stopped**'

    on script reload:
      - run drustcraftt_discord_load

    on player joins server_flagged:drustcraft.module.discord:
      - wait 60t
      - define 'message:<discord_embed.with[color].as[#00ff00].with[author_icon_url].as[https://crafatar.com/avatars/<player.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<player.name> joined Drustcraft]>'
      - ~discordmessage id:drustcraft channel:<server.flag[drustcraft.discord.channel]> <[message]>
      - run drustcraftt_discord_update_player_roles def:<player>

    on player quits server_flagged:drustcraft.module.discord:
      - define 'message:<discord_embed.with[color].as[#ff0000].with[author_icon_url].as[https://crafatar.com/avatars/<player.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<player.name> left Drustcraft]>'
      - ~discordmessage id:drustcraft channel:<server.flag[drustcraft.discord.channel]> <[message]>

    on player chats priority:100 server_flagged:drustcraft.module.discord:
      - ~discordmessage id:drustcraft channel:<server.flag[drustcraft.discord.channel]> '**<player.name>** » <context.message.strip_color>'

    on command server_flagged:drustcraft.module.discord:
      - if <context.source_type> == PLAYER:
        - ~discordmessage id:drustcraft channel:<server.flag[drustcraft.discord.channel]> '**<player.name>** /<context.command> <context.raw_args>'

    on player death server_flagged:drustcraft_discord:
      - define message:<discord_embed.with[color].as[#000000].with[author_icon_url].as[https://crafatar.com/avatars/<player.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<context.message.strip_color||died>]>
      - ~discordmessage id:drustcraft channel:<server.flag[drustcraft.discord.channel]> <[message]>

    on system time minutely every:12 server_flagged:drustcraft.module.discord:
      - run drustcraftt_discord_update_status

    on discord message received:
      - if <context.bot.name.equals[drustcraft]>:
        - define message:<context.new_message.text_stripped>

        - if <[message].starts_with[!]>:
          - define args:<[message].after[!].split[<&sp>]>
          - choose <[args].get[1]>:
            # - case reddit subreddit:
            #   - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://www.reddit.com/r/drustcraft].with[author_url].as[https://www.reddit.com/r/drustcraft]>'

            # - case twitter:
            #   - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://www.twitter.com/drustcraft].with[author_url].as[https://www.twitter.com/drustcraft]>'

            # - case facebook fb:
            #   - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://www.facebook.com/drustcraft].with[author_url].as[https://www.facebook.com/drustcraft]>'

            # - case insta instagram:
            #   - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://www.instagram.com/drustcraft].with[author_url].as[https://www.instagram.com/drustcraft]>'

            # - case yt youtube:
            #   - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://www.youtube.com/channel/UCUZLUu9b87ylDEai_rnUvKA].with[author_url].as[https://www.youtube.com/channel/UCUZLUu9b87ylDEai_rnUvKA]>'

            # - case link links social socials:
            #   - define 'message:Here are the best sites in the world:<n>Website - https://drustcraft.com.au/<n>Atlas - https://map.drustcraft.com.au<n>Subreddit - https://www.reddit.com/r/drustcraft<n>Twitter - https://www.twitter.com/drustcraft<n>Facebook - https://www.facebook.com/drustcraft<n>Insta - https://www.instagram.com/drustcraft<n>Youtube - https://www.youtube.com/channel/UCUZLUu9b87ylDEai_rnUvKA'
            #   - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> <[message]>

            - case tps:
              - define tps_list:<list[<server.recent_tps.get[1].round_to[1]>|<server.recent_tps.get[2].round_to[1]>|<server.recent_tps.get[3].round_to[1]>]>
              - ~discordmessage id:drustcraft channel:<context.channel> 'The server is reporting the following TPS<&co> <[tps_list].comma_separated>'

            - case online:
              - define online_result:<element[]>
              - define online_list:<server.online_players.parse[name].deduplicate.alphanumeric>

              - if <[online_list].size> == 0:
                - define 'online_result:No one is currently online <&co>('
              - else if <[online_list].size> == 1:
                - define 'online_result:There is 1 player online<&co> <[online_list].comma_separated>'
              - else:
                - define online_count:<[online_list].size>
                - define 'online_result:There are <[online_count]> players online<&co> <[online_list].comma_separated>'

              - ~discordmessage id:drustcraft channel:<context.channel> <[online_result]>

            - case skin:
              - define player_name:<[args].get[2]||<empty>>
              - if <[player_name]> == <empty>:
                - ~discordmessage id:drustcraft channel:<context.channel> "I'm not sure what player you want me to lookup!"
              - else:
                - define target_player:<server.match_offline_player[<[player_name]>]>
                - if <[target_player].name> != <[player_name]>:
                  - ~discordmessage id:drustcraft channel:<context.channel> "I've never seen **<[player_name]>** around these parts!"
                - else:
                  - if <[target_player].name.starts_with[*]>:
                    - ~discordmessage id:drustcraft channel:<context.channel> "**<[target_player].name>** is a tablet player. I can't get skins for them yet"
                  - else:
                    - ~discordmessage id:drustcraft channel:<context.channel> '<discord_embed.with[description].as[Here is the skin of **<[target_player].name>**].with[image].as[https://crafatar.com/skins/<[target_player].uuid>]>'

            - case time:
              - define world_time:<server.worlds.get[1].time>
              - define hours:<[world_time].div[1000].round_down.add[6]>
              - if <[hours]> >= 24:
                - define hours:-:24
              - define mins:<[world_time].mod[1000].mul[3.6].div[60].round_down>

              - define ampm:am
              - if <[hours]> >= 12:
                - define ampm:pm
                - if <[hours]> >= 13:
                  - define hours:-:12

              - if <[mins]> < 10:
                - define mins:0<[mins]>

              - ~discordmessage id:drustcraft channel:<context.channel> "Server time is currently <[hours]>:<[mins]><[ampm]>"

            - case status:
              - ~webget https://api.drustcraft.com.au/v1/status headers:drustcraft-version/2021-05-25 save:result_webget
              - define result_json:<entry[result_webget].result>

              - define result_map:<util.parse_yaml[<[result_json]>]>
              - define servers:<[result_map].get[servers]>

              - define message:<element[]>
              - if <[servers].size> == 0:
                - define 'message:Could not load the status information from the network'
              - else:
                - define 'message:The Drustcraft network status looks like:<n>'
                - foreach <[servers]>:
                  - if <[value].get[status]> == ok:
                    - define message:<[message]><&lt><&co>greentick<&co>866298384515465217<&gt><&sp>
                  - else if <[value].get[status]> == warning:
                    - define message:<[message]><&lt><&co>greytick<&co>866298412465651773<&gt><&sp>
                  - else:
                    - define message:<[message]><&lt><&co>redtick<&co>866298343100252180<&gt><&sp>

                  - define 'message:<[message]><[value].get[name]> (<[value].get[type]>)<n>'

              - ~discordmessage id:drustcraft channel:<context.channel> <[message]>

            - case value:
              - define item_name:<[args].remove[1].separated_by[_]>
              - if <[item_name]> == <empty>:
                - ~discordmessage id:drustcraft channel:<context.channel> "I'm not sure what item you want me to lookup!"
              - else:
                - define item_title:<[item_name].replace_text[_].with[<&sp>].to_titlecase>
                - if <server.material_types.parse[name].contains[<[item_name]>]>:
                  - define item_value:<proc[drustcraftp_value_item_to_currency].context[<[item_name]>]>

                  - if <[item_value]> == null:
                    - ~discordmessage id:drustcraft channel:<context.channel> "**<[item_title]>** has no value here"
                  - else:
                    - define response:<element[]>

                    - define 'response:My source says that value of a **<[item_title]>** is around '

                    - if <[item_value].get[item1].material.name||air> != air:
                      - define item:<[item_value].get[item1]>
                      - define 'response:<[response]><[item].quantity> <[item].material.name.replace_text[_].with[<&sp>].to_sentence_case><tern[<[item].quantity.equals[1]>].pass[].fail[s]> '
                      - if <[item_value].get[item2].material.name||air> != air:
                        - define 'response:<[response]>and '

                    - if <[item_value].get[item2].material.name||air> != air:
                      - define item:<[item_value].get[item2]>
                      - define 'response:<[response]><[item].quantity> <[item].material.name.replace_text[_].with[<&sp>].to_sentence_case><tern[<[item].quantity.equals[1]>].pass[].fail[s]> '

                    - if <[item_value].get[min_qty]> > 1:
                      - define 'response:<[response]>for every <[item_value].get[min_qty]> pieces'

                    - ~discordmessage id:drustcraft channel:<context.channel> <[response]>
                - else:
                  - ~discordmessage id:drustcraft channel:<context.channel> "I don<&sq>t know what **<[item_title]>** is"

            - case uuid:
              - define player_name:<[args].get[2]||<empty>>
              - define target_player:<server.match_offline_player[<[player_name]>]||<empty>>

              - if <[player_name]> != <empty>:
                - if <[target_player]> != <empty>:
                  - ~discordmessage id:drustcraft channel:<context.channel> "The uuid of **<[target_player].name>** is <[target_player].uuid>"
                - else:
                  - ~discordmessage id:drustcraft channel:<context.channel> "Could not find any info on **<[player_name]>**"
              - else:
                - ~discordmessage id:drustcraft channel:<context.channel> "Which player did you want to know about?"

            - case whereis:
              - define player_name:<[args].get[2]||<empty>>
              - define target_player:<server.match_offline_player[<[player_name]>]||<empty>>

              - if <[player_name]> != <empty>:
                - if <[target_player]> != <empty>:
                  - define target_location:<[target_player].location.round>
                  - define x:<[target_location].x>
                  - define z:<[target_location].z>
                  - define world:<[target_location].world.name.replace_text[_].with[<&sp>].to_titlecase>

                  - define region:<proc[drustcraftp_region.find].context[<[target_location]>]||<empty>>
                  - if !<list[<empty>|__global__].contains[<[region]>]>:
                    - define region:<proc[drustcraftp_region.title].context[<[target_location].world.name>|<[region]>]>
                    - if <[region]> != <empty>:
                      - define 'region:, <[region]>'
                    - else:
                      - define region:<element[]>
                  - else:
                    - define region:<element[]>

                  - define 'online:is currently'
                  - if !<server.online_players.contains[<[target_player]>]>:
                    - define 'online:was last seen'

                  - ~discordmessage id:drustcraft channel:<context.channel> "**<[target_player].name>** <[online]> at X: <[x]> Z: <[z]><[region]> in <[world]>."
                - else:
                  - ~discordmessage id:drustcraft channel:<context.channel> "Could not find any info on **<[player_name]>**"
              - else:
                - ~discordmessage id:drustcraft channel:<context.channel> "Which player did you want to know about?"
            
            # - case whois:
            #   - define discord_name:<[args].remove[1].space_separated||<empty>>
              
            #   - if <[discord_name]> != <empty>:
            #     - define found:false
                
            #     - ~sql id:drustcraft_database 'query:SELECT `player_uuid`,`discord_user_id` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE 1' save:sql_result
            #     - if <entry[sql_result].result.size||0> >= 1:
            #       - foreach <entry[sql_result].result>:
            #         - define row:<[value].split[/]||<list[]>>
            #         - define player_uuid:<[row].get[1]||<empty>>
            #         - define discord_user_id:<[row].get[2]||<empty>>
                    
            #         - define real_discord_name:<discord_user[drustcraft_discord_bot,<[discord_user_id]>].nickname[<server.flag[drustcraft_discord_server_id]>]||<discord_user[drustcraft_discord_bot,<[discord_user_id]>].name>>
                      
                      
            #         - if <[real_discord_name].regex_matches[.*<[discord_name]>.*]>:
            #           - define found:true
            #           - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> "Discord user **<[real_discord_name]>** is known as player **<player[<[player_uuid]>].name>**"
                
            #     - if <[found]> == false:
            #       - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> "Could not find any info on **<[discord_name]>**"
                
            # - case player:
            #   - define player_name:<[args].get[2]||<empty>>
            #   - define target_player:<server.match_offline_player[<[player_name]>]||<empty>>
              
            #   - if <[target_player]> != <empty>:
            #     - define found:false
                
            #     - ~sql id:drustcraft_database 'query:SELECT `discord_user_id` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE `player_uuid`="<[target_player].uuid>"' save:sql_result
            #     - if <entry[sql_result].result.size||0> >= 1:
            #       - foreach <entry[sql_result].result>:
            #         - define row:<[value].split[/]||<list[]>>
            #         - define discord_user_id:<[row].get[1]||<empty>>
                    
            #         - define real_discord_name:<discord_user[drustcraft_discord_bot,<[discord_user_id]>].nickname[<server.flag[drustcraft_discord_server_id]>]||<discord_user[drustcraft_discord_bot,<[discord_user_id]>].name>>
            #         - define found:true
            #         - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> "Player **<[target_player].name>** is known as discord user **<[real_discord_name]>**"
                
            #     - if <[found]> == false:
            #       - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> "Could not find any info on **<[player_name]>**"
                
            #   - else:
            #     - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> "Which player did you want to know about?"

            # - case event events:
            #   - define event_list:<proc[drustcraftp_event.running]>
              
            #   - if <[event_list].size> > 0:
            #     - if <[event_list].size> > 1:
            #       - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> "The following events are currently running:"
            #       - foreach <[event_list]>:
            #         - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> "  • <proc[drustcraftp_event.title].context[<[key]>]> for another <proc[drustcraftp_event.remaining].context[<[key]>].formatted_words>"
            #     - else:
            #       - define event_id:<[event_list].keys.get[1]>
            #       - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> "The <proc[drustcraftp_event.title].context[<[event_id]>]> event is running for another <proc[drustcraftp_event.remaining].context[<[event_id]>].formatted_words>"
            #   - else:
            #     - ~discordmessage id:drustcraft_discord_bot channel:<context.channel> "There are no events currently running in Drustcraft"

            - case weather:
              - ~discordmessage id:drustcraft channel:<context.channel> "The weather bureau is reporting the following conditions:"
              - wait 20t
              - foreach <server.worlds>:
                - define 'weather:Find and Sunny'

                - choose <[value].environment>:
                  - case NETHER:
                    - define 'weather:<list[Hot and humid|Fine but enjoy the lava|...|Overcast, jk].random>'
                  - case THE_END:
                    - define weather:<list[Dark|...].random>
                  - default:
                    - if <[value].has_storm>:
                      - if <[value].thundering>:
                        - define weather:Thunderstorms
                      - else:
                        - define 'weather:Overcast, possible rain and snow'

                - ~discordmessage id:drustcraft channel:<context.channel> "  • **<[value].name.replace_text[_].with[<&sp>].to_titlecase>**: <[weather]>"
                - wait 2t
        # - else if <context.channel.id> == <server.flag[drustcraft.discord.channel]>:
        #   - if !<context.new_message.author.is_bot>:
        #     - narrate '<&3><&lt>D<&gt><&7>[<context.new_message.author.nickname[<server.flag[drustcraft.discord.server]>]||<context.new_message.author.name>>] <&f><[message]>' targets:<server.online_players>


drustcraftt_discord_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if <discord[drustcraft]||null> != null:
      - ~discord id:drustcraft disconnect

    - if !<server.has_file[discord_token.txt]>:
      - debug ERROR 'Drustcraft Discord: discord_token.txt file was not found'
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - debug ERROR 'Drustcraft Discord: Drustcraft Setting is required'
      - stop

    - waituntil <server.has_flag[drustcraft.module.setting]>

    - run drustcraftt_setting_get def:discord.server|null|yaml save:result
    - if <entry[result].created_queue.determination.get[1]> == null:
      - debug ERROR 'Drustcraft Discord: discord.server is missing in drustcraft.yml'
      - stop
    - else:
      - flag server drustcraft.discord.server:<entry[result].created_queue.determination.get[1]>

    - run drustcraftt_setting_get def:discord.channel|null|yaml save:result
    - if <entry[result].created_queue.determination.get[1]> == null:
      - debug ERROR 'Drustcraft Discord: discord.channel is missing in drustcraft.yml'
      - stop
    - else:
      - flag server drustcraft.discord.channel:<entry[result].created_queue.determination.get[1]>

    - ~discordconnect id:drustcraft tokenfile:discord_token.txt
    - flag server drustcraft.module.discord:<script[drustcraftw_discord].data_key[version]>
    - run drustcraftt_discord_update_status


drustcraftt_discord_update_status:
  type: task
  debug: false
  script:
    - if <discord[drustcraft]||null> != null:
      - define 'activity_list:<list[Watching Drustcraft|Playing Drustcraft|Playing Minecraft|Watching a raid|Playing with Guards|Watching for Phantoms|Listening Music|Listening Zombies|Watching Fireworks|Playing with Bees|Listening Randoms|Watching <server.online_players.parse[name].random||<element[the Server]>>]>'
      - define activity:<[activity_list].random>

      - discord id:drustcraft status <[activity].after[<&sp>]> status:ONLINE activity:<[activity].before[<&sp>]>


drustcraftt_discord_update_player_roles:
  type: task
  debug: false
  defintions: player
  script:
    - determine <empty>


# embed:
#   - define message:<[1]>
#   - define colour:<[2]||<empty>>
#   - define imageUrl:<[3]||<empty>>

#   - define embed:<discord_embed.with[author_name].as[<[message]>]>
#   - if <[colour]> != <empty>:
#     - define embed:<[embed].with[color].as[<[colour]>]>
#   - if <[imageUrl]> != <empty>:
#     - define embed:<[embed].with[author_icon_url].as[<[imageUrl]>]>
  
#   - if <discord[drustcraft_discord_bot]||<empty>> != <empty>:
#     - ~discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> <[embed]>
  
  # update_player_roles:
  #   - define target_player:<[1]>
  #   - define discord_user_id:<empty>
    
  #   - ~sql id:drustcraft_database 'query:SELECT `discord_user_id` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE (`player_uuid`="<[target_player].uuid>")' save:sql_result
  #   - if <entry[sql_result].result.size||0> >= 1:
  #     - foreach <entry[sql_result].result>:
  #       - define row:<[value].split[/]||<list[]>>
  #       - define discord_user_id:<[row].get[1]||<empty>>
        
  #       - if <[discord_user_id]> == null:
  #         - define discord_user_id:<empty>
    
  #   - if <[discord_user_id]> != <empty>:
  #     - if <[target_player].groups.contains[staff]>:
  #       - discord discord id:drustcraft_discord_bot add_role user:<[discord_user_id]> role:787809504833699850 group:<server.flag[drustcraft_discord_server_id]>
  #     - else:
  #       - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:787809504833699850 group:<server.flag[drustcraft_discord_server_id]>
        
  #     - if <[target_player].groups.contains[moderator]>:
  #       - discord discord id:drustcraft_discord_bot add_role user:<[discord_user_id]> role:787809695099256884 group:<server.flag[drustcraft_discord_server_id]>
  #     - else:
  #       - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:787809695099256884 group:<server.flag[drustcraft_discord_server_id]>
        
  #     - if <[target_player].groups.contains[builder]>:
  #       - discord discord id:drustcraft_discord_bot add_role user:<[discord_user_id]> role:857087745976303618 group:<server.flag[drustcraft_discord_server_id]>
  #     - else:
  #       - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:857087745976303618 group:<server.flag[drustcraft_discord_server_id]>
        
      
  # clear_player_roles:
  #   - define target_player:<[1]>
  #   - define discord_user_id:<empty>
    
  #   - ~sql id:drustcraft_database 'query:SELECT `discord_user_id` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE (`player_uuid`="<[target_player].uuid>")' save:sql_result
  #   - if <entry[sql_result].result.size||0> >= 1:
  #     - foreach <entry[sql_result].result>:
  #       - define row:<[value].split[/]||<list[]>>
  #       - define discord_user_id:<[row].get[1]||<empty>>
    
  #   - if <[discord_user_id]> != <empty>:
  #     - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:787809504833699850 group:<server.flag[drustcraft_discord_server_id]>
  #     - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:787809695099256884 group:<server.flag[drustcraft_discord_server_id]>
  #     - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:857087745976303618 group:<server.flag[drustcraft_discord_server_id]>
  
  
  