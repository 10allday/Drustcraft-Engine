# Drustcraft - Cleanup
# Data Cleaup Utilities
# https://github.com/drustcraft/drustcraft

drustcraftw_cleanup:
  type: world
  debug: false
  events:
    after player joins:
      # remove after 04/10/2021
      - flag player drustcraft_coords_pointer:!

