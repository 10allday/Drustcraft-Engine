# Drustcraft - Cooldown
# Player Cooldowns
# https://github.com/drustcraft/drustcraft

drustcraftw_cooldown:
  type: world
  debug: false
  events:
    after player logs in:
      - wait 1t
      - if <server.online_players.contains[<player>]>:
        - cast heal d:20 entity:<player>
      
    on player respawns:
      - cast heal d:40 entity:<player>

    on player changes gamemode to SURVIVAL:
      - cast heal d:20 entity:<player>

    on entity teleports:
      - if <context.entity.is_player||false>:
        - cast heal d:20 entity:<player>
