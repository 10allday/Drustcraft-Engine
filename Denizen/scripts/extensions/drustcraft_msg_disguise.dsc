# Drustcraft - Message Disguise
# Modifies system messages to the player for consistency
# https://github.com/drustcraft/drustcraft

drustcraftw_msg_disguise:
  type: world
  debug: false
  events:
    on player receives message:
      - if <context.system_message>:
        # the following is required due to weirdness from FAWE
        - define message:<context.raw_json.from_raw_json.strip_color||<empty>>

        - if '<[message].starts_with[(FAWE) You are lacking the permission node]>':
          - determine 'MESSAGE:<&e>WorldEdit commands are not available outside of <&f>/builder<&e> mode'
        - else if '<[message].starts_with[Hey! Sorry]>':
          - determine 'MESSAGE:<&e><[message].after[Hey! ]>'
        - else if '<[message].starts_with[<&lb>GameModeInventories<&rb> ]>':
          - determine 'MESSAGE:<&e><[message].after[<&lb>GameModeInventories<&rb> ]>'
