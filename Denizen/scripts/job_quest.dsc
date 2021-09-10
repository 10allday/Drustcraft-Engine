# Drustcraft - Quests
# https://github.com/drustcraft/drustcraft

# TODO: Add quest requirement register (previous quest, role, in group, XP)
# TODO: Add cooldown
# TODO: Check NPCs exist
# TODO: Enable/Disable quests
# TODO: Quest IDs need to increment on each change

drustcraftw_job_quest:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_job_quest_load

    on script reload:
      - run drustcraftt_job_quest_load

    on player drops item server_flagged:drustcraft.module.job_quest:
      - define quest_id:<proc[drustcraftp_job_quest_book_to_id].context[<context.item>]>
      - if <[quest_id]> != NULL:
        - remove <context.entity>
        - run drustcraftt_job_quest_player_abandon def:<player>|<[quest_id]>

    on entity picks up item server_flagged:drustcraft.module.job_quest:
      - if <proc[drustcraftp_job_quest_book_to_id].context[<context.item>]> != NULL:
        - remove <context.entity>
        - determine cancelled

    on player closes inventory:
      - if <player.gamemode> == SURVIVAL:
        - define updates:false

        - define quest_list:<list[]>
        - foreach <player.inventory.map_slots> as:inv_item:
          - define quest_id:<proc[drustcraftp_job_quest_book_to_id].context[<[inv_item]>]>
          - if <[quest_id]> != NULL:
            - define quest_list:->:<[quest_id]>

        # remove from other inventory (not player)
        - foreach <context.inventory> key:inv_slot as:inv_item:
          - define quest_id:<proc[drustcraftp_job_quest_book_to_id].context[<[inv_item]>]>
          - if <[quest_id]> != NULL:
            - inventory set slot:<[inv_slot]> o:air d:<context.inventory>

        # abandoned list
        - foreach <proc[drustcraftp_job_quest_player_active_list].context[<player>].exclude[<[quest_list]>]>:
          - define updates:true
          - run drustcraftt_job_quest_player_abandon def:<player>|<[value]>

        # start list
        - foreach <[quest_list].exclude[<proc[drustcraftp_job_quest_player_active_list].context[<player>]>]>:
          - define updates:true
          - run drustcraftt_job_quest_player_start def:<player>|<[value]>

        - run drustcraftt_job_quest_update_markers_player_location def:<player>

    on player changes gamemode to SURVIVAL server_flagged:drustcraft.module.job_quest:
      - run drustcraftt_job_quest_update_markers_player_location def:<player>

    on player breaks block priority:100 server_flagged:drustcraft.module.job_quest:
      - run drustcraftt_job_quest_objective_event def:<player>|block_break|<map[].with[material].as[<context.material.name>].with[location].as[<context.location>]>

    on player places block priority:100 server_flagged:drustcraft.module.job_quest:
      - run drustcraftt_job_quest_objective_event def:<player>|block_place|<map[].with[material].as[<context.material.name>].with[location].as[<context.location>]>

    on player enters cuboid priority:100 server_flagged:drustcraft.module.job_quest:
      - run drustcraftt_job_quest_objective_event def:<player>|enter_region|<map[].with[region].as[<context.area.note_name||null>]>

    on player enters polygon priority:100 server_flagged:drustcraft.module.job_quest:
      - run drustcraftt_job_quest_objective_event def:<player>|enter_region|<map[].with[region].as[<context.area.note_name||null>]>

    on entity dies priority:100:
      - if <context.damager.object_type||<empty>> == PLAYER:
        - define name:<empty>
        - if <context.entity.is_mythicmob||false>:
          - define name:<context.entity.mythicmob.internal_name||<empty>>
        - else:
          - define name:<context.entity.name||<empty>>

        - if <[name]> != <empty>:
          - run drustcraftt_job_quest_objective_event def:<context.damager>|kill_mob|<map[].with[mob_name].as[<[name]>].with[location].as[<context.entity.location>]>


