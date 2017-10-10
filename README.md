# Halo Custom Edition

[![**Download Halo.zip**](https://raw.githubusercontent.com/HaloCustomEdition/Halo/master/page/Halo-Download.png)]()

The zip file includes these files and folders:

* **Halo Medals** - Halo client medals.
* **server_scripts** - Lua scripts and sever configs.
* **sapp_ce** - Latest sapp server release.
* **Universal_UI_Version_1.1** - Latest release of the popular UI.
* **Halo Custom Edition.zip** - Halo version 1.10 with HAC 2 and Universal UI.
* **documentations** - Good documentations for Halo CE.

# Halo Client

Extract the `Halo Custom Edition.zip` on your computer.

### Medals, Maps, and UI

Run `Halo Custom Edition v110\redist\msxmlenu.msi`.

**Copy** the **Custom Maps** files from your computer to `Halo Custom Edition\maps\`.

**Create** a **Shortcut** in the Halo folder:

    "haloce.exe" -vidmode 1920,1080,60 -console

Now **run Halo** with the shortcut and **create** a game **profile**.

Then **close Halo** and follow these next steps.

**Copy** the zip **files** from `Halo Medals\` to `%USERPROFILE%\Documents\My Games\Halo CE\hac\packs\` (Create the folder packs if necessary).

Now **start Halo** again. **Open** the **console** with `§`.

In the **console type** `optic load haloreach` and `custom chat 1`.

# Halo Server

**Install** the **Halo Client**.

Now **copy** the content of `sapp_ce\` to `Halo Custom Edition\`.

**Create** the Halo Server initialization **file** `init.txt` in the Halo folder with the following content:

```
sv_name "Heiligenschein"
sv_maxplayers 16
sv_motd "motd.txt"
sv_rcon_password 666
sv_log_enabled 1
sv_log_echo_chat 1
sv_tk_ban 5
sv_tk_grace 1s
sv_mapcycle_timeout 5
load
mapcycle_begin
```

Next **update** the Halo Sapp initialization **file** `init.txt` under `%USERPROFILE%\Documents\My Games\Halo CE\sapp\` with the following content:

```
log 1
no_lead 1
```

Then **update** the Halo Sapp map cycle **file** `mapcycle.txt` under `%USERPROFILE%\Documents\My Games\Halo CE\sapp\` with the following content:

```
bloodgulch:ctf:0:16
ratrace:slayer:0:16
sidewinder:ctf:0:16
carousel:slayer:0:16
```

haloceded.exe -port 2305

**Copy** the folder content of `Example_Modded_Server\My Games\Halo CE\` to `%USERPROFILE%\Documents\My Games\Halo CE\`.

**Copy** the folder content of `Example_Modded_Server\Halo CE\` to `Halo Custom Edition\`.

**Run** the **server** with `haloceded.exe`.
