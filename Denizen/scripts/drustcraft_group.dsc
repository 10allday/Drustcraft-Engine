# Drustcraft - Group Utilities
# https://github.com/drustcraft/drustcraft
#
# group_ - A group a player belongs to
# rank_ - A player rank that gives a player additional benefits
# role_ - A type of player such as mod, staff, admin, builder

# owner - different prefix
# admin - Full permissions

# game master - 
# /modtools, /group create|remove|modify, create/edit/remove workshops

# moderator - A Moderator is a volunteer staff member that enforces rules, regulations, and punishments over users on the Drustcraft Network
# /warn, /invsee, /kick, /mute, /tp, /vanish

# builder - has the ability to use builder tools in regions that they are a member
# player - default


drustcraftw_group:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_group_load

    on script reload:
      - run drustcraftt_group_load

    on luckperms|lp command:
      - run drustcraftt_util_run_once_later def:drustcraftt_group_update_owners|5


drustcraftt_group_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if !<server.scripts.parse[name].contains[drustcraftw_player]>:
      - debug ERROR 'Drustcraft groups requires Drustcraft Player installed'
      - stop
    - if !<server.scripts.parse[name].contains[drustcraftw_chatgui]>:
      - debug ERROR 'Drustcraft groups requires Drustcraft ChatGUI installed'
      - stop
    - if !<server.scripts.parse[name].contains[drustcraftw_setting]>:
      - debug ERROR 'Drustcraft groups requires Drustcraft setting installed'
      - stop
    - if !<server.scripts.parse[name].contains[drustcraftw_db]>:
      - debug ERROR 'Drustcraft groups requires Drustcraft Database installed'
      - stop
    - if !<server.plugins.parse[name].contains[LuckPerms]>:
      - debug ERROR 'Drustcraft groups requires LuckPerms installed'
      - stop

    - waituntil <server.has_flag[drustcraft.module.player]>

    - ~yaml id:luckperms_config load:../LuckPerms/config.yml
    - if <yaml[luckperms_config].read[storage-method]||null> != MySQL:
      - debug ERROR 'Drustcraft group requires LuckPerms storage method set to MySQL'
      - yaml id:luckperms_config unload
      - stop

    - flag server drustcraft.group.luckperms_prefix:<yaml[luckperms_config].read[data.table-prefix]||<empty>>
    - yaml id:luckperms_config unload

    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - waituntil <server.has_flag[drustcraft.module.tabcomplete]>

      - run drustcraftt_tabcomplete_completion def:group|create
      - run drustcraftt_tabcomplete_completion def:group|remove|_*group_group
      - run drustcraftt_tabcomplete_completion def:group|list|_*pageno
      - run drustcraftt_tabcomplete_completion def:group|info|_*group_group
      - run drustcraftt_tabcomplete_completion def:group|addmember|_*group_group|_^players
      - run drustcraftt_tabcomplete_completion def:group|remmember|_*group_group|_^players
      - run drustcraftt_tabcomplete_completion def:group|addowner|_*group_group|_^players
      - run drustcraftt_tabcomplete_completion def:group|remowner|_*group_group|_^players

    - waituntil <server.has_flag[drustcraft.module.chatgui]>

    - run drustcraftt_group_update_owners

    - flag server drustcraft.module.group:<script[drustcraftw_group].data_key[version]>


drustcraftt_group_update_owners:
  type: task
  debug: false
  script:
    - flag server drustcraft.group.players:!
    - waituntil <server.sql_connections.contains[drustcraft]>
    - ~sql id:drustcraft 'query:SELECT `uuid`, REPLACE(`permission`, "owner.", "") FROM `<server.flag[drustcraft.player.luckperms_prefix]>user_permissions` WHERE `permission` LIKE "owner.<&pc>"' save:sql_result
    - foreach <entry[sql_result].result>:
      - define row:<[value].split[/]||<list[]>>
      - define uuid:<[row].get[1]||<empty>>
      - define group_name:<[row].get[2]||<empty>>
      - flag server drustcraft.group.players.<[uuid]>.owners:->:<[group_name]>


drustcraftt_group_create:
  type: task
  debug: false
  definitions: name
  script:
    - execute as_server 'lp creategroup <[name]>'