# todo: up to here
drustcraftt_job_quest_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_npc]>:
      - debug ERROR 'Drustcraft Job Quest: Drustcraft NPC is required to be installed'
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR 'Drustcraft Job Quest: Drustcraft DB is required to be installed'
      - stop

    - if !<server.scripts.parse[name].contains[drustcraftw_chatgui]>:
      - debug ERROR 'Drustcraft Job Quest: Drustcraft Chat GUI is required to be installed'
      - stop

    - define create_tables:true
    - ~run drustcraftt_db_get_version def:drustcraft.job_quest save:result
    - define version:<entry[result].created_queue.determination.get[1]>
    - if <[version]> != 1:
      - if <[version]> != null:
        - debug ERROR "Drustcraft Job Quest: Unexpected database version. Ignoring DB storage"
      - else:
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_quest` (`id` INT NOT NULL AUTO_INCREMENT, `title` VARCHAR(128) NOT NULL, `owner` VARCHAR(36) NOT NULL, `npc_start` INT NOT NULL, `npc_end` INT NOT NULL, `npc_end_speak` VARCHAR(255), `repeatable` INT NOT NULL DEFAULT 0, `description` TEXT, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_quest_require` (`id` INT NOT NULL AUTO_INCREMENT, `quest_id` INT NOT NULL, `index` INT NOT NULL, `type` VARCHAR(16) NOT NULL, `data` TEXT, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_quest_give` (`id` INT NOT NULL AUTO_INCREMENT, `quest_id` INT NOT NULL, `material` VARCHAR(255) NOT NULL, `qty` INT NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_quest_objective` (`id` INT NOT NULL AUTO_INCREMENT, `quest_id` INT NOT NULL, `index` INT NOT NULL, `type` VARCHAR(16) NOT NULL, `data` TEXT, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_quest_reward` (`id` INT NOT NULL AUTO_INCREMENT, `quest_id` INT NOT NULL, `material` VARCHAR(255) NOT NULL, `qty` INT NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_quest_player` (`id` INT NOT NULL AUTO_INCREMENT, `quest_id` INT NOT NULL, `uuid` VARCHAR(36) NOT NULL, `completed` INT NOT NULL, start INT NOT NULL, PRIMARY KEY (`id`));'
        - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>job_quest_player_objective` (`id` INT NOT NULL AUTO_INCREMENT, `quest_id` INT NOT NULL, `uuid` VARCHAR(36) NOT NULL, `index` INT NOT NULL, `data` TEXT, `completed` INT, PRIMARY KEY (`id`));'
        - run drustcraftt_db_set_version def:drustcraft.job_quest|1

    # Load quests
    - ~sql id:drustcraft 'query:SELECT `id`, `title`, `owner`, `npc_start`, `npc_end`, `npc_end_speak`, `repeatable`, `description` FROM `<server.flag[drustcraft.db.prefix]>job_quest`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/].unescaped||<list[]>>
      - define quest_id:<[row].get[1]||<empty>>
      - define title:<[row].get[2].unescaped||<empty>>
      - define owner:<[row].get[3]||<empty>>
      - define npc_start:<[row].get[4]||<empty>>
      - define npc_end:<[row].get[5]||<empty>>
      - define npc_end_speak:<[row].get[6].unescaped||<empty>>
      - define repeatable:<[row].get[7]||<empty>>
      - define description:<[row].get[8].unescaped||<empty>>

      - flag server drustcraft.job_quest.quest.<[quest_id]>.title:<[title]>
      - flag server drustcraft.job_quest.quest.<[quest_id]>.owner:<[owner]>
      - flag server drustcraft.job_quest.quest.<[quest_id]>.npc_start:<[npc_start]>
      - flag server drustcraft.job_quest.quest.<[quest_id]>.npc_end:<[npc_end]>
      - flag server drustcraft.job_quest.quest.<[quest_id]>.npc_end_speak:<[npc_end_speak]>
      - flag server drustcraft.job_quest.quest.<[quest_id]>.repeatable:<[repeatable]>
      - flag server drustcraft.job_quest.quest.<[quest_id]>.description:<[description]>

      # Load quest require
      - ~sql id:drustcraft 'query:SELECT `index`, `type`, `data` FROM `<server.flag[drustcraft.db.prefix]>job_quest_require` WHERE `quest_id` = <[quest_id]>;' save:sql_subresult
      - foreach <entry[sql_subresult].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define index:<[row].get[1]||<empty>>
        - define type:<[row].get[2]||<empty>>
        - define data:<[row].get[3].unescaped||<empty>>

        - flag server drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.type:<[type]>
        - flag server drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.data:<[data]>

      # Load quest give
      - ~sql id:drustcraft 'query:SELECT `material`, `qty` FROM `<server.flag[drustcraft.db.prefix]>job_quest_give` WHERE `quest_id` = <[quest_id]>;' save:sql_subresult
      - foreach <entry[sql_subresult].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define material:<[row].get[1]||<empty>>
        - define qty:<[row].get[2]||<empty>>

        - flag server drustcraft.job_quest.quest.<[quest_id]>.give.<[material]>:<[qty]>

      # Load quest objective
      - ~sql id:drustcraft 'query:SELECT `index`, `type`, `data` FROM `<server.flag[drustcraft.db.prefix]>job_quest_objective` WHERE `quest_id` = <[quest_id]>;' save:sql_subresult
      - foreach <entry[sql_subresult].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define index:<[row].get[1]||<empty>>
        - define type:<[row].get[2]||<empty>>
        - define data:<[row].get[3].unescaped||<empty>>

        - flag server drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.type:<[type]>
        - flag server drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.data:<[data]>

      # Load quest reward
      - ~sql id:drustcraft 'query:SELECT `material`, `qty` FROM `<server.flag[drustcraft.db.prefix]>job_quest_reward` WHERE `quest_id` = <[quest_id]>;' save:sql_subresult
      - foreach <entry[sql_subresult].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define material:<[row].get[1]||<empty>>
        - define qty:<[row].get[2]||<empty>>

        - flag server drustcraft.job_quest.quest.<[quest_id]>.reward.<[material]>:<[qty]>

    # Load player quests
    - ~sql id:drustcraft 'query:SELECT `id`, `quest_id`, `uuid`, `completed`, `start` FROM `<server.flag[drustcraft.db.prefix]>job_quest_player`;' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/].unescaped||<list[]>>
      - define id:<[row].get[1]||<empty>>
      - define quest_id:<[row].get[2]||<empty>>
      - define uuid:<[row].get[3].unescaped||<empty>>
      - define completed:<[row].get[4]||<empty>>
      - define start:<[row].get[5]||<empty>>

      - flag server drustcraft.job_quest.player.<[uuid]>.<[quest_id]>.completed:<[completed]>
      - flag server drustcraft.job_quest.player.<[uuid]>.<[quest_id]>.start:<[start]>

      # Load player quest objective
      - ~sql id:drustcraft 'query:SELECT `index`, `data`, `completed` FROM `<server.flag[drustcraft.db.prefix]>job_quest_player_objective` WHERE `quest_id` = <[id]> AND `uuid` = "<[uuid]>";' save:sql_subresult
      - foreach <entry[sql_subresult].result>:
        - define row:<[value].split[/].unescaped||<list[]>>
        - define index:<[row].get[1]||<empty>>
        - define data:<[row].get[3].unescaped||<empty>>
        - define completed:<[row].get[4]||<empty>>
      
        - flag server drustcraft.job_quest.player.<[uuid]>.<[quest_id]>.objective.<[index]>.data:<[data]>
        - flag server drustcraft.job_quest.player.<[uuid]>.<[quest_id]>.objective.<[index]>.completed:<[completed]>

    # TODO: drustcraftt_job_quest
    - waituntil <server.has_flag[drustcraft.module.npc]>
    - run drustcraftt_npc_job_register def:quest|drustcraftt_job_quest_npc
    
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>

      # TODO: TEST
      - run drustcraftt_tabcomplete_completion def:quest|list|_*pageno
      - run drustcraftt_tabcomplete_completion def:quest|info|_*quest_ids
      - run drustcraftt_tabcomplete_completion def:quest|title|_*quest_ids
      - run drustcraftt_tabcomplete_completion def:quest|description|_*quest_ids
      - run drustcraftt_tabcomplete_completion def:quest|owner|_*quest_ids|_*players
      - run drustcraftt_tabcomplete_completion def:quest|repeatable|_*quest_ids|_*bool
      - run drustcraftt_tabcomplete_completion def:quest|npcstart|_*quest_ids|_*npcs
      - run drustcraftt_tabcomplete_completion def:quest|npcend|_*quest_ids|_*npcs
      - run drustcraftt_tabcomplete_completion def:quest|npcendspeak|_*quest_ids
      - run drustcraftt_tabcomplete_completion def:quest|require|_*quest_ids
      - run drustcraftt_tabcomplete_completion def:quest|require|_*quest_ids|add
      - run drustcraftt_tabcomplete_completion def:quest|require|_*quest_ids|edit
      - run drustcraftt_tabcomplete_completion def:quest|require|_*quest_ids|remove
      - run drustcraftt_tabcomplete_completion def:quest|give|_*quest_ids
      - run drustcraftt_tabcomplete_completion def:quest|give|_*quest_ids|add|_*materials|_*int_nozero
      - run drustcraftt_tabcomplete_completion def:quest|give|_*quest_ids|edit|_*materials|_*int_nozero
      - run drustcraftt_tabcomplete_completion def:quest|give|_*quest_ids|remove|_*materials
      - run drustcraftt_tabcomplete_completion def:quest|objective|_*quest_ids
      - run drustcraftt_tabcomplete_completion def:quest|objective|_*quest_ids|add
      - run drustcraftt_tabcomplete_completion def:quest|objective|_*quest_ids|edit
      - run drustcraftt_tabcomplete_completion def:quest|objective|_*quest_ids|remove|_*quest_objectiveindex
      - run drustcraftt_tabcomplete_completion def:quest|reward|_*quest_ids
      - run drustcraftt_tabcomplete_completion def:quest|reward|_*quest_ids|add|_*materials|_*int_nozero
      - run drustcraftt_tabcomplete_completion def:quest|reward|_*quest_ids|edit|_*materials|_*int_nozero
      - run drustcraftt_tabcomplete_completion def:quest|reward|_*quest_ids|remove|_*materials
      - run drustcraftt_tabcomplete_completion def:quest|create


      # TODO: Add the following
#      - run drustcraftt_tabcomplete_completion def:quest|objective|_*quest_ids
      # - run drustcraftt_tabcomplete_completion def:quest|npclist|_*npcs
      # - run drustcraftt_tabcomplete_completion def:quest|regionlist|_*regions|_*pageno
#      - run drustcraftt_tabcomplete_completion def:quest|create
#      - run drustcraftt_tabcomplete_completion def:quest|remove|_*quests
#      - run drustcraftt_tabcomplete_completion def:quest|find
#      - run drustcraftt_tabcomplete_completion def:quest|removeplayer|_*quests|_*players

    - waituntil <server.has_flag[drustcraft.module.player]>
    - run drustcraftt_player_death_drop_confirm_register def:drustcraftp_job_quest_death_drop

    # TODO: drustcraftt_interactor_quest

    # - run drustcraftt_quest.type_register def:block_place|drustcraftt_interactor_quest
    # - run drustcraftt_tab_complete.completions def:quest|addobj|_*quests|block_place|_*materials|_*int|_*regions
    # - run drustcraftt_tab_complete.completions def:quest|editobj|_*quests|_*int|block_place|_*materials|_*int|_*regions

    # - run drustcraftt_quest.type_register def:give|drustcraftt_interactor_quest
    # - run drustcraftt_tab_complete.completions def:quest|addobj|_*quests|give|_*materials|_*int
    # - run drustcraftt_tab_complete.completions def:quest|editobj|_*quests|_*int|give|_*materials|_*int

    # - run drustcraftt_quest.type_register def:enter_region|drustcraftt_interactor_quest
    # - run drustcraftt_tab_complete.completions def:quest|addobj|_*quests|enter_region|_*regions
    # - run drustcraftt_tab_complete.completions def:quest|editobj|_*quests|_*int|enter_region|_*regions

    # - run drustcraftt_quest.type_register def:kill|drustcraftt_interactor_quest
    # - run drustcraftt_tab_complete.completions def:quest|addobj|_*quests|kill|_*hostile|_*int|_*regions
    # - run drustcraftt_tab_complete.completions def:quest|editobj|_*quests|_*int|kill|_*hostile|_*int|_*regions

    # Quest Objectives
    - run drustcraftt_job_quest_objective_register def:block_break|drustcraftt_quest_objective_block_break
    - run drustcraftt_job_quest_objective_register def:block_place|drustcraftt_quest_objective_block_place
    - run drustcraftt_job_quest_objective_register def:give_npc|drustcraftt_quest_objective_give_npc
    - run drustcraftt_job_quest_objective_register def:kill_mob|drustcraftt_quest_objective_kill_mob

    # Quest Requirements
    - run drustcraftt_job_quest_require_register def:quest|drustcraftt_quest_require_quest

    - flag server drustcraft.module.job_quest:<script[drustcraftw_job_quest].data_key[version]>

    - foreach <server.online_players> as:target_player:
      - run drustcraftt_job_quest_update_markers_player_location def:<[target_player]>





  # create:
  #   - define title:<[1]||<empty>>
  #   - define quest_id:0
    
  #   - if <[title]> != <empty>:
  #     - define quest_id:<yaml[drustcraft_quests].list_keys[quests].highest.add[1]||1>
  #     - yaml id:drustcraft_quests set quests.<[quest_id]>.title:<[title]>
  #     - run drustcraftt_quest.save
    
  #   - determine <[quest_id]>
      
  # remove:
  #   - define quest_id:<[1]||<empty>>
    
  #   - if <[quest_id]> != <empty>:
  #     - yaml id:drustcraft_quests set quests.<[quest_id]>:!
  #     - run drustcraftt_quest.save
        
  # owner:
  #   - define quest_id:<[1]||<empty>>
  #   - define target_player:<[2]||<empty>>
    
  #   - if <[quest_id]> != <empty> && <[target_player].object_type> == Player:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.owner:<[target_player].uuid>
  #       - run drustcraftt_quest.save

  # description:
  #   - define quest_id:<[1]||<empty>>
  #   - define description:<[2]||<empty>>
    
  #   - if <[quest_id]> != <empty> && <[description]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.description:<[description]>
  #       - run drustcraftt_quest.save

  # title:
  #   - define quest_id:<[1]||<empty>>
  #   - define title:<[2]||<empty>>
    
  #   - if <[quest_id]> != <empty> && <[title]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.title:<[title]>
  #       - run drustcraftt_quest.save

  # npc_start:
  #   - define quest_id:<[1]||<empty>>
  #   - define npc_id:<[2]||<empty>>
    
  #   - if <[quest_id]> != <empty> && <[npc_id]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.npc_start:<[npc_id]>
  #       - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_interactor_quest
  #       - run drustcraftt_quest.save

  # npc_end:
  #   - define quest_id:<[1]||<empty>>
  #   - define npc_id:<[2]||<empty>>
    
  #   - if <[quest_id]> != <empty> && <[npc_id]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.npc_end:<[npc_id]>
  #       - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_interactor_quest
  #       - run drustcraftt_quest.save

  # npc_end_speak:
  #   - define quest_id:<[1]||<empty>>
  #   - define speak:<[2]||!>
    
  #   - if <[quest_id]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.npc_end_speak:<[speak]>
  #       - run drustcraftt_quest.save

  # add_requirement:
  #   - define quest_id:<[1]||<empty>>
  #   - define req_quest_id:<[2]||<empty>>
    
  #   - if <[quest_id]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.requirements].contains[<[req_quest_id]>]||false> == false:
  #         - yaml id:drustcraft_quests set quests.<[quest_id]>.requirements:->:<[req_quest_id]>
  #         - run drustcraftt_quest.save

  # remove_requirement:
  #   - define quest_id:<[1]||<empty>>
  #   - define req_quest_id:<[2]||<empty>>
    
  #   - if <[quest_id]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.requirements:<-:<[req_quest_id]>
  #       - run drustcraftt_quest.save

  # clear_requirements:
  #   - define quest_id:<[1]||<empty>>
  #   - define req_quest_id:<[2]||<empty>>
    
  #   - if <[quest_id]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.requirements:!
  #       - run drustcraftt_quest.save

  # repeatable:
  #   - define quest_id:<[1]||<empty>>
  #   - define repeatable:<[2]||<empty>>
    
  #   - if <[quest_id]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.repeatable:<[repeatable]>
  #       - run drustcraftt_quest.save

  # add_objective:
  #   - define quest_id:<[1]||<empty>>
  #   - define type:<[2]||<empty>>
  #   - define data:<[3]||<empty>>
  #   - define quantity:<[4]||<empty>>
  #   - define region:<[5]||<empty>>
      
  #   - if <[quest_id]> != <empty> && <[type]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - foreach <yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>:
  #         - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.type]||<empty>> == <[type]> && <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.data]||<empty>> == <[data]> && <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.region]||<empty>> == <[region]>:
  #           - if <[quantity]> != <empty>:
  #             - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[value]>.quantity:+:<[quantity]>
  #             - run drustcraftt_quest.save
  #             - determine <[value]>
        
  #     - define objective_id:<yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives].highest.add[1]||1>
  #     - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.type:<[type]>
  #     - if <[quantity]> != <empty>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.quantity:<[quantity]>
  #     - if <[data]> != <empty>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.data:<[data]>
  #     - if <[region]> != <empty>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.region:<[region]>
      
  #     - run drustcraftt_quest.save
  #     - determine <[objective_id]>

  #   - determine 0

  # remove_objective:
  #   - define quest_id:<[1]||<empty>>
  #   - define objective_id:<[2]||<empty>>
      
  #   - if <[quest_id]> != <empty> && <[objective_id]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>:!      
  #       - run drustcraftt_quest.save

  # update_objective:
  #   - define quest_id:<[1]||<empty>>
  #   - define objective_id:<[2]||<empty>>
  #   - define type:<[3]||<empty>>
  #   - define data:<[4]||<empty>>
  #   - define quantity:<[5]||<empty>>
  #   - define region:<[6]||<empty>>
  #   - define match:0
    
  #   - if <[quest_id]> != <empty> && <[type]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - define exists:false
    
  #   - if <yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives].contains[<[objective_id]>]>:
  #     - define exists:true
    
  #   - foreach <yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives].exclude[<[objective_id]>]||<list[]>>:
  #     - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.type]||<empty>> == <[type]> && <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.data]||<empty>> == <[data]> && <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.region]||<empty>> == <[region]>:
  #       - define match:<[value]>
  #       - foreach stop
    
  #   - if <[match]> > 0:
  #     - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>:!
  #     - if <[quantity]> != <empty>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[match]>.quantity:+:<[quantity]>
  #     - else:
  #       - if <[exists]> == false:
  #         - define objective_id:<yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives].highest.add[1]||1>
    
  #   - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.type:<[type]>
  #   - if <[quantity]> != <empty>:
  #     - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.quantity:<[quantity]>
  #   - else:
  #     - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.quantity:!
  #   - if <[data]> != <empty>:
  #     - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.data:<[data]>
  #   - else:
  #     - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.data:!
  #   - if <[region]> != <empty>:
  #     - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.region:<[region]>
  #   - else:
  #     - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.region:!
    
  #   - run drustcraftt_quest.save

  # add_reward:
  #   - define quest_id:<[1]||<empty>>
  #   - define reward_item:<[2]||<empty>>
  #   - define reward_quantity:<[3]||1>
      
  #   - if <[quest_id]> != <empty> && <[reward_item]> != <empty> && <[reward_quantity]> > 0:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.rewards].contains[<[reward_item]>]||false>:
  #         - yaml id:drustcraft_quests set quests.<[quest_id]>.rewards.<[reward_item]>:+:<[reward_quantity]>
  #       - else:
  #         - yaml id:drustcraft_quests set quests.<[quest_id]>.rewards.<[reward_item]>:<[reward_quantity]>
      
  #       - run drustcraftt_quest.save

  # remove_reward:
  #   - define quest_id:<[1]||<empty>>
  #   - define reward_item:<[2]||<empty>>
      
  #   - if <[quest_id]> != <empty> && <[reward_item]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.rewards.<[reward_item]>:!      
  #       - run drustcraftt_quest.save

  # update_reward:
  #   - define quest_id:<[1]||<empty>>
  #   - define reward_item:<[2]||<empty>>
  #   - define reward_quantity:<[3]||1>
      
  #   - if <[quest_id]> != <empty> && <[reward_item]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - if <[reward_quantity]> > 0:
  #         - yaml id:drustcraft_quests set quests.<[quest_id]>.rewards.<[reward_item]>:<[reward_quantity]>
  #       - else:
  #         - yaml id:drustcraft_quests set quests.<[quest_id]>.rewards.<[reward_item]>:!
      
  #       - run drustcraftt_quest.save
  
  # add_give:
  #   - define quest_id:<[1]||<empty>>
  #   - define give_item:<[2]||<empty>>
  #   - define give_quantity:<[3]||1>
      
  #   - if <[quest_id]> != <empty> && <[give_item]> != <empty> && <[give_quantity]> > 0:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.gives].contains[<[reward_item]>]||false>:
  #         - yaml id:drustcraft_quests set quests.<[quest_id]>.gives.<[give_item]>:+:<[give_quantity]>
  #       - else:
  #         - yaml id:drustcraft_quests set quests.<[quest_id]>.gives.<[give_item]>:<[give_quantity]>
      
  #       - run drustcraftt_quest.save

  # remove_give:
  #   - define quest_id:<[1]||<empty>>
  #   - define give_item:<[2]||<empty>>
      
  #   - if <[quest_id]> != <empty> && <[give_item]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set quests.<[quest_id]>.gives.<[give_item]>:!      
  #       - run drustcraftt_quest.save

  # update_give:
  #   - define quest_id:<[1]||<empty>>
  #   - define give_item:<[2]||<empty>>
  #   - define give_quantity:<[3]||1>
      
  #   - if <[quest_id]> != <empty> && <[give_item]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
  #       - if <[give_quantity]> > 0:
  #         - yaml id:drustcraft_quests set quests.<[quest_id]>.gives.<[give_item]>:<[give_quantity]>
  #       - else:
  #         - yaml id:drustcraft_quests set quests.<[quest_id]>.gives.<[give_item]>:!
      
  #       - run drustcraftt_quest.save

  # start:
  #   - define target_player:<[1]||<empty>>
  #   - define quest_id:<[2]||<empty>>
  #   - if <[target_player]> != <empty> && <[quest_id]> != <empty>:
  #     - if <yaml[drustcraft_quests].list_keys[player.<player.uuid>.quests.active].contains[<[quest_id]>]||false> == false:
  #       - define objective_list:<yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>
        
  #       - if <[objective_list].size> <= 0:
  #         - run drustcraftt_quest.done def:<[target_player]>|<[quest_id]>
  #       - else:
  #         - foreach <[objective_list]>:
  #           - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.active.<[quest_id]>.objectives.<[value]>:0
        
  #       - narrate '<&e>Quest accepted: <yaml[drustcraft_quests].read[quests.<[quest_id]>.title]||<empty>>'
        
  #       - define give_map:<yaml[drustcraft_quests].read[quests.<[quest_id]>.gives]||<map[]>>
  #       - foreach <[give_map]>:
  #         - give <[key]> quantity:<[value]> to:<[target_player].inventory>
        
  #       - run drustcraftt_quest.update_markers def:<[target_player]>|true
  #       - run drustcraftt_quest.save
    
  # done:
  #   - define target_player:<[1]||<empty>>
  #   - define quest_id:<[2]||<empty>>
  #   - if <[target_player]> != <empty> && <[quest_id]> != <empty>:
  #     - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.active.<[quest_id]>:!
  #     - if <yaml[drustcraft_quests].read[player.<[target_player].uuid>.quests.done].contains[<[quest_id]>]||false> == false:
  #       - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.done:->:<[quest_id]>
      
  #     - run drustcraftt_quest.update_markers def:<[target_player]>|true
  #     - run drustcraftt_quest.save
    
  # completed:
  #   - define target_player:<[1]||<empty>>
  #   - define quest_id:<[2]||<empty>>
  #   - if <[target_player]> != <empty> && <[quest_id]> != <empty>:
  #     - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.done:<-:<[quest_id]>
  #     - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.active.<[quest_id]>:!
      
  #     - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.repeatable]||false> == false:
  #       - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.completed:->:<[quest_id]>
      
  #     - narrate '<&e>Quest completed: <yaml[drustcraft_quests].read[quests.<[quest_id]>.title]>'
  
  #     - foreach <yaml[drustcraft_quests].read[quests.<[quest_id]>.rewards]||<map[]>>:
  #       - give <[key]> quantity:<[value]> to:<[target_player].inventory>
  #       - narrate '<&e>You received <material[<[key]>].translated_name||<[key]>> x <[value]>'

  #   - define end_speak:<yaml[drustcraft_quests].read[quests.<[quest_id]>.npc_end_speak]||<empty>>
  #   - if <[end_speak]> != <empty>:
  #     - define target_npc:<npc[<yaml[drustcraft_quests].read[quests.<[quest_id]>.npc_start]||0>]||<empty>>
  #     - narrate <proc[drustcraftp_chat_format].context[<npc>|<[end_speak]>]>
    
  #   - run drustcraftt_quest.update_markers def:<[target_player]>|true
  #   - run drustcraftt_quest.save
  
  # abandon:
  #   - define target_player:<[1]||<empty>>
  #   - define quest_id:<[2]||<empty>>
  #   - if <[target_player]> != <empty> && <[quest_id]> != <empty>:
  #     - define done:false
  #     - if <yaml[drustcraft_quests].list_keys[player.<[target_player].uuid>.quests.active].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.active.<[quest_id]>:!
  #       - define done:true
  #     - else if <yaml[drustcraft_quests].read[player.<[target_player].uuid>.quests.done].contains[<[quest_id]>]||false>:
  #       - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.done:<-:<[quest_id]>
  #       - define done:true
        
  #     - if <[done]>:
  #       - narrate '<&e>Quest abandoned: <yaml[drustcraft_quests].read[quests.<[quest_id]>.title]||<empty>>'
      
  #     - run drustcraftt_quest.update_markers def:<[target_player]>|true
  #     - run drustcraftt_quest.save
  
  # objective_event:
  #   - define event_player:<[1]||<empty>>
  #   - define event_type:<[2]||<empty>>
  #   - define event_data:<[3]||<empty>>
  #   - define event_location:<[4]||<empty>>
  #   - define changes:false
    
  #   - if <[event_player].object_type||<empty>> == PLAYER:
  #     - foreach <yaml[drustcraft_quests].list_keys[player.<[event_player].uuid>.quests.active]||<list[]>>:
  #       - define quest_id:<[value]>
  #       - define objective_list:<yaml[drustcraft_quests].list_keys[player.<[event_player].uuid>.quests.active.<[quest_id]>.objectives]||<list[]>>
  
  #       - foreach <[objective_list]>:
  #         - define objective_id:<[value]>
  #         - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.type]||<empty>> == <[event_type]>:
  #           - define objective_data:<yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.data]||<empty>>
  #           - if <[objective_data]> == <empty> || <[objective_data]> == * || <[objective_data]> == <[event_data]>:
  #             - define objective_region:<yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.region]||<empty>>
  #             - if <[objective_region]> == <empty> || <[event_location].regions.parse[id].contains[<[objective_region]>]||false>:
  #               - define objective_value:<yaml[drustcraft_quests].read[player.<[event_player].uuid>.quests.active.<[quest_id]>.objectives.<[objective_id]>]||0>
  #               - define objective_value:++
  #               - define changes:true
  
  #               - if <[objective_value]> >= <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.quantity]||0>:
  #                 - ~yaml id:drustcraft_quests set player.<[event_player].uuid>.quests.active.<[quest_id]>.objectives.<[objective_id]>:!
  #               - else:
  #                 - ~yaml id:drustcraft_quests set player.<[event_player].uuid>.quests.active.<[quest_id]>.objectives.<[objective_id]>:<[objective_value]>
  
  #       - if <yaml[drustcraft_quests].list_keys[player.<[event_player].uuid>.quests.active.<[quest_id]>.objectives].size||0> <= 0:
  #         - run drustcraftt_quest.done def:<[event_player]>|<[quest_id]>
      
  #     - if <[changes]>:
  #       - run drustcraftt_quest.update_markers def:<[event_player]>|true
  #       - run drustcraftt_quest.inventory_update def:<[event_player]>
      
  #     - determine <[changes]>
  #   - determine false
    
  # update_markers:
  #   - define target_player:<[1]||<empty>>
  #   - define force:<[2]||false>

  #   - if <[target_player].object_type||<empty>> == PLAYER:
  #     - if <[force]> == true || <util.time_now.is_after[<[target_player].flag[drustcraft_quest_update_makers]||<util.time_now.sub[5s]>>]>:
  #       - flag <[target_player]> drustcraft_quest_update_makers:<util.time_now.add[5s]>
  
  #       - foreach <[target_player].fake_entities>:
  #         - fakespawn <[value]> cancel
  
  #       - define npc_list:<[target_player].location.find.npcs.within[30]>
        
  #       - foreach <[npc_list]>:
  #         - define target_npc:<[value]>
  #         - define title:<empty>
  
  #         - define quest_list:<proc[drustcraftp_quest.npc.list_available].context[<[target_npc]>|<[target_player]>]||<list[]>>
  #         - if <[quest_list].as_list.size||0> > 0:
  #           - define 'title:<&e>-  '
            
  #           - foreach <[quest_list]>:
  #             - if <yaml[drustcraft_quests].read[quests.<[value]>.repeatable]||false> == true:
  #               - define 'title:<&1>  ?  '
            
  #         - if <proc[drustcraftp_quest.npc.list_done].context[<[target_npc]>|<[target_player]>].as_list.size||0> > 0:
  #           - define 'title:  !  '
              
  #         - if <[title]> != <empty>:
  #           - define height:0.1
  #           - if <[target_player].name.starts_with[*]>:
  #             - define height:2.1
            
  #           - fakespawn 'armor_stand[visible=false;custom_name=<&e><[title]>;custom_name_visibility=true;gravity=false]' <[target_npc].location.up[<[height]>]> save:newhologram d:10m players:<[target_player]>
  
  # inventory_update:
  #   - define target_player:<[1]||<empty>>
    
  #   - if <[target_player].object_type> == Player:
  #     - foreach <[target_player].inventory.map_slots>:
  #       - define 'book_title:<[value].book_title.strip_color||<empty>>'
  #       - if '<[book_title].starts_with[Quest<&co> ]>':
  #         - define 'quest_title:<[book_title].after[Quest<&co> ]>'
  #         - define quest_id:<proc[drustcraftp_quest.title_to_id].context[<[quest_title]>]>
          
  #         - if <[quest_id]> != 0:
  #           - define questbook:<proc[drustcraftp_quest.questbook].context[<[quest_id]>|<[target_player]>]>
  #           - if <[questbook]> != <empty>:
  #             - inventory set d:<[target_player].inventory> slot:<[key]> o:<[questbook]>
          
  #         #- define quest_id:-1

  #         #- foreach <yaml[drustcraft_quests].list_keys[]>:
  #         #  - if <yaml[drustcraft_quests].read[<[value]>.title]> == <[quest_title]>:
  #         #    - define quest_id:<[value]>
  #         #    - foreach stop
          
  #         #- if <[quest_id]> != -1:
  #         #  - define lore:<&nl><yaml[drustcraft_quests].read[<[quest_id]>.description]>

  #         #  - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.status]> != done:
  #         #    - inventory adjust d:<player.inventory> slot:<[key]> lore:<[lore].split_lines[40]>
  #         #  - else:
  #         #    - define 'lore:<[lore]> <&e>[Completed]'
  #         #    - inventory adjust d:<player.inventory> slot:<[key]> lore:<[lore].split_lines[40]>
  
  # type_register:
  #   - define type:<[1]||<empty>>
  #   - define task:<[2]||<empty>>
    
  #   - if <[type]> != <empty> && <[task]> != <empty>:
  #     - yaml id:drustcraft_quest_types set types.<[type]>:<[task]>


# Complete
drustcraftt_job_quest_require_register:
  type: task
  debug: false
  definitions: require_id|task_name
  script:
    - flag server drustcraft.job_quest.register.require.<[require_id]>:<[task_name]>
    - ~run <[task_name]> def:init|<[require_id]>|null|null|null
    - ~run <[task_name]> def:tabcomplete|<[require_id]>|null|null|null save:result
    - define tabcomplete:<entry[result].created_queue.determination.get[1]||<list[]>>
    - if <[tabcomplete].size||0> > 0:
      - run drustcraftt_tabcomplete_completion def:<list[quest|require|_*quest_ids|add].include[<[tabcomplete]>]>
      - run drustcraftt_tabcomplete_completion def:<list[quest|require|_*quest_ids|edit|_*quest_requireindex].include[<[tabcomplete]>]>


# Complete
drustcraftt_job_quest_objective_register:
  type: task
  debug: false
  definitions: objective_id|task_name
  script:
    - flag server drustcraft.job_quest.register.objective.<[objective_id]>:<[task_name]>
    - ~run <[task_name]> def:init|<[objective_id]>|null|null|null|null|null
    - ~run <[task_name]> def:tabcomplete|<[objective_id]>|null|null|null|null|null save:result
    - define tabcomplete:<entry[result].created_queue.determination.get[1]||<list[]>>
    - if <[tabcomplete].size||0> > 0:
      - run drustcraftt_tabcomplete_completion def:<list[quest|objective|_*quest_ids|add].include[<[tabcomplete]>]>
      - run drustcraftt_tabcomplete_completion def:<list[quest|objective|_*quest_ids|edit|_*quest_objectiveindex].include[<[tabcomplete]>]>


# TODO: Complete this task
drustcraftt_job_quest_objective_event:
  type: task
  debug: false
  definitions: target_player|event_id|event_data
  script:
    - foreach <server.flag[drustcraft.job_quest.player.<[target_player].uuid>].keys||<list[]>> as:quest_id:
      - if <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.completed]> == 0:
        - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective].keys> as:objective_index:
          - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[objective_index]>.type]> == <[event_id]> && <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective.<[objective_index]>.completed]||0> == 0:
            - ~run <server.flag[drustcraft.job_quest.register.objective.<[event_id]>]> def:event|<[event_id]>|<[quest_id]>|<[target_player]>|<[event_data]>|<server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[objective_index]>.data]>|<server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective.<[objective_index]>.data]||map[]> save:result
            - define update_data:<entry[result].created_queue.determination.filter[object_type.equals[map]].get[1]||null>
            - define update_quest:<entry[result].created_queue.determination.filter[object_type.equals[element]].get[1]||false>

            - if <[update_quest]>:
              - flag server drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective.<[objective_index]>.completed:1
              - waituntil <server.sql_connections.contains[drustcraft]>
              - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest_player_objective` SET `completed` = 1 WHERE `quest_id`= <[quest_id]> AND `index` = <[objective_index]>;'
              - define quest_updated:true
              - foreach <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective].keys> as:quest_objective_index:
                - if <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective.<[quest_objective_index]>.completed]> == 0:
                  - define quest_updated:false
                  - foreach stop
              - if <[quest_updated]>:
                - run drustcraftt_job_quest_update_marker_npc_id def:<[target_player]>|<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_end]>

            - if <[update_data]> != null:
              - flag server drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective.<[objective_index]>.data:<[update_data]>
              - foreach <[target_player].inventory.map_slots> key:inv_slot as:inv_item:
                - if <proc[drustcraftp_job_quest_book_to_id].context[<[inv_item]>]> == <[quest_id]>:
                  - inventory set slot:<[inv_slot]> o:<proc[drustcraftp_job_quest_questbook].context[<[quest_id]>|<[target_player]>]> d:<[target_player].inventory>
                  - foreach stop


