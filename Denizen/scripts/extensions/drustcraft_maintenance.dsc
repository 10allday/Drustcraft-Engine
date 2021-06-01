# Drustcraft - Maintenance
# Whitelist players using a variety of mechanics
# https://github.com/drustcraft/drustcraft

drustcraftw_maintenance:
  type: world
  debug: false
  version: 1
  events:
    # on player logs in:
    #   - if <list[nomadjimbob|MisterCobra1234].contains[<player.name>]> == FALSE:
    #     - determine 'KICKED:<&nl><&nl><&e>Drustcraft is currently under maintenance<&nl><&nl><&f>Please try again later'
    after player joins:
      - wait 160t
      - narrate '<&e> '
      - narrate '<&8>[<&d><&gt><&8>] <&f>Current Issues
      - narrate '<&e>  We are currently having issues with some NPCs due'
      - narrate '<&e>  to a recent plugin upgrade. This affects guards and'
      - narrate '<&e>  shopkeepers. We hope to have this fix ASAP'
      - wait 320t
      - narrate '<&e> '
      - narrate '<&8>[<&d><&gt><&8>] <&f>Join Ironport<&sq>s Expansion
      - narrate '<&e>  Would you like to help build Ironport in Creative'
      - narrate '<&e>  mode? We will be announcing a limited number of'
      - narrate '<&e>  builder roles for Ironport<&sq>s expansion shortly'
      - narrate '<&e>  at <&f>www.drustcraft.com.au' 
      - wait 320t
      - narrate '<&e> '
      - narrate '<&8>[<&d><&gt><&8>] <&f>New to Drustcraft?
      - narrate '<&e> - You cannot build at spawn, cities or within the deep'
      - narrate '<&e>   tram tunnels.'
      - narrate '<&e> - PVP and griefing is permitted outside of these areas' 
      - narrate '<&e>   except in Creative gamemode regions.'
      - narrate '<&e> - Guard will attack players who PVP near them.'
      - narrate '<&e> - Mobs get stronger the further away from spawn you go.'