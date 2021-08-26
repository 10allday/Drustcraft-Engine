# Drustcraft ChatGUI
# https://github.com/drustcraft/drustcraft

drustcraftw_chatgui:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_chatgui_load

    on script reload:
      - run drustcraftt_chatgui_load

drustcraftt_chatgui_load:
  type: task
  debug: false
  script:
    - flag server drustcraft.module.chatgui:<script[drustcraftw_chatgui].data_key[version]>


drustcraftt_chatgui_clear:
  type: task
  debug: false
  script:
    - flag player drustcraft.chatgui.items:!


drustcraftt_chatgui_item:
  type: task
  debug: false
  definitions: item
  script:
    - flag player drustcraft.chatgui.items:->:<[item]>


drustcraftt_chatgui_render:
  type: task
  debug: false
  definitions: cmd|title|page|as_list|no_items
  script:
    - define item_list:<player.flag[drustcraft.chatgui.items]||<list[]>>
    - if <[item_list].size> > 0:
      - define start_item:<[page].sub[1].mul[8].add[1]>
      - define page_count:<[item_list].size.div[8].round_up>

      - if <[start_item]> <= <[item_list].size>:
        - narrate <proc[drustcraftp_chatgui_title].context[<[title]>]>
        - foreach <[item_list].get[<[start_item]>].to[<[start_item].add[7]>]>:
          - define line:<[value]>
          - if <[as_list]||false>:
            - define line:<&d><[start_item].sub[1].add[<[loop_index]>]>.<&sp><[line]>
          - narrate <[line]>

        - run drustcraftt_chatgui_footer def:<[cmd]>|<[page]>|<[page_count]>
      - else:
        - narrate '<proc[drustcraftp_msg_format].context[error|That page does not exist]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[error|<[no_items]||There are no items to show>]>'
    - run drustcraftt_chatgui_clear


drustcraftp_chatgui_title:
  type: procedure
  debug: false
  definitions: title
  script:
    - define horz_line:-------------------------
    
    - define 'line: <[title]> '
    
    - define horz_size:<[horz_line].text_width.sub[<[line].text_width.div[2].round_up>].div[6].round_down>
    - define line:<&e><[horz_line].substring[0,<[horz_size]>]><&f><[line]><&e><[horz_line].substring[0,<[horz_size]>]>
    - determine <[line]>


drustcraftt_chatgui_footer:
  type: task
  debug: false
  definitions: cmd|page_no|page_max
  script:
    - define horz_line:-------------------------

    - define footer_width:67
    - if <[page_no]> > 1 && <[cmd]> != <empty>:
      - define 'prev_page: <element[<&lt><&lt><&lt>].on_click[/<[cmd]> <[page_no].sub[1]>].on_hover[Click to navigate]> '
      - define footer_width:+:19
    - else:
      - define prev_page:<empty>
    - if <[page_no]> != <[page_max]> && <[cmd]> != <empty>::
      - define 'next_page:<element[<&gt><&gt><&gt>].on_click[/<[cmd]> <[page_no].add[1]>].on_hover[Click to navigate]> '
      - define footer_width:+:19
    - else:
      - define next_page:<empty>

    - define 'line:<&6><[prev_page]> <&e>Page <&6><[page_no]> of <[page_max]> <[next_page]>'
    - define horz_size:<[horz_line].text_width.sub[<[footer_width].div[2].round_up>].div[6].round_down>
    - define line:<&e><[horz_line].substring[0,<[horz_size]>]><&f><[line]><&e><[horz_line].substring[0,<[horz_size]>]>
    - narrate <[line]>


drustcraftp_chatgui_option:
  type: procedure
  debug: false
  definitions: option
  script:
    - determine <&9><[option]>:<&sp>


drustcraftp_chatgui_listvalue:
  type: procedure
  debug: false
  definitions: option_value
  script:
    - determine <&6><[option_value]><&sp>


drustcraftp_chatgui_value:
  type: procedure
  debug: false
  script:
    - define option_value:<queue.definition_map.exclude[raw_context].values>
    - if <[option_value].size> == 1:
      - define option_value:<[option_value].get[1]>

    - define result_list:<list[]>
    - if <[option_value].object_type> != LIST:
      - if <[option_value].char_at[1]> == <element[(]>:
        - determine <&c><[option_value]>
      - determine <&e><[option_value]>
    - else:
      - if <[option_value].size> > 0:
        - foreach <[option_value]>:
          - if <[value].contains[:]>:
            - define result_list:->:<&7><[value].before[:]>:<&6><[value].after[:]>
          - else:
            - define result_list:->:<&e><[value]>

        - determine <[result_list].separated_by[<&9>,<&sp>]><&sp>
      - else:
        - determine <&7>(none)<&sp>

    - determine <empty>


drustcraftp_chatgui_flags:
  type: procedure
  debug: false
  definitions: flag_map
  script:
    - if <[flag_map].size> > 0:
      - define result_list:<list[]>

      - foreach <[flag_map]>:
        - define result_list:->:<&7><[key]>=<&6><[value]>

      - determine <&7>(<[result_list].separated_by[<&7>,<&sp>]><&7>)
    - determine <empty>


drustcraftp_chatgui_button:
  type: procedure
  debug: false
  definitions: type|title|command|hover|cmd_type
  script:
    - define colour:7
    - if <[type]> == add:
      - define colour:2
    - else if <[type]> == rem:
      - define colour:c

    - define cmd_type:<[cmd_type]||SUGGEST_COMMAND>
    - define link:<element[&<[colour]><&lb><[title]><&rb>].on_click[/<[command]>].type[<[cmd_type]>]>
    - if <[hover].exists>:
      - define link:<[link].on_hover[<[hover]>]>
    - determine <[link].parse_color>