# TODO: Complete this task
drustcraftt_job_quest_update_markers_player_location:
  type: task
  debug: false
  definitions: target_player
  script:
    - foreach <[target_player].location.find_entities[NPC].within[25]> as:target_npc:
      - run drustcraftt_job_quest_update_marker_npc_id def:<[target_player]>|<[target_npc].id>


# TODO: Complete this task
drustcraftt_job_quest_update_marker_npc_id:
  type: task
  debug: false
  definitions: target_player|npc_id
  script:
    - define quest_flag:null

    - if <[target_player].location.find_entities[NPC].within[25].parse[id].contains[<[npc_id]>]>:
      # search for quests to hand in
      - foreach <server.flag[drustcraft.job_quest.player.<[target_player].uuid>].keys||<list[]>> as:quest_id:
        - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_end]> == <[npc_id]> && <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.completed]> == 0:
          - define quest_completed:true
          - foreach <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective].keys||<list[]>> as:objective_index:
            - if <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective.<[objective_index]>.completed]> == 0:
              - define quest_completed:false
              - foreach stop

          - if <[quest_completed]>:
            - define 'quest_flag:<element[<&e>  !  ]>'
            - foreach stop

      # search for available quests
      - if <[quest_flag]> == null:
        - foreach <server.flag[drustcraft.job_quest.quest].keys||<list[]>> as:quest_id:
          - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_start]> == <[npc_id]>:
            - if !<server.flag[drustcraft.job_quest.player.<[target_player].uuid>].keys.contains[<[quest_id]>]||false>:
              - define show:true
              - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.require].keys||<list[]>> as:require_index:
                - define require_type:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[require_index]>.type]>
                - define require_data:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[require_index]>.data]>
                - if <server.has_flag[drustcraft.job_quest.register.require.<[require_type]>]>:
                  - ~run <server.flag[drustcraft.job_quest.register.require.<[require_type]>]> def:<list[player_meets_requirement|<[require_type]>|<[quest_id]>|<[target_player]>|<[require_data]>]> save:result
                  - if !<entry[result].created_queue.determination.get[1]||false>:
                    - define show:false
                    - foreach stop
                - else:
                  - define show:false
                  - foreach stop

              - if <[show]>:
                - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.repeatable]> == 1:
                  - define 'quest_flag:<element[<&1>  ?  ]>'
                - else:
                  - define 'quest_flag:<element[<&e>  ?  ]>'
                - foreach stop

      - if <[target_player].has_flag[drustcraft.job_quest.markers.<[npc_id]>]>:
        - if <[target_player].flag[drustcraft.job_quest.markers.<[npc_id]>].is_spawned>:
          - fakespawn <[target_player].flag[drustcraft.job_quest.markers.<[npc_id]>]> cancel players:<[target_player]>

      - if <[quest_flag]> != null:
        - define height:0.1
        - if <[target_player].name.starts_with[*]>:
          - define height:2.1

        - fakespawn armor_stand[visible=false;custom_name=<[quest_flag]>;custom_name_visibility=true;gravity=false] <npc[<[npc_id]>].location.up[<[height]>]> save:hologram d:10m players:<[target_player]>
        - flag <[target_player]> drustcraft.job_quest.markers.<[npc_id]>:<entry[hologram].faked_entity>


