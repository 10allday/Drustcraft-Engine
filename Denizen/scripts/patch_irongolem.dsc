# Patch - Iron Golem
# https://github.com/drustcraft/drustcraft

patch_irongolem:
  type: world
  debug: false
  events:
    on entity death:
      - if <context.entity.name> == iron_golem:
        - if <util.random.int[0].to[1]> == 0:
          - determine <list[<item[iron_ingot]>]>
        - determine NO_DROPS
