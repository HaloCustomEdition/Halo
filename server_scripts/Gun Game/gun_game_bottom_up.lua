--[[ ###  Gun-Game/Arms Race v5 'UP'  ###]]--
--[[ ###  by H® Shaft for Phasor v2   ###]]--

-- GUN GAME: Based on the Counter Strike game called 'Gun Game.' Also, derivatives known as 'Global Offensive' & 'Arsenal: Arms Race' by Valve
-- UP VERSION: Work your way up from weakest to strongest weapons.  Link: http://pastebin.com/NerBUTVk
-- DOWN VERSION: Work your way down from strongest to weakest weapons. Link: http://pastebin.com/9FFkFhZi
-- Compatible with CTF & Slayer gametypes only! Pre-fabricated gametypes for both PC and CE: http://www.mediafire.com/download/2jtch51nba7cmcs/gungame_gametypes.zip

-- GAME PLAY:
-- Each time you kill with a weapon, you will be given a new weapon. (oddball and flag: excluded weapons)
-- The first person to kill with each weapon in the game - wins!
-- There are 10 weapons. You can only use the weapon you are given. All weapons have infinite ammo.
-- When you kill another player, you will only advance if you survive the kill.  If you die during the kill, you don't advance.
-- Melee is instant kill and will advance your level.
-- If you are on level 10 (final level), and get killed by another player, betray or suicide, you are demoted one level.
-- Beserk Mode: When reaching level 10, you activate 'Beserk Mode' which temporarily speeds up all other players and heals the injured.
-- Your player speed is based on your weapon: With a strong weapon, you move slower than you will with a weaker weapon.

-- SERVER SETUP - USAGE: --- scroll to very bottom for additional info

-- edit --
logging = false			-- | true enable full script game logging: false = disable, true = enable, see also line 92 - can be spammy to the log, best used for tournaments/scrims/debugging
autobal_delay = 15  	-- | Time in seconds to delay balancing teams during the game and when players join or leave, you should not go lower than 10 seconds
-- don't edit --
team_play = false
map_reset = false
beserk = false
weapons = {}
level = {}
last_damage = {}
team_change = {}
mybattery = {}
playerscore = {}
teamscore = {}
needler_clip = 20
shotgun_clip = 12
assault_clip = 60
flame_clip = 100
pistol_clip = 12
rocket_clip = 2
sniper_clip = 4
battery = 0
cur_players = 0
game_autobal = nil

-- prefix globals
default_script_prefix = "\171GunGame\187  "
phasor_privatesay = privatesay
phasor_say = say

function GetRequiredVersion()
	return 200
end

function OnScriptLoad(process, game, persistent)
    GAME = game
	GetGameAddresses(game)
	processid = process
	Persistent = persistent
    ScriptLoad()
end

function OnScriptUnload()
    writedword(ctf_score_patch, 0xFFFDE9E8)
	writebyte(ctf_score_patch1, 0xFF)
	writebyte(slayer_score_patch, 0x74)
	writebyte(slayer_score_patch2, 0x75)
end

function OnNewGame(map)
	ScriptLoad()
	team_play = getteamplay()
	gametype = readbyte(gametype_base + 0x30)
	game_started = false

	if not new_game_timer then
    	new_game_timer = registertimer(0, "NewGameTimer")
	end
end

function ApplyPatches()
	writedword(ctf_score_patch, 0x90909090)
	writebyte(ctf_score_patch1, 0x90)
	writebyte(slayer_score_patch, 0xEB)
	writebyte(slayer_score_patch2, 0xEB)
end

function ScriptLoad()
	if Persistent then
		-- edit --
		logging = false			-- | true enable full script game logging: false = disable, true = enable, see also line 22 - can be spammy to the log, best used for tournaments/scrims/debugging
		autobal_delay = 15  	-- | Time in seconds to delay balancing teams during the game and when players join or leave, you should not go lower than 10 seconds
		-- don't edit --
		game_started = false
		team_play = false
		beserk = false
		weapons = {}
		level = {}
		last_damage = {}
		team_change = {}
		mybattery = {}
		playerscore = {}
		teamscore = {}
		needler_clip = 20
		shotgun_clip = 12
		assault_clip = 60
		flame_clip = 100
		pistol_clip = 12
		rocket_clip = 2
		sniper_clip = 4
		battery = 0
		game_autobal = nil

		if new_game_timer == nil then
			new_game_timer = registertimer(0, "NewGameTimer")
		end
	end

	GetGameAddresses(game)
	ApplyPatches()
	game_started = false
	team_play = false
	team_play = getteamplay()
	beserk = false
	gametype = readbyte(gametype_base + 0x30)
	cur_players = readword(network_base, 0x1A0)

	for i = 0,15 do
		if getplayer(i) then
			local ip = getip(i)
			last_damage[ip] = nil
			mybattery[i] = 1
			weapons[i] = "weapons\\plasma pistol\\plasma pistol"
			level[i] = 1
			playerscore[i] = 0
			team_change[i] = false
			cur_players = cur_players + 1
		end
	end

	if team_play and game_autobal == nil then
		game_autobal = registertimer(autobal_delay * 1000, "AutoBalance")
	end

	if gametype == 3 or gametype == 4 or gametype == 5 then
		for i=0,15 do
			if getplayer(i) then
				privatesay(i, "Koth, Oddball & Race gametypes are not compatible with Gun-Game. ", false)
			end
		end
		log_msg(4, "#GUN-GAME# Koth, Oddball & Race gametypes are NOT compatible with Gun-Game: try CTF or Slayer.") -- log in scripts log
		log_msg(1, "#GUN-GAME# Koth, Oddball & Race gametypes are NOT compatible with Gun-Game: try CTF or Slayer.") -- log in game log
	else
		game_started = false
		if new_game_timer == nil then
			new_game_timer = registertimer(0, "NewGameTimer")
		end
	end

end

function OnPlayerJoin(player)
	if getplayer(player) then
		local name = getname(player)
		cur_players = cur_players + 1
		mybattery[player] = 1
		weapons[player] = "weapons\\plasma pistol\\plasma pistol"
		level[player] = 1
		playerscore[player] = 0
		team_change[player] = false
		welcome = registertimer(9000, "Welcome", player)
		if game_started and team_play and cur_players > 3 then
			join_autobal = registertimer(autobal_delay * 1000, "AutoBalance")
		end
		if team_play and cur_players > 3 and not game_autobal then
			game_autobal = registertimer(autobal_delay * 1000, "AutoBalance")
		end
		if logging then log_msg(1, name .. " given plasma pistol on spawn.") end
	end
end

function Welcome(id, count, player)
	if count == 1 then
		if getplayer(player) then
			privatesay(player, "Welcome to Gun-Game Arms Race!")
			privatesay(player, "Each time you kill with a weapon, you will be given a new weapon.")
			privatesay(player, "The first person to kill with every weapon in the game - wins!")
			privatesay(player, "This version is 'UP': Start with Plasma Pistol, end with Plasma Cannon.")
			privatesay(player, "type @help for more info.")
		end
	end
	return false
end

function OnPlayerLeave(player)
	if getplayer(player) then
		cur_players = cur_players - 1
		if level[player] == 10 then
			beserk = false
		end
		mybattery[player] = {}
		team_change[player] = {}
		weapons[player] = {}
		level[player] = {}
		playerscore[player] = 0
		if game_started and team_play and cur_players > 3 then
			leave_autobal = registertimer(autobal_delay * 1000, "AutoBalance")
		end
		if team_play and cur_players < 4 and game_autobal then
			game_autobal = nil
		elseif team_play and cur_players > 3 and not game_autobal then
			game_autobal = registertimer(autobal_delay * 1000, "AutoBalance")
		end
	end
end

function OnPlayerSpawn(player, m_objectId)
	if getplayer(player) then
		local ip = getip(player)
		last_damage[ip] = nil
		team_change[player] = false
		if game_started then
			gameweap = registertimer(0, "AssignGameWeapons", player)
		end
	end
end

function OnServerCommand(player, command)
	local allow = nil
	local cmd = tokenizecmdstring(command)
	local tokencount = #cmd
	if tokencount > 0 then

		if cmd[1] == "sv_map_reset" then
			map_reset = true
			ScriptLoad()
			privatesay(player, "**RESET** The game has been reset and scripts reloaded. ")
			if logging then log_msg(1, getname(player) .. " used sv_map_reset command.") end
			for i=0,15 do
				if getplayer(i) then
					privatesay(i, "The game has been reset. ")
				end
			end
			allow = true

		elseif cmd[1] == "sv_script_reload" then
			map_reset = true
			writedword(gametime_base + 0x10, 0)
			ScriptLoad()
			privatesay(player, "**RELOAD** The game has been reset and scripts reloaded. ")
			if logging then log_msg(1, getname(player) .. " used sv_script_reload command.") end
			for i=0,15 do
				if getplayer(i) then
					kill(i)
					privatesay(i, "The game has been reset. ")
				end
			end
			allow = true
		end

	end
	return allow
end

function NewGameTimer(id, count)
	if map_reset == true then
		if team_play and cur_players > 3 then Balance_Teams() end
		map_reset = false
	end

	game_started = true
	team_play = getteamplay()

	if team_play then
		teamscore[0] = 0
		teamscore[1] = 0
		if not game_autobal and game_started and cur_players > 3 then
			game_autobal = registertimer(autobal_delay * 1000, "AutoBalance")
		end
	end

	if Persistent then
		if logging then log_msg(1, "Gun-Game has begun on " .. map_name .. " and running as a persistent script.") end
	else
		if logging then log_msg(1, "Gun-Game has begun on " .. map_name .. " and running as a non-persistent script.") end
	end

	for x = 0,15 do
		if getplayer(x) then
			local ip = getip(x)
			local name = getname(x)
			local m_objectId = getplayerobjectid(x)
			last_damage[ip] = nil
			team_change[x] = false
			beserk = false
			mybattery[x] = 0
			weapons[x] = "weapons\\plasma pistol\\plasma pistol"
			level[x] = 1
			playerscore[x] = 0
			speedtimer = registertimer(0, "SpeedTimer", x)

			if m_objectId ~= nil then
				local m_object = getobject(m_objectId)
				if m_object then
					for i = 0,3 do
						local weapID = readdword(getobject(m_objectId), 0x2F8 + i*4)
						if weapID ~= 0xFFFFFFFF then
							destroyobject(weapID)
						end
					end
					writebyte(m_object + 0x31E, 0)
					writebyte(m_object + 0x31F, 0)
				end

				if level[x] == 1 then
					battery = 0
					weapons[x] = "weapons\\plasma pistol\\plasma pistol"
					sendconsoletext(x, "Plasma Pistol - Level 1", 4, 0)
					if m_object then
						writebyte(m_object + 0x31E, 2)
						writebyte(m_object + 0x31F, 0)
					end
				end

				local m_weaponId = createobject(gettagid("weap", weapons[x]), 0, 20, false, 0, 0, 0)

				if m_weaponId then
					local m_weapon = getobject(m_weaponId)
					if m_weapon then
						assignweapon(x, m_weaponId)
						if logging then log_msg(1, name .. " given plasma pistol on new game.")	end
						if m_weapon then
							mybattery[x] = 1
						end
					end
				end

			end
		end
	end

	if updatescores == nil and game_started then
		updatescores = registertimer(500, "Update_Scores")
	end

	if checkbattery == nil and game_started then
		checkbattery = registertimer(1000, "CheckBattery")
	end

	new_game_timer = nil
	return false
end

function AssignGameWeapons(id, count, player)
	if map_reset == true then
		map_reset = false
	end

	local clip = 0
	local ammo = 9999

	if game_started then
		if getplayer(player) then
			local m_objectId = getplayerobjectid(player)
			local name = getname(player)
			local lvl = level[player]
			local team = getteam(player)

			if m_objectId ~= nil then
				if gametype == 1 or gametype == 2 then
					speedtimer = registertimer(0, "SpeedTimer", player)
				end

				local m_object = getobject(m_objectId)
				if m_object then
					for i = 0,3 do
						local weapID = readdword(getobject(m_objectId), 0x2F8 + i*4)
						if weapID ~= 0xFFFFFFFF then
							destroyobject(weapID)
						end
					end
					writebyte(m_object + 0x31E, 0)
					writebyte(m_object + 0x31F, 0)
				end

				if logging then log_msg(1, name .. " weapon assignment initiated - weapons & nades removed. Is level: " .. lvl) end

				if level[player] == nil then
					level[player] = 1
					weapons[player] = "weapons\\plasma pistol\\plasma pistol"
					sendconsoletext(player, "Level 1:   Plasma Pistol", 4, 0)
					if m_object then
						writebyte(m_object + 0x31E, 1)
						writebyte(m_object + 0x31F, 1)
					end
					if logging then log_msg(1, name .. " given plasma pistol, 1 frag, 1 plasma. Is level: " .. lvl) end

				elseif level[player] == 1 then
					weapons[player] = "weapons\\plasma pistol\\plasma pistol"
					sendconsoletext(player, "Level 1:   Plasma Pistol", 4, 0)
					if m_object then
						writebyte(m_object + 0x31E, 1)
						writebyte(m_object + 0x31F, 1)
					end

					if logging then log_msg(1, name .. " given plasma pistol, 1 frag, 1 plasma. Is level: " .. lvl) end

				elseif level[player] == 2 then
					clip = needler_clip
					weapons[player] = "weapons\\needler\\mp_needler"
					sendconsoletext(player, "Level 2:   Needler", 4, 0)
					if m_object then
						writebyte(m_object + 0x31E, 0)
						writebyte(m_object + 0x31F, 2)
					end
					if logging then log_msg(1, name .. " given needler, active camouflage, 2 plasmas. Is level: " .. lvl) end

				elseif level[player] == 3 then
					clip = shotgun_clip
					weapons[player] = "weapons\\shotgun\\shotgun"
					sendconsoletext(player, "Level 3:   Shotgun", 4, 0)
					health = registertimer(0, "ApplyHP", player)
					if m_object then
						writebyte(m_object + 0x31E, 1)
						writebyte(m_object + 0x31F, 0)
					end
					if logging then log_msg(1, name .. " given shotgun, 1 frag, active camouflage removed. Is level: " .. lvl) end

				elseif level[player] == 4 then
					weapons[player] = "weapons\\plasma rifle\\plasma rifle"
					sendconsoletext(player, "Level 4:   Plasma Rifle", 4, 0)
					if m_object then
						writebyte(m_object + 0x31E, 0)
						writebyte(m_object + 0x31F, 2)
					end
					if logging then log_msg(1, name .. " given plasma rifle, 2 plasmas. Is level: " .. lvl)	end

				elseif level[player] == 5 then
					clip = assault_clip
					weapons[player] = "weapons\\assault rifle\\assault rifle"
					sendconsoletext(player, "Level 5:   Assault Rifle", 4, 0)
					if m_object then
						writebyte(m_object + 0x31E, 1)
						writebyte(m_object + 0x31F, 0)
					end
					if logging then log_msg(1, name .. " given assault rifle, 1 frag. Is level: " .. lvl) end

				elseif level[player] == 6 then
					clip = flame_clip
					weapons[player] = "weapons\\flamethrower\\flamethrower"
					sendconsoletext(player, "Level 6: Flamethrower", 4, 0)
					if logging then log_msg(1, name .. " given flamethrower. Is level: " .. lvl) end

				elseif level[player] == 7 then
					clip = pistol_clip
					weapons[player] = "weapons\\pistol\\pistol"
					sendconsoletext(player, "Level 7:   Pistol", 4, 0)
					if logging then log_msg(1, name .. " given pistol. Is level: " .. lvl) end

				elseif level[player] == 8 then
					clip = rocket_clip
					weapons[player] = "weapons\\rocket launcher\\rocket launcher"
					sendconsoletext(player, "Level 8:   Rocket Launcher", 4, 0)
					health = registertimer(0, "ApplyHP", player)
					if logging then log_msg(1, name .. " given rocket launcher. Is level: " .. lvl) end

				elseif level[player] == 9 then
					clip = sniper_clip
					weapons[player] = "weapons\\sniper rifle\\sniper rifle"
					sendconsoletext(player, "Level 9:   Sniper Rifle", 4, 0)
					if logging then log_msg(1, name .. " given sniper rifle. Is level: " .. lvl) end

				elseif level[player] == 10 then
					weapons[player] = "weapons\\plasma_cannon\\plasma_cannon"
					beserk = true
					sendconsoletext(player, "Level 10:   Plasma Cannon --- FINAL LEVEL! ---", 4, 0)
					say(name .. " has reached level 10! Beserk mode activated! Kill 'em!")
					if logging then log_msg(1, name .. " given plasma cannon and booster function called. Is level: " .. lvl) end

					--Health Booster call for all but level 10
					for i=0,15 do
						if getplayer(i) then
							local name = getname(i)
							local lvl = level[i]
							local p_objectId = getplayerobjectid(i)
							if p_objectId ~= nil then
								if lvl <= 9 then
									local p_object = getobject(p_objectId)
									local obj_health = readfloat(p_object + 0xE0)
									if obj_health < 1 then
										p_objectId = registertimer(6000, "Booster", {i, m_objectId})
									end
								end
							end
						end
					end

				end

				local m_weaponId = createobject(gettagid("weap", weapons[player]), 0, 20, false, 0, 0, 0)

				if m_weaponId then
					local m_weapon = getobject(m_weaponId)
					assignweapon(player, m_weaponId)
					if m_weapon then
						if (level[player] == 1) or (level[player] == 4) or (level[player] == 10) then
							mybattery[player] = 1
						else
							mybattery[player] = 0
							writeword(m_weapon + 0x2B6, ammo)
							writeword(m_weapon + 0x2B8, clip)
							updateammo(m_weaponId)
						end
					end
				end

			end
		end
	end
	return false
end

function CheckBattery(id, count, player)
	-- checks battery level for plasma weapons and assigns replacement if low battery: plasma pistol, plasma rifle and plasma cannon
	for i = 0,15 do
		if getplayer(i) then
			if mybattery[i] == 1 then
				local name = getname(i)
				local lvl = level[i]
				local m_objectId = getplayerobjectid(i)
				if m_objectId ~= nil then
					local m_object = getobject(m_objectId)
					if m_object then
						local m_weaponId = readdword(m_object + 0x118)
						if m_weaponId then
							local m_weapon = getobject(m_weaponId)
							if m_weapon then
								if readfloat(m_weapon + 0x240) >= 0.84 then
									destroyplayerweaps(i)
									replaceplasmaweap = registertimer(0, "ReplacePlasmaWeap", i)
									if logging then log_msg(1, name .. " has a low battery on battery check. Is level: " .. lvl) end
								end
							end
						end
					end
				end
			end
		end
	end
	return true
end

function ReplacePlasmaWeap(id, count, player)
	-- replaces low battery plasma weapons
	if count == 1 then
		if player ~= nil and game_started then
			local name = getname(player)
			local lvl = level[player]
			if mybattery[player] == 1 then
				local m_weaponId = registertimer(0, "AssignGameWeapons", player)
				if logging then log_msg(1, name .. " was given assigment to replace plasma weapon. Is level: " .. lvl) end
				privatesay(player, "Battery recharged.")
				mybattery[player] = 0
			end
		end
	end
	return false
end

function Update_Scores(id, count)
	-- continuous score updating, not conditioned to game_started, updates negative values to 0 to prevent sabotage
	if not team_play then
		for i = 0,15 do
			if getplayer(i) then
				if playerscore[i] == nil or playerscore[i] < 0 then playerscore[i] = 0 end
				Write_Player_Score(i, playerscore[i])
			end
		end
	else
		for i = 0,15 do
			if getplayer(i) then
				if playerscore[i] == nil or playerscore[i] < 0 then playerscore[i] = 0 end
				Write_Player_Score(i, playerscore[i])
			end
		end
		if teamscore[0] == nil or teamscore[0] < 0 then teamscore[0] = 0 end
		if teamscore[1] == nil or teamscore[1] < 0 then teamscore[1] = 0 end
		Write_Team_Score(0, teamscore[0])
		Write_Team_Score(1, teamscore[1])
	end
	return true
end

function Write_Player_Score(player, score)
	-- writes the players score
	if gametype == 1 then
		if player then
			local m_player = getplayer(player)
			writeword(m_player + 0xC8, score)
		end
	elseif gametype == 2 then
		if player then
			writedword(slayer_globals + 0x40 + player*4, score)
		end
	end
end

function Write_Team_Score(team, score)
	-- writes the team score
	if gametype == 1 then
		writedword(ctf_globals + team*4 + 0x10, score)
	elseif gametype == 2 then
		writedword(slayer_globals + team*4, score)
	end
end

function GetGameAddresses(game)
	if game == "PC" or GAME == "PC" then
		map_name = readstring(0x698F21)
		gametype_base = 0x671340
		ctf_globals = 0x639B98
        ctf_score_patch = 0x488602
        ctf_score_patch1 = 0x488606
		slayer_globals = 0x63A0E8
        slayer_score_patch = 0x48F428
    	slayer_score_patch2 = 0x48F23E
		network_base = 0x745BA8
		gametime_base = 0x671420
	else
		map_name = readstring(0x61D151)
		gametype_base = 0x5F5498
		ctf_globals = 0x5BDBB8
		ctf_score_patch = 0x463472
		ctf_score_patch1 = 0x463476
		slayer_globals = 0x5BE108
        slayer_score_patch = 0x469CF8
    	slayer_score_patch2 = 0x4691CE
		network_base = 0x6C7988
		gametime_base = 0x5F55BC
	end
end

function getteamplay()
    if readbyte(gametype_base + 0x34) == 1 then
        return true
	else
        return false
	end
end

function privatesay(player, message, script_prefix)
    if GAME == "PC" then
        phasor_privatesay(player, (script_prefix or default_script_prefix) .. " " .. message, false)
    else
        phasor_privatesay(player, message, false)
    end
end

function say(message, script_prefix)
    if GAME == "PC" then
        phasor_say((script_prefix or default_script_prefix) .. " " .. message, false)
    else
        phasor_say(message, false)
    end
end

function getweaponobjectid(player, slot)
    local m_objectId = getplayerobjectid(player)
    if m_objectId then return readdword(getobject(m_objectId) + 0x2F8 + slot*4) end
end

function destroyplayerweaps(player)
	for i=0,3 do
		local weap_id = getweaponobjectid(player, i)
		if weap_id ~= 0xFFFFFFFF then destroyobject(weap_id) end
	end
end

function Booster(id, count, arg)
	-- heals all players level 9 and below when any other player reaches level 10
	if count == 1 and game_started then
		local player = arg[1]
		if getplayer(player) then
			local name = getname(player)
			local lvl = level[player]
			local m_playerObjId = getplayerobjectid(player)
			if m_playerObjId ~= nil and lvl <= 9 then
				local m_object = getobject(m_playerObjId)
				local obj_health = readfloat(m_object + 0xE0)
				if obj_health < 1 then
					writefloat(m_object + 0xE0, 1)
					sendconsoletext(player, "Bonus! Health restored!", 4, 0)
					if logging then log_msg(1, name .. " health restored from booster function. Is level: " .. lvl) end
				end
			end
		end
	end
	return false
end

function SpeedTimer(id, count, player)
	-- monitors player levels, and sets player speed accordingly. Also sets Beserk Mode speed.
	if player then
		local name = getname(player)
		local lvl = level[player]
		if level[player] == 1 then
			if beserk then
				setspeed(player, 1.5)
				sendconsoletext(player, "BESERK MODE!", 4, 1)
			else
				setspeed(player, 1.45) -- plasma pistol
			end
			if logging then log_msg(1, name .. " speed set at 1.45. Is level: " .. lvl) end
		elseif level[player] == 2 then
			if beserk then
				setspeed(player, 1.5)
				sendconsoletext(player, "BESERK MODE!", 4, 1)
			else
				setspeed(player, 1.35) -- needler
			end
			if logging then log_msg(1, name .. " speed set at 1.35. Is level: " .. lvl) end
		elseif level[player] == 3 then
			if beserk then
				setspeed(player, 1.5)
				sendconsoletext(player, "BESERK MODE!", 4, 1)
			else
				setspeed(player, 1.25) -- shotgun
			end
			if logging then log_msg(1, name .. " speed set at 1.25. Is level: " .. lvl) end
		elseif level[player] == 4 then
			if beserk then
				setspeed(player, 1.5)
				sendconsoletext(player, "BESERK MODE!", 4, 1)
			else
				setspeed(player, 1.15) -- plasma rifle
			end
			if logging then log_msg(1, name .. " speed set at 1.15. Is level: " .. lvl) end
		elseif level[player] == 5 then
			if beserk then
				setspeed(player, 1.5)
				sendconsoletext(player, "BESERK MODE!", 4, 1)
			else
				setspeed(player, 1.15) -- assault rifle
			end
			if logging then log_msg(1, name .. " speed set at 1.15. Is level: " .. lvl) end
		elseif level[player] == 6 then
			if beserk then
				setspeed(player, 1.5)
				sendconsoletext(player, "BESERK MODE!", 4, 1)
			else
				setspeed(player, 1) -- flamethrower
			end
			if logging then log_msg(1, name .. " speed set at 1. Is level: " .. lvl) end
		elseif level[player] == 7 then
			if beserk then
				setspeed(player, 1.5)
				sendconsoletext(player, "BESERK MODE!", 4, 1)
			else
				setspeed(player, 0.85) -- pistol
			end
			if logging then log_msg(1, name .. " speed set at 0.85. Is level: " .. lvl) end
		elseif level[player] == 8 then
			if beserk then
				setspeed(player, 1.5)
				sendconsoletext(player, "BESERK MODE!", 4, 1)
			else
				setspeed(player, 0.65) -- rocket launcher
			end
			if logging then log_msg(1, name .. " speed set at 0.65. Is level: " .. lvl) end
		elseif level[player] == 9 then
			if beserk then
				setspeed(player, 1.5)
				sendconsoletext(player, "BESERK MODE!", 4, 1)
			else
				setspeed(player, 0.75) -- sniper rifle
			end
			if logging then log_msg(1, name .. " speed set at 0.75. Is level: " .. lvl) end
		elseif level[player] == 10 then
			setspeed(player, 0.65) -- plasma cannon
			if logging then log_msg(1, name .. " speed set at 0.65. Is level: " .. lvl) end
		end
	end
	return false
end

function OnServerChat(player, type, message)
	local response = nil

	if player then
		local name = getname(player)

		if string.lower(message) == "help" or string.lower(message) == "@help" or string.lower(message) == "/help" then
			local response = false
			privatesay(player, "Each time you kill with a weapon, you will be given a new weapon.")
			privatesay(player, "The first person to kill with each weapon in the game - wins!")
			privatesay(player, "There are 10 weapons. Starting with plasma pistol and ending with plasma cannon.")
			privatesay(player, "Other weapons, grenades & powerups are blocked. Killing with vehicles blocked.")
			privatesay(player, "If you are on level 10, and get killed, suicide or betray you're demoted one level.")
			say(name .. " is reading the @help menu. ")
			return response
		end

		if string.lower(message) == "balance" then
			Balance_Teams()
			response = false
		end

	end
	return response
end

function OnPlayerKill(killer, victim, mode)
	local response = false

	if game_started then
		mybattery[victim] = 0

		if mode == 0 then -- player was killed by server
			if getplayer(victim) then
				if team_change[victim] then
					response = false
				else
					vlvl = level[victim]
					vname = getname(victim)
					vip = getip(victim)
					privatesay(victim, vname .. " - you were killed by the server.")
					if logging then log_msg(1, vname .. " was killed by the server. Is level: " .. vlvl) end
					response = false
				end
				response = false
			end

		elseif mode == 1 then -- player was killed by falling or team-change
				if getplayer(victim) then
					vlvl = level[victim]
					vname = getname(victim)
					vip = getip(victim)
					if not team_change[victim] and not map_reset then
						if last_damage[vip] == "globals\\distance" or last_damage[vip] == "globals\\falling" then
							say(vname .. " fell and died.")
							if logging then log_msg(1, vname .. " was killed by fall damage. Is level: " .. vlvl) end
							response = false
						end
					elseif team_change[victim] and map_reset then
						team_change[victim] = false
						if logging then log_msg(1, vname .. " was killed by team change. Is level: " .. vlvl) end
						response = false
					end
				end

		elseif mode == 2 then -- player was killed by the guardians
			if getplayer(victim) then
				vlvl = level[victim]
				vname = getname(victim)
				vip = getip(victim)
				say(vname .. " was killed by the guardians. ", false)
				if logging then log_msg(1, vname .. " was killed by guardians. Is level: " .. vlvl) end
				response = false
			end

		elseif mode == 3 then -- player was killed by vehicle
			if getplayer(victim) then
				vlvl = level[victim]
				vname = getname(victim)
				vip = getip(victim)
				say(vname .. " was killed by a vehicle. ")
				if logging then log_msg(1, vname .. " was killed by a vehicle. Is level: " .. vlvl) end
				response = false
			end

		elseif mode == 4 then -- player was killed by another player
			-- killer is not always valid, setup values to prevent error
			if getplayer(killer) then
				klvl = level[killer]
				kname = getname(killer)
				kip = getip(killer)
				kteam = getteam(killer)
			else
				kname = "NULL"
				klvl = NULL
				kteam = -1
			end

			if getplayer(victim) then
				vlvl = level[victim]
				vname = getname(victim)
				vip = getip(victim)
				vteam = getteam(victim)
				if vlvl == 10 then
					beserk = false
					sendconsoletext(victim, "Demoted to Level 9! Ain't that a bitch?!", 4, 0)
					say(vname .. " demoted to Level 9 for getting killed.")
					weapons[victim] = "weapons\\sniper rifle\\sniper rifle"
					level[victim] = 9
					playerscore[victim] = 8
					if team_play then if (teamscore[vteam] - 1) >= 0 then teamscore[vteam] = teamscore[vteam] - 1 end end
					if logging then log_msg(1, vname .. " level 10 demoted to 9 for being killed by another player.") end
					response = false
				end

				if last_damage[vip] then
					if getplayer(killer) then
						klvl = level[killer]
						kname = getname(killer)
						kip = getip(killer)
						kteam = getteam(killer)
						local k_objectId = getplayerobjectid(killer)
						if k_objectId ~= nil then -- sets condition that killer must be alive for the following
							if team_play then kteam = getteam(killer) teamscore[kteam] = teamscore[kteam] + 1 end

							if last_damage[vip] == "weapons\\plasma pistol\\bolt" or last_damage[vip] == "weapons\\plasma rifle\\charged bolt" or last_damage[vip] == "weapons\\plasma pistol\\melee" then
								if weapons[killer] == "weapons\\plasma pistol\\plasma pistol" then
									level[killer] = 2
									playerscore[killer] = 1
									if string.find(last_damage[vip], "melee") then
										say(kname .. " melee'd " .. vname .. " with a plasma pistol")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. "'s melee who is level: " .. klvl) end
									else
										say(kname .. " killed " .. vname .. " with a plasma pistol")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. " who is level: " .. klvl) end
									end
									gameweap = registertimer(0, "AssignGameWeapons", killer)
									response = false
								end

							elseif last_damage[vip] == "weapons\\needler\\detonation damage" or last_damage[vip] == "weapons\\needler\\explosion" or last_damage[vip] == "weapons\\needler\\impact damage" or last_damage[vip] == "weapons\\needler\\melee" then
								if weapons[killer] == "weapons\\needler\\mp_needler" then
									level[killer] = 3
									playerscore[killer] = 2
									if string.find(last_damage[vip], "melee") then
										say(kname .. " melee'd " .. vname .. " with a needler")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. "'s melee who is level: " .. klvl) end
									else
										say(kname .. " killed " .. vname .. " with a needler")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. " who is level: " .. klvl) end
									end
									gameweap = registertimer(0, "AssignGameWeapons", killer)
									response = false
								end

							elseif last_damage[vip] == "weapons\\shotgun\\pellet" or last_damage[vip] == "weapons\\shotgun\\melee" then
								if weapons[killer] == "weapons\\shotgun\\shotgun" then
									level[killer] = 4
									playerscore[killer] = 3
									if string.find(last_damage[vip], "melee") then
										say(kname .. " melee'd " .. vname .. " with a shotgun")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. "'s melee who is level: " .. klvl) end
									else
										say(kname .. " killed " .. vname .. " with a shotgun")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. " who is level: " .. klvl) end
									end
									gameweap = registertimer(0, "AssignGameWeapons", killer)
									response = false
								end

							elseif last_damage[vip] == "weapons\\plasma rifle\\bolt" or last_damage[vip] == "weapons\\plasma rifle\\melee" then
								if weapons[killer] == "weapons\\plasma rifle\\plasma rifle" then
									level[killer] = 5
									playerscore[killer] = 4
									if string.find(last_damage[vip], "melee") then
										say(kname .. " melee'd " .. vname .. " with a plasma rifle")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. "'s melee who is level: " .. klvl) end
									else
										say(kname .. " killed " .. vname .. " with a plasma rifle")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. " who is level: " .. klvl) end
									end
									gameweap = registertimer(0, "AssignGameWeapons", killer)
									response = false
								end

							elseif last_damage[vip] == "weapons\\assault rifle\\bullet" or last_damage[vip] == "weapons\\assault rifle\\melee" then
								if weapons[killer] == "weapons\\assault rifle\\assault rifle" then
									level[killer] = 6
									playerscore[killer] = 5
									if string.find(last_damage[vip], "melee") then
										say(kname .. " melee'd " .. vname .. " with an assault rifle")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. "'s melee who is level: " .. klvl) end
									else
										say(kname .. " killed " .. vname .. " with an assault rifle")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. " who is level: " .. klvl) end
									end
									gameweap = registertimer(0, "AssignGameWeapons", killer)
									response = false
								end

							elseif last_damage[vip] == "weapons\\flamethrower\\burning" or last_damage[vip] == "weapons\\flamethrower\\explosion" or last_damage[vip] == "weapons\\flamethrower\\impact damage" or last_damage[vip] == "weapons\\flamethrower\\melee" then
								if weapons[killer] == "weapons\\flamethrower\\flamethrower" then
									level[killer] = 7
									playerscore[killer] = 6
									if string.find(last_damage[vip], "melee") then
										say(kname .. " melee'd " .. vname .. " with a flamethrower")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. "'s melee who is level: " .. klvl) end
									else
										say(kname .. " killed " .. vname .. " with a flamethrower")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. " who is level: " .. klvl) end
									end
									gameweap = registertimer(0, "AssignGameWeapons", killer)
									response = false
								end

							elseif last_damage[vip] == "weapons\\pistol\\bullet" or last_damage[vip] == "weapons\\pistol\\melee" then
								if weapons[killer] == "weapons\\pistol\\pistol" then
									level[killer] = 8
									playerscore[killer] = 7
									if string.find(last_damage[vip], "melee") then
										say(kname .. " melee'd " .. vname .. " with a pistol")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. "'s melee who is level: " .. klvl) end
									else
										say(kname .. " killed " .. vname .. " with a pistol")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. " who is level: " .. klvl) end
									end
									gameweap = registertimer(0, "AssignGameWeapons", killer)
									response = false
								end

							elseif last_damage[vip] == "weapons\\rocket launcher\\explosion" or last_damage[vip] == "weapons\\rocket launcher\\melee" then
								if weapons[killer] == "weapons\\rocket launcher\\rocket launcher" then
									if isinvehicle(killer) then
										say(kname .. " killed " .. vname .. " with a warthog rocket")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. " who is level: " .. klvl .. " was vehicle rocket, no advance.") end
									else
										level[killer] = 9
										playerscore[killer] = 8
										if string.find(last_damage[vip], "melee") then
											say(kname .. " melee'd " .. vname .. " with a rocket launcher")
											if logging then log_msg(1, vname .. " was killed by " .. kname .. "'s melee who is level: " .. klvl) end
										else
											say(kname .. " killed " .. vname .. " with a rocket launcher")
											if logging then log_msg(1, vname .. " was killed by " .. kname .. " who is level: " .. klvl) end
										end
										gameweap = registertimer(0, "AssignGameWeapons", killer)
										response = false
									end
								end

							elseif last_damage[vip] == "weapons\\sniper rifle\\sniper bullet" or last_damage[vip] == "weapons\\sniper rifle\\melee" then
								if weapons[killer] == "weapons\\sniper rifle\\sniper rifle" then
									level[killer] = 10
									playerscore[killer] = 9
									beserk = true
									for i=0,15 do
										if getplayer(i) then
											speedtimer = registertimer(0, "SpeedTimer", i)
										end
									end
									if string.find(last_damage[vip], "melee") then
										say(kname .. " melee'd " .. vname .. " with a sniper rifle, advanced to Level 10!")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. "'s melee who is level: " .. klvl) end
									else
										say(kname .. " killed " .. vname .. " with a sniper rifle, advanced to Level 10!")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. " who is level: " .. klvl) end
									end
									gameweap = registertimer(0, "AssignGameWeapons", killer)
									response = false
								end

							elseif last_damage[vip] == "weapons\\plasma_cannon\\effects\\plasma_cannon_explosion" or last_damage[vip] == "weapons\\plasma_cannon\\effects\\plasma_cannon_melee" then
								if weapons[killer] == "weapons\\plasma_cannon\\plasma_cannon" then
									level[killer] = 11
									playerscore[killer] = playerscore[killer] + 11
									if team_play then kteam = getteam(killer) teamscore[kteam] = teamscore[kteam] + 11 end
									beserk = false
									if string.find(last_damage[vip], "melee") then
										say(kname .. " melee'd " .. vname .. " with a plasma cannon, advanced to WIN! +10 Points")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. "'s melee who is level: " .. klvl) end
									else
										say(kname .. " killed " .. vname .. " with a plasma cannon, advanced to WIN! +10 Points")
										if logging then log_msg(1, vname .. " was killed by " .. kname .. " who is level: " .. klvl) end
									end
									response = false
								end

							elseif last_damage[vip] == "weapons\\plasma grenade\\explosion" or last_damage[vip] == "weapons\\frag grenade\\explosion" then
								say(kname .. " killed " .. vname .. " with a grenade.")
								sendconsoletext(killer, "No level advancement for grenade kills.", 4, 0)
								if logging then log_msg(1, vname .. " was killed by " .. kname .. "'s grenade who is level: " .. klvl) end
								response = false
							end
						else
							response = false
						end
					end
				end
			end

		elseif mode == 5 then -- player was killed/betrayed by teammate
			if getplayer(killer) then
				klvl = level[killer]
				kname = getname(killer)
				kip = getip(killer)
				kteam = getteam(killer)
			else
				kname = "NULL"
				klvl = NULL
				kteam = -1
			end

			if getplayer(victim) then
				vlvl = level[victim]
				vname = getname(victim)
				vip = getip(victim)
				vteam = getteam(victim)
				if getplayer(killer) then
					klvl = level[killer]
					kname = getname(killer)
					kip = getip(killer)
					kteam = getteam(killer)
					mybattery[killer] = 0
					if level[killer] ~= nil and level[killer] > 1 then
						if (level[killer] - 1) >= 1 then level[killer] = level[killer] - 1 end
						if (playerscore[killer] - 1) >= 0 then playerscore[killer] = playerscore[killer] - 1 end
						if team_play then if (teamscore[kteam] - 1) >= 0 then teamscore[kteam] = teamscore[kteam] - 1 end end
						mybattery[killer] = 0
						kill(killer)
						say(kname .. " was demoted one level and killed for betraying " .. vname)
						if logging then log_msg(1, kname .. " was killed by server for betrayal of " .. vname) end
						response = false
					else
						kill(killer)
						say(kname .. " was killed for betraying " .. vname)
						if logging then log_msg(1, kname .. " was killed by server for betrayal of " .. vname) end
						response = false
					end
					response = false
				end
				response = false
			end

		elseif mode == 6 then --suicides - killer is self/victim
			if getplayer(victim) then
				vlvl = level[victim]
				vname = getname(victim)
				vip = getip(victim)
				vteam = getteam(victim)
				if vlvl == 10 then
					level[victim] = 9
					playerscore[victim] = 8
					beserk = false
					weapons[victim] = "weapons\\sniper rifle\\sniper rifle"
					sendconsoletext(victim, "Demoted to Level 9! Ain't that a bitch?!", 4, 0)
					say(vname .. " demoted to Level 9 for suicide.")
					if logging then log_msg(1, vname .. " demoted from level 10 to 9 for suicide. Is level: " .. vlvl) end
					response = false
				end
				if level[victim] ~= nil and level[victim] > 1 then
					if (level[victim] - 1) >= 1 then level[victim] = level[victim] - 1 end
					if (playerscore[victim] - 1) >= 0 then playerscore[victim] = playerscore[victim] - 1 end
					if team_play then if (teamscore[vteam] - 1) >= 0 then teamscore[vteam] = teamscore[vteam] - 1 end end
					say(vname .. " committed suicide and was demoted one level.")
					if logging then log_msg(1, vname .. " demoted one level for suicide. Is level: " .. vlvl) end
					response = false
				else
					say(vname .. " committed suicide.")
					response = false
				end
				response = false
			end
		end
	end

	return response
