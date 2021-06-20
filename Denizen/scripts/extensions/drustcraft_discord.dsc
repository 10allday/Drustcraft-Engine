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
      - wait 60t
      - define 'message:<discord_embed.with[color].as[#00ff00].with[author_icon_url].as[https://crafatar.com/avatars/<context.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<context.name> joined the network]>'
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> <[message]>
      
    on bungee player leaves network:
      - define 'message:<discord_embed.with[color].as[#ff0000].with[author_icon_url].as[https://crafatar.com/avatars/<context.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<context.name> left the network]>'
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> <[message]>

    on player joins:
      - wait 60t
      - define 'message:<discord_embed.with[color].as[#00ffff].with[author_icon_url].as[https://crafatar.com/avatars/<player.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<player.name> connected to <bungee.server.to_titlecase>]>'
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> <[message]>
      
    on player chats priority:100:
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> '**<player.name>** » <context.message>'
    
    on player death:
      - define 'message:<discord_embed.with[color].as[#000000].with[author_icon_url].as[https://crafatar.com/avatars/<player.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<player.name> <context.message||died>]>'
      - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> <[message]>
      
    # on player completes advancement:
    #   - define 'message:<discord_embed.with[color].as[#FFFF00].with[author_icon_url].as[https://crafatar.com/avatars/<player.uuid>?size=128&default=MHF_Steve&overlay].with[author_name].as[<player.name> has made the advancement <context.advancement>]>'
    #   - discordmessage id:drustcraft_discord_bot channel:<server.flag[drustcraft_discord_channel_chat]> <[message]>
    
    on system time hourly:
      - run drustcraftt_discord.update_status
    
    on discord message received:
      - if <context.bot.name.equals[drustcraft_discord_bot]>:
        - define message:<context.new_message.text_stripped>
        
        - if <[message].starts_with[<&at>Drustcraft<&sp>]>:
          - define message:<[message].after[<&at>Drustcraft<&sp>]>
          
          #- discordmessage id:drustcraft_discord_bot channel:<context.channel> <context.new_message.author.name>
          
          - if <[message].starts_with[!]>:
            - define args:<[message].after[!].split[<&sp>]>
            - choose <[args].get[1]>:
              - case help:
                - discordmessage id:drustcraft_discord_bot channel:<context.channel> 'Howdy stranger, you can ask me for a few things such as `!tps` for the current server TPS, `!online` to see who is online or even `!value <&lt>item<&gt>` for what an item is worth'
              - case ip server:
                - discordmessage id:drustcraft_discord_bot channel:<context.channel> 'You can connect to the Drustcraft server at **play.drustcraft.com.au**, bedrock or tablet players need to use port **20123**'
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
              - case value:
                - define item_name:<[args].get[2]>
                - if <[item_name]> == <empty>:
                  - discordmessage id:drustcraft_discord_bot channel:<context.channel> "I'm not sure what item you want me to lookup!"
                - else:
                  - define item_title:<item[<[item_name]>].material.translated_name.parsed||<[item_name]>>
                  - define item_value:<proc[drustcraftp_value.get].context[<[item_name]>]>
                  
                  - if <[item_value].get[value]> == 0:
                    - discordmessage id:drustcraft_discord_bot channel:<context.channel> "**<[item_name]>** has no value here"
                  - else:
                    - define response:<element[]>
                    
                    - define 'response:My source says that value of **<[item_title]>** is around'
                    
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
          - else:
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

  
