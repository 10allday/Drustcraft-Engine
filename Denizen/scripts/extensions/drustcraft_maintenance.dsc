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
    on bungee player joins network:
      - wait 160t
      - if <server.online_players.parse[name].contains[<context.name>]>:
        - run drustcraftt_maintenance.announcements
      
    
drustcraftt_maintenance:
  type: task
  debug: false
  script:
    - determine <empty>
    
  announcements:
    - if <player.flag[drustcraft_firstspawn]||1> < 4:
      - flag <player> drustcraft_firstspawn:++
      - narrate '<&e> '
      - narrate '<&8>[<&d><&gt><&8>] <&f>New to Drustcraft?
      - narrate '<&e> - You cannot build at spawn, cities or within the deep'
      - narrate '<&e>   tram tunnels.'
      - narrate '<&e> - PVP and griefing is permitted outside of these areas' 
      - narrate '<&e>   except in Creative gamemode regions.'
      - narrate '<&e> - Guard will attack players who PVP near them.'
      - narrate '<&e> - Mobs get stronger the further away from spawn you go.'
      - wait 240t
    
    - if <server.online_players.contains[<player>]>:
      - narrate '<&e> '
      - narrate '<&8>[<&d><&gt><&8>] <&f>Recent Changes
      # - narrate '<&e> - [Fixed] Builders can now again select NPCs using a stick'
      - narrate '<&e> - [Added] Players now drop their heads in battlegrounds!'
    
    # - if <server.online_players.contains[<player>]>:
    #   - wait 240t
    #   - narrate '<&e> '
    #   - narrate '<&8>[<&d><&gt><&8>] <&f>Current Issues
    #   - narrate '<&e> - We are currently having issues with some NPCs due'
    #   - narrate '<&e>   to a recent plugin upgrade. This affects guards and'
    #   - narrate '<&e>   shopkeepers. We hope to have this fix ASAP'
    
    # - if <server.online_players.contains[<player>]>:
    #   - wait 240t
    #   - narrate '<&e> '
    #   - narrate '<&8>[<&d><&gt><&8>] <&f>Join Ironport<&sq>s Expansion
    #   - narrate '<&e>  Would you like to help build Ironport in Creative'
    #   - narrate '<&e>  mode? We will be announcing a limited number of'
    #   - narrate '<&e>  builder roles for Ironport<&sq>s expansion shortly'
    #   - narrate '<&e>  at <&f>www.drustcraft.com.au' 

    - if <server.online_players.contains[<player>]>:
      - wait 240t
      - narrate '<&e> '
      - narrate '<&8>[<&d><&gt><&8>] <&f>1.17 Update
      - narrate '<&e>  There will be a delay with Drustcraft updating to'
      - narrate '<&e>  1.17 due to the complexity that this major update'
      - narrate '<&e>  brings to plugins and servers.'
      - narrate '<&e>  Visit drustcraft.com.au for updates!'
  