# Drustcraft - GameMode Inventory
# Player Gamemode Inventories
# https://github.com/drustcraft/drustcraft

drustcraftw_gamemode_inventory:
  type: world
  debug: false
  events:
    on player changes gamemode:
      - flag player gamemode.inventory.<player.gamemode>:<player.inventory.list_contents>
      - inventory clear
      - if <player.has_flag[gamemode.inventory.<context.gamemode>]> && <player.flag[gamemode.inventory.<context.gamemode>].size> > 0:
        - inventory set d:<player.inventory> origin:<player.flag[gamemode.inventory.<context.gamemode>]>
    
    on player opens inventory:
      - if <player.gamemode> != SURVIVAL:
        - narrate '<&8>[<&c>-<&8>] <&e>You cannot open chests or inventories while not in Surival mode'
        - determine CANCELLED
    
    on player drops item:
      - if <player.gamemode> != SURVIVAL:
        - narrate '<&8>[<&c>-<&8>] <&e>You cannot drop items while not in Surival mode'
        - determine CANCELLED
      