# Complete
drustcraftt_job_quest_player_start:
  type: task
  debug: false
  definitions: target_player|quest_id
  script:
    - playsound <[target_player]> sound:ENTITY_FIREWORK_ROCKET_LAUNCH volume:1.0 pitch:2
    - waituntil <server.sql_connections.contains[drustcraft]>
    - flag server drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.completed:0
    - flag server drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.start:<util.time_now>
    - flag server drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective:<list[]>

    - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective].keys||<list[]>> as:objective_index:
      - flag server drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective.<[objective_index]>.data:<map[]>
      - flag server drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective.<[objective_index]>.completed:0
      - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_quest_player_objective`(`quest_id`, `index`, `data`, `completed`, `uuid`) VALUES(<[quest_id]>, <[objective_index]>, "<map[]>", 0, "<[target_player].uuid>");'

    - narrate '<proc[drustcraftp_msg_format].context[arrow|Quest started: $e<server.flag[drustcraft.job_quest.quest.<[quest_id]>.title]>]>' targets:<[target_player]>
    - run drustcraftt_job_quest_update_markers_player_location def:<[target_player]>
    - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_quest_player`(`quest_id`, `uuid`, `completed`, `start`) VALUES(<[quest_id]>, "<[target_player].uuid>", 0, <util.time_now.epoch_millis.div[1000].round>);'

    - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.give]||<map[]>> key:material_id as:material_qty:
      - define target_npc:<npc[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_start]>]>
      - define target_item:<item[<[material_id]>[quantity=<[material_qty]>]]>
      - if <[target_player].inventory.can_fit[<[target_item]>]>:
        - give <[target_item]> to:<[target_player].inventory>
        - narrate '<proc[drustcraftp_msg_format].context[success|Received $e<[target_item].material.translated_name> $rx $e<[target_item].quantity>]>' targets:<[target_player]>
      - else:
        - drop <[target_item]> <cuboid[<[target_npc].location.add[-2,-2,-2]>|<[target_npc].location.add[2,2,2]>].spawnable_blocks.random>
        - narrate '<proc[drustcraftp_msg_format].context[success|<[target_npc].name.strip_color> dropped  $e<[target_item].material.translated_name> $rx $e<[target_item].quantity>]>' targets:<[target_player]>


# Complete
drustcraftt_job_quest_player_abandon:
  type: task
  debug: false
  definitions: target_player|quest_id
  script:
    - playsound <[target_player]> sound:ENTITY_SKELETON_HURT volume:1.0 pitch:1
    - flag server drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>:!
    - narrate '<proc[drustcraftp_msg_format].context[arrow|Quest abandoned: $e<server.flag[drustcraft.job_quest.quest.<[quest_id]>.title]>]>' targets:<[target_player]>
    - waituntil <server.sql_connections.contains[drustcraft]>
    - run drustcraftt_job_quest_update_markers_player_location def:<[target_player]>
    - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_quest_player` WHERE `quest_id` = <[quest_id]> AND `uuid` = "<[target_player].uuid>";'
    - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_quest_player_objective` WHERE `quest_id` = <[quest_id]> AND `uuid` = "<[target_player].uuid>";'


# TODO: Complete
drustcraftp_job_quest_questbook:
  type: procedure
  debug: false
  definitions: quest_id|target_player
  script:
    - define npc_start_name:Unknown
    - define npc_end_name:Unknown

    - if <npc[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_start]>].exists>:
      - define npc_start_name:<npc[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_start]>].name.strip_color>
    - if <npc[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_end]>].exists>:
      - define npc_end_name:<npc[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_end]>].name.strip_color>

    - define 'book_title:<&2>Quest<&co> <server.flag[drustcraft.job_quest.quest.<[quest_id]>.title]>'
    - define book_author:<[npc_start_name]>
    - define lore:<element[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.description].split_lines[40]>]>

    - define book_pages:<proc[drustcraftp_util_split_book_pages].context[<&2><bold><server.flag[drustcraft.job_quest.quest.<[quest_id]>.title]><p><&0><server.flag[drustcraft.job_quest.quest.<[quest_id]>.description]>]>

    # objectives
    - define objectives:<element[]>
    - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>.objective]>:
      - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective].keys> as:objective_index:
        - define objective_type:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[objective_index]>.type]>
        - define objective_data:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[objective_index]>.data]>

        - ~run <server.flag[drustcraft.job_quest.register.objective.<[objective_type]>]> def:<list[to_quest_text|<[objective_type]>|<[quest_id]>|<[target_player]>|null|<[objective_data]>|<server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective.<[objective_index]>.data]||<map[]>>]> save:result
        - define objective_text:<entry[result].created_queue.determination.get[1]>
        - if <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective.<[objective_index]>.completed]||0> == 1:
          - define 'objective_text:<[objective_text]> <&2>√'

        - define 'objectives:<[objectives]><&0>- <[objective_text]><&nl>'

    - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_start]> != <server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_end]>:
      - define 'objectives:<[objectives]><&0>- Find <[npc_end_name]><&nl>'

    - if <[objectives].length> == 0:
      - define 'objectives:<[objectives]><&0>- No objectives<&nl>'

    - define book_pages:->:<&0><bold>Objectives<p><[objectives]>

    # rewards
    - define rewards:<element[]>
    - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>.reward]>:
      - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.reward].keys> as:material_id:
        - define 'rewards:<[rewards]><&0>- <material[<[material_id]>].translated_name><tern[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.reward.<[material_id]>].is[or_more].than[2]>].pass[ x <server.flag[drustcraft.job_quest.quest.<[quest_id]>.reward.<[material_id]>]>].fail[]><&nl>'
    - else:
      - define 'rewards:<&0>- No rewards<&nl>'

    - define book_pages:->:<&0><bold>Rewards<p><[rewards]>

    - define book_pages:<proc[drustcraftp_util_list_replace_text].context[<list[$PLAYER-NAME|<[target_player].name>].include[<[book_pages]>]>]>
    - define book_pages:<proc[drustcraftp_util_list_replace_text].context[<list[$NPC-START-NAME|<[npc_start_name]>].include[<[book_pages]>]>]>
    - define book_pages:<proc[drustcraftp_util_list_replace_text].context[<list[$NPC-END-NAME|<[npc_end_name]>].include[<[book_pages]>]>]>

    - define book_map:<map.with[title].as[<[book_title]>].with[author].as[<[book_author]>].with[pages].as[<[book_pages]>]>
    - define 'questbook:<item[drustcraftbook_quest[book=<[book_map]>;lore=<[lore]> <&0>quest:<[quest_id]>]]>'

    - determine <[questbook]>


# Complete
drustcraftp_job_quest_player_active_list:
  type: procedure
  debug: false
  definitions: target_player
  script:
    - define active_list:<list[]>
    - foreach <server.flag[drustcraft.job_quest.player.<[target_player].uuid>].keys||<list[]>> as:quest_id:
      - if <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.completed]> == 0:
        - define active_list:->:<[quest_id]>
    - determine <[active_list]>


# Completed
drustcraftp_job_quest_player_completed:
  type: procedure
  debug: false
  definitions: target_player|quest_id
  script:
    - if <server.has_flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>]>:
      - determine <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.completed].equals[1]||false>
    - determine false


# Complete
drustcraftp_job_quest_book_to_id:
  type: procedure
  debug: false
  definitions: item
  script:
    - if <[item].is_book||false> && <[item].has_lore||false>:
      - foreach <[item].lore>:
        - define id:<[value].after[quest:].before[<&sp>]||<empty>>
        - if <[id].length> > 0 && <[id].is_integer>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[id]>]>:
            - determine <[id]>
    - determine NULL


# Complete
drustcraftp_job_quest_death_drop:
  type: procedure
  debug: false
  definitions: item
  script:
    - determine <[item].book_title.strip_color.starts_with[Quest:<&sp>]||false>


