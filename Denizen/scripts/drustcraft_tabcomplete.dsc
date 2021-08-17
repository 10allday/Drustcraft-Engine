# Drustcraft - Tab Complete
# https://github.com/drustcraft/drustcraft

# _*TASKNAME  Include entire list
# _&TASKNAME  Allow list to be reused with ,
# _^TASKNAME  Allow list to be reused with , exclude current items
# _&TASKNAME?perm


drustcraftw_tabcomplete:
  type: world
  debug: false
  version: 1
  events:
    on server start:
      - run drustcraftt_tabcomplete_load

    on script reload:
      - run drustcraftt_tabcomplete_load


drustcraftt_tabcomplete_load:
  type: task
  debug: false
  script:
    - wait 2t
    - waituntil <server.has_flag[drustcraft.module.core]>

    - if <yaml.list.contains[drustcraft_tabcomplete]>:
      - ~yaml unload id:drustcraft_tabcomplete
    - yaml create id:drustcraft_tabcomplete

    - if <server.has_flag[drustcraft_tabcomplete_hostile_mobs]>:
      - flag server drustcraft_tabcomplete_hostile_mobs:!

    - foreach <server.list_files[../MythicMobs/Mobs]||<list[]>> as:file:
      - ~yaml load:../MythicMobs/Mobs/<[file]> id:mythicmob
      - foreach <yaml[mythicmob].list_keys[]> as:key:
        - if <yaml[mythicmob].contains[<[key]>.damage]>:
          - flag server drustcraft_tabcomplete_hostile_mobs:|:<[key]>
      - ~yaml unload id:mythicmob

    - if !<server.has_flag[drustcraft_tabcomplete_hostile_mobs]>:
      - flag server drustcraft_tabcomplete_hostile_mobs:<list[]>

    - flag server drustcraft.module.tabcomplete:<script[drustcraftw_tabcomplete].data_key[version]>


drustcraftt_tabcomplete_completion:
  type: task
  debug: false
  script:
    - yaml id:drustcraft_tabcomplete set <queue.definition_map.exclude[raw_context].values.separated_by[.]>:end


drustcraftt_tabcomplete_remove:
  type: task
  debug: false
  script:
    - yaml id:drustcraft_tabcomplete set <queue.definition_map.exclude[raw_context].values.separated_by[.]>:!


drustcraftp_tabcomplete:
  type: procedure
  debug: false
  definitions: command|raw_args
  script:
    - define raw_args:<[raw_args]||<empty>>
    - define path:<[command]>
    - define 'args:|:<[raw_args].split[ ]>'
    - if <[args].get[1]||<empty>> == <empty>:
      - define args:<[args].remove[1]>
    - define argsSize:<[args].size>
    - define newArg:<[raw_args].ends_with[<&sp>].or[<[raw_args].is[==].to[<empty>]>]>
    - if <[newArg]>:
      - define argsSize:+:1
    - repeat <[argsSize].sub[1]> as:index:
      - define value:<[args].get[<[index]>]>
      - define keys:<yaml[drustcraft_tabcomplete].list_keys[<[path]>]||<list[]>>
      - define permLockedKeys:<[keys].filter[starts_with[?]]>

      - define keys:<-:<[permLockedKeys]>
      - if <[value]> == <empty>:
        - foreach next
      - if <[keys].contains[<[value]>]>:
        - define path:<[path]>.<[value]>
      - else if <[keys].contains[*]>:
        - define path:<[path]>.*
      - else:
        - if <[permLockedKeys].size> > 0:
          - define 'permMap:<[permLockedKeys].parse[after[ ]].map_with[<[permLockedKeys].parse[before[ ]]>]>'
          - define perm:<[permMap].get[<[value]>]||null>
          - if <[perm]> != null && <player.has_permission[<[perm].after[?]>]>:
            - define path:'<[path]>.<[perm]> <[value]>'
            - repeat next
        - define default <[keys].filter[starts_with[_]].get[1]||null>
        - if <[default]> == null:
          - determine <list[]>
        - define path:<[path]>.<[default]>
      - if <yaml[drustcraft_tabcomplete].read[<[path]>]> == end:
        - determine <list[]>

    - foreach <yaml[drustcraft_tabcomplete].list_keys[<[path]>]||<list[]>>:
      - if <[value].starts_with[_]>:
        - define value:<[value].after[_]>
        - if <[value].starts_with[*]>:
          - if <server.scripts.parse[name].contains[drustcraftp_tabcomplete_<[value].after[*]>]>:
            - define ret:|:<proc[drustcraftp_tabcomplete_<[value].after[*]>].context[<[args]>]>
        - if <[value].starts_with[&]>:
          - if <[raw_args].ends_with[,]>:
            - define parg:<[args].get[<[argsSize].sub[1]>]>
            - if <server.scripts.parse[name].contains[drustcraftp_tabcomplete_<[value].after[&]>]>:
              - define clist:<proc[drustcraftp_tabcomplete_<[value].after[&]>].context[<[args]>]>
              - foreach <[clist]>:
                - define ret:|:<[parg]><[value]>
          - else:
            - define ret:|:<proc[drustcraftp_tabcomplete_<[value].after[&]>].context[<[args]>]>
        - if <[value].starts_with[^]>:
          - if <[raw_args].ends_with[,]>:
            - define parg:<[args].get[<[argsSize].sub[1]>]>
            - define pitems:<[parg].split[,]>
            - if <server.scripts.parse[name].contains[drustcraftp_tabcomplete_<[value].after[^]>]>:
              - define clist:<proc[drustcraftp_tabcomplete_<[value].after[^]>].context[<[args]>]>
              - foreach <[clist]>:
                - if !<[pitems].contains[<[value]>]>:
                  - define ret:|:<[parg]><[value]>
          - else:
            - if <server.scripts.parse[name].contains[drustcraftp_tabcomplete_<[value].after[^]>]>:
              - define ret:|:<proc[drustcraftp_tabcomplete_<[value].after[^]>].context[<[args]>]>
      - else if <[value].starts_with[?]>:
        - define 'perm:<[value].before[ ].after[?]>'
        - if <player.has_permission[<[perm]>]>:
          - define 'ret:|:<[value].after[ ]>'
      - else:
        - define ret:->:<[value]>
    - if !<definition[ret].exists>:
      - determine <list[]>
    - if <[newArg]>:
      - determine <[ret]>
    - determine <[ret].filter[starts_with[<[args].last>]]>