drustcraftt_group_remove:
  type: task
  debug: false
  definitions: name
  script:
    - execute as_server 'lp deletegroup <[name]>'


drustcraftt_group_add_owner:
  type: task
  debug: false
  definitions: name|player
  script:
    - execute as_server 'lp user <[player].name> group add <[name]>'
    - wait 1t
    - execute as_server 'lp user <[player].name> permission set owner.<[name]>'


drustcraftt_group_remove_owner:
  type: task
  debug: false
  definitions: name|player
  script:
    - execute as_server 'lp user <[player].name> permission unset owner.<[name]>'


drustcraftt_group_add_member:
  type: task
  debug: false
  definitions: name|player
  script:
    - execute as_server 'lp user <[player].name> group add <[name]>'


drustcraftt_group_remove_member:
  type: task
  debug: false
  definitions: name|player
  script:
    - execute as_server 'lp user <[player].name> group remove <[name]>'


drustcraftp_group_owner_list:
  type: procedure
  debug: false
  definitions: name
  script:
    - determine <server.players.filter_tag[<proc[drustcraftp_group_is_owner].context[<[name]>|<[filter_value]>]>]>


drustcraftp_group_is_owner:
  type: procedure
  debug: false
  definitions: name|player
  script:
    - determine <server.flag[drustcraft.group.players.<[player].uuid>.owners].contains[<[name]>]||false>


drustcraftp_group_member_list:
  type: procedure
  debug: false
  definitions: name
  script:
    - determine <server.players.filter_tag[<proc[drustcraftp_player_in_group].context[<[filter_value]>|<[name]>]>]>


drustcraftp_group_is_member:
  type: procedure
  debug: false
  definitions: name|player
  script:
    - determine <proc[drustcraftp_player_in_group].context[<[player]>|<[name]>]>


drustcraftp_group_exists:
  type: procedure
  debug: false
  definitions: name
  script:
    - determine <server.permission_groups.contains[<[name]>]>


drustcraftp_group_player_member_list:
  type: procedure
  debug: false
  definitions: player
  script:
    - determine <proc[drustcraftp_player_groups].context[<[player]>]>


drustcraftp_group_player_owner_list:
  type: procedure
  debug: false
  definitions: player
  script:
    - determine <server.flag[drustcraft.group.players.<[player].uuid>.owners]||<list[]>>