# TODO: WORKING ON THIS NOW
drustcraftc_quest:
  type: command
  debug: false
  name: quest
  description: Creates, Edits and Removes quests
  usage: /quest <&lt>create|remove|info|list<&gt>
  permission: drustcraft.quest
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:quest
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.job_quest]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Quest module is not loaded or an error has occurred]>'
      - stop

    - choose <context.args.get[1]||<empty>>:
      - case list:
        - ~run drustcraftt_chatgui_clear

        - define quest_list:<list[]>
        - if <player.has_permission[drustcraft.quest.override]>:
          - define quest_list:<server.flag[drustcraft.job_quest.quest].keys>
        - else:
          - foreach <server.flag[drustcraft.job_quest.quest].keys> as:quest_id:
            - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid>:
              - define quest_list:->:<[quest_id]>

        - foreach <[quest_list]> as:quest_id:
          - define line:<proc[drustcraftp_chatgui_option].context[<[quest_id]>]>
          - define 'line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.title]>]> <proc[drustcraftp_chatgui_button].context[view|View|quest info <[quest_id]>|View details about this Quest|RUN_COMMAND]>'
          - ~run drustcraftt_chatgui_item def:<[line]>

        - ~run drustcraftt_chatgui_render 'def:quest list|Quests|<context.args.get[2]||1>'

      - case info:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - ~run drustcraftt_chatgui_clear
            - define allow_edit:false
            - if <player.has_permission[drustcraft.quest.override]> || <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid>:
              - define allow_edit:true

            # title
            - define line:<proc[drustcraftp_chatgui_option].context[Title]>
            - define line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.title]||<empty>>]>
            - if <[allow_edit]>:
              - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[edit|Edit|quest title <[quest_id]>|Edit the quest title]>'
            - ~run drustcraftt_chatgui_item def:<[line]>

            # description
            - define line:<proc[drustcraftp_chatgui_option].context[Description]>
            - define line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.description]||<empty>>]>
            - if <[allow_edit]>:
              - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[edit|Edit|quest description <[quest_id]>|Edit the quest description]>'
            - ~run drustcraftt_chatgui_item def:<[line]>

            # owner
            - define line:<proc[drustcraftp_chatgui_option].context[Owner]>
            - define line:<[line]><proc[drustcraftp_chatgui_value].context[<player[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]>].name||<empty>>]>
            - if <[allow_edit]>:
              - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[edit|Edit|quest owner <[quest_id]>|Edit the quest owner]>'
            - ~run drustcraftt_chatgui_item def:<[line]>

            # requires
            - define line:<proc[drustcraftp_chatgui_option].context[Requires]>
            - define count:<proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require].size||0>]>
            - define 'line:<[line]> <[count]> item<tern[<[count].equals[1]>].pass[].fail[s]>'
            - if <[allow_edit]>:
              - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[view|View|quest require <[quest_id]>|View the quest requirements]>'
            - ~run drustcraftt_chatgui_item def:<[line]>

            # repeatable
            - define line:<proc[drustcraftp_chatgui_option].context[Repeatable]>
            - define line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.repeatable]||<empty>>]>
            - if <[allow_edit]>:
              - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[edit|Edit|quest repeatable <[quest_id]>|Edit the quest repeatable]>'
            - ~run drustcraftt_chatgui_item def:<[line]>

            # npc start
            - define 'line:<proc[drustcraftp_chatgui_option].context[NPC Start]>'
            - define npc_name:<empty>
            - define npc_id:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_start]||<empty>>
            - if <[npc_id]> != <empty> && <server.npcs.parse[id].contains[<[npc_id]>]>:
              - define 'npc_name:<npc[<[npc_id]>].name> (<[npc_id]>)'
            - define line:<[line]><proc[drustcraftp_chatgui_value].context[<[npc_name]>]>
            - if <[allow_edit]>:
              - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[edit|Edit|quest npcstart <[quest_id]>|Edit the quest NPC start]>'
            - ~run drustcraftt_chatgui_item def:<[line]>

            # npc end
            - define 'line:<proc[drustcraftp_chatgui_option].context[NPC End]>'
            - define npc_name:<empty>
            - define npc_id:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_end]||<empty>>
            - if <[npc_id]> != <empty> && <server.npcs.parse[id].contains[<[npc_id]>]>:
              - define 'npc_name:<npc[<[npc_id]>].name> (<[npc_id]>)'
            - define line:<[line]><proc[drustcraftp_chatgui_value].context[<[npc_name]>]>
            - if <[allow_edit]>:
              - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[edit|Edit|quest npcend <[quest_id]>|Edit the quest NPC end]>'
            - ~run drustcraftt_chatgui_item def:<[line]>

            # npc end speak
            - define 'line:<proc[drustcraftp_chatgui_option].context[NPC End Speak]>'
            - define line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_end_speak]||<empty>>]>
            - if <[allow_edit]>:
              - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[edit|Edit|quest npcendspeak <[quest_id]>|Edit the quest NPC end speak]>'
            - ~run drustcraftt_chatgui_item def:<[line]>

            # gives
            - define line:<proc[drustcraftp_chatgui_option].context[Gives]>
            - define count:<proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.give].size||0>]>
            - define 'line:<[line]> <[count]> item<tern[<[count].equals[1]>].pass[].fail[s]>'
            - if <[allow_edit]>:
              - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[view|View|quest give <[quest_id]>|View the quest gives]>'
            - ~run drustcraftt_chatgui_item def:<[line]>

            # objectives
            - define line:<proc[drustcraftp_chatgui_option].context[Objectives]>
            - define count:<proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective].size||0>]>
            - define 'line:<[line]> <[count]> item<tern[<[count].equals[1]>].pass[].fail[s]>'
            - if <[allow_edit]>:
              - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[view|View|quest objective <[quest_id]>|View the quest objectives]>'
            - ~run drustcraftt_chatgui_item def:<[line]>

            # rewards
            - define line:<proc[drustcraftp_chatgui_option].context[Rewards]>
            - define count:<proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.reward].size||0>]>
            - define 'line:<[line]> <[count]> item<tern[<[count].equals[1]>].pass[].fail[s]>'
            - if <[allow_edit]>:
              - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[view|View|quest reward <[quest_id]>|View the quest rewards]>'
            - ~run drustcraftt_chatgui_item def:<[line]>

            - ~run drustcraftt_chatgui_render 'def:quest info <[quest_id]>|Quest ID: <[quest_id]>|<context.args.get[3]||1>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case title:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - define new_title:<context.args.remove[1|2].space_separated||<empty>>
            - if <[new_title]> != <empty>:
              - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                - if <[new_title].length> <= 20:
                  - flag server drustcraft.job_quest.quest.<[quest_id]>.title:<[new_title]>
                  - narrate '<proc[drustcraftp_msg_format].context[success|The quest title for quest ID $e<[quest_id]> $rhas been updated]>'
                  - waituntil <server.sql_connections.contains[drustcraft]>
                  - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest` SET `title` = "<[new_title]>" WHERE `id` = <[quest_id]>;'
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|The quest title must be 20 or less characters]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this quest]>'
            - else:
              - define title:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.title]||null>
              - if <[title]> != NULL:
                - narrate '<proc[drustcraftp_msg_format].context[arrow|The quest ID $e<[quest_id]> $rtitle is set to $e<[title]>]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[arrow|The quest ID $e<[quest_id]> $rdoes not have a title set]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case description:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - define new_description:<context.args.remove[1|2].space_separated||<empty>>
            - if <[new_description]> != <empty>:
              - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                - flag server drustcraft.job_quest.quest.<[quest_id]>.description:<[new_description]>
                - narrate '<proc[drustcraftp_msg_format].context[success|The quest description for quest ID $e<[quest_id]> $rhas been updated]>'
                - waituntil <server.sql_connections.contains[drustcraft]>
                - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest` SET `description` = "<[new_description]>" WHERE `id` = <[quest_id]>;'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this quest]>'
            - else:
              - define description:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.description]||null>
              - if <[description]> != NULL:
                - narrate '<proc[drustcraftp_msg_format].context[arrow|The quest ID $e<[quest_id]> $rdescription is set to $e<[description]>]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[arrow|The quest ID $e<[quest_id]> $rdoes not have a description set]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case owner:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - define target_player:<context.args.get[3]||<empty>>
            - if <[target_player]> != <empty>:
              - define found_player:<server.match_offline_player[<[target_player]>]>
              - if <[found_player].exists> && <[found_player].name> == <[target_player]>:
                - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                  - flag server drustcraft.job_quest.quest.<[quest_id]>.owner:<[found_player].uuid>
                  - narrate '<proc[drustcraftp_msg_format].context[success|The quest owner for quest ID $e<[quest_id]> $rhas been updated]>'
                  - waituntil <server.sql_connections.contains[drustcraft]>
                  - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest` SET `uuid` = "<[found_player].uuid>" WHERE `id` = <[quest_id]>;'
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this quest]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<[target_player]> $rwas not found on the server]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[arrow|The owner of quest ID $e<[quest_id]> $ris $e<player[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]>].name>]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case repeatable:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - define repeatable:<context.args.get[3]||<empty>>
            - if <[repeatable]> != <empty>:
              - if <list[true|false].contains[<[repeatable]>]>:
                - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                  - flag server drustcraft.job_quest.quest.<[quest_id]>.repeatable:<tern[<[repeatable].equals[true]>].pass[1].fail[0]>
                  - narrate '<proc[drustcraftp_msg_format].context[success|The quest ID $e<[quest_id]> $rrepeatability has been updated]>'
                  - waituntil <server.sql_connections.contains[drustcraft]>
                  - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest` SET `repeatable` = <[repeatable]> WHERE `id` = <[quest_id]>;'
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this quest]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The repeatable flag is required to be true or false]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[arrow|The quest ID $e<[quest_id]> $ris marked as $e<tern[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.repeatable]>].pass[repeatable].fail[not repeatable]>]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case npcstart:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - define npc_start:<context.args.get[3]||<empty>>
            - if <[npc_start]> != <empty>:
              - if <server.npcs.parse[id].contains[<[npc_start]>]>:
                - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                  - flag server drustcraft.job_quest.quest.<[quest_id]>.npc_start:<[npc_start]>
                  - narrate '<proc[drustcraftp_msg_format].context[success|The starting NPC for quest ID $e<[quest_id]> $rhas been updated]>'
                  - waituntil <server.sql_connections.contains[drustcraft]>
                  - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest` SET `npc_start` = <[npc_start]> WHERE `id` = <[quest_id]>;'
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this quest]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The NPC ID $e<[npc_start]> $rwas not found]>'
            - else:
              # TODO: what about none?
              - narrate '<proc[drustcraftp_msg_format].context[arrow|The starting NPC for quest ID $e<[quest_id]> $ris set to $e<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_start]>]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case npcend:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - define npc_end:<context.args.get[3]||<empty>>
            - if <[npc_end]> != <empty>:
              - if <server.npcs.parse[id].contains[<[npc_end]>]>:
                - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                  - flag server drustcraft.job_quest.quest.<[quest_id]>.npc_end:<[npc_end]>
                  - narrate '<proc[drustcraftp_msg_format].context[success|The ending NPC for quest ID $e<[quest_id]> $rhas been updated]>'
                  - waituntil <server.sql_connections.contains[drustcraft]>
                  - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest` SET `npc_end` = <[npc_end]> WHERE `id` = <[quest_id]>;'
                - else:
                  - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this quest]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The NPC ID $e<[npc_end]> $rwas not found]>'
            - else:
              # TODO: what about none?
              - narrate '<proc[drustcraftp_msg_format].context[arrow|The ending NPC for quest ID $e<[quest_id]> $ris set to $e<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_end]>]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case npcendspeak:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - define message:<context.args.remove[1|2].space_separated||<empty>>
            - if <[message]> != <empty>:
              - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                - flag server drustcraft.job_quest.quest.<[quest_id]>.npc_end_speak:<[message]>
                - narrate '<proc[drustcraftp_msg_format].context[success|The ending NPC speak for quest ID $e<[quest_id]> $rhas been updated]>'
                - waituntil <server.sql_connections.contains[drustcraft]>
                - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest` SET `npc_end_speak` = "<[message]>" WHERE `id` = <[quest_id]>;'
                - narrate '<proc[drustcraftp_msg_format].context[arrow|The ending NPC speak for quest ID $e<[quest_id]> $ris set to $e<[message]>]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this quest]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|No npc end speak was entered]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case require:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - define action:<context.args.get[3]||<empty>>
            - if <[action]> != <empty>:
              - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                - choose <[action]>:
                  - case add:
                    - define require_id:<context.args.get[4]||<empty>>
                    - if <[require_id]> != <empty>:
                      - if <server.has_flag[drustcraft.job_quest.register.require.<[require_id]>]>:
                        - define event_data:<map[]>
                        - foreach <context.args.remove[1|2|3|4]>:
                          - define event_data:<[event_data].with[<[loop_index]>].as[<[value]>]>
                        - ~run <server.flag[drustcraft.job_quest.register.require.<[require_id]>]> def:<list[add|<[require_id]>|<[quest_id]>|null|<[event_data]>]> save:result
                        - define data:<entry[result].created_queue.determination.get[1]||<empty>>
                        - if <[data]> != <empty>:
                          - define index:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require].keys.highest.add[1]||1>
                          - flag server drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.type:<[require_id]>
                          - flag server drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.data:<[data]>
                          - narrate '<proc[drustcraftp_msg_format].context[success|The quest requirement has been added]>'
                          - waituntil <server.sql_connections.contains[drustcraft]>
                          - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_quest_require`(`quest_id`, `index`, `type`, `data`) VALUES(<[quest_id]>, <[index]>, "<[require_id]>", <tern[<[data].equals[NULL]>].pass[NULL].fail["<[data]>"]>);'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|The requirement type $e<[require_id]> $ris not valid]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No requirement type was entered]>'

                  - case edit:
                    - define index:<context.args.get[4]||<empty>>
                    - if <[index]> != <empty>:
                      - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>]>:
                        - define require_id:<context.args.get[5]||<empty>>
                        - if <[require_id]> != <empty>:
                          - if <server.has_flag[drustcraft.job_quest.register.require.<[require_id]>]>:
                            - define event_data:<map[]>
                            - foreach <context.args.remove[1|2|3|4|5]>:
                              - define event_data:<[event_data].with[<[loop_index]>].as[<[value]>]>
                            - ~run <server.flag[drustcraft.job_quest.register.require.<[require_id]>]> def:<list[remove|<[require_id]>|<[quest_id]>|<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.type]>|null|<[event_data]>]> save:result
                            - ~run <server.flag[drustcraft.job_quest.register.require.<[require_id]>]> def:<list[add|<[require_id]>|<[quest_id]>|null|<[event_data]>]> save:result
                            - define data:<entry[result].created_queue.determination.get[1]||<empty>>
                            - if <[data]> != <empty>:
                              - flag server drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.type:<[require_id]>
                              - flag server drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.data:<[data]>
                              - narrate '<proc[drustcraftp_msg_format].context[success|The quest requirement has been updated]>'
                              - waituntil <server.sql_connections.contains[drustcraft]>
                              - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest_require` SET `type` =  "<[require_id]>", `data` = <tern[<[data].equals[NULL]>].pass[NULL].fail["<[data]>"]> WHERE `quest_id` = <[quest_id]> AND `index` = <[index]>;'
                          - else:
                            - narrate '<proc[drustcraftp_msg_format].context[error|The requirement type $e<[require_id]> $ris not valid]>'
                        - else:
                          - narrate '<proc[drustcraftp_msg_format].context[error|No requirement type was entered]>'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|The requirement number $e<[index]> $rwas not found]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No requirement number was entered]>'

                  - case remove:
                    - define index:<context.args.get[4]||<empty>>
                    - if <[index]> != <empty>:
                      - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>]>:
                        - define require_id:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.type]>
                        - if <server.has_flag[drustcraft.job_quest.register.require.<[require_id]>]>:
                          - run <server.flag[drustcraft.job_quest.register.require.<[require_id]>]> def:<list[remove|<[require_id]>|<[quest_id]>|null|<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.data]>]>
                        - flag server drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>:!
                        - narrate '<proc[drustcraftp_msg_format].context[success|The quest requirement has been removed]>'
                        - waituntil <server.sql_connections.contains[drustcraft]>
                        - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_quest_require` WHERE `quest_id` = <[quest_id]> AND `index` = <[index]>;'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|The requirement number $e<[index]> $rwas not found]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No requirement number was entered]>'

                  - default:
                    - narrate '<proc[drustcraftp_msg_format].context[error|The action you entered is not valid]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this quest]>'
            - else:
              - define allow_edit:false
              - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                - define allow_edit:true

              - ~run drustcraftt_chatgui_clear
              - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.require].keys> as:index:
                - define require_id:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.type]>

                - ~run <server.flag[drustcraft.job_quest.register.require.<[require_id]>]> def:<list[to_text|<[require_id]>|<[quest_id]>|null|<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.data]>]> save:result
                - define data_text:<entry[result].created_queue.determination.get[1]>

                - define line:<proc[drustcraftp_chatgui_option].context[<[index]>]>
                - define 'line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[index]>.type]> <[data_text]>]>'
                - if <[allow_edit]>:
                  - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[view|View|quest reward <[quest_id]>|View the quest rewards]>'
                  - ~run drustcraftt_chatgui_item def:<[line]>

              - ~run drustcraftt_chatgui_render 'def:quest require <[quest_id]>|Quest ID: <[quest_id]> Requires|<context.args.get[3]||1>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case give:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - define action:<context.args.get[3]||<empty>>
            - if <[action]> != <empty>:
              - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                - choose <[action]>:
                  - case add:
                    - define material_name:<context.args.get[4]||<empty>>
                    - if <[material_name]> != <empty>:
                      - if !<server.flag[drustcraft.job_quest.quest.<[quest_id]>.give].keys.contains[<[material_name]>]||false>:
                        - define quantity:<context.args.get[5]||<empty>>
                        - if <[quantity]> != <empty>:
                          - if <[quantity].is_integer> && <[quantity]> > 0:
                            - flag server drustcraft.job_quest.quest.<[quest_id]>.give.<[material_name]>:<[quantity]>
                            - narrate '<proc[drustcraftp_msg_format].context[success|The quest gives player $e<[material_name]> $rhas been added]>'
                            - waituntil <server.sql_connections.contains[drustcraft]>
                            - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_quest_give`(`quest_id`, `material`, `qty`) VALUES(<[quest_id]>, "<[material_name]>", <[quantity]>);'
                          - else:
                            - narrate '<proc[drustcraftp_msg_format].context[error|The quantity is required to be a whole number larger than 0]>'
                        - else:
                          - narrate '<proc[drustcraftp_msg_format].context[error|No quantity was entered]>'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|The material $e<[material_name]> $ralready exists]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No material was entered]>'

                  - case edit:
                    - define material_name:<context.args.get[4]||<empty>>
                    - if <[material_name]> != <empty>:
                      - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.give].keys.contains[<[material_name]>]||false>:
                        - define quantity:<context.args.get[5]||<empty>>
                        - if <[quantity]> != <empty>:
                          - if <[quantity].is_integer> && <[quantity]> > 0:
                            - flag server drustcraft.job_quest.quest.<[quest_id]>.give.<[material_name]>:<[quantity]>
                            - narrate '<proc[drustcraftp_msg_format].context[success|The quest gives player $e<[material_name]> $rhas been updated]>'
                            - waituntil <server.sql_connections.contains[drustcraft]>
                            - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest_give` SET `qty` = <[quantity]> WHERE `quest_id` = <[quest_id]> AND `material` = "<[material_name]>";'
                          - else:
                            - narrate '<proc[drustcraftp_msg_format].context[error|The quantity is required to be a whole number larger than 0]>'
                        - else:
                          - narrate '<proc[drustcraftp_msg_format].context[error|No quantity was entered]>'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|The material $e<[material_name]> $rdoes not exist]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No material was entered]>'

                  - case remove:
                    - define material_name:<context.args.get[4]||<empty>>
                    - if <[material_name]> != <empty>:
                      - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.give].keys.contains[<[material_name]>]||false>:
                        - flag server drustcraft.job_quest.quest.<[quest_id]>.give.<[material_name]>:!
                        - narrate '<proc[drustcraftp_msg_format].context[success|The quest gives player $e<[material_name]> $rhas been removed]>'
                        - waituntil <server.sql_connections.contains[drustcraft]>
                        - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_quest_give` WHERE `quest_id` = <[quest_id]> AND `material` = "<[material_name]>";'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|The material $e<[material_name]> $rdoes not exist]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No material was entered]>'

                  - default:
                    - narrate '<proc[drustcraftp_msg_format].context[error|The action you entered is not valid]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this quest]>'
            - else:
              - define allow_edit:false
              - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                - define allow_edit:true

              - ~run drustcraftt_chatgui_clear
              - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.give].keys> as:material_name:
                - define line:<proc[drustcraftp_chatgui_option].context[<[material_name]>]>
                - define line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.give.<[material_name]>]>]>
                - if <[allow_edit]>:
                  - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[edit|Edit|quest give <[quest_id]> edit <[material_name]>|Edit the quest gives]>'
                  - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[rem|Rem|quest give <[quest_id]> remove <[material_name]>|Remove the quest gives|RUN_COMMAND]>'
                  - ~run drustcraftt_chatgui_item def:<[line]>

              - ~run drustcraftt_chatgui_render 'def:quest give <[quest_id]>|Quest ID: <[quest_id]> Gives|<context.args.get[3]||1>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case objective:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - define action:<context.args.get[3]||<empty>>
            - if <[action]> != <empty>:
              - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                - choose <[action]>:
                  - case add:
                    - define objective_id:<context.args.get[4]||<empty>>
                    - if <[objective_id]> != <empty>:
                      - if <server.has_flag[drustcraft.job_quest.register.objective.<[objective_id]>]>:
                        - define event_data:<map[]>
                        - foreach <context.args.remove[1|2|3|4]>:
                          - define event_data:<[event_data].with[<[loop_index]>].as[<[value]>]>
                        - ~run <server.flag[drustcraft.job_quest.register.objective.<[objective_id]>]> def:<list[add|<[objective_id]>|<[quest_id]>|null|<[event_data]>|null|null]> save:result
                        - define data:<entry[result].created_queue.determination.get[1]||<empty>>
                        - if <[data]> != <empty>:
                          - define index:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective.keys.highest.add[1]]||1>
                          - flag server drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.type:<[objective_id]>
                          - flag server drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.data:<[data]>
                          - narrate '<proc[drustcraftp_msg_format].context[success|The quest objective has been added]>'
                          - waituntil <server.sql_connections.contains[drustcraft]>
                          - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_quest_objective`(`quest_id`, `index`, `type`, `data`) VALUES(<[quest_id]>, <[index]>, "<[objective_id]>", <tern[<[data].equals[NULL]>].pass[NULL].fail["<[data]>"]>);'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|The quest objective type $e<[objective_id]> $ris not valid]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No quest objective type was entered]>'

                  - case edit:
                    - define index:<context.args.get[4]||<empty>>
                    - if <[index]> != <empty>:
                      - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>]>:
                        - define objective_id:<context.args.get[5]||<empty>>
                        - if <[objective_id]> != <empty>:
                          - if <server.has_flag[drustcraft.job_quest.register.objective.<[objective_id]>]>:
                            - define event_data:<map[]>
                            - foreach <context.args.remove[1|2|3|4|5]>:
                              - define event_data:<[event_data].with[<[loop_index]>].as[<[value]>]>
                            - ~run <server.flag[drustcraft.job_quest.register.objective.<[objective_id]>]> def:<list[remove|<[objective_id]>|<[quest_id]>|null|<[event_data]>|<server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.data]>|null]> save:result
                            - ~run <server.flag[drustcraft.job_quest.register.objective.<[objective_id]>]> def:<list[add|<[objective_id]>|<[quest_id]>|null|<[event_data]>|null|null]> save:result
                            - define data:<entry[result].created_queue.determination.get[1]||<empty>>
                            - if <[data]> != <empty>:
                              - flag server drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.type:<[objective_id]>
                              - flag server drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.data:<[data]>
                              - narrate '<proc[drustcraftp_msg_format].context[success|The quest objective has been updated]>'
                              - waituntil <server.sql_connections.contains[drustcraft]>
                              - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest_objective` SET `type` =  "<[objective_id]>", `data` = <tern[<[data].equals[NULL]>].pass[NULL].fail["<[data]>"]> WHERE `quest_id` = <[quest_id]> AND `index` = <[index]>;'
                          - else:
                            - narrate '<proc[drustcraftp_msg_format].context[error|The quest objective type $e<[objective_id]> $ris not valid]>'
                        - else:
                          - narrate '<proc[drustcraftp_msg_format].context[error|No quest objective type was entered]>'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|Thequest objective number $e<[index]> $rwas not found]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No quest objective number was entered]>'

                  - case remove:
                    - define index:<context.args.get[4]||<empty>>
                    - if <[index]> != <empty>:
                      - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>]>:
                        - define objective_id:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.type]>
                        - if <server.has_flag[drustcraft.job_quest.register.objective.<[objective_id]>]>:
                          - define event_data:<map[]>
                          - foreach <context.args.remove[1|2|3|4|5]>:
                            - define event_data:<[event_data].with[<[loop_index]>].as[<[value]>]>
                          - ~run <server.flag[drustcraft.job_quest.register.objective.<[objective_id]>]> def:<list[remove|<[objective_id]>|<[quest_id]>|null|<[event_data]>|<server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.data]>|null]> save:result
                        - flag server drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>:!
                        - narrate '<proc[drustcraftp_msg_format].context[success|The quest objective has been removed]>'
                        - waituntil <server.sql_connections.contains[drustcraft]>
                        - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_quest_objective` WHERE `quest_id` = <[quest_id]> AND `index` = <[index]>;'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|The quest objective number $e<[index]> $rwas not found]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No quest objective number was entered]>'

                  - default:
                    - narrate '<proc[drustcraftp_msg_format].context[error|The action you entered is not valid]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this quest]>'
            - else:
              - define allow_edit:false
              - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                - define allow_edit:true

              - ~run drustcraftt_chatgui_clear
              - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective].keys> as:index:
                - define objective_id:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.type]>

                - ~run <server.flag[drustcraft.job_quest.register.objective.<[objective_id]>]> def:<list[to_text|<[objective_id]>|<[quest_id]>|null|null|<server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.data]>|null]> save:result
                - define data_text:<entry[result].created_queue.determination.get[1]>

                - define line:<proc[drustcraftp_chatgui_option].context[<[index]>]>
                - define 'line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.objective.<[index]>.type]> <[data_text]>]>'
                - if <[allow_edit]>:
                  - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[edit|Edit|quest objective <[quest_id]> <[index]>|Edit the objective]>'
                - ~run drustcraftt_chatgui_item def:<[line]>

              - ~run drustcraftt_chatgui_render 'def:quest.objective.<[quest_id]>|Quest ID: <[quest_id]> Objectives|<context.args.get[3]||1>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case reward:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <server.has_flag[drustcraft.job_quest.quest.<[quest_id]>]>:
            - define action:<context.args.get[3]||<empty>>
            - if <[action]> != <empty>:
              - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                - choose <[action]>:
                  - case add:
                    - define material_name:<context.args.get[4]||<empty>>
                    - if <[material_name]> != <empty>:
                      - if !<server.flag[drustcraft.job_quest.quest.<[quest_id]>.reward].keys.contains[<[material_name]>]||false>:
                        - define quantity:<context.args.get[5]||<empty>>
                        - if <[quantity]> != <empty>:
                          - if <[quantity].is_integer> && <[quantity]> > 0:
                            - flag server drustcraft.job_quest.quest.<[quest_id]>.reward.<[material_name]>:<[quantity]>
                            - narrate '<proc[drustcraftp_msg_format].context[success|The quest rewards $e<[material_name]> $rhas been added]>'
                            - waituntil <server.sql_connections.contains[drustcraft]>
                            - sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_quest_reward`(`quest_id`, `material`, `qty`) VALUES(<[quest_id]>, "<[material_name]>", <[quantity]>);'
                          - else:
                            - narrate '<proc[drustcraftp_msg_format].context[error|The quantity is required to be a whole number larger than 0]>'
                        - else:
                          - narrate '<proc[drustcraftp_msg_format].context[error|No quantity was entered]>'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|The material $e<[material_name]> $ralready exists]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No material was entered]>'

                  - case edit:
                    - define material_name:<context.args.get[4]||<empty>>
                    - if <[material_name]> != <empty>:
                      - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.reward].keys.contains[<[material_name]>]||false>:
                        - define quantity:<context.args.get[5]||<empty>>
                        - if <[quantity]> != <empty>:
                          - if <[quantity].is_integer> && <[quantity]> > 0:
                            - flag server drustcraft.job_quest.quest.<[quest_id]>.reward.<[material_name]>:<[quantity]>
                            - narrate '<proc[drustcraftp_msg_format].context[success|The quest rewards player $e<[material_name]> $rhas been updated]>'
                            - waituntil <server.sql_connections.contains[drustcraft]>
                            - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest_reward` SET `qty` = <[quantity]> WHERE `quest_id` = <[quest_id]> AND `material` = "<[material_name]>";'
                          - else:
                            - narrate '<proc[drustcraftp_msg_format].context[error|The quantity is required to be a whole number larger than 0]>'
                        - else:
                          - narrate '<proc[drustcraftp_msg_format].context[error|No quantity was entered]>'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|The material $e<[material_name]> $rdoes not exist]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No material was entered]>'

                  - case remove:
                    - define material_name:<context.args.get[4]||<empty>>
                    - if <[material_name]> != <empty>:
                      - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.reward].keys.contains[<[material_name]>]||false>:
                        - flag server drustcraft.job_quest.quest.<[quest_id]>.reward.<[material_name]>:!
                        - narrate '<proc[drustcraftp_msg_format].context[success|The quest rewards player $e<[material_name]> $rhas been removed]>'
                        - waituntil <server.sql_connections.contains[drustcraft]>
                        - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_quest_reward` WHERE `quest_id` = <[quest_id]> AND `material` = "<[material_name]>";'
                      - else:
                        - narrate '<proc[drustcraftp_msg_format].context[error|The material $e<[material_name]> $rdoes not exist]>'
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|No material was entered]>'

                  - default:
                    - narrate '<proc[drustcraftp_msg_format].context[error|The action you entered is not valid]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this quest]>'
            - else:
              - define allow_edit:false
              - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.owner]> == <player.uuid> || <player.has_permission[drustcraft.quest.override]>:
                - define allow_edit:true

              - ~run drustcraftt_chatgui_clear
              - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.reward].keys> as:material_name:
                - define line:<proc[drustcraftp_chatgui_option].context[<[material_name]>]>
                - define line:<[line]><proc[drustcraftp_chatgui_value].context[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.reward.<[material_name]>]>]>
                - if <[allow_edit]>:
                  - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[edit|Edit|quest reward <[quest_id]> edit <[material_name]>|Edit the quest rewards]>'
                  - define 'line:<[line]> <proc[drustcraftp_chatgui_button].context[rem|Rem|quest reward <[quest_id]> remove <[material_name]>|Remove the quest rewards|RUN_COMMAND]>'
                  - ~run drustcraftt_chatgui_item def:<[line]>

              - ~run drustcraftt_chatgui_render 'def:quest give <[quest_id]>|Quest ID: <[quest_id]> Rewards|<context.args.get[3]||1>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|The quest ID $e<[quest_id]> $rwas not found]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      - case create:
        - if <context.args.size> > 1:
          - define title:<context.args.remove[1].space_separated>
          - waituntil <server.sql_connections.contains[drustcraft]>
          - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>job_quest`(`title`, `owner`, `npc_start`, `npc_end`) VALUES("<[title]>", "<player.uuid||console>", 0, 0);' save:sql_result
          - ~sql id:drustcraft 'query:SELECT LAST_INSERT_ID();' save:sql_result
          - define quest_id:<entry[sql_result].result.get[1].split[/].get[1]>

          - flag server drustcraft.job_quest.quest.<[quest_id]>.title:<[title]>
          - flag server drustcraft.job_quest.quest.<[quest_id]>.owner:<player.uuid||console>
          - flag server drustcraft.job_quest.quest.<[quest_id]>.npc_start:0
          - flag server drustcraft.job_quest.quest.<[quest_id]>.npc_end:0
          - flag server drustcraft.job_quest.quest.<[quest_id]>.npc_end_speak:null
          - flag server drustcraft.job_quest.quest.<[quest_id]>.repeatable:0
          - flag server drustcraft.job_quest.quest.<[quest_id]>.description:null
          - flag server drustcraft.job_quest.quest.<[quest_id]>.require:<list[]>
          - flag server drustcraft.job_quest.quest.<[quest_id]>.objective:<list[]>

          - narrate '<proc[drustcraftp_msg_format].context[success|The quest $e<[title]> $rhas been created with ID $e<[quest_id]>]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest title was entered]>'