drustcraftp_tabcomplete_int:
  type: procedure
  debug: false
  script:
    - determine <list[0|1|2|3|4|5|6|7|8|9]>


drustcraftp_tabcomplete_int_nozero:
  type: procedure
  debug: false
  script:
    - determine <list[0|1|2|3|4|5|6|7|8|9]>


drustcraftp_tabcomplete_bool:
  type: procedure
  debug: false
  script:
    - determine <list[true|false]>


drustcraftp_tabcomplete_materials:
  type: procedure
  debug: false
  script:
    - determine <server.material_types.parse[name]>


drustcraftp_tabcomplete_groups:
  type: procedure
  debug: false
  script:
    - determine <server.permission_groups.filter[ends_with[_edit].not].exclude[default]>


drustcraftp_tabcomplete_durations:
  type: procedure
  debug: false
  script:
    - determine <list[5m|10m|15m|30m|1h|2h|4h|1d|2d|3d|1w|2w|4w]>


drustcraftp_tabcomplete_pageno:
  type: procedure
  debug: false
  script:
    - determine <list[1|2|3|4|5|6|7|8|9]>


drustcraftp_tabcomplete_onlineplayers:
  type: procedure
  debug: false
  script:
    - determine <server.online_players.parse[name]>


drustcraftp_tabcomplete_players:
  type: procedure
  debug: false
  script:
    - determine <server.players.parse[name]>


drustcraftp_tabcomplete_npcs:
  type: procedure
  debug: false
  script:
    - determine <server.npcs.parse[id]>


drustcraftp_tabcomplete_worlds:
  type: procedure
  debug: false
  script:
    - determine <server.worlds.parse[name]>


drustcraftp_tabcomplete_hostile:
  type: procedure
  debug: false
  script:
    - if <server.has_flag[drustcraft_tabcomplete_hostile_mobs]>:
      - determine <server.flag[drustcraft_tabcomplete_hostile_mobs].as_list>
    - determine <list[]>


drustcraftp_tabcomplete_regions:
  type: procedure
  debug: false
  script:
    - if <player||<empty>> != <empty>:
      - determine <player.location.world.list_regions.parse[id]>
    - determine <list[]>


