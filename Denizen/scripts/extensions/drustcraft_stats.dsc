# Drustcraft - Stats
# Displays server stats
# https://github.com/drustcraft/drustcraft

drustcraftc_stats:
  type: command
  debug: false
  name: stats
  description: Displays stats of the server
  usage: /stats
  permission: drustcraft.stats
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  script:
    - narrate ''
    - narrate '<&e>----- Server Information -----'
    - narrate '<&6>Online players: <&a><server.online_players.size> <&6>/ <&a><server.max_players>'
    - narrate '<&6>Disk free space: <&a><server.disk_free.div[1073741824].round_to[2]> GB'
    - narrate '<&6>Memory: <&a><server.ram_usage.div[1073741824].round_to[2]> GB <&6>(<&a><server.ram_free.div[1073741824].round_to[2]> GB <&6>free)'
    - narrate '<&6>Script count: <&a><server.scripts.size>'
    - narrate '<&6>Region count: <&a><server.notables.size>'
    - narrate '<&6>NPCs count: <&a><server.npcs.size>'
    
    - foreach <server.worlds>:
      - narrate '<&e><[value].name>: <&a><[value].entities.size> <&e>entities, <&a><[value].loaded_chunks.size> <&e>chunks'
    
    - define tps:<list[]>
    - foreach <server.recent_tps>:
      - define rounded:<[value].round_to[1]>
      
      - if <[rounded]> < 15:
        - define tps:|:<&c><[rounded]>
      - else if <[rounded]> < 18:
        - define tps:|:<&e><[rounded]>
      - else:
        - define tps:|:<&a><[rounded]>
    - narrate '<&6>Last TPS: <[tps].space_separated>'