#       - case find:
#         - define query:<context.args.get[2]||<empty>>
#         - define page_no:1
        
#         - if <context.args.size> > 2 && <context.args.last.is_integer>:
#           - define page_no:<context.args.last>
        
#         - if <[query]> != <empty>:
#           - define quest_ids:<proc[drustcraftp_quest.list]>
#           - define quest_map:<map[]>
          
#           - foreach <[quest_ids]>:
#             - define quest_id:<[value]>
#             - define 'quest_title:<proc[drustcraftp_quest.info].context[<[quest_id]>].get[title]||<empty>> <&e>(ID: <[quest_id]>)'
#             - if <[quest_title].advanced_matches_text[<[query]>]>:
#               - define quest_map:<[quest_map].with[<[quest_id]>].as[<[quest_title]>]>
          
#           - run drustcraftt_chat_paginate 'def:<list[Quests|<[page_no]>].include_single[<[quest_map]>].include[quest list|quest info]>'
#         - else:
#           - narrate '<&c>No query text was entered'

#       - case removeplayer:
#         - define quest_id:<context.args.get[2]||<empty>>
#         - define target_player:<context.args.get[3]||<empty>>
  
#         - if <[quest_id]> != <empty>:
#           - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
#             - if <[target_player]> != <empty>:
#               - define found_player:<server.match_offline_player[<[target_player]>]>
#               - if <[found_player].name||<empty>> == <[target_player]>:
#                 - yaml id:drustcraft_quests set player.<[found_player].uuid>.quests.active.<[quest_id]>:!
#                 - yaml id:drustcraft_quests set player.<[found_player].uuid>.quests.done:<-:<[quest_id]>
#                 - yaml id:drustcraft_quests set player.<[found_player].uuid>.quests.completed:<-:<[quest_id]>

