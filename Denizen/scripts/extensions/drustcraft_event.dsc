# Drustcraft - Event
# Event Management
# https://github.com/drustcraft/drustcraft

drustcraftw_event:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_event.load
      
    on script reload:
      - run drustcraftt_event.load
    
    after player joins:
      - wait 10t
      
      - define mins:<element[60].sub[<util.time_now.minute>]>
      
      - foreach <proc[drustcraftp_event.running]>:
        - define title:<proc[drustcraftp_event.title].context[<[key]>]>
        - if <[title]> != <empty>:
          - define duration:<[value].sub[1]>
          
          - define 'remaining:<[mins]> minutes'
          - if <[duration]> > 0:
            - if <[mins]> == 60:
              - define remaining:<element[]>
              - define duration:<[duration].add[1]>
           
            - define hours_txt:hours
            - if <[duration]> == 1:
              - define hours_txt:hour
              
            - define 'remaining:<[duration]> <[hours_txt]> <[remaining]>'
          
          - narrate '<&8><&l>[<&b>+<&8><&l>] <&b>The <[title]> event ends in <[remaining]>'
      

    on system time hourly:
      - run drustcraftt_event.cycle


drustcraftt_event:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <yaml.list.contains[drustcraft_event]>:
      - ~yaml unload id:drustcraft_event

    - if <server.has_file[/drustcraft_data/events.yml]>:
      - yaml load:/drustcraft_data/events.yml id:drustcraft_event
    - else:
      - yaml create id:drustcraft_event
      - yaml savefile:/drustcraft_data/events.yml id:drustcraft_event
    
  save:
    - if <yaml.list.contains[drustcraft_event]>:
      - yaml savefile:/drustcraft_data/events.yml id:drustcraft_event
  
  start:
    - define event_id:<[1]||<empty>>
    - if <[event_id]> != <empty>:
      - define title:<proc[drustcraftp_event.title].context[<[event_id]>]>

      - if <[title]> != <empty>:
        - playsound <server.online_players> sound:ENTITY_EXPERIENCE_ORB_PICKUP
        - narrate '<&8><&l>[<&b>+<&8><&l>] <&b>The <[title]> event has begun' targets:<server.online_players>
        
        - if <server.scripts.parse[name].contains[drustcraftw_discord]>:
          - run drustcraftt_discord.embed 'def:The <[title]> event has begun|#00008B|https://api.drustcraft.com.au/assets/images/red-flag.png'

      - define existing_events:<proc[drustcraftp_event.running]>
      - define duration:<yaml[drustcraft_event].read[events.<[event_id]>.duration]||1>
      
      - flag server drustcraft_events:<[existing_events].with[<[event_id]>].as[<[duration]>]>
      - if <[duration]> == 1:
        - narrate '<&8><&l>[<&b>+<&8><&l>] <&b>The <[title]> event ends in 1 hour' targets:<server.online_players>


      - foreach <yaml[drustcraft_event].read[events.<[event_id]>.commands.start]||<list[]>>:
        - execute as_server <[value]>
        - wait 2t


  end:
    - define event_id:<[1]||<empty>>
    - if <[event_id]> != <empty>:
      - define title:<proc[drustcraftp_event.title].context[<[event_id]>]>

      - if <[title]||<empty>> != <empty>:
        - narrate '<&8><&l>[<&b>+<&8><&l>] <&b>The <[title]> event has ended' targets:<server.online_players>

      - define existing_events:<proc[drustcraftp_event.running]>
      - flag server drustcraft_events:<[existing_events].exclude[<[event_id]>]>

      - foreach <yaml[drustcraft_event].read[events.<[event_id]>.commands.end]||<list[]>>:
        - execute as_server <[value]>
        - wait 2t

  cycle:
    - define events_running:<proc[drustcraftp_event.running]>
    - define events_updated:<map[]>
    
    - foreach <[events_running]>:
      - define title:<proc[drustcraftp_event.title].context[<[key]>]>

      - if <[value]> <= 1:
        - ~run drustcraftt_event.end def:<[key]>
      - else:
        - define existing_events:<proc[drustcraftp_event.running]>
        - flag server drustcraft_events:<[existing_events].with[<[key]>].as[<[value].sub[1]>]>
        
        - if <[value]> == 2:
          - if <[title]||<empty>> != <empty>:
            - narrate '<&8><&l>[<&b>+<&8><&l>] <&b>The <[title]> event ends in 1 hour' targets:<server.online_players>

    - define time_now:<util.time_now>
    - foreach <yaml[drustcraft_event].list_keys[events]||<list[]>> as:event_id:
      - foreach <yaml[drustcraft_event].read[events.<[event_id]>.schedule.dates]||<list[]>> as:date_time:
        - define scheduled:<time[<[date_time]>]||<empty>>
        - if <[scheduled]> != <empty> && <[time_now].year> == <[scheduled].year> && <[time_now].month> == <[scheduled].month> && <[time_now].day> == <[scheduled].day> && <[time_now].hour> == <[scheduled].hour> && <[time_now].minute> == <[scheduled].minute>:
          - ~run drustcraftt_event.start def:<[event_id]>
          - foreach stop


drustcraftp_event:
  type: procedure
  debug: false
  script:
    - determine <empty>
    
  running:
    - determine <server.flag[drustcraft_events].as_map||<map[]>>
  
  is_running:
    - define event_id:<[1]||<empty>>
    - if <[event_id]> != <empty>:
      - determine <proc[drustcraftp_event.running].keys.contains[<[event_id]>]||false>
      
    - determine false

  title:
    - define id:<[1]||<empty>>
    
    - if <[id]> != <empty>:
      - determine <yaml[drustcraft_event].read[events.<[id]>.title]||<empty>>
    
    - determine <empty>
  
  remaining:
    - define id:<[1]||<empty>>
    - define running:<proc[drustcraftp_event.running]>
    
    - if <[running].keys.contains[<[id]>]>:
      - define mins_remaining:<duration[<element[60].sub[<util.time_now.minute>].mul[60]>]>
      - define hours_remaining:<duration[<util.time_now.hour.add[<[running].get[<[id]>].sub[1]>].mul[3600]>]>

      - determine <duration[<[hours_remaining]>].add[<[mins_remaining]>]>
    - else:
      - determine <duration[0]>