# Only supports groups prefixed with group_
drustcraftc_group:
  type: command
  debug: false
  name: group
  description: Modifies player groups
  usage: /group (createremove|list|info|addmember|removemember|addowner|removeowner) <&lt>id<&gt> [<&lt>player<&gt>]
  permission: drustcraft.group;drustcraft.group.override
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  tab complete:
    - if <server.scripts.parse[name].contains[drustcraftw_tabcomplete]>:
      - define command:group
      - determine <proc[drustcraftp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
  script:
    - if !<server.has_flag[drustcraft.module.group]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|Drustcraft Groups is not yet loaded. Check console for errors]>'
      - stop

    - define group_name:<context.args.get[2]||<empty>>
    - if <[group_name]> == <empty> && !<list[list].contains[<context.args.get[1]||<empty>>]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|A group name is required]>'
      - stop

    - define group_name:<[group_name].to_lowercase>
    - if !<[group_name].matches_character_set[abcdefghijklmnopqrstuvwxyz0123456789_]>:
      - narrate '<proc[drustcraftp_msg_format].context[error|The group name $e<[group_name]> $rcontains invalid characters]>'
      - stop

    - choose <context.args.get[1]||<empty>>:
      # create
      - case create define add:
        - if !<proc[drustcraftp_group_exists].context[group_<[group_name]>]>:
          - run drustcraftt_group_create def:group_<[group_name]>
          - if !<context.server||false>:
            - run drustcraftt_group_add_owner def:group_<[group_name]>|<player>
          - narrate '<proc[drustcraftp_msg_format].context[success|The group $e<[group_name]> $rwas created]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The group $e<[group_name]> $ralready exists]>'

      # remove
      - case remove rem del delete:
        - if <proc[drustcraftp_group_exists].context[group_<[group_name]>]>:
          - run drustcraftt_group_create def:group_<[group_name]>
          - if <context.server||false> || <player.has_permission[drustcraft.group.override]> || <proc[drustcraftp_group_is_owner].context[group_<[group_name]>|<player>]>:
            - run drustcraftt_group_remove def:group_<[group_name]>
            - narrate '<proc[drustcraftp_msg_format].context[success|The group $e<[group_name]> $rwas removed]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to remove the group $e<[group_name]>]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The group $e<[group_name]> $rdoesn<&sq>t exist]>'

      # list
      - case list:
        - foreach <server.permission_groups.filter[starts_with[group_]].parse[after[group_]]> as:group:
          - if <context.server||false> || <player.has_permission[drustcraft.group.override]> || <proc[drustcraftp_group_is_owner].context[group_<[group]>|<player>]>:
            - define line:<proc[drustcraftp_chatgui_listvalue].context[<[group]>]>
            - define 'line:<[line]><proc[drustcraftp_chatgui_button].context[info|Info|group info <[group]>|Click for information]>'

          - ~run drustcraftt_chatgui_item def:<[line]>
        - run drustcraftt_chatgui_render 'def:groups list|Groups|<context.args.get[2]||1>'

      # info
      - case info:
        - if <proc[drustcraftp_group_exists].context[group_<[group_name]>]>:
          - if <context.server||false> || <player.has_permission[drustcraft.group.override]> || <proc[drustcraftp_group_is_owner].context[group_<[group_name]>|<player>]>:
            - narrate '<proc[drustcraftp_chatgui_title].context[Group: <[group_name]>]>'

            - define raw_members:<proc[drustcraftp_group_member_list].context[group_<[group_name]>]>
            - define owners:<proc[drustcraftp_group_owner_list].context[group_<[group_name]>]>
            - define members:<[raw_members].exclude[<[owners]>]>

            - narrate '<proc[drustcraftp_chatgui_option].context[Owners]><proc[drustcraftp_chatgui_value].context[<[owners].parse[name]>]><proc[drustcraftp_chatgui_button].context[add|Add|group addowner <[group_name]> |Add owner to group]><proc[drustcraftp_chatgui_button].context[rem|Rem|group remowner <[group_name]> |Remove owner from group]>'
            - narrate '<proc[drustcraftp_chatgui_option].context[Members]><proc[drustcraftp_chatgui_value].context[<[members].parse[name]>]><proc[drustcraftp_chatgui_button].context[add|Add|group addmember <[group_name]> |Add member to group]><proc[drustcraftp_chatgui_button].context[rem|Rem|group remmember <[group_name]> |Remove member from group]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to view this group]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The group $e<[group_name]> $rdoesn<&sq>t exist]>'

      # addmember / addowner
      - case am addmem addmember ao addown addowner:
        - if <proc[drustcraftp_group_exists].context[group_<[group_name]>]>:
          - if <context.args.get[3].exists>:
            - define target_player:<server.match_offline_player[<context.args.get[3]>]>
            - if <[target_player].exists> && <[target_player].name> == <context.args.get[3]>:
              - if <context.server||false> || <player.has_permission[drustcraft.group.override]> || <proc[drustcraftp_group_is_owner].context[group_<[group_name]>|<player>]>:
                - if <list[ao|addown|addowner].contains[<context.args.get[1]>]>:
                  - if !<proc[drustcraftp_group_is_owner].context[group_<[group_name]>|<[target_player]>]>:
                    - ~run drustcraftt_group_add_owner def:group_<[group_name]>|<[target_player]>
                    - narrate '<proc[drustcraftp_msg_format].context[success|The player $e<context.args.get[3]> $rwas added as an owner to this group]>'

                    - if <server.online_players.contains[<[target_player]>]>:
                      - narrate '<proc[drustcraftp_msg_format].context[success|You are now an owner of the group $e<[group_name]>]>' targets:<[target_player]>
                  - else:
                    - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[3]> $ris already an owner of this group]>'
                - else:
                  - if !<proc[drustcraftp_group_is_member].context[group_<[group_name]>|<[target_player]>]>:
                    - ~run drustcraftt_group_add_member def:group_<[group_name]>|<[target_player]>
                    - narrate '<proc[drustcraftp_msg_format].context[success|The player $e<context.args.get[3]> $rwas added to this group]>'

                    - if <server.online_players.contains[<[target_player]>]>:
                      - narrate '<proc[drustcraftp_msg_format].context[success|You are now a member of the group $e<[group_name]>]>' targets:<[target_player]>
                  - else:
                    - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[3]> $ris already a member of this group]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this group]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[3]> $rwas not found]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|No player name was entered]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The group $e<[group_name]> $rdoesn<&sq>t exist]>'

      # removemember / removeowner
      - case rm remmem remmember removemember ro remown remowner removeowner:
        - if <proc[drustcraftp_group_exists].context[group_<[group_name]>]>:
          - if <context.args.get[3].exists>:
            - define target_player:<server.match_offline_player[<context.args.get[3]>]>
            - if <[target_player].exists> && <[target_player].name> == <context.args.get[3]>:
              - if <context.server||false> || <player.has_permission[drustcraft.group.override]> || <proc[drustcraftp_group_is_owner].context[group_<[group_name]>|<player>]>:
                - if <list[ro|remown|remowner|removeowner].contains[<context.args.get[1]>]>:
                  - if <proc[drustcraftp_group_is_owner].context[group_<[group_name]>|<[target_player]>]>:
                    - ~run drustcraftt_group_remove_owner def:group_<[group_name]>|<[target_player]>
                    - narrate '<proc[drustcraftp_msg_format].context[success|The player $e<context.args.get[3]> $rwas removed as an owner from this group]>'

                    - if <server.online_players.contains[<[target_player]>]>:
                      - narrate '<proc[drustcraftp_msg_format].context[success|You are no longer an owner of the group $e<[group_name]>]>' targets:<[target_player]>
                  - else:
                    - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[3]> $rwas not an owner of this group]>'
                - else:
                  - if <proc[drustcraftp_group_is_member].context[group_<[group_name]>|<[target_player]>]>:
                    - if !<proc[drustcraftp_group_is_owner].context[group_<[group_name]>|<[target_player]>]>:
                      - ~run drustcraftt_group_remove_member def:group_<[group_name]>|<[target_player]>
                      - narrate '<proc[drustcraftp_msg_format].context[success|The player $e<context.args.get[3]> $rwas removed from this group]>'

                      - if <server.online_players.contains[<[target_player]>]>:
                        - narrate '<proc[drustcraftp_msg_format].context[success|You are now a member of the group $e<[group_name]>]>' targets:<[target_player]>
                    - else:
                      - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[3]> $ris an owner of this group. Try $e/groups remowner]>'
                  - else:
                    - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[3]> $rwas not a member of this group]>'
              - else:
                - narrate '<proc[drustcraftp_msg_format].context[error|You do not have permission to edit this group]>'
            - else:
              - narrate '<proc[drustcraftp_msg_format].context[error|The player $e<context.args.get[3]> $rwas not found]>'
          - else:
            - narrate '<proc[drustcraftp_msg_format].context[error|No player name was entered]>'
        - else:
          - narrate '<proc[drustcraftp_msg_format].context[error|The group $e<[group_name]> $rdoesn<&sq>t exist]>'

      - default:
        - narrate '<proc[drustcraftp_msg_format].context[error|Unknown option. Try <queue.script.data_key[usage].parsed>]>'


drustcraftc_groups:
  type: command
  debug: false
  name: groups
  description: Displays the groups you are within
  usage: /groups
  permission: drustcraft.groups
  permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
  script:
    - define 'groups:<proc[drustcraftp_player_groups].context[<player>].filter[starts_with[group_]].parse[after[group_]].separated_by[$r, $e]>'
    - if <[groups].length> > 0:
      - narrate '<proc[drustcraftp_msg_format].context[arrow|You are in the following groups: $e<[groups]>]>'
    - else:
      - narrate '<proc[drustcraftp_msg_format].context[arrow|You are not in any groups]>'


drustcraftp_tabcomplete_group_group:
  type: procedure
  debug: false
  script:
    - determine <server.permission_groups.filter[starts_with[group_]].parse[after[group_]]>