# Drustcraft Utilities
# https://github.com/drustcraft/drustcraft

drustcraftw_util:
  type: world
  debug: false
  version: 2
  events:
    on server start:
      - run drustcraftt_util_load

    on script reload:
      - run drustcraftt_util_load

    on system time hourly:
      - flag server drustcraft.util.day:<util.time_now.duration_since[<time[1970/01/01]>].in_days.round_down>
      - flag server drustcraft.util.week_of_month:<util.time_now.format[W]>


drustcraftt_util_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - debug ERROR "Drustcraft Util: Drustcraft Setting module is required to be installed"
      - stop

    - ~run drustcraftt_setting_get def:timezone|null|yaml save:result
    - if <entry[result].created_queue.determination.get[1]> == null:
      - run drustcraftt_setting_set def:timezone|Australia/Brisbane|yaml
      - flag server drustcraft.util.timezone:Australia/Brisbane
    - else:
      - flag server drustcraft.util.timezone:<entry[result].created_queue.determination.get[1]>

    - flag server drustcraft.util.day:<util.time_now.duration_since[<time[1970/01/01]>].in_days.round_down>
    - flag server drustcraft.util.week_of_month:<util.time_now.format[W]>

    - flag server drustcraft.module.util:<script[drustcraftw_util].data_key[version]>

# <proc[drustcraftp_util_determine_map].context[<entry[result].created_queue.determination>]>
drustcraftp_util_determine_map:
  type: procedure
  debug: false
  script:
    - define determine_list:<queue.definition[raw_context]||<empty>>
    - define determine_map:<map[]>

    - foreach <[determine_list]>:
      - define key:<[value].before[:]>
      - define val:<[value].after[:]>

      - if <[val].length> == 0:
        - define val:TRUE

      - define determine_map:<[determine_map].with[<[key]>].as[<[val]>]>

    - determine <[determine_map]>


drustcraftp_util_map_reverse:
  type: procedure
  debug: false
  script:
    - determine <[1].get_subset[<[1].keys.reverse>]>


drustcraftp_util_split_book_pages:
  type: procedure
  debug: false
  script:
    - define text:<[1]>
    - define text_split:<[1].split[<&sp>]>
    - define pages:<list[]>
    - define page:<element[]>
    - define page_width:0

    - foreach <[text_split]>:
      - define after:<&sp>
      - define word:<[value]>
      - define skip_on_new_page:false
      - define width:0

      - if <[word]> == <p>:
        - define width:150
        - define after:<element[]>
        - define skip_on_new_page:true
      - else if <[word]> == <n>:
        - define width:50
        - define after:<element[]>
        - define skip_on_new_page:true
      - else:
        - define width:<element[<[word]><[after]>].text_width>

      - if <[page_width].add[<[width]>]> > 900:
        - define pages:->:<[page]>...
        - if !<[skip_on_new_page]>:
          - define page:<[word]><[after]>
          - define page_width:<[width]>
        - else:
          - define page:<element[]>
          - define page_width:0
      - else:
        - define page:<[page]><[word]><[after]>
        - define page_width:+:<[width]>

    - if <[page].length> > 0:
      - define pages:->:<[page]>

    - determine <[pages]>


drustcraftp_util_epoch_to_time:
  type: procedure
  debug: false
  definitions: epoch
  script:
    - determine <time[1970/01/01_00:00:00].add[<[epoch]>s].to_zone[<server.flag[drustcraft.util.timezone]>]>


drustcraftp_util_to_version:
  type: procedure
  debug: false
  definitions: version
  script:
    - define left:<[version].index_of[.]>
    - if <[left]> == 0:
      - determine <[version]>.0
    - determine <[version].substring[1,<[left].add[2]>]>


drustcraftt_util_run_once_later:
  type: task
  debug: false
  definitions: task_name|delay
  script:
    - flag server drustcraft.util.run_once_later.<[task_name]>:++
    - run drustcraftt_util_run_once_later_runner def:<[task_name]> delay:<[delay]>


drustcraftt_util_run_once_later_runner:
  type: task
  debug: false
  definitions: task_name
  script:
    - flag server drustcraft.util.run_once_later.<[task_name]>:--
    - if <server.flag[drustcraft.util.run_once_later.<[task_name]>]> < 1:
      - run <[task_name]>

# min hour day-of-month month day-of-week week-of-month
drustcrafp_util_cron_now:
  type: procedure
  debug: false
  definitions: cron
  script:
    - define now:<util.time_now.to_zone[<server.flag[drustcraft.util.timezone]>]>
    - define cron:<[cron].split[<&sp>]>
    - if <[cron].size> == 6:
      - if <[cron].get[1]> == * || <[cron].get[1]> == <[now].minute>:
        - if <[cron].get[2]> == * || <[cron].get[2]> == <[now].hour>:
          - if <[cron].get[3]> == * || <[cron].get[3]> == <[now].day>:
            - if <[cron].get[4]> == * || <[cron].get[4]> == <[now].month>:
              - if <[cron].get[5]> == * || <[cron].get[5]> == <[now].day_of_week>:
                - if <[cron].get[6]> == * || <[cron].get[6]> == <[now].format[W]>:
                  - determine true
    - determine false


drustcraftp_util_list_replace_text:
  type: procedure
  debug: false
  script:
    - define find:<[1]>
    - define replace:<[2]>
    - define target_list:<queue.definition[raw_context].remove[1|2]||<list[]>>
    - define determine_list:<list[]>

    - foreach <[target_list]>:
      - define determine_list:->:<[value].replace_text[<[find]>].with[<[replace]>]>

    - determine <[determine_list]>


drustcraftp_util_to_version_map:
  type: procedure
  debug: false
  definitions: version_data
  script:
    - define version_map:<map[].with[major].as[0].with[minor].as[0].with[bug].as[0]>
    - if <[version_data].object_type> == ELEMENT:
      - if <[version_data].is_decimal>:
        - define version_map:<[version_map].with[major].as[<[version_data].truncate>]>
        - define version_map:<[version_map].with[minor].as[<[version_data].sub[<[version_map].get[major]>]>]>
      - else if <[version_data].is_integer>:
        - define version_map:<[version_map].with[major].as[<[version_data]>]>
      - else:
        - define version_data:<[version_data].before[-]>
        - define version_data:<[version_data].split[.]>
        - define version_map:<[version_map].with[major].as[<[version_data].get[1]||0>]>
        - define version_map:<[version_map].with[minor].as[<[version_data].get[2]||0>]>
        - define version_map:<[version_map].with[bug].as[<[version_data].get[3]||0>]>

    - determine <[version_map]>
