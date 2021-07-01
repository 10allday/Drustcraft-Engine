# Drustcraft - Discord
# Discord Bot
# https://github.com/drustcraft/drustcraft

drustcraftw_discord:
  type: world
  debug: false
  events:
    on server starts:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - ~run drustcraftt_discord.load
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> ':white_check_mark: **Server <bungee.server> has started**'
      
    on shutdown:
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> ':octagonal_sign: **Server <bungee.server> has stopped**'
      
    on script reload:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_server]>
      - run drustcraftt_discord.load
      
    on bungee player joins network:
      - wait 20t
      - define 'message:<discord_embed.with[color].as[#00ff00].with[author_icon_url].as[https://crafatar.com/avatars/<context.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<context.name> joined Drustcraft]>'
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_bot]> <[message]>
      
    on bungee player leaves network:
      - define 'message:<discord_embed.with[color].as[#ff0000].with[author_icon_url].as[https://crafatar.com/avatars/<context.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<context.name> left Drustcraft]>'
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_bot]> <[message]>

    on player joins:
      - wait 60t
      - define 'message:<discord_embed.with[color].as[#00ffff].with[author_icon_url].as[https://crafatar.com/avatars/<player.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<player.name> arrived in <bungee.server.to_titlecase>]>'
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_bot]> <[message]>
      - run drustcraftt_discord.update_player_roles def:<player>
      
      #ex discord id:drustcraft_discord_bot add_role user:846286915413082124 role:787809504833699850 group:782787130334248973 
      
    on player chats priority:100:
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> '**<player.name>** » <context.message.strip_color>'
    
    on player death:
      - define 'message:<discord_embed.with[color].as[#000000].with[author_icon_url].as[https://crafatar.com/avatars/<player.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<context.message.strip_color||died>]>'
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_bot]> <[message]>
      
    # on player completes advancement:
    #   - define 'message:<discord_embed.with[color].as[#FFFF00].with[author_icon_url].as[https://crafatar.com/avatars/<player.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<player.name> has made the advancement <context.advancement>]>'
    #   - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> <[message]>
    
    on system time minutely every:12:
      - run drustcraftt_discord.update_status

    on discord user joins:
      - define 'message::wave: **<context.user.mention>** and welcome to **Drustcraft**. Please visit <discord_channel[827353540564615188].mention> for around the what is expected around here and <discord_channel[827351975464402954].mention> about the various channels.'
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_bot]> <[message]>

    on discord message received:
      - if <context.bot.name.equals[drustcraft_discord_bot]>:
        - define message:<context.new_message.text_stripped>
        
        - if <[message].starts_with[!]>:
          - define args:<[message].after[!].split[<&sp>]>
          - choose <[args].get[1]>:
            - case help:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> 'Howdy stranger, you can ask me for a few things such as `!tps` for the current server TPS, `!online` to see who is online or even `!value <&lt>item<&gt>` for what an item is worth'
            - case ip server:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> 'You can connect to the Drustcraft server at **play.drustcraft.com.au**, bedrock or tablet players will need to set the port to **20123**<n><n>Java players can also set their port to **26963** (set the server address to **play.drustcraft.com.au:26963**) if you are having issues'
            
            - case website site:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://drustcraft.com.au/].with[author_url].as[https://drustcraft.com.au/]>'

            - case map atlas:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://map.drustcraft.com.au/].with[author_url].as[https://map.drustcraft.com.au/]>'

            - case reddit subreddit:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://www.reddit.com/r/drustcraft].with[author_url].as[https://www.reddit.com/r/drustcraft]>'

            - case twitter:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://www.twitter.com/drustcraft].with[author_url].as[https://www.twitter.com/drustcraft]>'

            - case facebook fb:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://www.facebook.com/drustcraft].with[author_url].as[https://www.facebook.com/drustcraft]>'

            - case insta instagram:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://www.instagram.com/drustcraft].with[author_url].as[https://www.instagram.com/drustcraft]>'

            - case yt youtube:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[author_name].as[https://www.youtube.com/channel/UCUZLUu9b87ylDEai_rnUvKA].with[author_url].as[https://www.youtube.com/channel/UCUZLUu9b87ylDEai_rnUvKA]>'

            - case link links social socials:
              - define 'message:Here are the best sites in the world:<n>Website - https://drustcraft.com.au/<n>Atlas - https://map.drustcraft.com.au<n>Subreddit - https://www.reddit.com/r/drustcraft<n>Twitter - https://www.twitter.com/drustcraft<n>Facebook - https://www.facebook.com/drustcraft<n>Insta - https://www.instagram.com/drustcraft<n>Youtube - https://www.youtube.com/channel/UCUZLUu9b87ylDEai_rnUvKA'
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> <[message]>

            - case currency economy:
              - define 'message:The most common items used in Drustcraft as currency is **Netherite Blocks**, **Netherite Ingots**, **Emerald Blocks**, **Emeralds**, **Diamonds** and **Iron Ingots**<n><n>1 Netherite Block = 9 Netherite Ingots<n>1 Netherite Ingot = 13 Emeralds<n>1 Emerald Block = 9 Emeralds<n>1 Diamond = 1 Emerald<n>1 Emerald = 4 Iron Ingots<n><n>You can exchange between these items at most banks<n><n>'
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> <[message]>
              
            - case tps:
              - define tps_result:<list[]>
              - foreach <bungee.list_servers.sort_by_value[]>:
                - ~bungeetag server:<[value]> '<server.recent_tps.get[1].round_to[1]>, <server.recent_tps.get[2].round_to[1]>, <server.recent_tps.get[3].round_to[1]>' save:tps
                - define 'tps_result:|:  - **<[value]>**: <entry[tps].result>'

              - if <[tps_result].size> == 0:
                - define 'tps_result:No servers are responding <&co>(
              - else:
                - define 'tps_result:The servers are reporting the following TPS<&co><&nl><[tps_result].separated_by[<&nl>]>'

              - discordmessage id:drustcraft_discord_bot channel:<context.channel> <[tps_result]>
            - case online:
              - define online_result:<list[]>
              - foreach <bungee.list_servers.sort_by_value[]>:
                - ~bungeetag server:<[value]> <server.online_players.parse[name]> save:online_players
                - define online_result:<[online_result].include[<entry[online_players].result>]>
              
              - define online_result:<[online_result].deduplicate.alphanumeric>
              
              - if <[online_result].size> == 0:
                - define 'online_result:No one is currently online <&co>('
              - else if <[online_result].size> == 1:
                - define 'online_result:There is 1 player online<&co> <[online_result].sort_by_value[].comma_separated>'
              - else:
                - define online_count:<[online_result].size>
                - define 'online_result:There are <[online_count]> players online<&co> <[online_result].sort_by_value[].comma_separated>'

              - discordmessage id:drustcraft_discord_bot channel:<context.channel> <[online_result]>
            - case skin:
              - define player_name:<[args].get[2]||<empty>>
              - if <[player_name]> == <empty>:
                - discordmessage id:drustcraft_discord_bot channel:<context.channel> "I'm not sure what player you want me to lookup!"
              - else:
                - define target_player:<server.match_offline_player[<[player_name]>]>
                - if <[target_player].name> != <[player_name]>:
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "I've never seen **<[player_name]>** around these parts!"
                - else:
                  - if <[target_player].name.starts_with[*]>:
                    - discordmessage id:drustcraft_discord_bot channel:<context.channel> "**<[target_player].name>** is a tablet player. I can't get skins for them yet"
                  - else:
                    - discordmessage id:drustcraft_discord_bot channel:<context.channel> '<discord_embed.with[description].as[Here is the skin of **<[target_player].name>**].with[image].as[https://crafatar.com/skins/<[target_player].uuid>]>'
            
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
              
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Server time is currently <[hours]>:<[mins]><[ampm]>"
              
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
                    - define message:<[message]><&co>green_circle<&co><&sp>
                  - else if <[value].get[status]> == warning:
                    - define message:<[message]><&co>yellow_circle<&co><&sp>
                  - else:
                    - define message:<[message]><&co>red_circle<&co><&sp>
                  
                  - define 'message:<[message]><[value].get[name]> (<[value].get[type]>)<n>'
              
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> <[message]>
                
            - case value:
              - define item_name:<[args].remove[1].separated_by[_]>
              - if <[item_name]> == <empty>:
                - discordmessage id:drustcraft_discord_bot channel:<context.channel> "I'm not sure what item you want me to lookup!"
              - else:
                - define item_title:<[item_name].replace_text[_].with[<&sp>].to_titlecase>
                - define item_value:<proc[drustcraftp_value.get].context[<[item_name]>]>
                
                - if <[item_value].get[value]> == 0:
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "**<[item_title]>** has no value here"
                - else:
                  - define response:<element[]>
                  
                  - define 'response:My source says that value of a **<[item_title]>** is around'
                  
                  - define item_value_list:<list[]>
                  
                  - if <[item_value].get[netherite_blocks]> > 0:
                    - define 'item_text:<[item_value].get[netherite_blocks]> Netherite block'
                    - if <[item_value].get[netherite_blocks]> > 1:
                      - define item_text:<[item_text]>s
                      
                    - define item_value_list:|:<[item_text]>
                  - if <[item_value].get[netherite_ingots]> > 0:
                    - define 'item_text:<[item_value].get[netherite_ingots]> Netherite ingot'
                    - if <[item_value].get[netherite_ingots]> > 1:
                      - define item_text:<[item_text]>s
                      
                    - define item_value_list:|:<[item_text]>
                  - if <[item_value].get[emeralds]> > 0:
                    - define 'item_text:<[item_value].get[emeralds]> Emerald'
                    - if <[item_value].get[emeralds]> > 1:
                      - define item_text:<[item_text]>s
                      
                    - define item_value_list:|:<[item_text]>
                  - if <[item_value].get[diamond]> > 0:
                    - define 'item_text:<[item_value].get[diamond]> Diamond'
                    - if <[item_value].get[diamond]> > 1:
                      - define item_text:<[item_text]>s
                      
                    - define item_value_list:|:<[item_text]>
                  - if <[item_value].get[iron_ingots]> > 0:
                    - define 'item_text:<[item_value].get[iron_ingots]> Iron ingot'
                    - if <[item_value].get[iron_ingots]> > 1:
                      - define item_text:<[item_text]>s
                      
                    - define item_value_list:|:<[item_text]>

                  - if <[item_value_list].size> > 1:
                    - define last_item:<[item_value_list].last>
                    
                    - define 'response:<[response]> <[item_value_list].remove[last].separated_by[, ]>'
                    - define 'response:<[response]> and <[last_item]>'
                  - else:
                    - define 'response:<[response]> <[item_value_list].separated_by[, ]>'
                  
                  - debug log <[item_value_list]>

                  - if <[item_value].get[min_qty]> > 1:
                    - define 'response:<[response]> for every <[item_value].get[min_qty]> pieces'
                
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> <[response]>

            - case link:
              - run drustcraftt_discord.link_player def:<context.channel>|<context.new_message.author>|<[args].get[2]||<empty>>

            - case unlink:
              - ~sql id:drustcraft_database 'query:SELECT `player_uuid` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE `discord_user_id`="<context.new_message.author.id>"' save:sql_result
              - if <entry[sql_result].result.size||0> >= 1:
                - foreach <entry[sql_result].result>:
                  - define row:<[value].split[/]||<list[]>>
                  - define player_uuid:<[row].get[1]||<empty>>
                  - define discord_user_id:<[row].get[2]||<empty>>

                  - run drustcraftt_discord.unlink_player def:<player[<[player_uuid]>]>
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Hey <context.new_message.author.mention>, you are no longer linked to the Minecraft account **<player[<[player_uuid]>].name>**"

              - else:
                - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Hey <context.new_message.author.mention>, you are not linked with a Minecraft account!"
            
            - case uuid:
              - define player_name:<[args].get[2]||<empty>>
              - define target_player:<server.match_offline_player[<[player_name]>]||<empty>>
              
              - if <[player_name]> != <empty>:
                - if <[target_player]> != <empty>:
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "The uuid of **<[target_player].name>** is <[target_player].uuid>"
                - else:
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Could not find any info on **<[player_name]>**"
              - else:
                - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Which player did you want to know about?"
            
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
                  
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "**<[target_player].name>** <[online]> at X: <[x]> Z: <[z]><[region]> in <[world]>."
                - else:
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Could not find any info on **<[player_name]>**"
              - else:
                - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Which player did you want to know about?"
            
            - case whois:
              - define discord_name:<[args].remove[1].space_separated||<empty>>
              
              - if <[discord_name]> != <empty>:
                - define found:false
                
                - ~sql id:drustcraft_database 'query:SELECT `player_uuid`,`discord_user_id` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE 1' save:sql_result
                - if <entry[sql_result].result.size||0> >= 1:
                  - foreach <entry[sql_result].result>:
                    - define row:<[value].split[/]||<list[]>>
                    - define player_uuid:<[row].get[1]||<empty>>
                    - define discord_user_id:<[row].get[2]||<empty>>
                    
                    - define real_discord_name:<discord_user[drustcraft_discord_bot,<[discord_user_id]>].nickname[<server.flag[drustcraft_discord_server_id]>]||<discord_user[drustcraft_discord_bot,<[discord_user_id]>].name>>
                      
                      
                    - if <[real_discord_name].regex_matches[.*<[discord_name]>.*]>:
                      - define found:true
                      - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Discord user **<[real_discord_name]>** is known as player **<player[<[player_uuid]>].name>**"
                
                - if <[found]> == false:
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Could not find any info on **<[discord_name]>**"
                
            - case player:
              - define player_name:<[args].get[2]||<empty>>
              - define target_player:<server.match_offline_player[<[player_name]>]||<empty>>
              
              - if <[target_player]> != <empty>:
                - define found:false
                
                - ~sql id:drustcraft_database 'query:SELECT `discord_user_id` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE `player_uuid`="<[target_player].uuid>"' save:sql_result
                - if <entry[sql_result].result.size||0> >= 1:
                  - foreach <entry[sql_result].result>:
                    - define row:<[value].split[/]||<list[]>>
                    - define discord_user_id:<[row].get[1]||<empty>>
                    
                    - define real_discord_name:<discord_user[drustcraft_discord_bot,<[discord_user_id]>].nickname[<server.flag[drustcraft_discord_server_id]>]||<discord_user[drustcraft_discord_bot,<[discord_user_id]>].name>>
                    - define found:true
                    - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Player **<[target_player].name>** is known as discord user **<[real_discord_name]>**"
                
                - if <[found]> == false:
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Could not find any info on **<[player_name]>**"
                
              - else:
                - discordmessage id:drustcraft_discord_bot channel:<context.channel> "Which player did you want to know about?"
            
            - case joke:
              - define jokes:<yaml[drustcraft_discord].list_keys[discord.jokes]||<list[]>>
              
              - if <[jokes].size> > 0:
                - foreach <yaml[drustcraft_discord].read[discord.jokes.<yaml[drustcraft_discord].list_keys[discord.jokes].random>]||<list[]>>:
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> <[value]>
                  - wait 60t
              - else:
                - discordmessage id:drustcraft_discord_bot channel:<context.channel> "I got no jokes today"
            
            - case event events:
              - define event_list:<proc[drustcraftp_event.running]>
              
              - if <[event_list].size> > 0:
                - if <[event_list].size> > 1:
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "The following events are currently running:"
                  - foreach <[event_list]>:
                    - discordmessage id:drustcraft_discord_bot channel:<context.channel> "  • <proc[drustcraftp_event.title].context[<[key]>]> for another <proc[drustcraftp_event.remaining].context[<[key]>].formatted_words>"
                - else:
                  - define event_id:<[event_list].keys.get[1]>
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "The <proc[drustcraftp_event.title].context[<[event_id]>]> event is running for another <proc[drustcraftp_event.remaining].context[<[event_id]>].formatted_words>"
              - else:
                - discordmessage id:drustcraft_discord_bot channel:<context.channel> "There are no events currently running in Drustcraft"
            
            - case weather:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> "The weather bureau is reporting the following conditions:"
              - wait 20t
              - foreach <server.worlds>:
                - define 'weather:Find and Sunny'
                
                - choose <[value].environment>:
                  - case NETHER:
                    - define 'weather:<list[Hot and humid|Fine but enjoy the lava|...|Overcast, jk].random>'
                  - case THE_END:
                    - define 'weather:<list[Dark|...].random>'
                  - default:
                    - if <[value].has_storm>:
                      - if <[value].thundering>:
                        - define weather:Thunderstorms
                      - else:
                        - define 'weather:Overcast, possible rain and snow'
                
                - discordmessage id:drustcraft_discord_bot channel:<context.channel> "  • **<[value].name.replace_text[_].with[<&sp>].to_titlecase>**: <[weather]>"
                - wait 2t
                  
            
            - default:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> "What you talking about?"
              
        - else if <context.channel.id> == <server.flag[drustcraft_discord_channel_chat]>:
          - if !<context.new_message.author.is_bot>:
            - narrate '<&3><&lt>D<&gt><&7>[<context.new_message.author.nickname[<server.flag[drustcraft_discord_server_id]>]||<context.new_message.author.name>>] <&f><[message]>' targets:<server.online_players>


drustcraftt_discord:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <discord[drustcraft_discord_bot]||<empty>> == <empty>:
      - ~discordconnect id:drustcraft_discord_bot tokenfile:drustcraft_data/discord_token.txt

    - if <yaml.list.contains[drustcraft_discord]>:
      - yaml unload id:drustcraft_discord
  
    - if <server.has_file[/drustcraft_data/discord.yml]>:
      - yaml load:/drustcraft_data/discord.yml id:drustcraft_discord
    - else:
      - yaml create id:drustcraft_discord
      - yaml savefile:/drustcraft_data/discord.yml id:drustcraft_discord

    - waituntil <server.sql_connections.contains[drustcraft_database]>
    
      # - if <yaml[drustcraft_server].contains[drustcraft.regenerate.radius]> == false:
      #   - yaml id:drustcraft_server set drustcraft.regenerate.radius:20

    - flag server drustcraft_discord_server_id:782787130334248973
    - flag server drustcraft_discord_channel_general:803069653273542696
    - flag server drustcraft_discord_channel_bot:855647065841467392
    - flag server drustcraft_discord_channel_chat:804613169631854632
    
    - run drustcraftt_discord.update_status

    - define create_tables:true
    - ~sql id:drustcraft_database 'query:SELECT version FROM <server.flag[drustcraft_database_table_prefix]>drustcraft_version WHERE name="drustcraft_discord";' save:sql_result
    - if <entry[sql_result].result.size||0> >= 1:
      - define row:<entry[sql_result].result.get[1].split[/]||0>
      - define create_tables:false
      #- if <[row]> >= 2 || <[row]> < 1:
        # Weird version error

    - if <[create_tables]>:
      - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_version` (`name`,`version`) VALUES ("drustcraft_discord",'1');'
      - ~sql id:drustcraft_database 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` (`id` INT NOT NULL AUTO_INCREMENT, `player_uuid` VARCHAR(255) NOT NULL, `discord_user_id` VARCHAR(255), `discord_link_code` VARCHAR(4), PRIMARY KEY (`id`));'


    - waituntil <yaml.list.contains[drustcraft_tab_complete]>
    - run drustcraftt_tab_complete.completions def:discord|link
    - run drustcraftt_tab_complete.completions def:discord|unlink  
  
  save:
    - yaml id:drustcraft_discord savefile:/drustcraft_data/discord.yml
  
  update_status:
    - if <discord[drustcraft_discord_bot]||<empty>> != <empty>:
      - define 'activity_list:<list[Watching Drustcraft|Playing Drustcraft|Playing Minecraft|Watching a raid|Playing with Guards|Watching for Phantoms|Listening Music|Listening Zombies|Watching Fireworks|Playing with Bees|Listening Randoms|Watching <server.online_players.parse[name].random||<element[the Server]>>]>'
      - define activity:<[activity_list].random>
      
      - ~discord id:drustcraft_discord_bot status "<[activity].after[<&sp>]>" "status:ONLINE" "activity:<[activity].before[<&sp>]>"
  
  message:
    - define message:<[1]>
    
    - if <discord[drustcraft_discord_bot]||<empty>> != <empty>:
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> <[message]>

  embed:
    - define message:<[1]>
    - define colour:<[2]||<empty>>
    - define imageUrl:<[3]||<empty>>

    - define embed:<discord_embed.with[author_name].as[<[message]>]>
    - if <[colour]> != <empty>:
      - define embed:<[embed].with[color].as[<[colour]>]>
    - if <[imageUrl]> != <empty>:
      - define embed:<[embed].with[author_icon_url].as[<[imageUrl]>]>
    
    - if <discord[drustcraft_discord_bot]||<empty>> != <empty>:
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> <[embed]>
  
  update_player_roles:
    - define target_player:<[1]>
    - define discord_user_id:<empty>
    
    - ~sql id:drustcraft_database 'query:SELECT `discord_user_id` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE (`player_uuid`="<[target_player].uuid>")' save:sql_result
    - if <entry[sql_result].result.size||0> >= 1:
      - foreach <entry[sql_result].result>:
        - define row:<[value].split[/]||<list[]>>
        - define discord_user_id:<[row].get[1]||<empty>>
        
        - if <[discord_user_id]> == null:
          - define discord_user_id:<empty>
    
    - if <[discord_user_id]> != <empty>:
      - if <[target_player].groups.contains[staff]>:
        - discord discord id:drustcraft_discord_bot add_role user:<[discord_user_id]> role:787809504833699850 group:<server.flag[drustcraft_discord_server_id]>
      - else:
        - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:787809504833699850 group:<server.flag[drustcraft_discord_server_id]>
        
      - if <[target_player].groups.contains[moderator]>:
        - discord discord id:drustcraft_discord_bot add_role user:<[discord_user_id]> role:787809695099256884 group:<server.flag[drustcraft_discord_server_id]>
      - else:
        - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:787809695099256884 group:<server.flag[drustcraft_discord_server_id]>
        
      - if <[target_player].groups.contains[builder]>:
        - discord discord id:drustcraft_discord_bot add_role user:<[discord_user_id]> role:857087745976303618 group:<server.flag[drustcraft_discord_server_id]>
      - else:
        - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:857087745976303618 group:<server.flag[drustcraft_discord_server_id]>
        
      
  clear_player_roles:
    - define target_player:<[1]>
    - define discord_user_id:<empty>
    
    - ~sql id:drustcraft_database 'query:SELECT `discord_user_id` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE (`player_uuid`="<[target_player].uuid>")' save:sql_result
    - if <entry[sql_result].result.size||0> >= 1:
      - foreach <entry[sql_result].result>:
        - define row:<[value].split[/]||<list[]>>
        - define discord_user_id:<[row].get[1]||<empty>>
    
    - if <[discord_user_id]> != <empty>:
      - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:787809504833699850 group:<server.flag[drustcraft_discord_server_id]>
      - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:787809695099256884 group:<server.flag[drustcraft_discord_server_id]>
      - discord discord id:drustcraft_discord_bot remove_role user:<[discord_user_id]> role:857087745976303618 group:<server.flag[drustcraft_discord_server_id]>
  
  
  
  link_player:
    - define channel:<[1]>
    - define author:<[2]>
    - define link_code:<[3]||<empty>>
    
    - if <[link_code]> != <empty>:
      - define player_uuid:<empty>
      
      - ~sql id:drustcraft_database 'query:SELECT `player_uuid` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE (`discord_link_code`="<[link_code]>")' save:sql_result
      - if <entry[sql_result].result.size||0> >= 1:
        - foreach <entry[sql_result].result>:
          - define row:<[value].split[/]||<list[]>>
          - define player_uuid:<[row].get[1]||<empty>>
      
      - if <[player_uuid]> != <empty>:
        - ~sql id:drustcraft_database 'update:UPDATE `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` SET `discord_user_id`="<[author].id>", `discord_link_code`=NULL WHERE (`discord_link_code`="<[link_code]>")' save:sql_result
        - discordmessage id:drustcraft_discord_bot channel:<[channel]> "Hey <[author].mention>, you are now linked with player <player[<[player_uuid]>].name>"
      - else:
        - discordmessage id:drustcraft_discord_bot channel:<[channel]> "Hey, I could not find that discord link code"
      
    - else:
      - discordmessage id:drustcraft_discord_bot channel:<[channel]> "You can link your Minecraft account to this Discord server by typing `/discord link` while in Drustcraft"
  
  unlink_player:
    - define target_player:<[1]>
    - run drustcraftt_discord.clear_player_roles def:<[target_player]>
    - ~sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE (`player_uuid`="<[target_player].uuid>")'


  
drustcraftc_discord:
  type: command
  debug: false
  name: discord
  description: Manages your discord link
  usage: /discord <&lt>link|unlink<&gt>
  permission: drustcraft.discord
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:discord
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case link:
        - define discord_user_id:null
        - define discord_link_code:null
        
        - ~sql id:drustcraft_database 'query:SELECT `discord_user_id`,`discord_link_code` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE (`player_uuid`="<player.uuid>")' save:sql_result
        - if <entry[sql_result].result.size||0> >= 1:
          - foreach <entry[sql_result].result>:
            - define row:<[value].split[/]||<list[]>>
            - define discord_user_id:<[row].get[1]||<empty>>
            - define discord_link_code:<[row].get[2]||<empty>>
        
        - if <[discord_user_id]> == null:
          - if <[discord_link_code]> == null:
            - define found:false
            - define discord_link_code:null
            
            - while !<[found]>:
              - define discord_link_code:<util.random.int[1000].to[9999]>
              - ~sql id:drustcraft_database 'query:SELECT `id` FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE (`discord_link_code`=<[discord_link_code]>)' save:sql_result
              - if <entry[sql_result].result.size||0> == 0:
                - define found:true

            - ~sql id:drustcraft_database 'update:DELETE FROM `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` WHERE (`player_uuid`="<player.uuid>")'
            - ~sql id:drustcraft_database 'update:INSERT INTO `<server.flag[drustcraft_database_table_prefix]>drustcraft_discord` (`player_uuid`,`discord_link_code`) VALUES("<player.uuid>", <[discord_link_code]>)'
          
          - narrate '<&e>Jump into Discord and enter <&f>!link <[discord_link_code]>'
        - else:
          - narrate '<&e>You already have linked your Minecraft account to a Discord user. Use <&f>/discord unlink <&e>to remove this link'

      - case unlink:
        - run drustcraftt_discord.unlink_player def:<player>
        - narrate '<&e>Any Discord user links to this player has been removed.'
        
      - default:
        - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
