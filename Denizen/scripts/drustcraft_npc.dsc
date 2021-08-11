# Drustcraft - NPC
# https://github.com/drustcraft/drustcraft

drustcraftw_npc:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_npc_load

    on script reload:
      - run drustcraftt_npc_load

    on player respawns:
      - run drustcraftt_npc_spawn_near def:<context.location>

    after player joins:
      - wait 10t
      - run drustcraftt_npc_spawn_near def:<player.location>

    on system time secondly every:5:
      - foreach <server.npcs.filter[location.find_entities[Player].within[25].size.is[OR_MORE].than[1]].filter[is_spawned.not]>:
        - spawn <[value]> <[value].location>
        - run drustcraftt_npc_job_run def:<[value]>|spawn
        - if <[value].has_flag[drustcraft.npc.job.title]>:
          - adjust <[value]> hologram_lines:<list[&e<[value].flag[drustcraft.npc.job.title]>]>
        - else:
          - adjust <[value]> hologram_lines:<list[]>

    on system time minutely:
      - foreach <server.npcs.filter[location.find_entities[Player].within[50].size.is[==].to[0]].filter[is_spawned].filter[not[is_navigating]]>:
        - despawn <[value]>
        - run drustcraftt_npc_job_run def:<[value]>|despawn

    on tab complete:
      - if <context.command> == npc:
        - define args:<context.buffer.split[<&sp>].remove[1]>
        - if <context.buffer.ends_with[<&sp>]>:
          - define args:->:<empty>

        - if <[args].size> == 1:
          - determine <context.completions.include[job]>
        - else if <[args].size> == 2 && <[args].get[1]> == job:
          - determine <yaml[drustcraft_npc_job].list_keys[]>

    on player closes inventory:
      - if <player.has_flag[drustcraft.npc.engaged]> && <player.flag[drustcraft.npc.engaged].has_flag[drustcraft.npc.engaged]> && <player.flag[drustcraft.npc.engaged].flag[drustcraft.npc.engaged]> == <player>:
        - if <player.gamemode> == SURVIVAL:
          - run drustcraftt_npc_job_run def:<player.flag[drustcraft.npc.engaged]>|close|<player>|<context.inventory>

      - if <player.has_flag[drustcraft.npc.engaged]>:
        - if <player.flag[drustcraft.npc.engaged].has_flag[drustcraft.npc.engaged]> && <player.flag[drustcraft.npc.engaged].flag[drustcraft.npc.engaged]> == <player>:
          - flag <player.flag[drustcraft.npc.engaged]> drustcraft.npc.engaged:!
        - flag <player> drustcraft.npc.engaged:!

    on npc command:
      - choose <context.args.get[1]||<empty>>:
        - case create rename:
          - wait 5t
          - assignment set script:drustcrafta_npc npc:<player.selected_npc>

          - foreach <server.npcs>:
            - if !<[value].name.starts_with[<&ss>]>:
              - adjust <[value]> name:<&e><[value].name>
        - case job:
          - determine passively fulfilled
          - define job:<context.args.get[2]||<empty>>
          - if <player.selected_npc.object_type||null> == NPC:
            - if <[job]> != <empty>:
              - if <yaml[drustcraft_npc_job].list_keys[].contains[<[job]>]>:
                - if <player.selected_npc.has_flag[drustcraft.npc.job]>:
                  - ~run drustcraftt_npc_job_run def:<player.selected_npc>|remove|<player>|null
                  - adjust <player.selected_npc> hologram_lines:<list[]>

                - flag <player.selected_npc> drustcraft.npc.job.id:<[job]>
                - flag <player.selected_npc> drustcraft.npc.job.task:<yaml[drustcraft_npc_job].read[<[job]>.task]>
                - if <yaml[drustcraft_npc_job].list_keys[<[job]>].contains[title]>:
                  - adjust <player.selected_npc> hologram_lines:<list[&e<yaml[drustcraft_npc_job].read[<[job]>.title]>]>
                  - flag <player.selected_npc> drustcraft.npc.job.title:<yaml[drustcraft_npc_job].read[<[job]>.title]>

                - waituntil <server.sql_connections.contains[drustcraft]>
                - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>npc` WHERE `server` IS NULL AND `npc_id` = <player.selected_npc.id>;'
                - ~sql id:drustcraft 'update:INSERT INTO `<server.flag[drustcraft.db.prefix]>npc`(`npc_id`, `job`, `data`) VALUES(<player.selected_npc.id>, "<[job]>", NULL);'
                - ~run drustcraftt_npc_job_run def:<player.selected_npc>|add|<player>|null
                - ~run drustcraftt_npc_job_run def:<player.selected_npc>|init|null|null
                - narrate '<proc[drustcraftp_msg_format].context[success|The NPC<&sq>s job is now set to $e<[job]>]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|The NPC job $e<[job]> $ris not available]>'
            - else:
              - if <player.selected_npc.has_flag[drustcraft.npc.job]>:
                - ~run drustcraftt_npc_job_run def:<player.selected_npc>|remove|<player>|null
                - adjust <player.selected_npc> hologram_lines:<list[]>
                - waituntil <server.sql_connections.contains[drustcraft]>
                - ~sql id:drustcraft 'update:DELETE FROM `<server.flag[drustcraft.db.prefix]>npc` WHERE `server` IS NULL AND `npc_id` = <player.selected_npc.id>;'

              - narrate '<proc[drustcraftp_msg_format].context[success|The NPC<&sq>s job has been removed]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|You have no NPC selected]>'


drustcraftt_npc_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - log ERROR 'Drustcraft NPC: Drustcraft DB is required to be installed'
      - stop

    - waituntil <server.sql_connections.contains[drustcraft]>

    - ~run drustcraftt_db_get_version def:drustcraft.npc save:result
    - define version:<entry[result].created_queue.determination.get[1]>

    - if <[version]> == null:
      - ~sql id:drustcraft 'update:CREATE TABLE IF NOT EXISTS `<server.flag[drustcraft.db.prefix]>npc` (`id` INT NOT NULL AUTO_INCREMENT, `server` VARCHAR(255), `npc_id` INT NOT NULL, `job` VARCHAR(255) NOT NULL, `data` TEXT, PRIMARY KEY (`id`));'
      - run drustcraftt_db_set_version def:drustcraft.npc|1

    - if <yaml.list.contains[drustcraft_npc_job]>:
      - ~yaml unload id:drustcraft_npc_job
    - yaml create id:drustcraft_npc_job

    - foreach <server.npcs_flagged[drustcraft.npc]> as:npc:
      - flag <[npc]> drustcraft.npc.job:!
      - flag <[npc]> drustcraft.npc.title:!
      - if <[npc].is_spawned>:
        - adjust <[npc]> hologram_lines:<list[]>

    - ~sql id:drustcraft 'query:SELECT `npc_id`, `job`, `data` FROM `<server.flag[drustcraft.db.prefix]>npc` WHERE 1' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define npc_id:<[row].get[1]||<empty>>
      - define job:<[row].get[2].unescaped||<empty>>
      - define data:<[row].get[3].unescaped||<empty>>

      - if <server.npcs.parse[id].contains[<[npc_id]>]>:
        - flag <npc[<[npc_id]>]> drustcraft.npc.job.id:<[job]>
        - flag <npc[<[npc_id]>]> drustcraft.npc.job.data:<[data]>

    - flag server drustcraft.module.npc:<script[drustcraftw_npc].data_key[version]>


drustcraftt_npc_spawn_near:
  type: task
  debug: false
  definitions: location
  script:
    - foreach <server.npcs.filter[location.distance[<[location]>].is[OR_LESS].than[25]].filter[is_spawned.not]>:
      - spawn <[value]> <[value].location>
      - run drustcraftt_npc_job_run def:<[value]>|spawn


drustcraftt_npc_job_register:
  type: task
  debug: false
  definitions: job|task_name|title
  script:
    - yaml id:drustcraft_npc_job set <[job]>.task:<[task_name]>
    - if <[title]||<empty>> != <empty>:
      - yaml id:drustcraft_npc_job set <[job]>.title:<[title]>

    - foreach <server.npcs_flagged[drustcraft.npc]> as:npc:
      - if <[npc].flag[drustcraft.npc.job.id]||<empty>> == <[job]>:
        - flag <[npc]> drustcraft.npc.job.task:<[task_name]>
        - if <[title].exists>:
          - flag <[npc]> drustcraft.npc.job.title:<[title]>
        - ~run drustcraftt_npc_job_run def:<[npc]>|init|null|null
        - if <[npc].is_spawned> && <[npc].has_flag[drustcraft.npc.job.title]>:
          - adjust <[npc]> hologram_lines:<list[&e<[npc].flag[drustcraft.npc.job.title]>]>


drustcraftt_npc_job_run:
  type: task
  debug: false
  definitions: npc|action|player|data
  script:
    - if <[npc].has_flag[drustcraft.npc.job.task]>:
      - run <[npc].flag[drustcraft.npc.job.task]> def:<[action]>|<[npc]>|<[player]>|<[data]> save:result
      - determine <entry[result].created_queue.determination.get[1]||null>
    - determine null


drustcraftt_npc_title:
  type: task
  debug: false
  definitions: npc|title
  script:
    - flag <[npc]> drustcraft.npc.job.title:<[title]>
    - if <[npc].is_spawned>:
      - adjust <[npc]> hologram_lines:<list[&e<[npc].flag[drustcraft.npc.job.title]>]>


drustcraftp_npc_title:
  type: procedure
  debug: false
  definitions: npc
  script:
    - determine <[npc].flag[drustcraft.npc.job.title]||null>


drustcrafti_npc:
  type: interact
  debug: false
  speed: 0
  steps:
    1:
      click trigger:
        script:
          - if <npc.has_flag[drustcraft.npc.job]> && <player.gamemode> == SURVIVAL:
            - if <npc.has_flag[drustcraft.npc.engaged]>:
              - if !<server.online_players.contains[<npc.flag[drustcraft.npc.engaged]>]> || !<npc.flag[drustcraft.npc.engaged].has_flag[drustcraft.npc.engaged]> || <npc.flag[drustcraft.npc.engaged].flag[drustcraft.npc.engaged]> != <npc>:
                - flag <npc> drustcraft.npc.engaged:!

            - if !<npc.has_flag[drustcraft.npc.engaged]>:
              - run drustcraftt_npc_job_run def:<npc>|click|<player>|null save:result
              - if <entry[result].created_queue.determination.get[1]>:
                - flag <npc> drustcraft.npc.engaged:<player>
                - flag <player> drustcraft.npc.engaged:<npc>
            - else:
              - run drustcraftt_npc_job_run def:<npc>|busy|<player>|<npc.flag[drustcraft.npc.engaged]>


      proximity trigger:
        entry:
          script:
            - if <npc.has_flag[drustcraft.npc.job]> && <player.gamemode> == SURVIVAL:
              - if !<player.has_flag[drustcraft.npc.entry]> || <player.flag[drustcraft.npc.entry].from_now.in_seconds> > 5:
                - flag player drustcraft_npc_entry:<util.time_now>
                - run drustcraftt_npc_job_run def:<npc>|entry|<player>|null

        exit:
          script:
            - if <npc.has_flag[drustcraft.npc.job]> && <player.gamemode> == SURVIVAL:
              - run drustcraftt_npc_job_run def:<npc>|exit|<player>|null
            - if <npc.has_flag[drustcraft.npc.engaged]> && <npc.flag[drustcraft.npc.engaged]> == <player>:
              - flag <npc> drustcraft.npc.engaged:!
            - if <player.has_flag[drustcraft.npc.engaged]> && <player.flag[drustcraft.npc.engaged]> == <npc>:
              - flag <player> drustcraft.npc.engaged:!


drustcrafta_npc:
  type: assignment
  debug: false
  actions:
    on assignment:
      - trigger name:click state:true
      - trigger name:chat state:true
      - trigger name:proximity state:true

    on mob enter proximity:
      - run drustcraftt_npc_job_run def:<npc>|mobenter|<context.entity>|null

    on mob exit proximity:
      - run drustcraftt_npc_job_run def:<npc>|mobexit|<context.entity>|null

    on mob move proximity:
      - run drustcraftt_npc_job_run def:<npc>|mobmove|<context.entity>|null

    on death:
      - run drustcraftt_npc_job_run def:<npc>|death|<context.entity||null>|<context.killer||null>

  interact scripts:
  - drustcrafti_npc


drustcraftp_npc_chat_format:
  type: procedure
  debug: false
  definitions: npc|text
  script:
    - determine '<&6>[NPC] <[npc].name.strip_color>: <[text]>'