end

function OnVehicleEntry(player, veh_id, seat, mapid, relevant)
	if getplayer(player) then
		privatesay(player, getname(player) .. " NOTE: You can't kill players with vehicle or vehicle guns.")
	end
	return nil
end

function OnDamageApplication(receiving, causing, tagid, hit, backtap)
	-- sets the last damage value for all players, used to determine how a player was damaged and with which weapon
	if receiving then
		local r_object = getobject(receiving)
		if r_object then
			local receiver = objectaddrtoplayer(r_object)
			if receiver then
				local rip = getip(receiver)
				local tagname,tagtype = gettaginfo(tagid)
				last_damage[rip] = tagname
			end
		end
	end
	return nil
end

function OnDamageLookup(receiving, causing, tagid)
	-- looks up and sets damage variables
	if receiving and causing and receiving ~= causing then
		local tagname, tagtype = gettaginfo(tagid)
		local melee = string.find(tagname, "melee")
		local ppistolc = string.find(tagname, "weapons\\plasma rifle\\charged bolt")
		local ppistolb = string.find(tagname, "weapons\\plasma pistol\\bolt")
		local needlerd = string.find(tagname, "weapons\\needler\\detonation damage")
		local plasrifle = string.find(tagname, "weapons\\plasma rifle\\bolt")
		local c_player = objectidtoplayer(causing)
		local r_player = objectidtoplayer(receiving)
		-- block vehicle and vehicle gun damage
		if c_player and isinvehicle(c_player) then
			local m_vehicleId = getplayervehicleid(c_player)
			if m_vehicleId then
				local m_vehicle = getobject(m_vehicleId)
				local gunner = readdword(m_vehicle + 0x328)
				local driver = readdword(m_vehicle + 0x324)
				if gunner == causing then
					return false
				elseif driver == causing then
					return false
				end
			end
		end
		-- increase damage of melee to instant kill, increase plasma pistol, needler and plasma rifle to balance game play
    	if c_player and r_player then
			if melee then odl_multiplier(9999) end
			if ppistolc then odl_multiplier(1.85) end
			if ppistolb then odl_multiplier(1.85) end
			if needlerd then odl_multiplier(1.75) end
			if plasrifle then odl_multiplier(1.35) end
		end
	end
	return nil
