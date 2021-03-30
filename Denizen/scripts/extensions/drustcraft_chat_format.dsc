# Drustcraft - Chat Format
# Formats chat to specific colours and formats using codes
# https://github.com/drustcraft/drustcraft

drustcraftp_chat_format:
  type: procedure
  debug: false
  script:
    - define entity:<[1]||<empty>>
    - define message:<[2]||<empty>>
    - define name:<[entity].name.strip_color||UNKNOWN>
    
    - if <[entity]> != <empty> && <[message]> != <empty> && <[name]> != <empty>:
      - define colour:f
        
    - if <[entity].object_type> == Player:
      - if <[entity].in_group[moderator]> || <[entity].in_group[leader]>:
        - define colour:a
      - if <[entity].in_group[developer]>:
        - define colour:d
    - else if <[entity].object_type> == NPC:
      - define colour:6
    - else:
      - define colour:f
        
    - if <[message].starts_with[*]>:
      - determine '<element[&<[colour]><[name]> <[message].after[*]>].parse_color>'
    - else:
      - determine '<element[&<[colour]>[<[name]>]: <[message]>].parse_color>'
