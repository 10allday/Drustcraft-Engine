# Drustcraft - Chat Menu Utility
# Provides a Chat Menu utility
# https://github.com/drustcraft/drustcraft

drustcraftw_chat_menu:
  type: world
  debug: false
  events:
    on command:
      - if <player||<empty>> != <empty>:
          - run drustcraftt_chat_menu.close

    on player chats:
      - if <player.flag[drustcraft_chat_menu.tasks]||<empty>> != <empty>:
        - determine passively cancelled
        - run drustcraftt_chat_menu.key def:<context.message>


#    on player login:
#      - run drustcraftt_chat_menu.close


drustcraftt_chat_menu:
  type: task
  debug: false
  script:
    - determine <empty>
    
  create:
    - define task:<[1]||<empty>>
    - define id:<[2]||<empty>>
    - define page:<[3]||1>

    - ~run drustcraftt_chat_menu.close
    - flag player drustcraft_chat_menu.tasks:->:<map[task/<[task]>|id/<[id]>]>
    - flag player drustcraft_chat_menu.page:<[page]>
    - run <[task]> def:<[id]>
  
  close:
    - flag player drustcraft_chat_menu:!

  clear:
    - flag player drustcraft_chat_menu.header:<element[]>
    - flag player drustcraft_chat_menu.line:0
    - flag player drustcraft_chat_menu.key:0
    - flag player drustcraft_chat_menu.page:1
    - flag player drustcraft_chat_menu.items:!

  add:
    - define item:<[1]||<empty>>
    - if <[item]> != <empty>:
      - flag player drustcraft_chat_menu.line:++
      - if <player.flag[drustcraft_chat_menu.line]> > 6:
        - flag player drustcraft_chat_menu.line:0
        - flag player drustcraft_chat_menu.key:0

      - if <[item].type> == Element:
        - define item:<map[title/<[item]>]>
      - else:
        - if <[item].keys.contains[key]> == false:
          - flag player drustcraft_chat_menu.key:++
          - define item:<[item].with[key].as[<player.flag[drustcraft_chat_menu.key]>]>

      - flag player drustcraft_chat_menu.items:->:<[item].escaped>
  
  ask:
    - flag player drustcraft_chat_menu.ask_task:<[2]||<empty>>
    - flag player drustcraft_chat_menu.ask_id:<[3]||<empty>>
    - narrate <&e><[1]||<empty>>
  
  back:
    - if <player.flag[drustcraft_chat_menu.tasks].size> > 1:
      - flag player drustcraft_chat_menu.tasks:<-:<player.flag[drustcraft_chat_menu.tasks].last>
      - run drustcraftt_chat_menu.clear
      - define menu_item:<player.flag[drustcraft_chat_menu.tasks].last.as_map>
      
      - define task:<[menu_item].get[task]>
      - if <[task]> != <empty>:
        - ~run <[task]> def:<[menu_item].get[id]||<empty>>
      - else:
        - run drustcraftt_chat_menu.close

  header:
    - flag player drustcraft_chat_menu.header:<[1]>
  
  render:
    - flag player drustcraft_chat_menu.ask_task:!
    - flag player drustcraft_chat_menu.ask_id:!

    - if <player.flag[drustcraft_chat_menu.header]||<empty>> != <empty>:
      - define 'header: <player.flag[drustcraft_chat_menu.header]> '
      - define half_width:<element[24].add[<[header].length.div[2].round_down>]>
      - define header:<&e><[header].pad_left[<[half_width]>].with[-]>
      - define header:<[header].pad_right[48].with[-]>
      - narrate <[header]>

    - define start_item:<player.flag[drustcraft_chat_menu.page].sub[1].mul[6].add[1]>
    - if <player.flag[drustcraft_chat_menu.items].size> >= <[start_item]>:
      - define menu_items:<player.flag[drustcraft_chat_menu.items].get[<[start_item]>].to[<[start_item].add[5]>]>
      - define found:false
      
      - foreach <[menu_items]>:
        - define menu_item:<[value].unescaped.as_map>

        - define text:<element[]>
          
        - if <[menu_item].keys.contains[key]>:
          - define 'text:<[text]><[menu_item].get[key]><&e> - '

        - define text:<[text]><[menu_item].get[title]>
        
        - narrate <[text]>
    
      - define 'back_exit:X <&e>- Exit'
      - if <player.flag[drustcraft_chat_menu.tasks].size> > 1:
        - define 'back_exit:B <&e>- Back   /   <&f><[back_exit]>'
      - narrate <[back_exit]>

      - define 'footer: <&f>Page <player.flag[drustcraft_chat_menu.page]> of <player.flag[drustcraft_chat_menu.items].size.div[6].round_up><&e> '
      - if <player.flag[drustcraft_chat_menu.page]> > 1:
        - define 'footer: <&f><&lt><&lt><&lt> (P)rev --<&e><[footer]>'
      - if <player.flag[drustcraft_chat_menu.page]> < <player.flag[drustcraft_chat_menu.items].size.div[6].round_up>:
        - define 'footer:<[footer]>-- <&f>(N)ext <&gt><&gt><&gt><&e> '

      - define half_width:<element[24].add[<[footer].length.div[2].round_down>]>
      - define footer:<[footer].pad_left[<[half_width]>].with[-]>
      - define footer:<[footer].pad_right[48].with[-]>

      - narrate <&e><[footer]>

  key:
    - define key:<[1]>

    - if <player.flag[drustcraft_chat_menu.ask_task]||<empty>> != <empty>:
      - run <player.flag[drustcraft_chat_menu.ask_task]> def:<player.flag[drustcraft_chat_menu.ask_id]>|<[key]>
    - else:
      - choose <[key]>:
        - case x exit:
          - narrate '<&e><player.flag[drustcraft_chat_menu.header]||Menu> exited'
          - run drustcraftt_chat_menu.close
        - case b:
          - if <player.flag[drustcraft_chat_menu.tasks].size> > 1:
            - flag player drustcraft_chat_menu.tasks:<-:<player.flag[drustcraft_chat_menu.tasks].last>
            - run drustcraftt_chat_menu.clear
            - define menu_item:<player.flag[drustcraft_chat_menu.tasks].last.as_map>
            
            - ~run <[menu_item].get[task]> def:<[menu_item].get[id]||<empty>>
          - else:
            - narrate '<&c>You can<&sq>t go back a menu'
            - run drustcraftt_chat_menu.render
        - case p:
          - if <player.flag[drustcraft_chat_menu.page]> > 1:
            - flag player drustcraft_chat_menu.page:--
            - run drustcraftt_chat_menu.render
          - else:
            - narrate '<&c>That page does not exist'
            - run drustcraftt_chat_menu.render
        - case n:
          - if <player.flag[drustcraft_chat_menu.page].add[1]> <= <player.flag[drustcraft_chat_menu.items].size.div[6].round_up>:
            - flag player drustcraft_chat_menu.page:++
            - run drustcraftt_chat_menu.render 
          - else:
            - narrate '<&c>That page does not exist'
            - run drustcraftt_chat_menu.render
        - default:
          - define start_item:<player.flag[drustcraft_chat_menu.page].sub[1].mul[6].add[1]>
          - if <player.flag[drustcraft_chat_menu.items].size> >= <[start_item]>:
            - define menu_items:<player.flag[drustcraft_chat_menu.items].get[<[start_item]>].to[<[start_item].add[10]>]>
            - define found:false
            
            - foreach <[menu_items]>:
              - define menu_item:<[value].unescaped.as_map>
              - if <[menu_item].keys.contains[key]> && <[menu_item].get[key]> == <[key]>:
                - if <[menu_item].keys.contains[task]>:
                  - define id:<[menu_item].get[id]||<empty>>
                  - ~run drustcraftt_chat_menu.clear
                  - flag player drustcraft_chat_menu.tasks:->:<map[task/<[menu_item].get[task]>|id/<[id]>].escaped>
                  - define task:<[menu_item].get[task]>
                  - if <[task]> != <empty>:
                    - ~run <[task]> def:<[id]>
                    - if <player.flag[drustcraft_chat_menu.items].size> == 0:
                      - run drustcraftt_chat_menu.close
                  - else:
                    - run drustcraftt_chat_menu.close

                - define found:true
                - foreach stop

            - if <[found]> == false:
              - narrate '<&c><&sq><[key]><&sq> is not a valid option'
              - run drustcraftt_chat_menu.render
          - else:
            - narrate '<&c>An unexpected error occured with this menu'
            - run drustcraftt_chat_menu.close
