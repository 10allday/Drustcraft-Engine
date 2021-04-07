# Drustcraft - Quests
# Quests Management
# https://github.com/drustcraft/drustcraft

# you can give items to a questgiver and they will keep it!

drustcraftw_quest:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_quest.load
      
    on script reload:
      - run drustcraftt_quest.load
    
    on player death:
      - determine passively KEEP_INV
      - determine passively NO_DROPS
      
      - foreach <context.entity.inventory.map_slots>:
        - if <[value].book_title.strip_color.starts_with[Quest:<&sp>]||false> == false:
          - take <[value]> quantity:<[value].quantity> from:<context.entity.inventory>
          - drop <[value]> <cuboid[<context.entity.location.add[-2,-2,-2]>|<context.entity.location.add[2,2,2]>].spawnable_blocks.random>
    

    on player drops item:
      - if <context.item.is_book> && <context.item.book_title.strip_color.starts_with[Quest:<&sp>]>:
        - define quest_id:<proc[drustcraftp_quest.title_to_id].context[<context.item.book_title.after[Quest:<&sp>]>]||0>
        - if <[quest_id]> != 0:
          - remove <context.entity>
          - run drustcraftt_quest.abandon def:<player>|<[quest_id]>

        
    on entity picks up item:
      - if <context.item.is_book> && <context.item.book_title.strip_color.starts_with[Quest:<&sp>]>:
        - remove <context.entity>
        - determine cancelled

    
    on player closes inventory:
      - foreach <context.inventory.map_slots>:
        - if <[value].is_book> && <[value].book_title.strip_color.starts_with[Quest:<&sp>]>:
          - define quest_id:<proc[drustcraftp_quest.title_to_id].context[<[value].book_title.after[Quest:<&sp>]>]||0>
          - if <[quest_id]> != 0 && <proc[drustcraftp_quest.state].context[<[quest_id]>|<player>]> == active:
            - inventory set slot:<[key]> o:air d:<context.inventory>
            - run drustcraftt_quest.abandon def:<player>|<[quest_id]>
      
      - foreach <player.inventory.map_slots>:
        - if <[value].is_book> && <[value].book_title.strip_color.starts_with[Quest:<&sp>]>:
          - define quest_id:<proc[drustcraftp_quest.title_to_id].context[<[value].book_title.after[Quest:<&sp>]>]||0>
          - if <[quest_id]> != 0 && <proc[drustcraftp_quest.state].context[<[quest_id]>|<player>]> == available:
            - run drustcraftt_quest.start def:<player>|<[quest_id]>


    on player changes gamemode to SURVIVAL:
      - run drustcraftt_quest.update_markers def:<player>|true


    on player breaks block priority:100:
			- run drustcraftt_quest.objective_event def:<player>|block_break|<context.material.name>|<context.location>
    
    
    on player places block priority:100:
			- run drustcraftt_quest.objective_event def:<player>|block_place|<context.material.name>|<context.location>
      
    
    on player enters cuboid priority:100:
      - define region_name:<context.area.note_name||<empty>>
      - run drustcraftt_quest.objective_event def:<player>|enter_region|<[region_name]>


    on entity dies priority:100:
      - if <context.damager.object_type||<empty>> == PLAYER:
        - define name:<empty>
        - if <context.entity.is_mythicmob>:
          - define name:<context.entity.mythicmob.internal_name||<empty>>
        - else:
          - define name:<context.entity.name||<empty>>
        
        - if <[name]> != <empty>:
  			  - run drustcraftt_quest.objective_event def:<context.damager>|kill|<[name]>|<context.entity.location>
    


