# Drustcraft - Utilities
# Utilities
# https://github.com/drustcraft/drustcraft

drustcraftp_utils:
  type: procedure
  debug: false
  script:
    - determine <empty>
    
  split_for_pages:
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