end

function getplayervehicleid(player)
    local m_objectId = getplayerobjectid(player)
    if m_objectId then return readdword(getobject(m_objectId) + 0x11C) end
end

function OnObjectInteraction(player, objId, mapId)
	-- blocks players from picking up weapons and nades
	local Pass = nil
	local name, type = gettaginfo(mapId)
	if type == "weap" then
		if weapons[player] ~= nil then
			if name ~= weapons[player] then
				Pass = false
			end
		end
	elseif type == "eqip" then
		if name == "powerups\\over shield" or name == "powerups\\health pack" then
			Pass = true
		else
			Pass = false
		end
	end
	return Pass
end

function ApplyHP(id, count, player)
	-- restores players health, called when a player reaches levels 3 and 8
	if count == 1 then
		if player and game_started then
			local name = getname(player)
			local lvl = level[player]
			local m_playerObjId = getplayerobjectid(player)
			if m_playerObjId ~= nil then
				local m_object = getobject(m_playerObjId)
				local obj_health = readfloat(m_object + 0xE0)
				if obj_health < 1 then
					writefloat(m_object + 0xE0, 1)
					sendconsoletext(player, "Bonus: Your health has been restored.", 4, 0)
					if logging then log_msg(1, name .. " Health Bonus applied. Is Level: " .. lvl) end
				end
			end
		end
	end
	return false
