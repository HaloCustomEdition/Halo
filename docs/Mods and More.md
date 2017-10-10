# Mods and More

Remember:
* The sapp init file is located here `%USERPROFILE%\Documents\My Games\Halo CE\sapp\init.txt`.
* To enable Lua scripting make sure the `lua 1` option is in the sapp init file.

### Map Voting
Enable map voting.
Copy the file `server_scripts\mapvoting.txt` to `%USERPROFILE%\Documents\My Games\Halo CE\sapp\`.

Add `mapvote 1` to the sapp init file.

### Sprinting
Double tap the forward key to run faster. If you sprint for too long, you will become exhausted and run slower.

Copy the file `server_scripts\Sprinting\sprinting.lua` to `%USERPROFILE%\Documents\My Games\Halo CE\sapp\lua\`.

Add this line to the sapp init file:

    lua_load sprinting

### Combo Messages
This script does is the same thing that an events kill spree messages would do but, it sends it to the console instead and you can choose the alignment of spree or combo message that can be said.

Copy the script file `server_scripts\Combo Messages\combo_messages.lua` to `%USERPROFILE%\Documents\My Games\Halo CE\sapp\lua\`.

Add this line to the sapp init file:

    lua_load combo_messages

### Server Administration

Add the first user as admin with password halo and admin privileges level 4.

    admin add 1 "halo" 4