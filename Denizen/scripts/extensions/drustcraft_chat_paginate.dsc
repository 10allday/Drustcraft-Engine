# Drustcraft - Chat Paginate Utils
# Provide Chat Paginate utility
# https://github.com/drustcraft/drustcraft

drustcraftw_chat_paginate:
  type: world
  debug: false
  events:
    on server start:
      - wait 2t


drustcraftt_chat_paginate:
  type: task
  debug: false
  script:
    - define title:<[1]||<empty>>
    - define page_no:<[2]||1>
    - define paginate_list:<[3]||<list[]>>
    - define cmd_list:<[4]||<empty>>
    - define cmd_info:<[5]||<empty>>
    - define show_numbers:<[6]||true>
    - define cmd_edit:<[7]||<empty>>
    - define cmd_remove:<[8]||<empty>>

    - if <[paginate_list].size> == 0:
      - narrate '<&e>No items could be found'
    - else:
      - define paginate_map:<empty>
      - if <[paginate_list].object_type> == Map:
        - define paginate_map:<[paginate_list]>
        - define paginate_list:<[paginate_list].keys>
      
      - define paginate_list_start:<[page_no].sub[1].mul[8].add[1]>
      - define paginate_list_end:<[paginate_list_start].add[7]>

      - if <[paginate_list].size> < <[paginate_list_start]>:
        - narrate '<&e>That page doesn<&sq>t exist'
      - else:
        - if <[paginate_list].size> < <[paginate_list_end]>:
          - define paginate_list_end:<[paginate_list].size>
        
        - define page_max:<[paginate_list].size.div[8].round_up>
        - define paginate_list:<[paginate_list].get[<[paginate_list_start]>].to[<[paginate_list_end]>]>
        - define horz_line:-------------------------
        
        - define 'line: <[title]> '
        - define line_length:<[line].text_width>
        - define horz_size:<[horz_line].text_width.sub[<[line].text_width.div[2].round_up>].div[6].round_down>
        - define line:<&e><[horz_line].substring[0,<[horz_size]>]><&f><[line]><&e><[horz_line].substring[0,<[horz_size]>]>
        - narrate <[line]>
                    
        - foreach <[paginate_list]>:
          - define item_title:<[value]>
          - define item_id:<[value]>
          
          - if <[paginate_map]> != <empty>:
            - define item_title:<[paginate_map].get[<[item_id]>]>
                      
          - if <[cmd_info]> != <empty>:
            - define 'info: <&7><element[<&lb>Info<&rb>].on_click[/<[cmd_info]> <[item_id]>].on_hover[Click for info]>'
          - else:
            - define info:<empty>
          
          - if <[cmd_edit]> != <empty>:
            - define 'edit: <&7><element[<&lb>Edit<&rb>].on_click[/<[cmd_edit]> <[item_id]>].on_hover[Click to edit item]>'
          - else:
            - define edit:<empty>
          
          - if <[cmd_remove]> != <empty>:
            - define 'remove: <&c><element[<&lb>Rem<&rb>].on_click[/<[cmd_remove]> <[item_id]>].on_hover[Click to remove item]>'
          - else:
            - define remove:<empty>
          
          - define number:<empty>
          - if <[show_numbers]>:
            - define 'number:<[paginate_list_start].add[<[loop_index]>].sub[1]>. '
          - narrate '<&d><[number]><&6><[item_title].parse_color><[info]><[edit]><[remove]>'
        
        - define footer_width:67
        - if <[page_no]> > 1 && <[cmd_list]> != <empty>:
          - define 'prev_page: <element[<&lt><&lt><&lt>].on_click[/<[cmd_list]> <[page_no].sub[1]>].on_hover[Click to navigate]> '
          - define footer_width:+:19
        - else:
          - define prev_page:<empty>
        - if <[page_no]> != <[page_max]> && <[cmd_list]> != <empty>::
          - define 'next_page:<element[<&gt><&gt><&gt>].on_click[/<[cmd_list]> <[page_no].add[1]>].on_hover[Click to navigate]> '
          - define footer_width:+:19
        - else:
          - define next_page:<empty>

        - define 'line:<&6><[prev_page]> <&e>Page <&6><[page_no]> of <[page_max]> <[next_page]>'
        - define horz_size:<[horz_line].text_width.sub[<[footer_width].div[2].round_up>].div[6].round_down>
        - define line:<&e><[horz_line].substring[0,<[horz_size]>]><&f><[line]><&e><[horz_line].substring[0,<[horz_size]>]>
        - narrate <[line]>