end

function OnObjectCreationAttempt(mapId, parentId, player)
	local response = nil
	if game_started then
		-- blocks creation of these items when game starts, only if game_started is valid (after script load, after new game)
		if mapId == gettagid("weap", "weapons\\ball\\ball") or
			mapId == gettagid("eqip", "weapons\\frag grenade\\frag grenade") or
			mapId == gettagid("eqip", "weapons\\plasma grenade\\plasma grenade") then
			response = false
		end
		if mapId == gettagid("weap", "weapons\\flag\\flag") then
			return gettagid("weap", "weapons\\plasma pistol\\plasma pistol")
		end
		if mapId == gettagid("eqip", "powerups\\active camouflage") then
			return gettagid("eqip", "powerups\\over shield")
		end
	elseif not game_started then
		-- allows creation of these items when game starts or on script load
		if mapId == gettagid("eqip", "powerups\\full-spectrum vision") or
			mapId == gettagid("eqip", "powerups\\health pack") or
			mapId == gettagid("bipd", "characters\\cyborg_mp\\cyborg_mp") or
			mapId == gettagid("vehi", "vehicles\\warthog\\mp_warthog") or
			mapId == gettagid("vehi", "vehicles\\rwarthog\\rwarthog") or
			mapId == gettagid("vehi", "vehicles\\ghost\\ghost_mp") or
			mapId == gettagid("vehi", "vehicles\\c gun turret\\c gun turret_mp") or
			mapId == gettagid("vehi", "vehicles\\scorpion\\scorpion_mp") then
			response = true
		end
		-- blocks creation of these items when game starts, when game is restarted, or scripts reloaded
		if mapId == gettagid("weap", "weapons\\ball\\ball") or
			mapId == gettagid("eqip", "weapons\\frag grenade\\frag grenade") or
			mapId == gettagid("eqip", "weapons\\plasma grenade\\plasma grenade") then
			response = false
		end
		if mapId == gettagid("weap", "weapons\\flag\\flag") then
			return gettagid("weap", "weapons\\plasma pistol\\plasma pistol")
		end
		if mapId == gettagid("eqip", "powerups\\active camouflage") then
			return gettagid("eqip", "powerups\\over shield")
		end
	else
		response = false
	end
	return response
