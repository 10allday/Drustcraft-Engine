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
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_bot]> ':white_check_mark: **Server <bungee.server> has started**'
      
    on shutdown:
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_bot]> ':octagonal_sign: **Server <bungee.server> has stopped**'
      
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
      
    on player chats priority:100:
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> '**<player.name>** » <context.message>'
    
    on player death:
      - define 'message:<discord_embed.with[color].as[#000000].with[author_icon_url].as[https://crafatar.com/avatars/<player.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<context.message||died>]>'
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_bot]> <[message]>
      
    # on player completes advancement:
    #   - define 'message:<discord_embed.with[color].as[#FFFF00].with[author_icon_url].as[https://crafatar.com/avatars/<player.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<player.name> has made the advancement <context.advancement>]>'
    #   - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> <[message]>
    
    on system time hourly:
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
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> 'You can connect to the Drustcraft server at **play.drustcraft.com.au**, bedrock or tablet players need to use port **20123**'
            
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

            - case tps:
              - define tps_result:<list[]>
              - foreach <bungee.list_servers.sort_by_value[]>:
                - ~bungeetag server:<[value]> <server.recent_tps.get[1].round_to[1]> save:tps
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
                  - if <[item_value].get[gold_ingots]> > 0:
                    - define 'item_text:<[item_value].get[gold_ingots]> Gold ingot'
                    - if <[item_value].get[gold_ingots]> > 1:
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
            - default:
              - discordmessage id:drustcraft_discord_bot channel:<context.channel> "What you talking about?"


drustcraftt_discord:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <discord[drustcraft_discord_bot]||<empty>> == <empty>:
      - ~discordconnect id:drustcraft_discord_bot tokenfile:drustcraft_data/discord_token.txt
    
    - flag server drustcraft_discord_channel_general:803069653273542696
    - flag server drustcraft_discord_channel_bot:855647065841467392
    - flag server drustcraft_discord_channel_chat:804613169631854632
    
    - run drustcraftt_discord.update_status
    #ex ~discordmessage id:drustcraft_discord_bot channel:<discord[drustcraft_discord_bot].group[Drustcraft].channel[bot-taunting]> "Hello world!"
  
  update_status:
    - if <discord[drustcraft_discord_bot]||<empty>> != <empty>:
      - define 'activity_list:<list[Watching Drustcraft|Playing Drustcraft|Playing Minecraft|Watching a raid|Playing with Guards|Watching for Phantoms|Listening Music|Listening Zombies]>'
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

  
