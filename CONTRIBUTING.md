Thank for for considering a contribution! Generally, Drustcraft welcomes PRs from everyone. There are some guidelines about what features should go where:


*Pull requests that may not get accepted:* Niche features that apply to a specific group, for example an item that would not be widely used by other players or developers. For now, please create a separate Denizen script if possible. 


We have some general notes that should be applied throughout the code:

  - Scripts must begin with 'drustcraft', the first letter of the script type followed by an underscore and the script group. A world script for quests would be named drustcraftw_quest
  
  - Combine task scripts using seperate keys if possible within a single script. ie drustcraftt_quest.add
  
  - Use the MySQL database for storage. Player/server do not carry across servers with BungeeCord
  
  - Make sure to comment your code where possible.


We have a rundown of all you need to know to develop over on our [wiki](https://github.com/Drustcraft/Drustcraft/wiki/Developer-Guide). If you have any questions, please feel free to reach out to our [Discord](https://discord.drustcraft.com.au)!