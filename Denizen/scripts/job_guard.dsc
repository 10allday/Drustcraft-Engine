# Drustcraft - Guard
# https://github.com/drustcraft/drustcraft

drustcraftw_job_guard:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_job_guard_load

    on script reload:
      - run drustcraftt_job_guard_load


drustcraftt_job_guard_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_npc]>:
      - log ERROR 'Drustcraft Job Guard: Drustcraft NPC is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.npc]>
    - run drustcraftt_npc_job_register def:guard|drustcraftt_job_guard
    - flag server drustcraft.module.job_guard:<script[drustcraftw_job_guard].data_key[version]>


drustcraftt_job_guard:
  type: task
  debug: false
  definitions: action|npc|player
  script:
    - choose <[action]>:
      - case add:
        - if !<[npc].traits.contains[sentinel]>:
          - trait state:true sentinel to:<[npc]>
        - adjust <[npc]> skin_layers:<[npc].skin_layers.exclude[cape]>
        - adjust <[npc]> name:<&e>Guard
        - equip <[npc]> hand:<item[netherite_sword]>
        - equip <[npc]> offhand:<item[shield]>
        - give <item[crossbow]> quantity:1 to:<[npc].inventory>
        - execute as_player 'sentinel addtarget monsters --id <[npc].id>'
        - execute as_player 'sentinel addtarget event:pvp --id <[npc].id>'
        - execute as_player 'sentinel addtarget event:pvsentinel --id <[npc].id>'
        - execute as_player 'sentinel autoswitch true --id <[npc].id>'
        - execute as_player 'sentinel spawnpoint --id <[npc].id>'
        - adjust <player> selected_npc:<[npc]>
        - execute as_player 'npc skin --url https://www.drustcraft.com.au/skins/guard.png'

      - case remove:
        - if <[npc].traits.contains[sentinel]>:
          - trait state:false sentinel to:<[npc]>

      - case entry:
        - if <util.random.int[0].to[1]> == 0:
          - random:
            - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|Hey there, Make sure you dont leave anything laying around. There are thieves everywhere]>'
            - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|Hello <[player].name>]>, We will try to protect you from mobs and PVP. But sometimes, I like to see how strong you are'
            - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|<[player].name> take what you can, it may not be there when you come back]>'