end

function OnClientUpdate(player)
	if getplayer(player) then
		local lvl = level[player]
		if lvl ~= nil then
			-- monitors and initiates game win announcement
			if lvl == 11 and game_started then
				game_started = false
				announcewin = registertimer(0, "AnnounceWin", player)
				if logging then log_msg(1, "Game win detected - Announcement called.") end
			end
		end
	end
end

function AnnounceWin(id, count, player)
	-- announces game winner
	if player and game_started == false then
		local name = getname(player)
		svcmd("sv_map_next")
		if not team_play then
			say(name .. " WINS THE GAME! ")
		else
			local team = getteam(player)
			if team == 0 then team = "RED TEAM" elseif team == 1 then team = "BLUE TEAM" end
			say(name .. " OF " .. team .. " WINS THE GAME! ")
		end
		log_msg(1, name .. " has won the Gun-Game on " .. map_name .. "!")
	end
	return false
end

function OnTeamChange(player, old_team, new_team, relevant)
	-- prevent unbalancing teams by team change
	local response = nil
	if getplayer(player) then

		local newteam = "New Team"
		local oldteam = "Old Team"

		if not team_play then response = false return response end

		if new_team == 0 then
			oldteam = "Blue Team"
			newteam = "Red Team"
		elseif new_team == 1 then
			oldteam = "Red Team"
			newteam = "Blue Team"
		end

		if relevant == true or relevant == 1 then
			if getteamsize(old_team) == getteamsize(new_team) then
				privatesay(player, "You cannot change teams.")
				response = false
			elseif getteamsize(old_team) + 1 == getteamsize(new_team) then
				privatesay(player, "You cannot change teams.")
				response = false
			elseif getteamsize(old_team) == getteamsize(new_team) + 1 then
				privatesay(player, "You cannot change teams.")
				response = false
			elseif getteamsize(old_team) > getteamsize(new_team) then
				team_change[player] = true
				-- transfer player score to new team score, and deduct new player score from old team score
				if team_play then
					teamscore[new_team] = teamscore[new_team] + playerscore[player]
					teamscore[old_team] = teamscore[old_team] - playerscore[player]
				end
				mybattery[player] = 0
				say(getname(player) .. " switched to the "  .. newteam)
				response = true
			elseif getteamsize(old_team) < getteamsize(new_team) then
				team_change[player] = true
				-- transfer player score to new team score, and deduct new player score from old team score
				if team_play then
					teamscore[new_team] = teamscore[new_team] + playerscore[player]
					teamscore[old_team] = teamscore[old_team] - playerscore[player]
				end
				mybattery[player] = 0
				say(getname(player) .. " switched to the "  .. newteam)
				response = true
			end
		elseif relevant == false or relevant == 0 then
			team_change[player] = true
			-- transfer player score to new team score, and deduct new player score from old team score
			if team_play then
				teamscore[new_team] = teamscore[new_team] + playerscore[player]
				teamscore[old_team] = teamscore[old_team] - playerscore[player]
			end
			mybattery[player] = 0
			say(getname(player) .. " was team-switched to balance the teams.")
			response = true
		end

	end
	return response