drustcraftt_quest:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - waituntil <yaml.list.contains[drustcraft_tab_complete]>

      - run drustcraftt_tab_complete.completions def:quest|list|_*pageno
      - run drustcraftt_tab_complete.completions def:quest|npclist|_*npcs
      - run drustcraftt_tab_complete.completions def:quest|info|_*quests
      - run drustcraftt_tab_complete.completions def:quest|create
      - run drustcraftt_tab_complete.completions def:quest|remove|_*quests
      - run drustcraftt_tab_complete.completions def:quest|find
      - run drustcraftt_tab_complete.completions def:quest|setowner|_*quests|_*players
      - run drustcraftt_tab_complete.completions def:quest|npcstart|_*quests|_*npcs
      - run drustcraftt_tab_complete.completions def:quest|npcend|_*quests|_*npcs
      - run drustcraftt_tab_complete.completions def:quest|endspeak|_*quests
      - run drustcraftt_tab_complete.completions def:quest|title|_*quests
      - run drustcraftt_tab_complete.completions def:quest|addreq|_*quests|_^quests
      - run drustcraftt_tab_complete.completions def:quest|remreq|_*quests|_^quests
      - run drustcraftt_tab_complete.completions def:quest|clrreq|_*quests|_^quests
      - run drustcraftt_tab_complete.completions def:quest|remobj|_*quests|_*int
      - run drustcraftt_tab_complete.completions def:quest|addrew|_*quests|_*materials|_*int
      - run drustcraftt_tab_complete.completions def:quest|editrew|_*quests|_*materials|_*int
      - run drustcraftt_tab_complete.completions def:quest|remrew|_*quests|_*materials
      - run drustcraftt_tab_complete.completions def:quest|reload
      - run drustcraftt_tab_complete.completions def:quest|save
      - run drustcraftt_tab_complete.completions def:quest|addgive|_*quests|_*materials|_*int
      - run drustcraftt_tab_complete.completions def:quest|editgive|_*quests|_*materials|_*int
      - run drustcraftt_tab_complete.completions def:quest|remgive|_*quests|_*materials

    - if <yaml.list.contains[drustcraft_quests]>:
      - ~yaml unload id:drustcraft_quests

    - if <server.has_file[/drustcraft_data/quests.yml]>:
      - yaml load:/drustcraft_data/quests.yml id:drustcraft_quests
    - else:
      - yaml create id:drustcraft_quests
      - yaml savefile:/drustcraft_data/quests.yml id:drustcraft_quests
    
    - if <yaml.list.contains[drustcraft_quest_types]>:
      - ~yaml unload id:drustcraft_quest_types
    - yaml create id:drustcraft_quest_types

    - run drustcraftt_quest.type_register def:block_break|drustcraftt_interactor_quest
    - run drustcraftt_tab_complete.completions def:quest|addobj|_*quests|block_break|_*materials|_*int|_*regions
    - run drustcraftt_tab_complete.completions def:quest|editobj|_*quests|_*int|block_break|_*materials|_*int|_*regions
          
    - run drustcraftt_quest.type_register def:block_place|drustcraftt_interactor_quest
    - run drustcraftt_tab_complete.completions def:quest|addobj|_*quests|block_place|_*materials|_*int|_*regions
    - run drustcraftt_tab_complete.completions def:quest|editobj|_*quests|_*int|block_place|_*materials|_*int|_*regions

    - run drustcraftt_quest.type_register def:give|drustcraftt_interactor_quest
    - run drustcraftt_tab_complete.completions def:quest|addobj|_*quests|give|_*materials|_*int
    - run drustcraftt_tab_complete.completions def:quest|editobj|_*quests|_*int|give|_*materials|_*int
    
    - run drustcraftt_quest.type_register def:enter_region|drustcraftt_interactor_quest
    - run drustcraftt_tab_complete.completions def:quest|addobj|_*quests|enter_region|_*regions
    - run drustcraftt_tab_complete.completions def:quest|editobj|_*quests|_*int|enter_region|_*regions

    - run drustcraftt_quest.type_register def:kill|drustcraftt_interactor_quest
    - run drustcraftt_tab_complete.completions def:quest|addobj|_*quests|kill|_*hostile|_*int|_*regions
    - run drustcraftt_tab_complete.completions def:quest|editobj|_*quests|_*int|kill|_*hostile|_*int|_*regions


    - define npc_list:<list[]>

    - foreach <yaml[drustcraft_quests].list_deep_keys[quests].filter[ends_with[.npc_start]]||<list[]>>:
      - define npc_list:|:<yaml[drustcraft_quests].read[quests.<[value]>]>
    - foreach <yaml[drustcraft_quests].list_deep_keys[quests].filter[ends_with[.npc_end]]||<list[]>>:
      - define npc_list:|:<yaml[drustcraft_quests].read[quests.<[value]>]>
    
    - wait 2t
    - waituntil <yaml.list.contains[drustcraft_npc]>

    - foreach <[npc_list].deduplicate>:
      - ~run drustcraftt_npc.interactor def:<[value]>|drustcraftt_interactor_quest
                        
  save:
    - if <yaml.list.contains[drustcraft_quests]>:
      - yaml savefile:/drustcraft_data/quests.yml id:drustcraft_quests


  create:
    - define title:<[1]||<empty>>
    - define quest_id:0
    
    - if <[title]> != <empty>:
      - define quest_id:<yaml[drustcraft_quests].list_keys[quests].highest.add[1]||1>
      - yaml id:drustcraft_quests set quests.<[quest_id]>.title:<[title]>
      - run drustcraftt_quest.save
    
    - determine <[quest_id]>
      
  remove:
    - define quest_id:<[1]||<empty>>
    
    - if <[quest_id]> != <empty>:
      - yaml id:drustcraft_quests set quests.<[quest_id]>:!
      - run drustcraftt_quest.save
        
  owner:
    - define quest_id:<[1]||<empty>>
    - define target_player:<[2]||<empty>>
    
    - if <[quest_id]> != <empty> && <[target_player].object_type> == Player:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.owner:<[target_player].uuid>
        - run drustcraftt_quest.save

  description:
    - define quest_id:<[1]||<empty>>
    - define description:<[2]||<empty>>
    
    - if <[quest_id]> != <empty> && <[description]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.description:<[description]>
        - run drustcraftt_quest.save

  title:
    - define quest_id:<[1]||<empty>>
    - define title:<[2]||<empty>>
    
    - if <[quest_id]> != <empty> && <[title]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.title:<[title]>
        - run drustcraftt_quest.save

  npc_start:
    - define quest_id:<[1]||<empty>>
    - define npc_id:<[2]||<empty>>
    
    - if <[quest_id]> != <empty> && <[npc_id]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.npc_start:<[npc_id]>
        - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_interactor_quest
        - run drustcraftt_quest.save

  npc_end:
    - define quest_id:<[1]||<empty>>
    - define npc_id:<[2]||<empty>>
    
    - if <[quest_id]> != <empty> && <[npc_id]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.npc_end:<[npc_id]>
        - run drustcraftt_npc.interactor def:<[npc_id]>|drustcraftt_interactor_quest
        - run drustcraftt_quest.save

  npc_end_speak:
    - define quest_id:<[1]||<empty>>
    - define speak:<[2]||!>
    
    - if <[quest_id]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.npc_end_speak:<[npc_id]>
        - run drustcraftt_quest.save

  add_requirement:
    - define quest_id:<[1]||<empty>>
    - define req_quest_id:<[2]||<empty>>
    
    - if <[quest_id]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.requirements].contains[<[req_quest_id]>]||false> == false:
          - yaml id:drustcraft_quests set quests.<[quest_id]>.requirements:->:<[req_quest_id]>
          - run drustcraftt_quest.save

  remove_requirement:
    - define quest_id:<[1]||<empty>>
    - define req_quest_id:<[2]||<empty>>
    
    - if <[quest_id]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.requirements:<-:<[req_quest_id]>
        - run drustcraftt_quest.save

  clear_requirements:
    - define quest_id:<[1]||<empty>>
    - define req_quest_id:<[2]||<empty>>
    
    - if <[quest_id]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.requirements:!
        - run drustcraftt_quest.save

  repeatable:
    - define quest_id:<[1]||<empty>>
    - define repeatable:<[2]||<empty>>
    
    - if <[quest_id]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.repeatable:<[repeatable]>
        - run drustcraftt_quest.save

  add_objective:
    - define quest_id:<[1]||<empty>>
    - define type:<[2]||<empty>>
    - define data:<[3]||<empty>>
    - define quantity:<[4]||<empty>>
    - define region:<[5]||<empty>>
      
    - if <[quest_id]> != <empty> && <[type]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - foreach <yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>:
          - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.type]||<empty>> == <[type]> && <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.data]||<empty>> == <[data]> && <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.region]||<empty>> == <[region]>:
            - if <[quantity]> != <empty>:
              - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[value]>.quantity:+:<[quantity]>
              - run drustcraftt_quest.save
              - determine <[value]>
        
      - define objective_id:<yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives].highest.add[1]||1>
      - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.type:<[type]>
      - if <[quantity]> != <empty>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.quantity:<[quantity]>
      - if <[data]> != <empty>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.data:<[data]>
      - if <[region]> != <empty>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.region:<[region]>
      
      - run drustcraftt_quest.save
      - determine <[objective_id]>

    - determine 0

  remove_objective:
    - define quest_id:<[1]||<empty>>
    - define objective_id:<[2]||<empty>>
      
    - if <[quest_id]> != <empty> && <[objective_id]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>:!      
        - run drustcraftt_quest.save

  update_objective:
    - define quest_id:<[1]||<empty>>
    - define objective_id:<[2]||<empty>>
    - define type:<[3]||<empty>>
    - define data:<[4]||<empty>>
    - define quantity:<[5]||<empty>>
    - define region:<[6]||<empty>>
      
    - if <[quest_id]> != <empty> && <[type]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - define exists:false
        - define match:0
    
    - if <yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives].contains[<[objective_id]>]>:
      - define exists:true
    
    - foreach <yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives].exclude[<[objective_id]>]||<list[]>>:
      - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.type]||<empty>> == <[type]> && <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.data]||<empty>> == <[data]> && <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.region]||<empty>> == <[region]>:
        - define match:<[value]>
        - foreach stop
    
    - if <[match]> > 0:
      - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>:!
    - if <[quantity]> != <empty>:
      - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[match]>.quantity:+:<[quantity]>
    - else:
      - if <[exists]> == false:
        - define objective_id:<yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives].highest.add[1]||1>
    
    - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.type:<[type]>
    - if <[quantity]> != <empty>:
      - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.quantity:<[quantity]>
    - else:
      - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.quantity:!
    - if <[data]> != <empty>:
      - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.data:<[data]>
    - else:
      - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.data:!
    - if <[region]> != <empty>:
      - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.region:<[region]>
    - else:
      - yaml id:drustcraft_quests set quests.<[quest_id]>.objectives.<[objective_id]>.region:!
    
    - run drustcraftt_quest.save

  add_reward:
    - define quest_id:<[1]||<empty>>
    - define reward_item:<[2]||<empty>>
    - define reward_quantity:<[3]||1>
      
    - if <[quest_id]> != <empty> && <[reward_item]> != <empty> && <[reward_quantity]> > 0:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.rewards].contains[<[reward_item]>]||false>:
          - yaml id:drustcraft_quests set quests.<[quest_id]>.rewards.<[reward_item]>:+:<[reward_quantity]>
        - else:
          - yaml id:drustcraft_quests set quests.<[quest_id]>.rewards.<[reward_item]>:<[reward_quantity]>
      
        - run drustcraftt_quest.save

  remove_reward:
    - define quest_id:<[1]||<empty>>
    - define reward_item:<[2]||<empty>>
      
    - if <[quest_id]> != <empty> && <[reward_item]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.rewards.<[reward_item]>:!      
        - run drustcraftt_quest.save

  update_reward:
    - define quest_id:<[1]||<empty>>
    - define reward_item:<[2]||<empty>>
    - define reward_quantity:<[3]||1>
      
    - if <[quest_id]> != <empty> && <[reward_item]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - if <[reward_quantity]> > 0:
          - yaml id:drustcraft_quests set quests.<[quest_id]>.rewards.<[reward_item]>:<[reward_quantity]>
        - else:
          - yaml id:drustcraft_quests set quests.<[quest_id]>.rewards.<[reward_item]>:!
      
        - run drustcraftt_quest.save
  
  add_give:
    - define quest_id:<[1]||<empty>>
    - define give_item:<[2]||<empty>>
    - define give_quantity:<[3]||1>
      
    - if <[quest_id]> != <empty> && <[reward_item]> != <empty> && <[give_quantity]> > 0:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.gives].contains[<[reward_item]>]||false>:
          - yaml id:drustcraft_quests set quests.<[quest_id]>.gives.<[give_item]>:+:<[give_quantity]>
        - else:
          - yaml id:drustcraft_quests set quests.<[quest_id]>.gives.<[give_item]>:<[give_quantity]>
      
        - run drustcraftt_quest.save

  remove_give:
    - define quest_id:<[1]||<empty>>
    - define give_item:<[2]||<empty>>
      
    - if <[quest_id]> != <empty> && <[reward_item]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set quests.<[quest_id]>.gives.<[give_item]>:!      
        - run drustcraftt_quest.save

  update_give:
    - define quest_id:<[1]||<empty>>
    - define give_item:<[2]||<empty>>
    - define give_quantity:<[3]||1>
      
    - if <[quest_id]> != <empty> && <[give_item]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
        - if <[give_quantity]> > 0:
          - yaml id:drustcraft_quests set quests.<[quest_id]>.gives.<[give_item]>:<[give_quantity]>
        - else:
          - yaml id:drustcraft_quests set quests.<[quest_id]>.gives.<[give_item]>:!
      
        - run drustcraftt_quest.save

  start:
    - define target_player:<[1]||<empty>>
    - define quest_id:<[2]||<empty>>
    - if <[target_player]> != <empty> && <[quest_id]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[player.<player.uuid>.quests.active].contains[<[quest_id]>]||false> == false:
        - define objective_list:<yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>
        
        - if <[objective_list].size> <= 0:
          - run drustcraftt_quest.done def:<[target_player]>|<[quest_id]>
        - else:
          - foreach <[objective_list]>:
            - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.active.<[quest_id]>.objectives.<[value]>:0
        
        - narrate '<&e>Quest accepted: <yaml[drustcraft_quests].read[quests.<[quest_id]>.title]||<empty>>'
        
        - define give_map:<yaml[drustcraft_quests].read[quests.<[quest_id]>.gives]||<map[]>>
        - foreach <[give_map]>:
          - give <[target_player]> <[key]> quantity:<[value]>
        
        - run drustcraftt_quest.update_markers def:<[target_player]>|true
        - run drustcraftt_quest.save
    
  done:
    - define target_player:<[1]||<empty>>
    - define quest_id:<[2]||<empty>>
    - if <[target_player]> != <empty> && <[quest_id]> != <empty>:
      - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.active.<[quest_id]>:!
      - if <yaml[drustcraft_quests].read[player.<[target_player].uuid>.quests.done].contains[<[quest_id]>]||false> == false:
        - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.done:->:<[quest_id]>
      
      - run drustcraftt_quest.update_markers def:<[target_player]>|true
      - run drustcraftt_quest.save
    
  completed:
    - define target_player:<[1]||<empty>>
    - define quest_id:<[2]||<empty>>
    - if <[target_player]> != <empty> && <[quest_id]> != <empty>:
      - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.done:<-:<[quest_id]>
      - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.active.<[quest_id]>:!
      
      - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.repeatable]||false> == false:
        - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.completed:->:<[quest_id]>
      
      - narrate '<&e>Quest completed: <yaml[drustcraft_quests].read[quests.<[quest_id]>.title]>'
  
      - foreach <yaml[drustcraft_quests].read[quests.<[quest_id]>.rewards]||<map[]>>:
        - give <[key]> quantity:<[value]> player:<[target_player]>
        - narrate '<&e>You received <material[<[key]>].translated_name||<[key]>> x <[value]>'

    - define end_speak:<yaml[drustcraft_quests].read[quests.<[quest_id]>.npc_end_speak]||<empty>>
    - if <[end_speak]> != <empty>:
      - define target_npc:<npc[<yaml[drustcraft_quests].read[quests.<[quest_id]>.npc_start]||0>]||<empty>>
      - narrate <proc[drustcraftp.format_chat].context[<npc>|<[end_speak]>]>
    
    - run drustcraftt_quest.update_markers def:<[target_player]>|true
    - run drustcraftt_quest.save
  
  abandon:
    - define target_player:<[1]||<empty>>
    - define quest_id:<[2]||<empty>>
    - if <[target_player]> != <empty> && <[quest_id]> != <empty>:
      - define done:false
      - if <yaml[drustcraft_quests].list_keys[player.<[target_player].uuid>.quests.active].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.active.<[quest_id]>:!
        - define done:true
      - else if <yaml[drustcraft_quests].read[player.<[target_player].uuid>.quests.done].contains[<[quest_id]>]||false>:
        - yaml id:drustcraft_quests set player.<[target_player].uuid>.quests.done:<-:<[quest_id]>
        - define done:true
        
      - if <[done]>:
        - narrate '<&e>Quest abandoned: <yaml[drustcraft_quests].read[quests.<[quest_id]>.title]||<empty>>'
      
      - run drustcraftt_quest.update_markers def:<[target_player]>|true
      - run drustcraftt_quest.save
  
  objective_event:
    - define event_player:<[1]||<empty>>
    - define event_type:<[2]||<empty>>
    - define event_data:<[3]||<empty>>
    - define event_location:<[4]||<empty>>
    - define changes:false
    
    - if <[event_player].object_type||<empty>> == PLAYER:
      - foreach <yaml[drustcraft_quests].list_keys[player.<[event_player].uuid>.quests.active]||<list[]>>:
        - define quest_id:<[value]>
        - define objective_list:<yaml[drustcraft_quests].list_keys[player.<[event_player].uuid>.quests.active.<[quest_id]>.objectives]||<list[]>>
  
        - foreach <[objective_list]>:
          - define objective_id:<[value]>
          - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.type]> == <[event_type]>:
            - define objective_data:<yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.data]||<empty>>
            - if <[objective_data]> == <empty> || <[objective_data]> == * || <[objective_data]> == <[event_data]>:
              - define objective_region:<yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.region]||<empty>>
              - if <[objective_region]> == <empty> || <[event_location].regions.parse[id].contains[<[objective_region]>]||false>:
                - define objective_value:<yaml[drustcraft_quests].read[player.<[event_player].uuid>.quests.active.<[quest_id]>.objectives.<[objective_id]>]||0>
                - define objective_value:++
                - define changes:true
  
                - if <[objective_value]> >= <yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.quantity]||0>:
                  - ~yaml id:drustcraft_quests set player.<[event_player].uuid>.quests.active.<[quest_id]>.objectives.<[objective_id]>:!
                - else:
                  - ~yaml id:drustcraft_quests set player.<[event_player].uuid>.quests.active.<[quest_id]>.objectives.<[objective_id]>:<[objective_value]>
  
        - if <yaml[drustcraft_quests].list_keys[player.<[event_player].uuid>.quests.active.<[quest_id]>.objectives].size||0> <= 0:
          - run drustcraftt_quest.done def:<[event_player]>|<[quest_id]>
      
      - if <[changes]>:
        - run drustcraftt_quest.update_markers def:<[event_player]>|true
        - run drustcraftt_quest.inventory_update def:<[event_player]>
      
      - determine <[changes]>
    - determine false
    
  update_markers:
    - define target_player:<[1]||<empty>>
    - define force:<[2]||false>

    - if <[target_player].object_type||<empty>> == PLAYER:
      - if <[force]> == true || <util.time_now.is_after[<[target_player].flag[drustcraft_quest_update_makers]||<util.time_now.sub[5s]>>]>:
        - flag <[target_player]> drustcraft_quest_update_makers:<util.time_now.add[5s]>
  
        - foreach <[target_player].fake_entities>:
          - fakespawn <[value]> cancel
  
        - define npc_list:<[target_player].location.find.npcs.within[30]>
        
        - foreach <[npc_list]>:
          - define target_npc:<[value]>
          - define title:<empty>
  
          - define quest_list:<proc[drustcraftp_quest.npc.list_available].context[<[target_npc]>|<[target_player]>]||<list[]>>
          - if <[quest_list].as_list.size||0> > 0:
            - define 'title:<&e>  ?  '
            
            - foreach <[quest_list]>:
              - if <yaml[drustcraft_quests].read[quests.<[value]>.repeatable]||false> == true:
                - define 'title:<&b>  ?  '
            
          - if <proc[drustcraftp_quest.npc.list_done].context[<[target_npc]>|<[target_player]>].as_list.size||0> > 0:
            - define 'title:  !  '
              
          - if <[title]> != <empty>:
            - define height:0.1
            - if <[target_player].name.starts_with[*]>:
              - define height:2.1
            
            - fakespawn 'armor_stand[visible=false;custom_name=<&e><[title]>;custom_name_visibility=true;gravity=false]' <[target_npc].location.up[<[height]>]> save:newhologram d:10m players:<[target_player]>
  
  inventory_update:
    - define target_player:<[1]||<empty>>
    
    - if <[target_player].object_type> == Player:
      - foreach <[target_player].inventory.map_slots>:
        - define 'book_title:<[value].book_title.strip_color||<empty>>'
        - if '<[book_title].starts_with[Quest<&co> ]>':
          - define 'quest_title:<[book_title].after[Quest<&co> ]>'
          - define quest_id:<proc[drustcraftp_quest.title_to_id].context[<[quest_title]>]>
          
          - if <[quest_id]> != 0:
            - define questbook:<proc[drustcraftp_quest.questbook].context[<[quest_id]>|<[target_player]>]>
            - if <[questbook]> != <empty>:
              - inventory set d:<[target_player].inventory> slot:<[key]> o:<[questbook]>
          
          #- define quest_id:-1

          #- foreach <yaml[drustcraft_quests].list_keys[]>:
          #  - if <yaml[drustcraft_quests].read[<[value]>.title]> == <[quest_title]>:
          #    - define quest_id:<[value]>
          #    - foreach stop
          
          #- if <[quest_id]> != -1:
          #  - define lore:<&nl><yaml[drustcraft_quests].read[<[quest_id]>.description]>

          #  - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.status]> != done:
          #    - inventory adjust d:<player.inventory> slot:<[key]> lore:<[lore].split_lines[40]>
          #  - else:
          #    - define 'lore:<[lore]> <&e>[Completed]'
          #    - inventory adjust d:<player.inventory> slot:<[key]> lore:<[lore].split_lines[40]>
  
  type_register:
    - define type:<[1]||<empty>>
    - define task:<[2]||<empty>>
    
    - if <[type]> != <empty> && <[task]> != <empty>:
      - yaml id:drustcraft_quest_types set types.<[type]>:<[task]>