drustcraftp_tabcomplete_timezone:
  type: procedure
  debug: false
  script:
    - determine <list[Etc/GMT+12|Etc/GMT+11|Pacific/Midway|Pacific/Niue|Pacific/Pago_Pago|Pacific/Samoa|US/Samoa|America/Adak|America/Atka|Etc/GMT+10|HST|Pacific/Honolulu|Pacific/Johnston|Pacific/Rarotonga|Pacific/Tahiti|SystemV/HST10|US/Aleutian|US/Hawaii|Pacific/Marquesas|AST|America/Anchorage|America/Juneau|America/Nome|America/Sitka|America/Yakutat|Etc/GMT+9|Pacific/Gambier|SystemV/YST9|SystemV/YST9YDT|US/Alaska|America/Dawson|America/Ensenada|America/Los_Angeles|America/Metlakatla|America/Santa_Isabel|America/Tijuana|America/Vancouver|America/Whitehorse|Canada/Pacific|Canada/Yukon|Etc/GMT+8|Mexico/BajaNorte|PST|PST8PDT|Pacific/Pitcairn|SystemV/PST8|SystemV/PST8PDT|US/Pacific|US/Pacific-New|America/Boise|America/Cambridge_Bay|America/Chihuahua|America/Creston|America/Dawson_Creek|America/Denver|America/Edmonton|America/Hermosillo|America/Inuvik|America/Mazatlan|America/Ojinaga|America/Phoenix|America/Shiprock|America/Yellowknife|Canada/Mountain|Etc/GMT+7|MST|MST7MDT|Mexico/BajaSur|Navajo|PNT|SystemV/MST7|SystemV/MST7MDT|US/Arizona|US/Mountain|America/Bahia_Banderas|America/Belize|America/Cancun|America/Chicago|America/Costa_Rica|America/El_Salvador|America/Guatemala|America/Indiana/Knox|America/Indiana/Tell_City|America/Knox_IN|America/Managua|America/Matamoros|America/Menominee|America/Merida|America/Mexico_City|America/Monterrey|America/North_Dakota/Beulah|America/North_Dakota/Center|America/North_Dakota/New_Salem|America/Rainy_River|America/Rankin_Inlet|America/Regina|America/Resolute|America/Swift_Current|America/Tegucigalpa|America/Winnipeg|CST|CST6CDT|Canada/Central|Canada/East-Saskatchewan|Canada/Saskatchewan|Chile/EasterIsland|Etc/GMT+6|Mexico/General|Pacific/Easter|Pacific/Galapagos|SystemV/CST6|SystemV/CST6CDT|US/Central|US/Indiana-Starke|America/Atikokan|America/Bogota|America/Cayman|America/Coral_Harbour|America/Detroit|America/Eirunepe|America/Fort_Wayne|America/Grand_Turk|America/Guayaquil|America/Havana|America/Indiana/Indianapolis|America/Indiana/Marengo|America/Indiana/Petersburg|America/Indiana/Vevay|America/Indiana/Vincennes|America/Indiana/Winamac|America/Indianapolis|America/Iqaluit|America/Jamaica|America/Kentucky/Louisville|America/Kentucky/Monticello|America/Lima|America/Louisville|America/Montreal|America/Nassau|America/New_York|America/Nipigon|America/Panama|America/Pangnirtung|America/Port-au-Prince|America/Porto_Acre|America/Rio_Branco|America/Thunder_Bay|America/Toronto|Brazil/Acre|Canada/Eastern|Cuba|EST|EST5EDT|Etc/GMT+5|IET|Jamaica|SystemV/EST5|SystemV/EST5EDT|US/East-Indiana|US/Eastern|US/Michigan|America/Caracas|America/Anguilla|America/Antigua|America/Aruba|America/Asuncion|America/Barbados|America/Blanc-Sablon|America/Boa_Vista|America/Campo_Grande|America/Cuiaba|America/Curacao|America/Dominica|America/Glace_Bay|America/Goose_Bay|America/Grenada|America/Guadeloupe|America/Guyana|America/Halifax|America/Kralendijk|America/La_Paz|America/Lower_Princes|America/Manaus|America/Marigot|America/Martinique|America/Moncton|America/Montserrat|America/Port_of_Spain|America/Porto_Velho|America/Puerto_Rico|America/Santiago|America/Santo_Domingo|America/St_Barthelemy|America/St_Kitts|America/St_Lucia|America/St_Thomas|America/St_Vincent|America/Thule|America/Tortola|America/Virgin|Antarctica/Palmer|Atlantic/Bermuda|Brazil/West|Canada/Atlantic|Chile/Continental|Etc/GMT+4|PRT|SystemV/AST4|SystemV/AST4ADT|America/St_Johns|CNT|Canada/Newfoundland|AGT|America/Araguaina|America/Argentina/Buenos_Aires|America/Argentina/Catamarca|America/Argentina/ComodRivadavia|America/Argentina/Cordoba|America/Argentina/Jujuy|America/Argentina/La_Rioja|America/Argentina/Mendoza|America/Argentina/Rio_Gallegos|America/Argentina/Salta|America/Argentina/San_Juan|America/Argentina/San_Luis|America/Argentina/Tucuman|America/Argentina/Ushuaia|America/Bahia|America/Belem|America/Buenos_Aires|America/Catamarca|America/Cayenne|America/Cordoba|America/Fortaleza|America/Godthab|America/Jujuy|America/Maceio|America/Mendoza|America/Miquelon|America/Montevideo|America/Paramaribo|America/Recife|America/Rosario|America/Santarem|America/Sao_Paulo|Antarctica/Rothera|Atlantic/Stanley|BET|Brazil/East|Etc/GMT+3|America/Noronha|Atlantic/South_Georgia|Brazil/DeNoronha|Etc/GMT+2|America/Scoresbysund|Atlantic/Azores|Atlantic/Cape_Verde|Etc/GMT+1|Africa/Abidjan|Africa/Accra|Africa/Bamako|Africa/Banjul|Africa/Bissau|Africa/Casablanca|Africa/Conakry|Africa/Dakar|Africa/El_Aaiun|Africa/Freetown|Africa/Lome|Africa/Monrovia|Africa/Nouakchott|Africa/Ouagadougou|Africa/Sao_Tome|Africa/Timbuktu|America/Danmarkshavn|Antarctica/Troll|Atlantic/Canary|Atlantic/Faeroe|Atlantic/Faroe|Atlantic/Madeira|Atlantic/Reykjavik|Atlantic/St_Helena|Eire|Etc/GMT|Etc/GMT+0|Etc/GMT-0|Etc/GMT0|Etc/Greenwich|Etc/UCT|Etc/UTC|Etc/Universal|Etc/Zulu|Europe/Belfast|Europe/Dublin|Europe/Guernsey|Europe/Isle_of_Man|Europe/Jersey|Europe/Lisbon|Europe/London|GB|GB-Eire|GMT|GMT0|Greenwich|Iceland|Portugal|UCT|UTC|Universal|WET|Zulu|Africa/Algiers|Africa/Bangui|Africa/Brazzaville|Africa/Ceuta|Africa/Douala|Africa/Kinshasa|Africa/Lagos|Africa/Libreville|Africa/Luanda|Africa/Malabo|Africa/Ndjamena|Africa/Niamey|Africa/Porto-Novo|Africa/Tunis|Africa/Windhoek|Arctic/Longyearbyen|Atlantic/Jan_Mayen|CET|ECT|Etc/GMT-1|Europe/Amsterdam|Europe/Andorra|Europe/Belgrade|Europe/Berlin|Europe/Bratislava|Europe/Brussels|Europe/Budapest|Europe/Busingen|Europe/Copenhagen|Europe/Gibraltar|Europe/Ljubljana|Europe/Luxembourg|Europe/Madrid|Europe/Malta|Europe/Monaco|Europe/Oslo|Europe/Paris|Europe/Podgorica|Europe/Prague|Europe/Rome|Europe/San_Marino|Europe/Sarajevo|Europe/Skopje|Europe/Stockholm|Europe/Tirane|Europe/Vaduz|Europe/Vatican|Europe/Vienna|Europe/Warsaw|Europe/Zagreb|Europe/Zurich|MET|Poland|ART|Africa/Blantyre|Africa/Bujumbura|Africa/Cairo|Africa/Gaborone|Africa/Harare|Africa/Johannesburg|Africa/Kigali|Africa/Lubumbashi|Africa/Lusaka|Africa/Maputo|Africa/Maseru|Africa/Mbabane|Africa/Tripoli|Asia/Amman|Asia/Beirut|Asia/Damascus|Asia/Gaza|Asia/Hebron|Asia/Istanbul|Asia/Jerusalem|Asia/Nicosia|Asia/Tel_Aviv|CAT|EET|Egypt|Etc/GMT-2|Europe/Athens|Europe/Bucharest|Europe/Chisinau|Europe/Helsinki|Europe/Istanbul|Europe/Kiev|Europe/Mariehamn|Europe/Nicosia|Europe/Riga|Europe/Sofia|Europe/Tallinn|Europe/Tiraspol|Europe/Uzhgorod|Europe/Vilnius|Europe/Zaporozhye|Israel|Libya|Turkey|Africa/Addis_Ababa|Africa/Asmara|Africa/Asmera|Africa/Dar_es_Salaam|Africa/Djibouti|Africa/Juba|Africa/Kampala|Africa/Khartoum|Africa/Mogadishu|Africa/Nairobi|Antarctica/Syowa|Asia/Aden|Asia/Baghdad|Asia/Bahrain|Asia/Kuwait|Asia/Qatar|Asia/Riyadh|EAT|Etc/GMT-3|Europe/Kaliningrad|Europe/Minsk|Indian/Antananarivo|Indian/Comoro|Indian/Mayotte|Asia/Riyadh87|Asia/Riyadh88|Asia/Riyadh89|Mideast/Riyadh87|Mideast/Riyadh88|Mideast/Riyadh89|Asia/Tehran|Iran|Asia/Baku|Asia/Dubai|Asia/Muscat|Asia/Tbilisi|Asia/Yerevan|Etc/GMT-4|Europe/Moscow|Europe/Samara|Europe/Simferopol|Europe/Volgograd|Indian/Mahe|Indian/Mauritius|Indian/Reunion|NET|W-SU|Asia/Kabul|Antarctica/Mawson|Asia/Aqtau|Asia/Aqtobe|Asia/Ashgabat|Asia/Ashkhabad|Asia/Dushanbe|Asia/Karachi|Asia/Oral|Asia/Samarkand|Asia/Tashkent|Etc/GMT-5|Indian/Kerguelen|Indian/Maldives|PLT|Asia/Calcutta|Asia/Colombo|Asia/Kolkata|IST|Asia/Kathmandu|Asia/Katmandu|Antarctica/Vostok|Asia/Almaty|Asia/Bishkek|Asia/Dacca|Asia/Dhaka|Asia/Qyzylorda|Asia/Thimbu|Asia/Thimphu|Asia/Yekaterinburg|BST|Etc/GMT-6|Indian/Chagos|Asia/Rangoon|Indian/Cocos|Antarctica/Davis|Asia/Bangkok|Asia/Ho_Chi_Minh|Asia/Hovd|Asia/Jakarta|Asia/Novokuznetsk|Asia/Novosibirsk|Asia/Omsk|Asia/Phnom_Penh|Asia/Pontianak|Asia/Saigon|Asia/Vientiane|Etc/GMT-7|Indian/Christmas|VST|Antarctica/Casey|Asia/Brunei|Asia/Choibalsan|Asia/Chongqing|Asia/Chungking|Asia/Harbin|Asia/Hong_Kong|Asia/Kashgar|Asia/Krasnoyarsk|Asia/Kuala_Lumpur|Asia/Kuching|Asia/Macao|Asia/Macau|Asia/Makassar|Asia/Manila|Asia/Shanghai|Asia/Singapore|Asia/Taipei|Asia/Ujung_Pandang|Asia/Ulaanbaatar|Asia/Ulan_Bator|Asia/Urumqi|Australia/Perth|Australia/West|CTT|Etc/GMT-8|Hongkong|PRC|Singapore|Australia/Eucla|Asia/Dili|Asia/Irkutsk|Asia/Jayapura|Asia/Pyongyang|Asia/Seoul|Asia/Tokyo|Etc/GMT-9|JST|Japan|Pacific/Palau|ROK|ACT|Australia/Adelaide|Australia/Broken_Hill|Australia/Darwin|Australia/North|Australia/South|Australia/Yancowinna|AET|Antarctica/DumontDUrville|Asia/Khandyga|Asia/Yakutsk|Australia/ACT|Australia/Brisbane|Australia/Canberra|Australia/Currie|Australia/Hobart|Australia/Lindeman|Australia/Melbourne|Australia/NSW|Australia/Queensland|Australia/Sydney|Australia/Tasmania|Australia/Victoria|Etc/GMT-10|Pacific/Chuuk|Pacific/Guam|Pacific/Port_Moresby|Pacific/Saipan|Pacific/Truk|Pacific/Yap|Australia/LHI|Australia/Lord_Howe|Antarctica/Macquarie|Asia/Sakhalin|Asia/Ust-Nera|Asia/Vladivostok|Etc/GMT-11|Pacific/Efate|Pacific/Guadalcanal|Pacific/Kosrae|Pacific/Noumea|Pacific/Pohnpei|Pacific/Ponape|SST|Pacific/Norfolk|Antarctica/McMurdo|Antarctica/South_Pole|Asia/Anadyr|Asia/Kamchatka|Asia/Magadan|Etc/GMT-12|Kwajalein|NST|NZ|Pacific/Auckland|Pacific/Fiji|Pacific/Funafuti|Pacific/Kwajalein|Pacific/Majuro|Pacific/Nauru|Pacific/Tarawa|Pacific/Wake|Pacific/Wallis|NZ-CHAT|Pacific/Chatham|Etc/GMT-13|MIT|Pacific/Apia|Pacific/Enderbury|Pacific/Fakaofo|Pacific/Tongatapu|Etc/GMT-14|Pacific/Kiritimati]>