#                 # remove from inv
#                 - foreach <[found_player].inventory.map_slots>:
#                   - if <[value].is_book> && <[value].book_title.strip_color.starts_with[Quest:<&sp>]>:
#                     - define book_quest_id:<proc[drustcraftp_quest.title_to_id].context[<[value].book_title.after[Quest:<&sp>]>]||0>
#                     - if <[book_quest_id]> == <[quest_id]>:
#                       - inventory set slot:<[key]> o:air d:<[found_player].inventory>

#                 - run drustcraftt_quest.update_markers def:<[found_player]>|true
#                 - run drustcraftt_quest.save
#                 - narrate '<&e>The quest was removed from the player'
#               - else:
#                 - narrate '<&c>A player named <[target_player].name||<empty>> was not found'
#             - else:
#               - narrate '<&c>No player was entered'
#           - else:
#             - narrate '<&c>The quest ID <[quest_id]> doesnt exist'
#         - else:
#           - narrate '<&c>No quest ID was entered'


#       - case create:
#         - define title:<context.args.remove[1].space_separated||<empty>>
#         - if <[title]> != <empty>:
#           - ~run drustcraftt_quest.create def:<[title]> save:quest_result
#           - define quest_id:<entry[quest_result].created_queue.determination.get[1]||0>
#           - if <[quest_id]> != 0:
#             - if <context.server||false> == false:
#               - run drustcraftt_quest.owner def:<[quest_id]>|<player>
            
#             - narrate '<&e>Quest <&sq><[title]><&sq> (ID: <[quest_id]>)'
#           - else:
#             - narrate '<&c>There was an unknown error creating the quest'
#         - else:
#           - narrate '<&c>No quest title was entered'
      
#       - case remove:
#         - define quest_id:<context.args.get[2]||<empty>>
#         - if <[quest_id]> != <empty>:
#           - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
#             - if <context.server||false> || <player.has_permission[drustcraft.quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
#               - run drustcraftt_quest.remove def:<[quest_id]>
#               - narrate '<&e>The Quest ID <&sq><[quest_id]><&sq> has been removed'
#             - else:
#               - narrate '<&c>You do not have permission to remove that quest'
#           - else:
#             - narrate '<&c>The Quest ID <&sq><[quest_id]><&sq> does not exist'
#         - else:
#           - narrate '<&c>No Quest ID was entered to remove'

      # - case npclist:
      #   - if <player.selected_npc||<empty>> != <empty>:        
      #     - define page_no:<context.args.get[2]||1>
      #     - define quest_ids:<proc[drustcraftp_quest.list]>
      #     - define quest_map:<map[]>

      #     - foreach <[quest_ids]>:
      #       - define quest_id:<[value]>
      #       - define quest_info:<proc[drustcraftp_quest.info].context[<[quest_id]>]>
      #       - if <[quest_info].get[npc_start]||0> == <player.selected_npc.id> || <[quest_info].get[npc_end]||0> == <player.selected_npc.id>:
      #         - define 'quest_title:<[quest_info].get[title]||<empty>> <&e>(ID: <[quest_id]>)'
      #         - define quest_map:<[quest_map].with[<[quest_id]>].as[<[quest_title]>]>

      #     - run drustcraftt_chat_paginate 'def:<list[Quests for <player.selected_npc.name> (ID: <player.selected_npc.id>)|<[page_no]>].include_single[<[quest_map]>].include[quest list|quest info]>'
      #   - else:
      #     - narrate '<&c>No NPC is selected'

      # - case regionlist:
      #   - define region_id:<context.args.get[2]||<empty>>

      #   - if <[region_id]> != <empty>:
      #     - define page_no:<context.args.get[3]||1>
      #     - define quest_ids:<proc[drustcraftp_quest.list]>
      #     - define quest_map:<map[]>

      #     - foreach <[quest_ids]> as:quest_id:
      #       - define add_quest:false
      #       - define quest_info:<proc[drustcraftp_quest.info].context[<[quest_id]>]>

      #       # - narrate <server.npcs.parse[id].contains[<[quest_info].get[npc_start]>]>

      #       - if <[quest_info].get[npc_start]||0> != 0 && <server.npcs.parse[id].contains[<[quest_info].get[npc_start]>]> && <npc[<[quest_info].get[npc_start]>].location.in_region[<[region_id]>]>:
      #         - define add_quest:true
      #       - if <[quest_info].get[npc_end]||0> != 0 && <server.npcs.parse[id].contains[<[quest_info].get[npc_end]>]> && <npc[<[quest_info].get[npc_end]>].location.in_region[<[region_id]>]>:
      #         - define add_quest:true

      #       - if <[add_quest]>:
      #         - define 'quest_title:<[quest_info].get[title]||<empty>> <&e>(ID: <[quest_id]>)'
      #         - define quest_map:<[quest_map].with[<[quest_id]>].as[<[quest_title]>]>

      #     - run drustcraftt_chat_paginate 'def:<list[Quests located in <[region_id]>|<[page_no]>].include_single[<[quest_map]>].include[quest list|quest info]>'

      #   - else:
      #     - narrate '<proc[drustcraftp.message_format].context[error|A region ID is required to list the quests of a region]>'

      - default:
        - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'


# TODO: Working on this
drustcraftt_job_quest_npc:
  type: task
  debug: false
  definitions: action|target_npc|target_player|data
  script:
    - choose <[action]>:
      - case click:
        - note '<inventory[generic[size=54;title=<[target_npc].name.strip_color> Quests]]>' as:drustcraft_quest_<[target_player].uuid>

        # Correct any issues of quests not synced
        - foreach <server.flag[drustcraft.job_quest.player.<[target_player].uuid>].keys||<list[]>> as:quest_id:
          - if <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.completed]> == 0:
            - define found:false
            - foreach <[target_player].inventory.map_slots> key:inv_slot as:inv_item:
              - if <proc[drustcraftp_job_quest_book_to_id].context[<[inv_item]>]> == <[quest_id]>:
                - define found:true
            - if !<[found]>:
              - flag server drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>:!
              - waituntil <server.sql_connections.contains[drustcraft]>
              - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_quest_player` WHERE `quest_id` = <[quest_id]> AND `uuid` = "<[target_player].uuid>";'
              - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_quest_player_objective` WHERE `quest_id` = <[quest_id]> AND `uuid` = "<[target_player].uuid>";'


        # Give items in players hand to NPC if they are wanted
        - if <[target_player].item_in_hand.material.name> != AIR:
          - ~run drustcraftt_job_quest_objective_event def:<[target_player]>|give_npc|<map[].with[npc_id].as[<[target_npc].id>]>

        # Remove completed quests
        - foreach <server.flag[drustcraft.job_quest.player.<[target_player].uuid>].keys||<list[]>> as:quest_id:
          - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_end]> == <[target_npc].id> && <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.completed]> == 0:
            - define quest_completed:true
            - foreach <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective].keys||<list[]>> as:objective_index:
              - if <server.flag[drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.objective.<[objective_index]>.completed]||0> == 0:
                - define quest_completed:false
                - foreach stop

            - if <[quest_completed]>:
              - foreach <[target_player].inventory.map_slots> key:inv_slot as:inv_item:
                - if <proc[drustcraftp_job_quest_book_to_id].context[<[inv_item]>]> == <[quest_id]>:
                  - inventory set slot:<[inv_slot]> o:air d:<[target_player].inventory>
                  - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.repeatable]> == 0:
                    - flag server drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>.completed:1
                    - waituntil <server.sql_connections.contains[drustcraft]>
                    - sql id:drustcraft 'update:UPDATE `<server.flag[drustcraft.db.prefix]>job_quest_player` SET `completed` = 1 WHERE `quest_id`= <[quest_id]> AND `uuid` = "<[target_player].uuid>";'
                  - else:
                    - flag server drustcraft.job_quest.player.<[target_player].uuid>.<[quest_id]>:!
                    - waituntil <server.sql_connections.contains[drustcraft]>
                    - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_quest_player` WHERE `quest_id`= <[quest_id]> AND `uuid` = "<[target_player].uuid>";'
                    - sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>job_quest_player_objective` WHERE `quest_id`= <[quest_id]> AND `uuid` = "<[target_player].uuid>";'

                  - playsound <[target_player]> sound:UI_TOAST_CHALLENGE_COMPLETE volume:1.0 pitch:2
                  - narrate '<proc[drustcraftp_msg_format].context[success|Quest completed: $e<server.flag[drustcraft.job_quest.quest.<[quest_id]>.title]>]>' targets:<[target_player]>
                  - wait 1t
                  - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.reward]||<map[]>> key:material_id as:material_qty:
                    - define target_item:<item[<[material_id]>[quantity=<[material_qty]>]]>
                    - if <[target_player].inventory.can_fit[<[target_item]>]>:
                      - give <[target_item]> to:<[target_player].inventory>
                      - narrate '<proc[drustcraftp_msg_format].context[success|Received $e<[target_item].material.translated_name> $rx $e<[target_item].quantity>]>' targets:<[target_player]>
                    - else:
                      - drop <[target_item]> <cuboid[<[target_npc].location.add[-2,-2,-2]>|<[target_npc].location.add[2,2,2]>].spawnable_blocks.random>
                      - narrate '<proc[drustcraftp_msg_format].context[success|<[target_npc].name.strip_color> dropped $e<[target_item].material.translated_name> $rx $e<[target_item].quantity>]>' targets:<[target_player]>
                  - run drustcraftt_job_quest_update_marker_npc_id def:<[target_player]>|<[target_npc].id>
                  - foreach stop

        # - define quests_done:<proc[drustcraftp_quest.npc.list_done].context[<[target_npc]>|<[target_player]>]>
        # - foreach <proc[drustcraftp_quest.player_inventory].context[<[target_player]>]>:
        #   - if <[quests_done].contains[<[key]>]>:
        #     - define gave_items:true
        #     - inventory set slot:<[value]> o:air d:<[target_player].inventory>
        #     - ~run drustcraftt_quest.completed def:<[target_player]>|<[key]>
        #     - run drustcraftt_quest.update_markers def:true

        # - if <[gave_items]>:
        #   - run drustcraftt_quest.update_markers def:true
        #   - determine cancelled
###

        # Add quests not listed in player to NPC inventory
        - foreach <server.flag[drustcraft.job_quest.quest].keys> as:quest_id:
          - if <server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_start]> == <[target_npc].id>:
            - if !<server.flag[drustcraft.job_quest.player.<[target_player].uuid>].keys.contains[<[quest_id]>]||false>:
              - define show:true
              - foreach <server.flag[drustcraft.job_quest.quest.<[quest_id]>.require].keys||<list[]>> as:require_index:
                - define require_id:<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[require_index]>.type]>
                - ~run <server.flag[drustcraft.job_quest.register.require.<[require_id]>]> def:<list[player_meets_requirement|<[require_id]>|<[quest_id]>|<[target_player]>|<server.flag[drustcraft.job_quest.quest.<[quest_id]>.require.<[require_index]>.data]>]> save:result
                - if !<entry[result].created_queue.determination.get[1]||true>:
                  - define show:false
                  - foreach stop

              - if <[show]>:
                - give <proc[drustcraftp_job_quest_questbook].context[<[quest_id]>|<[target_player]>]> to:<inventory[drustcraft_quest_<[target_player].uuid>]>


        - if <inventory[drustcraft_quest_<[target_player].uuid>].list_contents.size> > 0:
          - inventory open d:<inventory[drustcraft_quest_<[target_player].uuid>]>
          - determine true

        - note remove as:<inventory[drustcraft_quest_<[target_player].uuid>]>
        - random:
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[target_npc]>|Howdy there <[target_player].name>]>' targets:<[target_player]>
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[target_npc]>|Great weather today!]>' targets:<[target_player]>
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[target_npc]>|Whats up there?]>' targets:<[target_player]>
        - determine false

      - case close:
        - note remove as:drustcraft_quest_<[target_player].uuid>

      - case entry:
        - run drustcraftt_job_quest_update_marker_npc_id def:<[target_player]>|<[target_npc].id>