drustcraftp_quest:
  type: procedure
  debug: false
  script:
    - determine <empty>
    
  list:
    - determine <yaml[drustcraft_quests].list_keys[quests]||<list[]>>
  
  info:
    - define quest_id:<[1]||<empty>>
    - define quest_info:<map[]>
    
    - foreach <yaml[drustcraft_quests].list_deep_keys[quests.<[quest_id]>]||<list[]>>:
      - define quest_info:<[quest_info].with[<[value]>].as[<yaml[drustcraft_quests].read[quests.<[quest_id]>.<[value]>]>]>
    
    - determine <[quest_info]>
  
  is_owner:
    - define quest_id:<[1]||<empty>>
    - define target_player:<[2]||<empty>>
    
    - if <[target_player].object_type> == Player:
      - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.owner]||<empty>> == <[target_player].uuid>:
        - determine true
    
    - determine false
  
  npc:
    list_available:
      - define target_npc:<[1]||<empty>>
      - define target_player:<[2]||<empty>>
      - define quest_list:<list[]>

      - if <[target_npc].id||-1> > -1:
        - foreach <yaml[drustcraft_quests].list_keys[quests]>:
          - define quest_id:<[value]>
          - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.npc_start]||<empty>> == <[target_npc].id>:
            - if <yaml[drustcraft_quests].list_keys[player.<[target_player].uuid>.quests.active].contains[<[quest_id]>]||false> == false && <yaml[drustcraft_quests].read[player.<[target_player].uuid>.quests.done].contains[<[quest_id]>]||false> == false && <yaml[drustcraft_quests].read[player.<[target_player].uuid>.quests.completed].contains[<[quest_id]>]||false> == false:
              
              - define available:true
              - foreach <yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>:
                - define objective_type:<yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.type]||<empty>>
                - if <[objective_type]> != <empty> && <yaml[drustcraft_quest_types].list_keys[types].contains[<[objective_type]>]||false> == false:
                  - define available:false
              
              - foreach <yaml[drustcraft_quests].read[quests.<[quest_id]>.requirements]||<list[]>>:
                - if <yaml[drustcraft_quests].read[player.<[target_player].uuid>.quests.completed].contains[<[value]>]||false> == false:
                  - define available:false

              - if <[available]>:
                - define quest_list:->:<[quest_id]>
      
      - determine <[quest_list]>
  
    list_done:
      - define target_npc:<[1]||<empty>>
      - define target_player:<[2]||<empty>>
      - define quest_list:<list[]>

      - if <[target_npc].id||-1> > -1:
        - foreach <yaml[drustcraft_quests].list_keys[quests]>:
          - define quest_id:<[value]>
          - if <yaml[drustcraft_quests].read[quests.<[quest_id]>.npc_end]||<empty>> == <[target_npc].id> && <yaml[drustcraft_quests].read[player.<[target_player].uuid>.quests.done].contains[<[quest_id]>]||false> == true:
            - define quest_list:->:<[quest_id]>
      
      - determine <[quest_list]>
  
  state:
    - define quest_id:<[1]||<empty>>
    - define target_player:<[2]||<empty>>

    - if <[target_player]> != <empty> && <[quest_id]> != <empty>:
      - if <yaml[drustcraft_quests].list_keys[player.<[target_player].uuid>.quests.active].contains[<[quest_id]>]||false>:
        - determine active
      - if <yaml[drustcraft_quests].read[player.<[target_player].uuid>.quests.done].contains[<[quest_id]>]||false>:
        - determine done
      - if <yaml[drustcraft_quests].list_keys[player.<[target_player].uuid>.quests.completed].contains[<[quest_id]>]||false>:
        - determine completed

    - determine available
  
  player_inventory:
    - define target_player:<[1]||<empty>>
    - define quests:<map[]>

    - foreach <[target_player].inventory.map_slots>:
      - define 'book_title:<[value].book_title.strip_color||<empty>>'
      - if '<[book_title].starts_with[Quest<&co> ]>':
        - define 'quest_title:<[book_title].after[Quest<&co> ]>'

        - foreach <yaml[drustcraft_quests].list_keys[quests]>:
          - if <yaml[drustcraft_quests].read[quests.<[value]>.title]||<empty>> == <[quest_title]>:
            - define quests:<[quests].with[<[value]>].as[<[key]>]>
            - foreach stop
              
    - determine <[quests]>
  
  title_to_id:
    - define quest_title:<[1]||<empty>>
    
    - foreach <yaml[drustcraft_quests].list_keys[quests]||<list[]>>:
      - if <yaml[drustcraft_quests].read[quests.<[value]>.title]||<empty>> == <[quest_title]>:
        - determine <[value]>
    
    - determine 0
  
  questbook:
    - define quest_id:<[1]||<empty>>
    - define target_player:<[2]||<empty>>
    - define force_new:<[3]||false>
    - define questbook:<empty>
    
    - if <[quest_id]> != <empty> && <[target_player].object_type> == Player && <yaml[drustcraft_quests].list_keys[quests].contains[<[quest_id]>]||false>:
      - define npc_name:Unknown
      - define npc_id:<yaml[drustcraft_quests].read[quests.<[quest_id]>.npc_start]||0>
      - if <server.npcs.parse[id].contains[<[npc_id]>]||false>:
        - define npc_name:<npc[<[npc_id]>].name.strip_color>
      
      - define 'book_title:<&2>Quest<&co> <yaml[drustcraft_quests].read[quests.<[quest_id]>.title]>'
      - define book_author:<&e><[npc_name]>

      - define gives:<element[]>
