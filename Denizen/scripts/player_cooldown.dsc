# Player Cooldown
# https://github.com/drustcraft/drustcraft

drustcraftw_cooldown:
  type: world
  debug: false
  version: 1
  events:
    after player joins:
      - wait 10t
      - if <server.online_players.contains[<player>]>:
        - cast DAMAGE_RESISTANCE duration:20 amplifier:10 entity:<player> hide_particles

    on player respawns:
      - cast DAMAGE_RESISTANCE duration:20 amplifier:10 entity:<player> hide_particles

    on player changes gamemode to SURVIVAL:
      - cast DAMAGE_RESISTANCE duration:40 amplifier:10 entity:<player> hide_particles

    # spam right click causes this to fire
    # on entity teleports:
    #   - if <context.entity.is_player||false>:
    #     - cast DAMAGE_RESISTANCE duration:20 amplifier:10 entity:<player> hide_particles


drustcraftt_cooldown_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>
    - flag <server> drustcraft.module.cooldown:<script[drustcraftw_cooldown].data_key[version]>