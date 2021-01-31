# Drustcraft - AXE
# Simplies gives a wooden axe to a player with the permission to use as a tool
# https://github.com/drustcraft/drustcraft

drustcraftc_axe:
    type: command
    debug: false
    name: axe
    description: Gives the player a wooden axe
    usage: /axe
    permission: drustcraft.axe
    permission message: <&c>I'm sorry, you do not have permission to perform this command
    script:
        - give wooden_axe
