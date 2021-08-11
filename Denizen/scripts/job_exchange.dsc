# Drustcraft - Job Exchange
# https://github.com/drustcraft/drustcraft

drustcraftw_job_exchange:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_job_exchange_load

    on script reload:
      - run drustcraftt_job_exchange_load


drustcraftt_job_exchange_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_npc]>:
      - log ERROR 'Drustcraft Job Exchange: Drustcraft NPC is required to be installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.npc]>
    - run drustcraftt_npc_job_register def:exchange|drustcraftt_job_exchange|Exchange
    - flag server drustcraft.module.job_exchange:<script[drustcraftw_job_exchange].data_key[version]>


drustcraftt_job_exchange:
  type: task
  debug: false
  definitions: action|npc|player|data
  script:
    - choose <[action]>:
      - case click:
        - define items:|:trade[inputs=<item[iron_ingot[quantity=4]]>|<item[air]>;result=<item[emerald]>;max_uses=9999]
        - define items:|:trade[inputs=<item[emerald]>|<item[air]>;result=<item[iron_ingot[quantity=4]]>;max_uses=9999]
        - define items:|:trade[inputs=<item[iron_ingot[quantity=4]]>|<item[air]>;result=<item[diamond]>;max_uses=9999]
        - define items:|:trade[inputs=<item[diamond]>|<item[air]>;result=<item[emerald]>;max_uses=9999]

        - define items:|:trade[inputs=<item[emerald]>|<item[air]>;result=<item[copper_ingot[quantity=2]]>;max_uses=9999]
        - define items:|:trade[inputs=<item[copper_ingot[quantity=2]]>|<item[air]>;result=<item[emerald]>;max_uses=9999]

        - define items:|:trade[inputs=<item[iron_ingot[quantity=36]]>|<item[air]>;result=<item[emerald_block]>;max_uses=9999]
        - define items:|:trade[inputs=<item[emerald[quantity=9]]>|<item[air]>;result=<item[emerald_block]>;max_uses=9999]
        - define items:|:trade[inputs=<item[emerald_block]>|<item[air]>;result=<item[emerald[quantity=9]]>;max_uses=9999]

        - define items:|:trade[inputs=<item[emerald[quantity=13]]>|<item[air]>;result=<item[netherite_ingot]>;max_uses=9999]
        - define items:|:trade[inputs=<item[netherite_ingot]>|<item[air]>;result=<item[emerald[quantity=13]]>;max_uses=9999]

        - define items:|:trade[inputs=<item[netherite_ingot[quantity=9]]>|<item[air]>;result=<item[netherite_block]>;max_uses=9999]
        - define items:|:trade[inputs=<item[emerald_block[quantity=13]]>|<item[air]>;result=<item[netherite_block]>;max_uses=9999]
        - define items:|:trade[inputs=<item[netherite_block]>|<item[air]>;result=<item[netherite_ingot[quantity=9]]>;max_uses=9999]
        - define items:|:trade[inputs=<item[netherite_block]>|<item[air]>;result=<item[emerald_block[quantity=13]]>;max_uses=9999]

        - define items:|:trade[inputs=<item[emerald]>|<item[iron_ingot]>;result=<item[chest]>;max_uses=9999]
        - define items:|:trade[inputs=<item[diamond[quantity=26]]>|<item[iron_ingot[quantity=2]]>;result=<item[ender_chest]>;max_uses=9999]

        - opentrades <[items]> 'title:Currency Exchange'

      - case entry:
        - random:
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|Hey <[player].name>, you got emeralds, diamonds or netherite to exchange?]>'
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|Exchange emeralds here buddy]>'
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|Psst, got any spare diamonds?]>'

      - case close:
        - random:
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|Pleasure doing business]>'
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|Have a good day]>'
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|Please come again]>'
          - narrate '<proc[drustcraftp_npc_chat_format].context[<[npc]>|Is that all you want to trade?]>'