#      - define gives:<list[]>
#      - define give_map:<yaml[drustcraft_quests].read[quests.<[quest_id]>.gives]||<map[]>>
#       - foreach <[give_map]>:
#         - define 'gives:|: - <material[<[key]>].translated_name||<[key]>> x <[value]>'
# 
#       - if <[gives].size> > 0:
#         - define 'gives:<&nl>You will receive:<&nl><[gives].separated_by[<&nl>]>'
#       - else:
#         - define gives:<element[]>
        
      - define lore:<&nl><yaml[drustcraft_quests].read[quests.<[quest_id]>.description].split_lines[40]||<empty>><[gives]>
            
      - define objectives:<empty>
      - foreach <yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>:
        - define type:<yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.type]||<empty>>
        - define data:<yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.data]||<empty>>
        - define quantity:<yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.quantity]||1>
        - define region:<yaml[drustcraft_quests].read[quests.<[quest_id]>.objectives.<[value]>.region]||<empty>>
        
        - define 'item:<[type]> <[data]> <[quantity]> <[region]>'
        - define task:<yaml[drustcraft_quest_types].read[types.<[type]>]||<empty>>
        - if <[task]> != <empty>:
          - define current_default:<[quantity]>
          - if <[force_new]>:
            - define current_default:0
            
          - define current:<yaml[drustcraft_quests].read[player.<[target_player].uuid>.quests.active.<[quest_id]>.objectives.<[value]>]||<[current_default]>>
          
          - ~run <[task]> def:<empty>|<[target_player]>|text_status|<[type]>|<[data]>|<[quantity]>|<[region]>|<[current]>|<[quest_id]> save:result
          - define item:<entry[result].created_queue.determination.get[1]||<[item]>>
        
        - define 'objectives:<[objectives]><&0>- <[item]><&nl>'
      
      - define npc_start:<yaml[drustcraft_quests].read[quests.<[quest_id]>.npc_start]||<empty>>
      - define npc_end:<yaml[drustcraft_quests].read[quests.<[quest_id]>.npc_end]||<empty>>
      - if <[npc_end]> != <empty>:
        - if <[npc_start]> != <[npc_end]>:
          - define 'objectives:<[objectives]>- Find <npc[<[npc_end]>].name.strip_color||Unknown><&nl>'
        
      
      - if <[objectives]> == <empty>:
        - define 'objectives:- No objectives'

      - define rewards:<empty>
      - foreach <yaml[drustcraft_quests].list_keys[quests.<[quest_id]>.rewards]||<list[]>>:
        - define 'rewards:<[rewards]>- <material[<[value]>].translated_name||<[value]>> x <yaml[drustcraft_quests].read[quests.<[quest_id]>.rewards.<[value]>]><&nl>'
      
      - if <[rewards]> == <empty>:
        - define 'rewards:- No rewards'
      
      - define 'book_pages:<list_single[<&2><bold><yaml[drustcraft_quests].read[quests.<[quest_id]>.title]||<empty>><p><&0><yaml[drustcraft_quests].read[quests.<[quest_id]>.description]||<empty>>|<&0><bold>Objectives<p><&0><[objectives]>|<&0><bold>Rewards<p><&0><[rewards]>]>'
      
      #<item[drustcraft_questbook[book=map@title/<&4>Quest: My quest|author/nomadjimbob|pages/li@el@page 1&amppipeel@page 2]]>'
      - define book_map:<map.with[title].as[<[book_title]>].with[author].as[<[book_author]>].with[pages].as[<[book_pages]>]>
      - define questbook:<item[drustcraft_questbook[book=<[book_map]>;lore=<[lore]>]]>
      
    - determine <[questbook]>