end

function AutoBalance(id, count)
	Balance_Teams()
	if game_started and team_play and cur_players > 3 then
		return true
	else
		return false
	end
end

function AutoBalance(id, count)
	if game_started and team_play and cur_players > 3 then
		Balance_Teams()
		if join_autobal then join_autobal = nil end
		if leave_autobal then leave_autobal = nil end
		return true
	elseif game_started and team_play and cur_players < 4 then
		return false
	else
		return false
	end
end

-- inspired by 002's team balance for Sapp
function Balance_Teams()
	if game_started and team_play then
		local redteam = getteamsize(0)
		local blueteam = getteamsize(1)
		if redteam > blueteam then
			while TeamsAreUneven() do
				while (getteamsize(0) > getteamsize(1)+1) do
					local randomred = SelectPlayer(0)
					if randomred ~= nil then
						changeteam(randomred, true)
					end
				end
			end
		elseif blueteam > redteam then
			while TeamsAreUneven() do
				while (getteamsize(1) > getteamsize(0)+1) do
					local randomblu = SelectPlayer(1)
					if randomblu ~= nil then
						changeteam(randomblu, true)
					end
				end
			end
		end
	end
end

-- inspired by 002's team balance for Sapp
function TeamsAreUneven()
    local red = getteamsize(0)
    local blue = getteamsize(1)
    if (red > blue + 1 or blue > red + 1) then return true end
    return false
