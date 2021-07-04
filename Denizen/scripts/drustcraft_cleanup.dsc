# Drustcraft - Cleanup
# Data Cleaup Utilities
# https://github.com/drustcraft/drustcraft

drustcraftw_cleanup:
  type: world
  debug: false
  events:
    on server stats:
      # remove after 04/10/2021
      - waituntil <yaml.list.contains[drustcraft_npc]>
      - yaml id:drustcraft_npc set npc.storage:!      
    
    after player joins:
      # remove after 04/10/2021
      - flag player drustcraft_coords_pointer:!
      - flag player npc_engaged:!
      
