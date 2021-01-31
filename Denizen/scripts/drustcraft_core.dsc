# Drustcraft - Core
# The bare core of Drustcraft
# https://github.com/drustcraft/drustcraft

drustcraftw:
    type: world
    debug: false
    events:
        on server start:
            - event 'drustcraft preload'
            - define time_now:<util.time_now.epoch_millis.add[5000]>
            - waituntil <queue.list.size> <= 1 || <[time_now]> < <util.time_now.epoch_millis>

            - event 'drustcraft load'
            - define time_now:<util.time_now.epoch_millis.add[5000]>
            - waituntil <queue.list.size> <= 1 || <[time_now]> < <util.time_now.epoch_millis>

        on script reload:
            - event 'drustcraft preload'
            - define time_now:<util.time_now.epoch_millis.add[5000]>
            - waituntil <queue.list.size> <= 1 || <[time_now]> < <util.time_now.epoch_millis>

            - event 'drustcraft load'
            - define time_now:<util.time_now.epoch_millis.add[5000]>
            - waituntil <queue.list.size> <= 1 || <[time_now]> < <util.time_now.epoch_millis>

            - narrate '<&e>Server scripts have been reloaded' targets:<server.online_players.filter[in_group[builder]]>

        on drustcraft preload priority:-10:
            - if <yaml.list.contains[drustcraft_server]>:
                - ~yaml unload id:drustcraft_server
    
            - if <server.has_file[/drustcraft_data/server.yml]>:
                - yaml load:/drustcraft_data/server.yml id:drustcraft_server
            - else:
                - yaml create id:drustcraft_server
                - yaml savefile:/drustcraft_data/server.yml id:drustcraft_server