end

function SelectPlayer(team)
	local t = {}
	for i=0,15 do
		if getplayer(i) and getteam(i) == team then
			table.insert(t, i)
		end
	end
	if #t > 0 then
		local r = getrandomnumber(1, #t+1)
		return t[r]
	end
	return nil
end

function OnGameEnd(stage)
	-- terminate or nil timers, set game values.  Some timers cannot be removed, instead they are nil'd
	if stage == 1 then
		game_started = false
		beserk = false
		if gameweap then
			gameweap = nil
		end
		if announcewin then
			announcewin = nil
		end
		if m_weaponId then
			m_weaponId = nil
		end
		if replaceplasmaweap then
			replaceplasmaweap = nil
		end
		if p_objectId then
			p_objectId = nil
		end
		if health then
			health = nil
		end
		if welcome then
			welcome = nil
		end
		if speedtimer then
			speedtimer = nil
		end
		if checkbattery then
			checkbattery = nil
		end
		if updatescores then
			updatescores = nil
		end
		if consoletimer then
			consoletimer = nil
		end
		if game_autobal then
			game_autobal = nil
		end
		if join_autobal then
			join_autobal = nil
		end
		if leave_autobal then
			leave_autobal = nil
		end
	elseif stage == 3 then
		for i = 0, 15 do
			if getplayer(i) then
				privatesay(i, "Thank you for playing the Gun-Game Arms Race!")
				privatesay(i, "This and other scripts available on HaloRace.org")
			end
		end
	end
end

-- -------------------------------------------------------------------------
-- Start sendconsoletext overloaded by Nugget
console = {}
console.__index = console
consoletimer = registertimer(100, "ConsoleTimer")
phasor_sendconsoletext = sendconsoletext

function sendconsoletext(player, message, time, order, align, height, func)
	if player then
		console[player] = console[player] or {}
		local temp = {}
		temp.player = player
		temp.id = nextid(player, order)
		temp.message = message or ""
		temp.time = time or 0.7
		temp.remain = temp.time
		temp.align = align or "left"
		temp.height = height or 0
		if type(func) == "function" then
			temp.func = func
		elseif type(func) == "string" then
			temp.func = _G[func]
		end
		console[player][temp.id] = temp
		setmetatable(console[player][temp.id], console)
		return console[player][temp.id]
	end
end

function nextid(player, order)
	if not order then
		local x = 0
		for k,v in pairs(console[player]) do
			if k > x + 1 then
				return x + 1
			end

			x = x + 1
		end
		return x + 1
	else
		local original = order
		while console[player][order] do
			order = order + 0.001
			if order == original + 0.999 then break end
		end
		return order
	end
end

function getmessage(player, order)
	if console[player] then
		if order then
			return console[player][order]
		end
	end
end

function getmessages(player)
	return console[player]
end

function getmessageblock(player, order)
	local temp = {}
	for k,v in opairs(console[player]) do
		if k >= order and k < order + 1 then
			table.insert(temp, console[player][k])
		end
	end
	return temp
end

function console:getmessage()
	return self.message
end

function console:append(message, reset)
	if console[self.player] then
		if console[self.player][self.id] then
			if getplayer(self.player) then
				if reset then
					if reset == true then
						console[self.player][self.id].remain = console[self.player][self.id].time
					elseif tonumber(reset) then
						console[self.player][self.id].time = tonumber(reset)
						console[self.player][self.id].remain = tonumber(reset)
					end
				end

				console[self.player][self.id].message = message or ""
				return true
			end
		end
	end
end

function console:shift(order)
	local temp = console[self.player][self.id]
	console[self.player][self.id] = console[self.player][order]
	console[self.player][order] = temp
end

function console:pause(time)
	console[self.player][self.id].pausetime = time or 5
end

function console:delete()
	console[self.player][self.id] = nil
end

function ConsoleTimer(id, count)
	for i,_ in opairs(console) do
		if tonumber(i) then
			if getplayer(i) then
				for k,v in opairs(console[i]) do
					if console[i][k].pausetime then
						console[i][k].pausetime = console[i][k].pausetime - 0.1
						if console[i][k].pausetime <= 0 then
							console[i][k].pausetime = nil
						end
					else
						if console[i][k].func then
							if not console[i][k].func(i) then
								console[i][k] = nil
							end
						end
						if console[i][k] then
							console[i][k].remain = console[i][k].remain - 0.1
							if console[i][k].remain <= 0 then
								console[i][k] = nil
							end
						end
					end
				end
				if table.len(console[i]) > 0 then
					local paused = 0
					for k,v in pairs(console[i]) do
						if console[i][k].pausetime then
							paused = paused + 1
						end
					end
					if paused < table.len(console[i]) then
						local str = ""
						for i = 0,30 do
							str = str .. " \n"
						end
						phasor_sendconsoletext(i, str)
						for k,v in opairs(console[i]) do
							if not console[i][k].pausetime then
								if console[i][k].align == "right" or console[i][k].align == "center" then
									phasor_sendconsoletext(i, consolecenter(string.sub(console[i][k].message, 1, 78)))
								else
									phasor_sendconsoletext(i, string.sub(console[i][k].message, 1, 78))
								end
							end
					    end
					end
				end
			else
				console[i] = nil
			end
		end
	end
	return true
end

function consolecenter(text)
	if text then
		local len = string.len(text)
		for i = len + 1, 78 do
			text = " " .. text
		end
		return text
	end
end

function opairs(t)
	local keys = {}
	for k,v in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys,
	function(a,b)
		if type(a) == "number" and type(b) == "number" then
			return a < b
		end
		an = string.lower(tostring(a))
		bn = string.lower(tostring(b))
		if an ~= bn then
			return an < bn
		else
			return tostring(a) < tostring(b)
		end
	end)
	local count = 1
	return function()
		if table.unpack(keys) then
			local key = keys[count]
			local value = t[key]
			count = count + 1
			return key,value
		end
	end