drustcraftc_quest:
  type: command
  debug: false
  name: quest
  description: Creates, Edits and Removes quests
  usage: /quest <&lt>create|remove|info|list<&gt>
  permission: drustcraft.quest
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:quest
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - choose <context.args.get[1]||<empty>>:
      - case reload:
        - ~run drustcraftt_quest.load
        - narrate '<&e>Quest data loaded'
      
      - case save:
        - ~run drustcraftt_quest.save
        - narrate '<&e>Quest data saved'
        
      - case list:
        - define page_no:<context.args.get[2]||1>
        - define quest_ids:<proc[drustcraftp_quest.list]>
        - define quest_map:<map[]>
        
        - foreach <[quest_ids]>:
          - define quest_id:<[value]>
          - define 'quest_title:<proc[drustcraftp_quest.info].context[<[quest_id]>].as_map.get[title]||<empty>> <&e>(ID: <[quest_id]>)'
          - define quest_map:<[quest_map].with[<[quest_id]>].as[<[quest_title]>]>
        
        - run drustcraftt_chat_paginate 'def:<list[Quests|<[page_no]>].include_single[<[quest_map]>].include[quest list|quest info]>'

      - case npclist:
        - if <player.selected_npc||<empty>> != <empty>:        
          - define page_no:<context.args.get[2]||1>
          - define quest_ids:<proc[drustcraftp_quest.list]>
          - define quest_map:<map[]>
          
          - foreach <[quest_ids]>:
            - define quest_id:<[value]>
            - define quest_info:<proc[drustcraftp_quest.info].context[<[quest_id]>]>
            - if <[quest_info].get[npc_start]||0> == <player.selected_npc.id> || <[quest_info].get[npc_end]||0> == <player.selected_npc.id>:
              - define 'quest_title:<[quest_info].get[title]||<empty>> <&e>(ID: <[quest_id]>)'
              - define quest_map:<[quest_map].with[<[quest_id]>].as[<[quest_title]>]>
          
          - run drustcraftt_chat_paginate 'def:<list[Quests for <player.selected_npc.name> (ID: <player.selected_npc.id>)|<[page_no]>].include_single[<[quest_map]>].include[quest list|quest info]>'
        - else:
          - narrate '<&c>No NPC is selected'

      - case info:
        - define quest_id:<context.args.get[2]||<empty>>
        # todo: check that chat_gui is installed
        - run drustcraftt_chat_gui.title 'def:Quest: ID <[quest_id]>'
        
        - define quest_map:<proc[drustcraftp_quest.info].context[<[quest_id]>]||<map[]>>
        
        - define 'row:<&9>Title: <&6><[quest_map].get[title]||<&c>(none)> <element[<&7><&lb>Edit<&rb>].on_click[/quest title <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
        - narrate <[row]>
        
        - define 'row:<&9>Description: <&6><[quest_map].get[description]||<&c>(none)> <element[<&7><&lb>Edit<&rb>].on_click[/quest description <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
        - narrate <[row]>
        
        - define owner:<[quest_map].get[owner]||<empty>>
        - define owner:<player[<[owner]>].name||<&c>(none)>
        - define 'row:<&9>Owner: <&6><[owner]> <element[<&7><&lb>Edit<&rb>].on_click[/quest setowner <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
        - narrate <[row]>

        - define title:<[quest_map].get[requirements]||<empty>>
        - if <[title]> != <empty>:
          - foreach <[title]>:
            - define req_quest_map:<proc[drustcraftp_quest.info].context[<[value]>]>
            - define 'title:<[title].overwrite[<&e><[req_quest_map].get[title]||<empty>> (<[value]>)].at[<[loop_index]>]>'
          
          - define 'title:<[title].separated_by[, ]>'
        - else:
          - define title:<&c>(none)
        - define 'txt_events:<element[<&a><&lb>Add<&rb>].on_click[/quest addreq <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to add item]> '
        - define 'txt_events:<[txt_events]><element[<&c><&lb>Rem<&rb>].on_click[/quest remreq <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to remove item]> '
        - define 'txt_events:<[txt_events]><element[<&c><&lb>Clr<&rb>].on_click[/quest clrreq <[quest_id]>].type[SUGGEST_COMMAND].on_hover[Click to clear items]>'
        - define 'row:<&9>Requires: <&6><[title]> <[txt_events]>'
        - narrate <[row]>
        
        - define title:<[quest_map].get[repeatable]||false>
        - define 'row:<&9>Repeatable: <&6><[title]> <element[<&7><&lb>Edit<&rb>].on_click[/quest repeatable <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
        - narrate <[row]>

        - define title:<[quest_map].get[npc_start]||<empty>>
        - if <[title]> != <empty>:
          - define 'title:<npc[<[title]>].name||<&c>(unknown)> <&e>(ID: <[title]>)'
        - else:
          - define title:<&c>(none)
        - define 'row:<&9>NPC Start: <&6><[title]> <element[<&7><&lb>Edit<&rb>].on_click[/quest npcstart <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
        - narrate <[row]>
        
        - define title:<[quest_map].get[npc_end]||<empty>>
        - if <[title]> != <empty>:
          - define 'title:<npc[<[title]>].name||<&c>(unknown)> <&e>(ID: <[title]>)'
        - else:
          - define title:<&c>(none)
        - define 'row:<&9>NPC End: <&6><[title]> <element[<&7><&lb>Edit<&rb>].on_click[/quest npcend <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
        - narrate <[row]>

        - define 'row:<&9>NPC End Speak: <&6><[quest_map].get[npc_end_speak]||<&c>(none)> <element[<&7><&lb>Edit<&rb>].on_click[/quest npcendspeak <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to edit]>'
        - narrate <[row]>

        - define pretitle:<empty>
        - define title:<[quest_map].get[gives]||<empty>>
        - if <[title]> != <empty>:
          - define 'give_list:<list[ ]>'
          - foreach <[title]>:
            - define 'txt_events:<element[<&7><&lb>Edit<&rb>].on_click[/quest editgiv <[quest_id]> <[key]> <[value]>].type[SUGGEST_COMMAND].on_hover[Click to edit item]> '
            - define 'txt_events:<[txt_events]><element[<&c><&lb>Rem<&rb>].on_click[/quest remgive <[quest_id]> <[key]> ].type[SUGGEST_COMMAND].on_hover[Click to remove item]> '
            - define 'give_list:->:  <&e><[key]> <&6><[value]> <[txt_events]>'
          
          - define 'title:<[give_list].separated_by[<&nl>]>'
        - else:
          - define 'pretitle:<&c>(none) '
        - define 'txt_events:<element[<&a><&lb>Add<&rb>].on_click[/quest addgive <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to add item]> '
        - define 'row:<&9>Gives: <[pretitle]><[txt_events]> <[title]>'
        - narrate <[row]>


        - define pretitle:<empty>
        - define title:<[quest_map].get[objectives]||<empty>>
        - if <[title]> != <empty>:
          - define 'objective_list:<list[ ]>'
          - define objective_ids:<[title].keys.numerical>
          - foreach <[objective_ids]>:
            - define 'objective_data: <[title].get[<[value]>].get[data]||<empty>>'
            - define 'objective_quantity: <[title].get[<[value]>].get[quantity]||<empty>>'
            - define 'objective_region: <[title].get[<[value]>].get[region]||<empty>>'

            - define 'txt_events:<element[<&7><&lb>Edit<&rb>].on_click[/quest editobj <[quest_id]> <[value]> <[title].get[<[value]>].get[type]><[objective_data]><[objective_quantity]><[objective_region]>].type[SUGGEST_COMMAND].on_hover[Click to edit item]> '
            - define 'txt_events:<[txt_events]><element[<&c><&lb>Rem<&rb>].on_click[/quest remobj <[quest_id]> <[value]> ].type[SUGGEST_COMMAND].on_hover[Click to remove item]> '
            - define 'objective_list:->:  <&f><[value]>: <&e><[title].get[<[value]>].get[type]><&f><[objective_data]><&6><[objective_quantity]><&3><[objective_region]> <[txt_events]>'
          
          - define 'title:<[objective_list].separated_by[<&nl>]>'
        - else:
          - define 'pretitle:<&c>(none) '
        - define 'txt_events:<element[<&a><&lb>Add<&rb>].on_click[/quest addobj <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to add item]> '
        - define 'row:<&9>Objectives: <[pretitle]><[txt_events]> <[title]>'
        - narrate <[row]>

        - define pretitle:<empty>
        - define title:<[quest_map].get[rewards]||<empty>>
        - if <[title]> != <empty>:
          - define 'reward_list:<list[ ]>'
          - foreach <[title]>:
            - define 'txt_events:<element[<&7><&lb>Edit<&rb>].on_click[/quest editrew <[quest_id]> <[key]> <[value]>].type[SUGGEST_COMMAND].on_hover[Click to edit item]> '
            - define 'txt_events:<[txt_events]><element[<&c><&lb>Rem<&rb>].on_click[/quest remrew <[quest_id]> <[key]> ].type[SUGGEST_COMMAND].on_hover[Click to remove item]> '
            - define 'reward_list:->:  <&e><[key]> <&6><[value]> <[txt_events]>'
          
          - define 'title:<[reward_list].separated_by[<&nl>]>'
        - else:
          - define 'pretitle:<&c>(none) '
        - define 'txt_events:<element[<&a><&lb>Add<&rb>].on_click[/quest addrew <[quest_id]> ].type[SUGGEST_COMMAND].on_hover[Click to add item]> '
        - define 'row:<&9>Rewards: <[pretitle]><[txt_events]> <[title]>'
        - narrate <[row]>

      - case find:
        - define query:<context.args.get[2]||<empty>>
        - define page_no:1
        
        - if <context.args.size> > 2 && <context.args.last.is_integer>:
          - define page_no:<context.args.last>
        
        - if <[query]> != <empty>:
          - define quest_ids:<proc[drustcraftp_quest.list]>
          - define quest_map:<map[]>
          
          - foreach <[quest_ids]>:
            - define quest_id:<[value]>
            - define 'quest_title:<proc[drustcraftp_quest.info].context[<[quest_id]>].get[title]||<empty>> <&e>(ID: <[quest_id]>)'
            - if <[quest_title].advanced_matches_text[<[query]>]>:
              - define quest_map:<[quest_map].with[<[quest_id]>].as[<[quest_title]>]>
          
          - run drustcraftt_chat_paginate 'def:<list[Quests|<[page_no]>].include_single[<[quest_map]>].include[quest list|quest info]>'
        - else:
          - narrate '<&c>No query text was entered'

      - case create:
        - define title:<context.args.remove[1].space_separated||<empty>>
        - if <[title]> != <empty>:
          - ~run drustcraftt_quest.create def:<[title]> save:quest_result
          - define quest_id:<entry[quest_result].created_queue.determination.get[1]||0>
          - if <[quest_id]> != 0:
            - if <context.server||false> == false:
              - run drustcraftt_quest.owner def:<[quest_id]>|<player>
            
            - narrate '<&e>Quest <&sq><[title]><&sq> (ID: <[quest_id]>)'
          - else:
            - narrate '<&c>There was an unknown error creating the quest'
        - else:
          - narrate '<&c>No quest title was entered'
      
      - case remove:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
              - run drustcraftt_quest.remove def:<[quest_id]>
              - narrate '<&e>The Quest ID <&sq><[quest_id]><&sq> has been removed'
            - else:
              - narrate '<&c>You do not have permission to remove that quest'
          - else:
            - narrate '<&c>The Quest ID <&sq><[quest_id]><&sq> does not exist'
        - else:
          - narrate '<&c>No Quest ID was entered to remove'
      
      - case title:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
              - if <context.args.size> > 2:
                - define quest_title:<context.args.remove[1|2].space_separated>
                - if <[quest_title].length> <= 20:
                  - run drustcraftt_quest.title def:<[quest_id]>|<[quest_title]>
                  - narrate '<&e>The title for Quest ID <&sq><[quest_id]><&sq> was changed'
                - else:
                  - narrate '<&c>The quest title must be 20 or less characters'
              - else:
                - narrate '<&c>No Quest title was entered'
            - else:
              - narrate '<&c>You do not have permission to edit that quest'
          - else:
            - narrate '<&c>The Quest ID <&sq><[quest_id]><&sq> does not exist'
        - else:
          - narrate '<&c>No Quest ID was entered to remove'
      
      - case description:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
              - if <context.args.size> > 2:
                - define quest_description:<context.args.remove[1|2].space_separated>
                - run drustcraftt_quest.description def:<[quest_id]>|<[quest_description]>
                - narrate '<&e>The description for Quest ID <&sq><[quest_id]><&sq> was changed'
              - else:
                - narrate '<&c>No Quest description was entered'
            - else:
              - narrate '<&c>You do not have permission to edit that quest'
          - else:
            - narrate '<&c>The Quest ID <&sq><[quest_id]><&sq> does not exist'
        - else:
          - narrate '<&c>No Quest ID was entered to remove'

      - case setowner:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
              - define target_player:<context.args.get[3]||<empty>>
              - if <[target_player]> != <empty>:
                - define found_player:<server.match_offline_player[<[target_player]>]>
                - if <[found_player].object_type> == Player && <[found_player].name> == <[target_player]>:
                  - run drustcraftt_quest.owner def:<[quest_id]>|<[found_player]>
                  - narrate '<&e>The owner for Quest ID <&sq><[quest_id]><&sq> was changed'
                - else:
                  - narrate '<&c>The player <&sq><[target_player]><&sq> was not found'
              - else:
                - narrate '<&c>No player was entered'
            - else:
              - narrate '<&c>You do not have permission to edit that quest'
          - else:
            - narrate '<&c>The Quest ID <&sq><[quest_id]><&sq> does not exist'
        - else:
          - narrate '<&c>No Quest ID was entered to remove'

      - case npcstart:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define npc_id:<context.args.get[3]||<empty>>
            - if <[npc_id]> != <empty>:
              - if <server.npcs.parse[id].contains[<[npc_id]>]>:
                - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                  - run drustcraftt_quest.npc_start def:<[quest_id]>|<[npc_id]>
                  - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> has been updated'
                - else:
                  - narrate '<&e>You do not have permission to change this quest'
              - else:
                - narrate '<&e>NPC ID <&sq><[npc_id]><&sq> was not found on the server'
            - else:
              - narrate '<&e>A NPC ID was not entered to change'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case npcend:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define npc_id:<context.args.get[3]||<empty>>
            - if <[npc_id]> != <empty>:
              - if <server.npcs.parse[id].contains[<[npc_id]>]>:
                - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                  - run drustcraftt_quest.npc_end def:<[quest_id]>|<[npc_id]>
                  - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> has been updated'
                - else:
                  - narrate '<&e>You do not have permission to change this quest'
              - else:
                - narrate '<&e>NPC ID <&sq><[npc_id]><&sq> was not found on the server'
            - else:
              - narrate '<&e>A NPC ID was not entered to change'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      # todo: npc_id is never defined
      - case endspeak npcendspeak:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define speak:<context.args.remove[1|2].space_separated||<empty>>
            - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
              #- run drustcraftt_quest.npc_end_speak def:<[quest_id]>|<[npc_id]>
              - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> has been updated'
            - else:
              - narrate '<&e>You do not have permission to change this quest'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case addreq addrequirement:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define requirements:<context.args.get[3].split[,]||<empty>>
            
            - if <[requirements]> != <empty> && <[requirements].size> > 0:
              - if <[requirements].contains[<[quest_id]>]> == false:
                - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                  - foreach <[requirements]>:
                    - if <proc[drustcraftp_quest.list].as_list.contains[<[value]>]>:
                      - run drustcraftt_quest.add_requirement def:<[quest_id]>|<[value]>
                      - narrate '<&e>Quest ID <&sq><[value]><&sq> added as a requirement'
                    - else:
                      - narrate '<&e>Quest ID <&sq><[value]><&sq> is not a valid quest'
                - else:
                  - narrate '<&e>You do not have permission to change this quest'
              - else:
                - narrate '<&e>A quest can not require itself'
            - else:
              - narrate '<&e>No quest requirements where entered'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case remreq removerequirement:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define requirements:<context.args.get[3].split[,]||<empty>>
            
            - if <[requirements]> != <empty> && <[requirements].size> > 0:
              - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                - foreach <[requirements]>:
                  - if <proc[drustcraftp_quest.list].as_list.contains[<[value]>]>:
                    - run drustcraftt_quest.remove_requirement def:<[quest_id]>|<[value]>
                    - narrate '<&e>Quest ID <&sq><[value]><&sq> removed as a requirement'
                  - else:
                    - narrate '<&e>Quest ID <&sq><[value]><&sq> is not a valid quest'
              - else:
                - narrate '<&e>You do not have permission to change this quest'
            - else:
              - narrate '<&e>No quest requirements where entered'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case clrreq clearrequirements:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
              - run drustcraftt_quest.clear_requirements def:<[quest_id]>
              - narrate '<&e>Requirements cleared for Quest ID <&sq><[quest_id]><&sq>'
            - else:
              - narrate '<&e>You do not have permission to change this quest'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case repeat repeatable:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define repeatable:<context.args.get[3]||<empty>>
            
            - if <[repeatable]> != <empty> && <list[true|false].contains[<[repeatable]>:
              - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                - run drustcraftt_quest.repeatable def:<[quest_id]>|<[repeatable]>
                - narrate '<&e>Quest ID <&sq><[value]><&sq> has been updated'
              - else:
                - narrate '<&e>You do not have permission to change this quest'
            - else:
              - narrate '<&e>Quest repeatable needs to be true or false'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case addobj addobjective:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define type:<context.args.get[3]||<empty>>
            - define data:<context.args.get[4]||<empty>>
            - define quantity:<context.args.get[5]||<empty>>
            - define region:<context.args.get[6]||<empty>>
            - if <[type]> != <empty>:
              - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                - run drustcraftt_quest.add_objective def:<[quest_id]>|<[type]>|<[data]>|<[quantity]>|<[region]>
                - narrate '<&e>The objectives for Quest ID <&sq><[quest_id]><&sq> was updated'
              - else:
                - narrate '<&e>You do not have permission to change this quest'
            - else:
              - narrate '<&e>No objective type was entered'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case remobj remobjective:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define objective_id:<context.args.get[3]||<empty>>
            - if <[objective_id]> != <empty>:
              - define quest_map:<proc[drustcraftp_quest.info].context[<[quest_id]>]||<map[]>>
              - if <[quest_map].get[objectives].keys.contains[<[objective_id]>]||false>:
                - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                  - run drustcraftt_quest.remove_objective def:<[quest_id]>|<[objective_id]>
                  - narrate '<&e>The objectives for Quest ID <&sq><[quest_id]><&sq> was updated'
                - else:
                  - narrate '<&e>You do not have permission to change this quest'
              - else:
                - narrate '<&e>A valid objective ID was not entered'
            - else:
              - narrate '<&e>No objective ID was entered'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case editobj editobjective:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define objective_id:<context.args.get[3]||<empty>>
            - if <[objective_id]> != <empty>:
              - define quest_map:<proc[drustcraftp_quest.info].context[<[quest_id]>]||<map[]>>
              - if <[quest_map].get[objectives].keys.contains[<[objective_id]>]||false>:
                - define type:<context.args.get[4]||<empty>>
                - define data:<context.args.get[5]||<empty>>
                - define quantity:<context.args.get[6]||<empty>>
                - define region:<context.args.get[7]||<empty>>
                - if <[type]> != <empty>:
                  - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                    - run drustcraftt_quest.update_objective def:<[quest_id]>|<[objective_id]>|<[type]>|<[data]>|<[quantity]>|<[region]>
                    - narrate '<&e>The objectives for Quest ID <&sq><[quest_id]><&sq> was updated'
                  - else:
                    - narrate '<&e>You do not have permission to change this quest'
                - else:
                  - narrate '<&e>No objective type was entered'
              - else:
                - narrate '<&e>A valid objective ID was not entered'
            - else:
              - narrate '<&e>No objective ID was entered'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'

      - case addrew addreward:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define item:<context.args.get[3]||<empty>>
            - define quantity:<context.args.get[4]||1>
            - if <[item]> != <empty>:
              - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                - run drustcraftt_quest.add_reward def:<[quest_id]>|<[item]>|<[quantity]>
                - narrate '<&e>The rewards for Quest ID <&sq><[quest_id]><&sq> was updated'
              - else:
                - narrate '<&e>You do not have permission to change this quest'
            - else:
              - narrate '<&e>No reward item was entered'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case editrew editreward:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define item:<context.args.get[3]||<empty>>
            - define quantity:<context.args.get[4]||1>
            - if <[item]> != <empty>:
              - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                - run drustcraftt_quest.update_reward def:<[quest_id]>|<[item]>|<[quantity]>
                - narrate '<&e>The rewards for Quest ID <&sq><[quest_id]><&sq> was updated'
              - else:
                - narrate '<&e>You do not have permission to change this quest'
            - else:
              - narrate '<&e>No reward item was entered'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case remrew remreward removereward:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define item:<context.args.get[3]||<empty>>
            - if <[item]> != <empty>:
              - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                - run drustcraftt_quest.remove_reward def:<[quest_id]>|<[item]>
                - narrate '<&e>The rewards for Quest ID <&sq><[quest_id]><&sq> was updated'
              - else:
                - narrate '<&e>You do not have permission to change this quest'
            - else:
              - narrate '<&e>No reward item was entered'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
##
      - case addgive:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define item:<context.args.get[3]||<empty>>
            - define quantity:<context.args.get[4]||1>
            - if <[item]> != <empty>:
              - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                - run drustcraftt_quest.add_give def:<[quest_id]>|<[item]>|<[quantity]>
                - narrate '<&e>The give items for Quest ID <&sq><[quest_id]><&sq> was updated'
              - else:
                - narrate '<&e>You do not have permission to change this quest'
            - else:
              - narrate '<&e>No give item was entered'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case editgive:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define item:<context.args.get[3]||<empty>>
            - define quantity:<context.args.get[4]||1>
            - if <[item]> != <empty>:
              - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                - run drustcraftt_quest.update_give def:<[quest_id]>|<[item]>|<[quantity]>
                - narrate '<&e>The give item for Quest ID <&sq><[quest_id]><&sq> was updated'
              - else:
                - narrate '<&e>You do not have permission to change this quest'
            - else:
              - narrate '<&e>No give item was entered'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
      
      - case remgive removegive:
        - define quest_id:<context.args.get[2]||<empty>>
        - if <[quest_id]> != <empty>:
          - if <proc[drustcraftp_quest.list].as_list.contains[<[quest_id]>]>:
            - define item:<context.args.get[3]||<empty>>
            - if <[item]> != <empty>:
              - if <context.server||false> || <player.has_permission[drustcraft_quest.override]||false> || <proc[drustcraftp_quest.is_owner].context[<[quest_id]>|<player>]>:
                - run drustcraftt_quest.remove_give def:<[quest_id]>|<[item]>
                - narrate '<&e>The give items for Quest ID <&sq><[quest_id]><&sq> was updated'
              - else:
                - narrate '<&e>You do not have permission to change this quest'
            - else:
              - narrate '<&e>No give item was entered'
          - else:
            - narrate '<&e>Quest ID <&sq><[quest_id]><&sq> was not found on the server'
        - else:
          - narrate '<&e>A Quest ID was not entered to change'
          
      - default:
        - narrate '<&c>Unknown option. Try <queue.script.data_key[usage].parsed>'
        

drustcraftt_interactor_quest:
    type: task
    debug: false
    script:
		- define target_npc:<[1]>
		- define target_player:<[2]>
		- define action:<[3]>
		
        - choose <[action]||<empty>>:
            - case click:
                - note 'in@generic[size=45;title=<npc[<[1]>].name.strip_color>]' as:drustcraft_npc_<player.uuid>
                - define inventory_name:drustcraft_npc_<player.uuid>

                # Give items in players hand to NPC if they are wanted
                - define gave_items:false
                - while true:
                    - ~run drustcraftt_quest.objective_event def:give|<player.item_in_hand.material.name> save:result
                    - if <entry[result].created_queue.determination.get[1]||true>:
                        - define gave_items:true
                        - take item_in_hand quantity:1
                    - else:
                        - while stop
                
                # Check if there are done quests and take them from the players inventory
                - define quests_done:<proc[drustcraftp_quest.npc.list_done].context[<[target_npc]>|<[target_player]>]>
                - foreach <proc[drustcraftp_quest.player_inventory].context[<[target_player]>]>:
                    - if <[quests_done].contains[<[key]>]>:
                        - define gave_items:true
                        - inventory set slot:<[value]> o:air d:<player.inventory>
                        - ~run drustcraftt_quest.completed def:<player>|<[key]>
                        - run drustcraftt_quest.update_markers def:true

                - if <[gave_items]>:
                    - run drustcraftt_quest.update_markers def:true
                    - determine cancelled

                # add quest items to inventory
                - if <[inventory_name]> != <empty>:
                    - define quest_list:<proc[drustcraftp_quest.npc.list_available].context[<[target_npc]>|<[target_player]>]>
                    - if <[quest_list].size> > 0:
                        - foreach <[quest_list]>:
                            - define quest_id:<[value]>
                            - define slot:<inventory[<[inventory_name]>].first_empty>
                            - if <[slot]> == -1:
                                - foreach stop

                            - define questbook:<proc[drustcraftp_quest.questbook].context[<[quest_id]>|<player>|true]>
                            - if <[questbook]> != <empty>:
                                - inventory set d:<inventory[<[inventory_name]>]> slot:<[slot]> o:<[questbook]>
                                
                        - inventory open d:in@drustcraft_npc_<player.uuid>
                        - determine false
                
                - determine true
            
            - case entry:
                - run drustcraftt_quest.update_markers
            
            - case text_status:
                - define type:<[4]>
                - define data:<[5]>
                - define quantity:<[6]>
                - define region:<[7]>
                - define current:<[8]>
                - define quest_id:<[9]>
                
                - choose <[type]>:
                    - case enter_region:                
                        - define region_title:<proc[drustcraftp.region.title].context[<[target_player].location.world.name>|<[data]>]>
                        - if <[region_title]> == <empty>:
                            - define region_title:<[data]>
                        
                        - define 'status:Visit <[region_title]>'
                        - if <[current]> == 1:
                            - define 'status:<[status]> <&2>√'
                        
                        - determine <[status]>
                    - case block_break:
                        - define 'status:Break <[current]>/<[quantity]> <material[<[data]>].translated_name||<[data]>>'

                        - if <[region]> != <empty>:
                            - define region_title:<proc[drustcraftp.region.title].context[<[target_player].location.world.name>|<[region]>]>
                            - if <[region_title]> == <empty>:
                                - define region_title:<[data]>
                            - define 'status:<[status]> at <[region_title]>'

                        - if <[current]> >= <[quantity]>:
                            - define 'status:<[status]> <&2>√'
                        
                        - determine <[status]>
                    - case block_place:
                        - define 'status:Place <[current]>/<[quantity]> <material[<[data]>].translated_name||<[data]>>'

                        - if <[region]> != <empty>:
                            - define region_title:<proc[drustcraftp.region.title].context[<[target_player].location.world.name>|<[region]>]>
                            - if <[region_title]> == <empty>:
                                - define region_title:<[data]>
                            - define 'status:<[status]> at <[region_title]>'

                        - if <[current]> >= <[quantity]>:
                            - define 'status:<[status]> <&2>√'
                        
                        - determine <[status]>
                    - case give:
                        - define npc_end:<yaml[drustcraft_quests].read[quests.<[quest_id]>.npc_end]||0>
                        - define npc_name:Unknown
                        
                        - if <[npc_end]> != 0:
                            - define npc_name:<npc[<[npc_end]>].name.strip_color||<[npc_name]>>
                        
                        - define 'status:Give <[npc_name]> <[current]>/<[quantity]> <material[<[data]>].translated_name||<[data]>>'

                        - if <[region]> != <empty>:
                            - define region_title:<proc[drustcraftp.region.title].context[<[target_player].location.world.name>|<[region]>]>
                            - if <[region_title]> == <empty>:
                                - define region_title:<[data]>
                            - define 'status:<[status]> at <[region_title]>'

                        - if <[current]> >= <[quantity]>:
                            - define 'status:<[status]> <&2>√'
                        
                        - determine <[status]>
                    - case kill:
                        - define 'status:Kill <[current]>/<[quantity]> <[data]>'

                        - if <[region]> != <empty>:
                            - define region_title:<proc[drustcraftp.region.title].context[<[target_player].location.world.name>|<[region]>]>
                            - if <[region_title]> == <empty>:
                                - define region_title:<[data]>
                            - define 'status:<[status]> at <[region_title]>'

                        - if <[current]> >= <[quantity]>:
                            - define 'status:<[status]> <&2>√'
                        
                        - determine <[status]>
                        
drustcraftp_tab_complete_quests:
  type: procedure
  debug: false
  script:
    - determine <proc[drustcraftp_quest.list]>

drustcraft_questbook:
  type: book
  title: Quest Book
  author: Quest Book
  signed: true
  text:
  - You should not be seeing this padiwan. Can you report how you got it using the command /report please?