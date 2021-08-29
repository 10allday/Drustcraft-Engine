# Drustcraft - Job Bank
# https://github.com/drustcraft/drustcraft

drustcraftw_job_banker:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_job_banker_load

    on script reload:
      - run drustcraftt_job_banker_load

    on player closes inventory:
      - if <context.inventory.title.starts_with[Banker]>:
        - define slot_map:<context.inventory.map_slots>
        - note remove as:drustcraft_bank_<player.uuid>
        - run drustcraftt_setting_set def:drustcraft.bank.<player.uuid>|<[slot_map].to_json>
        - if <player.has_flag[drustcraft.npc.last_clicked]>:
          - define target_npc:<player.flag[drustcraft.npc.last_clicked]>
          - random:
            - narrate '<proc[drustcraftp_npc_chat_format].context[<[target_npc]>|See ya round]>'
            - narrate '<proc[drustcraftp_npc_chat_format].context[<[target_npc]>|I<&sq>ll take good care of all this]>'

drustcraftt_job_banker_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_npc]>:
      - log ERROR 'Drustcraft Job Banker: Drustcraft NPC is required to be installed'
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - log ERROR 'Drustcraft Job Banker: Drustcraft Setting is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.npc]>
    - waituntil <server.has_flag[drustcraft.module.setting]>
    - run drustcraftt_npc_job_register def:banker|drustcraftt_job_banker|Banker
    - flag server drustcraft.module.job_banker:<script[drustcraftw_job_banker].data_key[version]>


drustcraftt_job_banker:
  type: task
  debug: false
  definitions: action|target_npc|target_player
  script:
    - choose <[action]>:
      - case click:
        - ~run drustcraftt_setting_get def:drustcraft.bank.<[target_player].uuid> save:result
        - define slot_map:<entry[result].created_queue.determination.get[1]>
        - if <[slot_map]> == null:
          - define slot_map:<map[]>
        - else:
          - define slot_map:<util.parse_yaml[<[slot_map]>]>

        - note <inventory[generic[size=54;title=Banker]]> as:drustcraft_bank_<[target_player].uuid>
        - inventory set d:<inventory[drustcraft_bank_<[target_player].uuid>]> o:<[slot_map]>
        - inventory open d:<inventory[drustcraft_bank_<[target_player].uuid>]>

      - case entry:
        - if <util.random.int[0].to[1]> == 0:
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[target_npc]>|<[target_player].name>, welcome to a town bank]>'
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[target_npc]>|You can click on me to open your personal vault]>'
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[target_npc]>|Anything you store in your bank vault is safe and can be retrieved from any town bank]>'