###
      # - case text_status:
      #   - define type:<[4]>
      #   - define data:<[5]>
      #   - define quantity:<[6]>
      #   - define region:<[7]>
      #   - define current:<[8]>
      #   - define quest_id:<[9]>
        
      #   - choose <[type]>:
      #     - case enter_region:                
      #       - define region_title:<proc[drustcraftp.region.title].context[<[target_player].location.world.name>|<[data]>]>
      #       - if <[region_title]> == <empty>:
      #         - define region_title:<[data]>
            
      #       - define 'status:Visit <[region_title]>'
      #       - if <[current]> == 1:
      #         - define 'status:<[status]> <&2>√'
            
      #       - determine <[status]>
      #     - case block_break:
      #       - define 'status:Break <[current]>/<[quantity]> <material[<[data]>].translated_name||<[data]>>'

      #       - if <[region]> != <empty>:
      #         - define region_title:<proc[drustcraftp.region.title].context[<[target_player].location.world.name>|<[region]>]>
      #         - if <[region_title]> == <empty>:
      #           - define region_title:<[data]>
      #         - define 'status:<[status]> at <[region_title]>'

      #       - if <[current]> >= <[quantity]>:
      #         - define 'status:<[status]> <&2>√'
            
      #       - determine <[status]>
      #     - case block_place:
      #       - define 'status:Place <[current]>/<[quantity]> <material[<[data]>].translated_name||<[data]>>'

      #       - if <[region]> != <empty>:
      #         - define region_title:<proc[drustcraftp.region.title].context[<[target_player].location.world.name>|<[region]>]>
      #         - if <[region_title]> == <empty>:
      #           - define region_title:<[data]>
      #         - define 'status:<[status]> at <[region_title]>'

      #       - if <[current]> >= <[quantity]>:
      #         - define 'status:<[status]> <&2>√'
            
      #       - determine <[status]>
      #     - case give:
      #       - define npc_end:<yaml[drustcraft_quests].read[quests.<[quest_id]>.npc_end]||0>
      #       - define npc_name:Unknown
            
      #       - if <[npc_end]> != 0:
      #         - define npc_name:<npc[<[npc_end]>].name.strip_color||<[npc_name]>>
            
      #       - define 'status:Give <[npc_name]> <[current]>/<[quantity]> <material[<[data]>].translated_name||<[data]>>'

      #       - if <[region]> != <empty>:
      #           - define region_title:<proc[drustcraftp.region.title].context[<[target_player].location.world.name>|<[region]>]>
      #           - if <[region_title]> == <empty>:
      #             - define region_title:<[data]>
      #           - define 'status:<[status]> at <[region_title]>'

      #       - if <[current]> >= <[quantity]>:
      #         - define 'status:<[status]> <&2>√'
            
      #       - determine <[status]>
      #     - case kill:
      #       - define 'status:Kill <[current]>/<[quantity]> <[data]>'

      #       - if <[region]> != <empty>:
      #         - define region_title:<proc[drustcraftp.region.title].context[<[target_player].location.world.name>|<[region]>]>
      #         - if <[region_title]> == <empty>:
      #           - define region_title:<[data]>
      #         - define 'status:<[status]> at <[region_title]>'

      #       - if <[current]> >= <[quantity]>:
      #         - define 'status:<[status]> <&2>√'
            
      #       - determine <[status]>


# Complete
drustcraftt_quest_objective_block_break:
  type: task
  debug: false
  definitions: action|objective_id|quest_id|target_player|event_data|quest_data|user_quest_data
  script:
    - choose <[action]>:
      # return the tab complete to add
      - case tabcomplete:
        - determine <list[block_break|_*materials|_*int_nozero|_*regions]>

      # Return if the event objective complete (true|false). Return MAP to update user objective quest data
      - case event:
        - if <[event_data].get[material]> == <[quest_data].get[material]>:
          - if <[quest_data].get[region]> != null:
            - if !<[event_data].location.regions.parse[id].contains[<[quest_data].get[region]>]>:
              - determine false
          - define user_quest_data:<[user_quest_data].with[qty].as[<[user_quest_data].get[qty].add[1]||1>]>
          - determine passively <[user_quest_data]>
          - if <[user_quest_data].get[qty]||0> >= <[quest_data].get[qty]>:
            - determine true
        - determine false

      # return anything except false if adding mets the requirements. The result is what will be stored in the database
      - case add:
        - define material:<[event_data].get[1]||null>
        - define qty:<[event_data].get[2]||null>
        - define region_id:<[event_data].get[3]||null>
        - if <[material]> != null:
          - if <[qty]> != null:
            - if <[qty].is_integer> && <[qty]> > 0:
              - determine <map[].with[material].as[<[material]>].with[qty].as[<[qty]>].with[region].as[<[region_id]>]>
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The quantity must be 1 or more]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|No quantity was entered]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No material was entered]>'

      # return false if removing mets the requirements
      #- case remove:
      #  - determine true

      # convert data to human readable text
      - case to_text:
        - determine '<[quest_data].get[material]> qty:<[quest_data].get[qty]> rgn:<[quest_data].get[region]>'
        # - determine 'Break <[quest_data].get[qty]> x <[quest_data].get[material].replace_text[_].with[ ].to_titlecase>'

      - case to_quest_text:
        - determine 'Break <material[<[quest_data].get[material]>].translated_name> [<[user_quest_data].get[qty]||0>/<[quest_data].get[qty]>]'


# Complete
drustcraftt_quest_objective_block_place:
  type: task
  debug: false
  definitions: action|objective_id|quest_id|target_player|event_data|quest_data|user_quest_data
  script:
    - choose <[action]>:
      # return the tab complete to add
      - case tabcomplete:
        - determine <list[block_place|_*materials|_*int_nozero|_*regions]>

      # Return if the event objective complete (true|false). Return MAP to update user objective quest data
      - case event:
        - if <[event_data].get[material]> == <[quest_data].get[material]>:
          - if <[quest_data].get[region]> != null:
            - if !<[event_data].location.regions.parse[id].contains[<[quest_data].get[region]>]>:
              - determine false
          - define user_quest_data:<[user_quest_data].with[qty].as[<[user_quest_data].get[qty].add[1]||1>]>
          - determine passively <[user_quest_data]>
          - if <[user_quest_data].get[qty]||0> >= <[quest_data].get[qty]>:
            - determine true
        - determine false

      # return anything except false if adding mets the requirements. The result is what will be stored in the database
      - case add:
        - define material:<[event_data].get[1]||null>
        - define qty:<[event_data].get[2]||null>
        - define region_id:<[event_data].get[3]||null>
        - if <[material]> != null:
          - if <[qty]> != null:
            - if <[qty].is_integer> && <[qty]> > 0:
              - determine <map[].with[material].as[<[material]>].with[qty].as[<[qty]>].with[region].as[<[region_id]>]>
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The quantity must be 1 or more]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|No quantity was entered]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No material was entered]>'

      # return false if removing mets the requirements
      #- case remove:
      #  - determine true

      # convert data to human readable text
      - case to_text:
        - determine '<[quest_data].get[material]> qty:<[quest_data].get[qty]> rgn:<[quest_data].get[region]>'
        # - determine 'Break <[quest_data].get[qty]> x <[quest_data].get[material].replace_text[_].with[ ].to_titlecase>'

      - case to_quest_text:
        - determine 'Place <material[<[quest_data].get[material]>].translated_name> [<[user_quest_data].get[qty]||0>/<[quest_data].get[qty]>]'


# Complete
drustcraftt_quest_objective_give_npc:
  type: task
  debug: false
  definitions: action|objective_id|quest_id|target_player|event_data|quest_data|user_quest_data
  script:
    - choose <[action]>:
      # return the tab complete to add
      - case tabcomplete:
        - determine <list[give_npc|_*materials|_*int_nozero]>

      # Return if the event objective complete (true|false). Return MAP to update user objective quest data
      - case event:
        - if <[event_data].get[npc_id]> == <server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_end]>:
          - if <[target_player].item_in_hand.material.name> == <[quest_data].get[material]>:
            - define remaining:<[quest_data].get[qty].sub[<[user_quest_data].get[qty]||0>]>
            - if <[target_player].item_in_hand.quantity> > <[remaining]>:
              - take iteminhand quantity:<[remaining]> player:<[target_player]>
              - define user_quest_data:<[user_quest_data].with[qty].as[<[user_quest_data].get[qty].add[<[remaining]>]||<[remaining]>>]>
            - else:
              - define quantity:<[target_player].item_in_hand.quantity>
              - take iteminhand quantity:<[quantity]> player:<[target_player]>
              - define user_quest_data:<[user_quest_data].with[qty].as[<[user_quest_data].get[qty].add[<[quantity]>]||<[quantity]>>]>

            - narrate '<proc[drustcraftp_npc_chat_format].context[<npc[<[event_data].get[npc_id]>]>|Thanks for the <[target_player].item_in_hand.material.translated_name> <[target_player].name>]>' targets:<[target_player]>

            - determine passively <[user_quest_data]>
            - if <[user_quest_data].get[qty]||0> >= <[quest_data].get[qty]>:
              - determine true

        - determine false

      # return anything except false if adding mets the requirements. The result is what will be stored in the database
      - case add:
        - define material:<[event_data].get[1]||null>
        - define qty:<[event_data].get[2]||null>
        - if <[material]> != null:
          - if <[qty]> != null:
            - if <[qty].is_integer> && <[qty]> > 0:
              - determine <map[].with[material].as[<[material]>].with[qty].as[<[qty]>]>
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The quantity must be 1 or more]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|No quantity was entered]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No material was entered]>'

      # return false if removing mets the requirements
      #- case remove:
      #  - determine true

      # convert data to human readable text
      - case to_text:
        - determine '<[quest_data].get[material]> qty:<[quest_data].get[qty]>'

      - case to_quest_text:
        - define npc_end_name:<npc[<server.flag[drustcraft.job_quest.quest.<[quest_id]>.npc_end]>].name.strip_color>
        - determine 'Give <material[<[quest_data].get[material]>].translated_name> to <[npc_end_name]> [<[user_quest_data].get[qty]||0>/<[quest_data].get[qty]>]'


# Complete
drustcraftt_quest_objective_kill_mob:
  type: task
  debug: false
  definitions: action|objective_id|quest_id|target_player|event_data|quest_data|user_quest_data
  script:
    - choose <[action]>:
      # return the tab complete to add
      - case tabcomplete:
        - determine <list[kill_mob|_*hostile|_*int_nozero]>

      # Return if the event objective complete (true|false). Return MAP to update user objective quest data
      - case event:
        - if <[event_data].get[mob_name]> == <[quest_data].get[mob_name]>:
          - define user_quest_data:<[user_quest_data].with[qty].as[<[user_quest_data].get[qty].add[1]||1>]>
          - determine passively <[user_quest_data]>
          - if <[user_quest_data].get[qty]||0> >= <[quest_data].get[qty]>:
            - determine true
        - determine false

      # return anything except false if adding mets the requirements. The result is what will be stored in the database
      - case add:
        - define mob_name:<[event_data].get[1]||null>
        - define qty:<[event_data].get[2]||null>
        - if <[mob_name]> != null:
          - if <[qty]> != null:
            - if <[qty].is_integer> && <[qty]> > 0:
              - determine <map[].with[mob_name].as[<[mob_name]>].with[qty].as[<[qty]>]>
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The quantity must be 1 or more]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|No quantity was entered]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No mob name was entered]>'

      # return false if removing mets the requirements
      #- case remove:
      #  - determine true

      # convert data to human readable text
      - case to_text:
        - determine '<[quest_data].get[mob_name]> qty:<[quest_data].get[qty]>'

      - case to_quest_text:
        - determine 'Kill <[quest_data].get[mob_name]> [<[user_quest_data].get[qty]||0>/<[quest_data].get[qty]>]'


# Complete
drustcraftt_quest_require_quest:
  type: task
  debug: false
  definitions: action|require_id|quest_id|target_player|quest_data
  script:
    - choose <[action]>:
      # return the tab complete to add
      - case tabcomplete:
        - determine <list[quest|_*quest_ids]>

      # return true if adding command meets the requirements
      - case add:
        - define require_quest_id:<[quest_data].get[1]||null>
        - if <[require_quest_id]> != null:
          - if <[quest_id]> != <[require_quest_id]>:
            - if <server.flag[drustcraft.job_quest.quest].keys.contains[<[require_quest_id]>]||false>:
              - determine <map[].with[quest_id].as[<[require_quest_id]>]>
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID $<[require_quest_id]> $rwas not found]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|You cannot set a required quest to be the same as the original quest]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|No quest ID was entered]>'

      # return true if removing command meets the requirements
      #- case remove:
      #  - determine true

      # convert data to human readable text, used in GUI
      - case to_text:
        - determine '<&7>(ID: <[quest_data].get[quest_id]>)'

      # determine true if player meets requirement
      - case player_meets_requirement:
        - determine <proc[drustcraftp_job_quest_player_completed].context[<[target_player]>|<[quest_data].get[quest_id]>]>


# Complete
drustcraftp_tabcomplete_quest_ids:
  type: procedure
  debug: false
  script:
    - determine <server.flag[drustcraft.job_quest.quest].keys||<list[]>>

# TODO: Working on it
drustcraftp_tabcomplete_quest_objectiveindex:
  type: procedure
  debug: false
  script:
    - if <server.has_flag[drustcraft.job_quest.quest.<queue.definitions.get[2]||null>.objective]>:
      - determine <server.flag[drustcraft.job_quest.quest.<queue.definitions.get[2]>.objective].keys>
    - determine <list[1|2|3|4|5|6|7|8|9]>


drustcraftp_tabcomplete_quest_requireindex:
  type: procedure
  debug: false
  script:
    - if <server.has_flag[drustcraft.job_quest.quest.<queue.definitions.get[2]||null>.require]>:
      - determine <server.flag[drustcraft.job_quest.quest.<queue.definitions.get[2]>.require].keys>
    - determine <list[1|2|3|4|5|6|7|8|9]>


# Complete
drustcraftbook_quest:
  type: book
  title: Quest Book
  author: Quest Book
  signed: true
  text:
  - You should not be seeing this padiwan. Can you report how you got it using the command /report please?
  #1644