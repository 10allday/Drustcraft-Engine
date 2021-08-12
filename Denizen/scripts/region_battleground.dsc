# Drustcraft - Battleground
# https://github.com/drustcraft/drustcraft

drustcraftw_region_battleground:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - ~run drustcraftt_region_battleground_load

    on script reload:
      - ~run drustcraftt_region_battleground_load

    on entity death:
      - if <context.entity.is_player||false>:
        - if <proc[drustcraftp_region_location_type].context[<context.entity.location>]> == battleground:
          - drop <item[player_head[skull_skin=<context.entity.skull_skin>|<context.entity.name>]]> <context.entity.location.random_offset[3,0,3]> quantity:1

        - if <context.entity.has_flag[drustcraft.battleground.engaged]>:
          - flag <context.entity> drustcraft.battleground.engaged:!

        - foreach <server.online_players> as:player:
          - if <[player].has_flag[drustcraft.battleground.engaged]> && <[player].flag[drustcraft.battleground.engaged].contains[<context.entity.uuid>]>:
            - flag <[player]> drustcraft.battleground.engaged:<-:<context.entity.uuid>

    on entity damaged:
      - if <context.entity.is_player||false>:
        - if <context.damager.is_player||false>:
          - if !<context.entity.has_flag[drustcraft.battleground.engaged]> || !<context.entity.flag[drustcraft.battleground.engaged].contains[<context.damager.uuid>]>:
            - flag <context.entity> drustcraft.battleground.engaged:|:<context.damager.uuid>
          - if !<context.damager.has_flag[drustcraft.battleground.engaged]> || !<context.damager.flag[drustcraft.battleground.engaged].contains[<context.entity.uuid>]>:
            - flag <context.damager> drustcraft.battleground.engaged:|:<context.entity.uuid>


drustcraftt_region_battleground_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_region]>:
      - log ERROR 'Drustcraft Battleground: Drustcraft Region is required to be installed'
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_player]>:
      - log ERROR 'Drustcraft Battleground: Drustcraft Player is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.region]>

    - run drustcraftt_region_type_register def:battleground|drustcraftt_region_battleground
    - flag server drustcraft.module.region_battleground:<script[drustcraftw_region_battleground].data_key[version]>


drustcraftt_region_battleground:
  type: task
  debug: false
  definitions: command|world|region|type|title
  script:
    - choose <[command]>:
      - case enter:
        - playsound <player.location> sound:UI_TOAST_CHALLENGE_COMPLETE
        - random:
          - narrate '<&6>You feel an evil presence watching over you'
          - narrate '<&6>[Daevas] No one should be left standing'
          - narrate '<&6>[Daevas] Prove your worth here'
          - narrate '<&6>Daevas laughs at you'
          - narrate '<&6>[Daevas] Leave while you can'
          - narrate '<&6>[Daevas] Ahh! A new compeditor'
        - title title:<&6><[title]> subtitle:<&6>Battlegrounds
      - case exit:
        - if <player.has_flag[drustcraft.battleground.engaged]> && <player.flag[drustcraft.battleground.engaged].size> > 0:
          - flag player 'drustcraft.player.death_message:Daevas doesn<&sq>t like cowards'
          - hurt <player.health> <player>
          - drop <item[player_head[skull_skin=<player.skull_skin>|<player.name>]]> <player.location.random_offset[3,0,3]> quantity:1
