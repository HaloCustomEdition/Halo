# Relevant files and folders

* **Example_Modded_Server** - Basic server setup.
* **Halo Medals** - Halo client medals.
* **server_scripts** - Lua scripts and sever configs.
* **sapp_ce** - Latest sapp server release.
* **Universal_UI_Version_1.1** - Latest release of the popular UI.
* **Halo Custom Edition 1.0.10.zip** - Halo version 1.10 with HAC 2.
* **documentations** - Good documentations for Halo CE.

# Halo client

Extract the `Halo Custom Edition 1.0.10.zip` on your computer.

### medals, maps, and ui

Run `Halo Custom Edition v110\redist\msxmlenu.msi`

Copy the file `Universal_UI_Version_1.1\UI.map` to `Halo Custom Edition v110\maps\`.

Copy the maps files from `custom_maps\` to `Halo Custom Edition v110\maps\`.

Create a shortcut on your desktop with this link

    "C:\Halo Custom Edition v110\haloce.exe" -vidmode 1920,1080,60 -console

Now run halo with the shortcut and create a game profile.

Then close halo and follow these next steps.

Copy the zip files from `Halo Medals` to `%USERPROFILE%\Documents\My Games\Halo CE\hac\packs\` (Create the folder packs if necessary).

Now start halo again.

Open the console with `§`.

In the console type `optic load haloreach` and `custom chat 1`.

# Halo server

Install the Halo client.

Copy the folder content of `Example_Modded_Server\My Games\Halo CE\` to ` `%USERPROFILE%\Documents\My Games\Halo CE\`.

Copy the folder content of `Example_Modded_Server\Halo CE\` to `Halo Custom Edition v110`.

Finally copy the content of `sapp_ce\` to `Halo Custom Edition v110`.

Run the server with `haloceded.exe`.

If you run Halo client and server on the same machine make sure to use a different client port with the Halo client.

## mods and more

Remember:
* The sapp init file is located here `%USERPROFILE%\Documents\My Games\Halo CE\sapp\init.txt`.
* To enable Lua scripting make sure the `lua 1` option is in the sapp init file.

### map voting
Enable map voting.
Copy the file `server_scripts\mapvoting.txt` to `%USERPROFILE%\Documents\My Games\Halo CE\sapp\`.

Add `mapvote 1` to the sapp init file.

### Zombie
Zombie game type.

### Combo Messages
This script does is the same thing that an events kill spree messages would do but, it sends it to the console instead and you can choose the alignment of spree or combo message that can be said.

Copy the script file `server_scripts\Combo Messages\combo_messages.lua` to `%USERPROFILE%\Documents\My Games\Halo CE\sapp\lua\`.

Add this line to the sapp init file:

    lua_load combo_messages

### Gun Game
Based on the Counter Strike game called Gun Game.

## server administration

Add the first user as admin with password halo and admin privileges level 4.

    admin add 1 "halo" 4

# Source

http://xhalo.tk/
http://opencarnage.net/index.php?/forum/50-halo-server-scripts/