end

function table.len(t)
	local count = 0
	for k,v in pairs(t) do
		count = count + 1
	end
	return count
end

--[[ Created by H® Shaft.
Thanks to Oxide, AelitePrime, Nugget & Wizard.
Visit http://halorace.org/forum/index.php?topic=514.0 or
Visit http://pastebin.com/u/HR_Shaft for more phasor scripts
Special thanks to AelitePrime, as this was an attempt to script patterned after his style similar to his Zombie script 4.1, and other scripts we have mutually developed.
Note: This was written and developed by H® Shaft prior to the release of any other similar script with similar names. Any claims of duplication of concept/script are 100% bullpucky.

Special thanks to our beta testers, server hosts & contributors:
H® HUMMER, H® BugZ, H® Monkey, H® Wingnut, H® LoLLi, H® Stone, H® RUDE, H® Outage, H® Griff, -JR- Mumbler, -JR- RAVIN,
-JR-Hollypaw, -JR- Slayer, -JR- Falx, -JR- Spec4, -JR- Slayer, -JR-wraith, AR~Dvs_One, -JR-ÄÐhè®é,  AR~Hazy,
AR~Un¡t»Zero, AR~Hanabal, AR~DSPFlag, AR~HiroP, AR~Archon, Forseti, Mastermind, [x] fisk, ²MõD²Wrath, ²MõD²Corvair,
²MõD²Bear, ²MõD²Buster, «§H»Kennan, Telyx, Lobo, Awesome, Nugget, Wizard, particleboy, PÕQ clan, {ØZ} clan, Skylace,
A§H» clan, Ponyboy and the Ousiders, PÕQ~Technut, smiley, Btcc22, Roger W, sehé°°, kornman00, Geomitar]]

--[[ SERVER SETUP - USAGE:
Compatible with CTF & Slayer gametypes only - 'Standard' PC & CE Maps and custom maps with classic weapon sets. Not compatible with race, oddball or koth gametypes, or custom named weapons CE maps.
Gametype should set weapons to normal/generic, infinite nades off.
Place in your cg/scripts/persistent folder.  Intended to be used as a persisitent script, but not required.
DO NOT combine with other death message/player kill scripts during this game.
Use of server rcon commands sv_map_reset and sv_script_reload are allowed, and function well with no errors.  Reloading will behave similar to resetting.
Extended game logging best used for tournaments/scrims/ or debugging.  If you choose to customize this script, set logging to true to help you.
This script has been rigorously tested and believed to be error free. If you get errors, try running the script by itself, it could conflict with other scripts. Set logging to true on lines 29 and 98 to help you debug then read the logs
If help is needed, message me on phasor.proboards.com, or on www.HaloRace.org, or xfire: nervebooger2012
Thank you, I hope you enjoy this as much as we have on our PC and CE servers.
Visit us at http://halorace.org/forum/index.php
]]
