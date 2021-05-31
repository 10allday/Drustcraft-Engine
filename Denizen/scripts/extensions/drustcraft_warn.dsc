# Drustcraft - Warn
# Player warnings and bans
# https://github.com/drustcraft/drustcraft

drustcraftw_warn:
  type: world
  debug: false
  events:
    on server start:
      - run drustcraftt_warn.load
    
    on script reload:
      - run drustcraftt_warn.load
      
    on player logs in:
      - define banned_until:<yaml[drustcraft_warn].read[players.<player.uuid>.banned_until]||<empty>>
      - define banned_track:<yaml[drustcraft_warn].read[players.<player.uuid>.banned_track]||<empty>>
      
      - if <[banned_until]> != <empty>:      
        - if <[banned_until]> == perm || <[banned_until]> > <server.current_time_millis.div[1000].round>:        
          - determine KICKED:<proc[drustcraftp_warn.generate_msg].context[<[banned_track]>|<[banned_until]>]>
        - else:
          - yaml id:drustcraft_warn set players.<player.uuid>.banned_track:!
          - yaml id:drustcraft_warn set players.<player.uuid>.banned_until:!
          - run drustcraftt_warn.save
      
    

drustcraftt_warn:
  type: task
  debug: false
  script:
    - determine <empty>
  
  load:
    - if <server.has_file[/drustcraft_data/warn.yml]>:
      - yaml load:/drustcraft_data/warn.yml id:drustcraft_warn
    - else:
      - yaml create id:drustcraft_warn
      - yaml savefile:/drustcraft_data/warn.yml id:drustcraft_warn

    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - wait 2t
      - waituntil <yaml.list.contains[drustcraft_tab_complete]>
      
      - run drustcraftt_tab_complete.completions def:warn|_*players|_*warn_tracks
      
      
  save:
    - yaml id:drustcraft_warn savefile:/drustcraft_data/warn.yml


drustcraftc_warn:
  type: command
  debug: false
  name: warn
  description: Warns a player and applies a track
  usage: /warn <&lt>player<&gt> <&lt>track<&gt>
  permission: drustcraft.warn
  permission message: <&c>I'm sorry, you do not have permission to perform this command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tab_complete]>:
      - define command:warn
      - determine <proc[drustcraftp_tab_complete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - define target_player:<context.args.get[1]||<empty>>
    - define track:<context.args.get[2]||<empty>>

    - if <[target_player]> != <empty>:
      - define found_player:<server.match_offline_player[<[target_player]>]||<empty>>
      - if <[found_player].name||<empty>> == <[target_player]>:
        - define target_player:<[found_player]>
        
        - if <[track]> != <empty>:
          - if <yaml[drustcraft_warn].read[tracks].contains[<[track]>]>:
            - define next_row:<yaml[drustcraft_warn].read[players.<[target_player].uuid>.tracks.<[track]>].keys.highest.add[1]||1>
            
            - define track_data:<yaml[drustcraft_warn].read[tracks.<[track]>].get[<[next_row]>]||warning>
            - define action:<[track_data].before[:]>
            - define timeframe:perm
            - if <[track_data].after[:]> != perm:
              - define timeframe:<util.time_now.add[<[track_data].after[:].as_duration||0s>].epoch_millis.div[1000].round||perm>
            
            - choose <[action]>:
              - case mute:
                - narrate '<&e>MUTE'
              - case kick:
                - kick <[target_player]> reason:<proc[drustcraftp_warn.generate_msg].context[<[track]>]>
              - case ban:
                - yaml id:drustcraft_warn set players.<[target_player].uuid>.banned_track:<[track]>
                - if <[timeframe]> == perm:
                  - yaml id:drustcraft_warn set players.<[target_player].uuid>.banned_until:perm
                - else:
                  - if <yaml[drustcraft_warn].read[players.<[target_player].uuid>.banned_until]||0> < <[timeframe]>:
                    - yaml id:drustcraft_warn set players.<[target_player].uuid>.banned_until:<[timeframe]>
                  - else:
                    - define timeframe:<yaml[drustcraft_warn].read[players.<[target_player].uuid>.banned_until]||0>
                
                - kick <[target_player]> reason:<proc[drustcraftp_warn.generate_msg].context[<[track]>|<[timeframe]>]>
              - default:
                - narrate '<&e>You have received a WARNING for <[track]>'

            - yaml id:drustcraft_warn set players.<[target_player].uuid>.tracks.<[track]>.<[next_row]>.time:<util.time_now.epoch_millis.div[1000].round>
            - yaml id:drustcraft_warn set players.<[target_player].uuid>.tracks.<[track]>.<[next_row]>.by:<player.uuid||console>
            - if <context.args.size> > 2:
              - yaml id:drustcraft_warn set players.<[target_player].uuid>.tracks.<[track]>.<[next_row]>.reason:<context.args.remove[1|2].space_separated>
            
            - run drustcraftt_warn.save
          - else:
            - narrate '<&e>The track <[track]> was not found'
        - else:
          - narrate '<&e>A track is needed to warn a player'
      - else:
        - narrate '<&e>The player <[target_player]> was not found'
    - else:
      - narrate '<&e>A player is needed to warn'


drustcraftp_warn:
  type: procedure
  script:
    - determine <empty>
  
  generate_msg:
    - define msg:<element[]>
    
    - define 'ban_type:Temporarily Banned'
    - define 'ban_track:<&nl><&nl><&c>Reason <&8>» <&7><[1].to_titlecase>'
    - define ban_until:<[2]>
    - define duration:<element[]>
    
    - if <[ban_until]||<empty>> != <empty>:
      - if <[ban_until].is_integer>:
        - define duration_line:<element[]>
        
        - define seconds_difference:<[ban_until].sub[<server.current_time_millis.div[1000].round>]>
        - define duration_left:<util.time_now.add[<[seconds_difference].as_duration>].from_now>      
        - define 'duration:<&nl><&c>Duration <&8>» <&7><[duration_left].formatted>'
      - else:
        - if <[2]> == perm:
          - define 'ban_type:Permanently Banned'
    - else:
      - define 'ban_type:Kicked from Server'

    - define ban_type:<&nl><&7><&l><[ban_type]>
    - determine '<[ban_type]><[ban_track]><[duration]><&nl><&nl><&7>Visit <&e>www.drustcraft.com.au <&7>for more info'
    
        
drustcraftp_tab_complete_warn_tracks:
  type: procedure
  debug: false
  script:
    - determine <yaml[drustcraft_warn].read[tracks].keys||<list[]>>
