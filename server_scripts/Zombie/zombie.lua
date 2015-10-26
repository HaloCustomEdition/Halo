-- Zombies For Sapp 9.0+
-- Script made by: Skylace aka Devieth
-- Website: bud.boards.net

-- Full Public Version 1.2

-- Welcome to the server
welcome_msg_enabled = true -- Enable or disable welcome message.
welcome_msg = "Welcome to zombies by Devieth!" -- ;) Want to let them know who made the script???

-- Team settings
human_team = "red" -- You can fully swapp teams colors via name (only red and blue) but I haven't tested to make sure it works. :P
zombie_team = "blue"

-- Spawn Timers (in seconds.)
human_spawn_time = 3
zombie_spawn_time = 0

-- Speed settings (boost speed is activated when players hit their flashlight key.)
human_speed = 1 -- Default human speed.
human_boost_speed = 1.75 -- Speed humans will have if they use their flashlight.
last_man_speed = 1.5 -- Default last man speed.
last_man_boost_speed = 2.25 -- Speed last man will have if they use their flashlight.
zombie_speed = 1.75 -- Default zombie speed.
zombie_boost_speed = 2.25 -- Speed zombies will have if they use their flashlight.
speed_boost_time = 3 -- If you use 2.5 or anything other then a whole number it will just round the next even number. Ex: 2.2 hahah!! Nope thats 3 seconds sorry had to do this cause sapp is retarded.

-- Lastman settings
last_man_ammo = 200 -- Unloaded ammo
last_man_mag = 200 -- Loaded ammo
last_man_camo_time = 20 -- How long does the last man get camoflage? (In seconds.)

-- Weapon(s)
zombie_weapon = "weapons\\ball\\ball" -- Weapon that zombies will spawn with (Donnot use ball or flag as I have not found out how to force players to pick them back up correctly.)

-- Scoring
human_score_per_second = 0.2 -- Score a human gets every time the score_timer is called.
zombie_score_per_second = 0.1 -- Score a zombie gets every time the score_timer is called.
human_score_per_kill = 5 -- For each kill they get + 1 score.
zombie_score_per_kill = 15 -- For each infect they get + 5 score.

-- Messages (Spaces not required before and after "" marks.
infected_msg = "has been infected!"
suicide_msg = "couldn't take the pressure!"
human_msg = "You are a human!!! Protect yourself from the zombies."
zombie_msg = "You are a zombie!!! Go eat BRAINZ!!!"
nozombies_msg = "There are no zombies left! A random player will be picked in"
lastman_msg = "is the last person alive!! Find them and eat their BRAINZ!!"
end_msg = "The last human has been infected!!! The game will now end..."
zombie_needs_help_msg = "Seems like the zombie needs some help. Picking a random player to be a zombie!"

-- Misc
afk_zombie_kills = 0 -- We are assuming an afk zombie would have 0 kills.
afk_zombie_deaths = 5 -- How many deaths to be confermed afk and create a new zombie.
human_again_kills = 4 -- Kills a zombie must get to become human.

-- Bools
disable_vehicles = true -- Enables or disables vehicles.
zombies_invis_on_crouch = true -- Enables or disables zombies becoming invisable when they crouch.
human_again_enabled = true -- Enables or disables the ability to become human again after human_again_kills is reached.
disable_os_for_humans = true -- Enables or disables OS for humans.
humans_spawn_on_death_loc = false -- Enables or disabled players becoming zombies spawning where they where infected.

--------------------------------------------------------------------------------------
-- Don't touch anything below this point ---- Don't touch anything below this point --
--------------------------------------------------------------------------------------

speed = {}
speed_current = {}
zkills = {}
fail_safe_speed = {}
human_again = {}
score = {}
gamescore = {}
deathcoords = {}
spawnondeathcoords = {}
zombieweapid = {}

human_count = 0
zombie_count = 0
player_count = 0

count = 0
other_count = 0
rand_max = 0

api_version = "1.6.0.0"

function OnScriptLoad()
	loadgamesettings()
	score = tableload("score.data")
	register_callback(cb['EVENT_GAME_START'], "OnGameStart")
	register_callback(cb['EVENT_GAME_END'], "OnScriptUnload")
	register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
	register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
   	register_callback(cb['EVENT_SPAWN'], "OnPlayerSpawn")
	register_callback(cb['EVENT_ALIVE'], "OnPlayerAlive")
	register_callback(cb['EVENT_DIE'], "OnPlayerDeath")
	register_callback(cb['EVENT_SUICIDE'], "OnPlayerSuicide")
	register_callback(cb['EVENT_WEAPON_DROP'], "OnWeaponDrop")
	register_callback(cb['EVENT_TICK'], "OnEventTick")
	register_callback(cb['EVENT_CHAT'], "OnPlayerChat")
	timer(1000, "applyscorepersistent")
	allow_getrandplayer = true
end

function OnPlayerChat(PlayerIndex, Message)
	local msg = string.lower(Message)
	local allow_chat = true
	if msg == "/stats" or msg == "\\stats" or msg == "\\score" or msg == "/score" or msg == "\\cr" or msg == "/cr" then
		if msg == "\\score" or msg == "/score" or msg == "\\cr" or msg == "/cr" then
			timer(10, "delayscoredisplay", PlayerIndex)
			allow_chat = false
		else
			timer(10, "delayscoredisplay", PlayerIndex)
		end
	end
	return allow_chat
end

function delayscoredisplay(PlayerIndex)
	if score[getname(PlayerIndex)] then else score[getname(PlayerIndex)] = 0 end
	say(PlayerIndex, "Your score is: " .. math.floor(tonumber(score[getname(PlayerIndex)])))
end

function OnGameStart()
	local gametype = get_var(1, "$gt")

	if halo_type == "PC" then
		ctf_globals = 0x639B98
		flags_pointer = 0x6A590C
	else
		ctf_globals = 0x5BDBB8
	end

	if gametype == "CTF" and halo_type == "PC" then
		safe_read(true)
		safe_write(true)
		local flags_table_base = read_dword(flags_pointer)
		local flags_count = read_dword(flags_table_base + 0x378)
		local flags_table_address = read_dword(flags_table_base + 0x37C)
		for i = 0,flags_count do
			flag_address = flags_table_address + i * 148
			flag_z_coord = write_float(flag_address + 0x8, -100)
		end
		safe_write(false)
		safe_read(false)
	end

	newgametimercalled = false
	gamestarted = false
	onlastmanactive = false
	map_reset = false
	allow_getrandplayer = true
	score = tableload("score.data")

	local tag_address = read_dword(0x40440000)
	local tag_count = read_word(0x4044000C)

	for i=0,tag_count-1 do
		local tag = tag_address + i * 0x20
		if(read_dword(tag) == 1785754657) then -- if jpt!.
			local tag_data = read_dword(tag + 0x14)
			if(read_word(tag_data + 0x1C6) == 6) then -- if damage category is melee
				write_float(tag_data + 0x1D0, 999)
				write_float(tag_data + 0x1D4, 999)
				write_float(tag_data + 0x1D8, 999)
				--write_float(tagdata + 0x1F4, 999)
				write_float(tag_data + 0x1DC, 1) -- Makes it so they can damage people inside vehicles with melees
			end
		end
	end

end

function OnScriptUnload()
	gamestarted = false
	onlastmanactive = false
	tablesave(score, "score.data")
end

function OnPlayerJoin(PlayerIndex)
	if welcome_msg_enabled then
		say(PlayerIndex, welcome_msg)
	end
	spawnondeathcoords[getname(PlayerIndex)] = false
	gamescore[getname(PlayerIndex)] = 0
	speed[PlayerIndex] = false
	speed_current[PlayerIndex] = false
	zombieweapid[getname(PlayerIndex)] = nil
	if not gamestarted then
		setteam(PlayerIndex, human_team, false) -- Makes everyone a human if the game hasn't been started.
		local humans, zombies, players = getteamsizes(PlayerIndex)
		if tonumber(players) > 1 then -- If there is more then one player in the server then the game can start.
			if not newgametimercalled then
				timer(1500, "newgametimer")
				newgametimercalled = true
			end
		else
			say(PlayerIndex, "Please wait for another player to join...") -- This will always be said to the first player to connect.
		end
	else
		timer(1000, "checkgamestate", PlayerIndex)
		setteam(PlayerIndex, zombie_team, true) -- Game is started sets new players to the zombie team.
	end
	if not onlastmanactive then
		takenavsaway() -- Make sure that the navs for joining players are above their head.
	end
end

function OnPlayerLeave(PlayerIndex)
	timer(1000, "checkgamestate", PlayerIndex)
end

function OnPlayerSpawn(PlayerIndex)
	timer(1000, "checkgamestate", PlayerIndex)
	local humans, zombies, players = getteamsizes(PlayerIndex)
	speed[PlayerIndex] = false
	speed_current[PlayerIndex] = false
	fail_safe_speed[PlayerIndex] = 0
	zkills[getname(PlayerIndex)] = 0
	if gamestarted then
		if getteam(PlayerIndex) == zombie_team then
			givezombieweapons(PlayerIndex)
		end
		local name = getname(PlayerIndex)
		if humans_spawn_on_death_loc then -- If humans_spawn_on_death_loc is enabled then this will teleport them to where they died as they spawn.
			if spawnondeathcoords[name] == true then
				if deathcoords[name] then
					execute_command("t " .. PlayerIndex .. " " .. deathcoords[name].x .. " " .. deathcoords[name].y .. " " .. deathcoords[name].z)
				end
				spawnondeathcoords[name] = false -- Make sure they don't keep spawning at that location.
			end
		end
	end
end

function OnPlayerAlive(PlayerIndex) -- This whole function is here to maintain player speeds in all gamemodes.
	if speed_current[PlayerIndex] ~= true then
		if getteam(PlayerIndex) == human_team then
			if onlastmanactive then
				setspeed(PlayerIndex, last_man_speed)
			else
				setspeed(PlayerIndex, human_speed)
			end
		else
			setspeed(PlayerIndex, zombie_speed)
		end
	else
		if fail_safe_speed[PlayerIndex] then -- Function that removes the speed boost (I may re-write this in a later build.)
			fail_safe_speed[PlayerIndex] = tonumber(fail_safe_speed[PlayerIndex]) + 1
			if tonumber(fail_safe_speed[PlayerIndex]) >= speed_boost_time then
				speed_current[PlayerIndex] = false
				fail_safe_speed[PlayerIndex] = 0
			end
		else
			fail_safe_speed[PlayerIndex] = 1
		end
	end
end

function OnPlayerSuicide(PlayerIndex) -- They killed themselves.
	if map_reset then
		if PlayerIndex ~= "-1" then
			if getteam(PlayerIndex) == human_team then
				setteam(PlayerIndex, zombie_team, false)
				say_all(getname(PlayerIndex) .. " " .. suicide_msg)
				timer(1000, "checkgamestate", PlayerIndex)
			end
		end
	end
end

function OnPlayerDeath(PlayerIndex, KillerIndex)
	if map_reset then
		if PlayerIndex ~= "-1" then -- Well would be strange

			local vname = getname(PlayerIndex)
			local vteam = getteam(PlayerIndex)

			local m_player = get_player(PlayerIndex)

			if m_player ~= 0 then
				if vteam == zombie_team then
					write_dword(m_player + 0x2C, zombie_spawn_time * 30)
				else
					write_dword(m_player + 0x2C, human_spawn_time * 30)
				end
			end

			if KillerIndex == "-1" then -- Well if there is not killer then lets eather make them a zombie or check if they are becoming a human again.
				if human_again[vname] == false or human_again[vname] == nil then
					if vteam == human_team then
						setteam(PlayerIndex, zombie_team, false)
						say_all(vname .. " " .. infected_msg)
					end
				else
					human_again[vname] = false
					setteam(PlayerIndex, human_team, false) -- We want them to be a human here.
				end
			else
				local kname = getname(KillerIndex)
				local kteam = getteam(KillerIndex)
				helpzombie(PlayerIndex, kteam) -- Run a check if the zombie needs some help.
				if kteam == zombie_team then
					if kteam ~= vteam then -- Lets make sure this wasnt a betray or suicide.
						countzombiekills(KillerIndex) -- Count how many kills zombies have and use it if human_again is enabled.
						applyscore(KillerIndex) -- Give the zombie score for getting an infect.
					end
					if vteam == human_team then
						setteam(PlayerIndex, zombie_team, false)
						say_all(vname .. " " .. infected_msg)
						local x,y,z = getloc(PlayerIndex)
						if x ~= nil then -- Lets load up thier death location into a table so we can have it ready when they spawn.
							spawnondeathcoords[vname] = true
							deathcoords[vname] = {}
							deathcoords[vname].x = x
							deathcoords[vname].y = y
							deathcoords[vname].z = z
						end
					else
						setteam(PlayerIndex, zombie_team, false) -- OnPlayerSuicide should take care of this but just in case something goes wrong.
					end
				else
					applyscore(KillerIndex) -- Give the human score for getting a kill.
					giveammo(KillerIndex) -- Give the ammo the human for getting a kill.
				end
			end
			timer(1000, "checkgamestate", PlayerIndex)
		end
	end
end

function countzombiekills(PlayerIndex) -- This counts player kills so if human_again_enabled is enabled that it keeps track of how many infects a zombie player has.
	if human_again_enabled then
		local name = getname(PlayerIndex)
		if zkills[name] then
			zkills[name] = tonumber(zkills[name]) + 1
			if tonumber(zkills[name]) >= human_again_kills then
				human_again[name] = true
				say_all(name .. " will become human again for getting " .. zkills[name] .. " infections!")
				setteam(PlayerIndex, human_team, true)
				zkills[name] = 0
			end
		else
			zkills[name] = 1
		end
	end
end

function helpzombie(PlayerIndex, kteam) -- This checks if the zombie needs some help and if ther is enough players to get help.
	local vteam = getteam(PlayerIndex)
	if kteam == human_team and vteam == zombie_team then
		local vkills = get_var(PlayerIndex, "$kills")
		local vdeaths = get_var(PlayerIndex, "$deaths")
		local huamn_count, zombie_count, player_count = getteamsizes(PlayerIndex)
		if tonumber(vkills) <= afk_zombie_kills and tonumber(vdeaths) >= afk_zombie_deaths then
			if tonumber(zombie_count) <= 2 and tonumber(human_count) > 2 then
				say_all(zombie_needs_help_msg)
				getrandomplayer(zombie_team, true)
			end
		end
	end
end

function giveammo(PlayerIndex)
	execute_command("ammo " .. PlayerIndex .. " +1 0")
end

function OnWeaponDrop(PlayerIndex, Slot) -- If the weapon is a ball (oddball) or flag then this will force themt to pick it back up.
	if getteam(PlayerIndex) == zombie_team then
		if zombie_weapon == "weapons\\ball\\ball" or zombie_weapon == "weapons\\flag\\flag" then -- this block of code is ment to stop players dron dropping sculls but instead it causes a spectacular amount of stupidness.
			if zombieweapid[getname(PlayerIndex)] then
				assign_weapon(zombieweapid[getname(PlayerIndex)], PlayerIndex)
			end
		end
	end
end

function OnEventTick() -- This is used to check if a player is using their flashlight (for speed boost) or crouching (for camo while crouched.)
	for i = 0,15 do
		local PlayerIndex = to_player_index(i)
		if player_alive(PlayerIndex) then
			local m_object = get_dynamic_player(PlayerIndex)
			local flashlight = read_byte(m_object + 0x206)
			local crouch = read_byte(m_object + 0x2A0)
			local team = get_var(PlayerIndex, "$team")
			if crouch == 3 then -- Check if the player is crouching
				if team == zombie_team then -- Check if the player that is crouching is a zombie.
					if zombies_invis_on_crouch then -- YAY they are a zombie lets give them invis.
						camo(PlayerIndex, 1)
					end
				end
			end
			if flashlight == 8 and speed[PlayerIndex] == false then -- Did that player just turn his flashlight on? Yup!
				speed[PlayerIndex] = true -- Hes used up his speed for his current life...
				speed_current[PlayerIndex] = true -- This is here to help with the removal of his speed.
				if team == human_team then -- Check what team they are on and apply the correct speed.
					if onlastmanactive then
						setspeed(PlayerIndex, last_man_boost_speed)
					else
						setspeed(PlayerIndex, human_boost_speed)
					end
				else
					setspeed(PlayerIndex, zombie_boost_speed)
				end
			end
		end
	end
end

function newgametimer() -- Lets get this thing roling.
	for i = 0,15 do
		local PlayerIndex = to_player_index(i)
		if player_present(PlayerIndex) then
			setteam(PlayerIndex, human_team, false)
		end
	end
	timer(1000, "gamecountdown")
end

function gamecountdown() -- Lets notify players with a count down and start this thing.
	local allow_return_other = true
	if other_count then
		other_count = tonumber(other_count) + 1
		say_all("The game will start in " .. 6 - other_count) -- Woo Hoo the game is started lets reset the map and let players go at it.
		if other_count >= 6 then
			gamestarted = true
			getrandomplayer(zombie_team, false)
			execute_command("sv_map_reset")
			allow_return_other = false
			say_all("The game has started")
			timer(1000, "sendgamestartedmsgs")
			other_count = 0
		end
	else
		other_count = 1
	end
	return allow_return_other
end

function sendgamestartedmsgs() -- Lets let players know what team they are on (if they don't know.)
	map_reset = true
	for i = 0,15 do
		local PlayerIndex = to_player_index(i)
		if player_present(PlayerIndex) then
			if getteam(PlayerIndex) == human_team then
				say(PlayerIndex, human_msg)
			else
				say(PlayerIndex, zombie_msg)
			end
		end
	end
end

function givezombieweapons(PlayerIndex) -- Give zombies their weapons.
	execute_command("wdel ".. PlayerIndex .. " 5")
	execute_command("nades " .. PlayerIndex .. " 0 0")

	local m_object = get_dynamic_player(PlayerIndex)
	local x,y,z = read_vector3d(m_object + 0x5C)
	local metaId = GetTag("weap", zombie_weapon)

	if zombieweapid[getname(PlayerIndex)] ~= nil then
		assign_weapon(zombieweapid[getname(PlayerIndex)], PlayerIndex)
	else
		local m_weaponId = spawn_object("weap",zombie_weapon,x,y,z+1,0.0, metaId)
		zombieweapid[getname(PlayerIndex)] = m_weaponId
		assign_weapon(m_weaponId, PlayerIndex)
	end

	if zombie_weapon ~= "weapons\\ball\\ball" or zombie_weapon ~= "weapons\\flag\\flag" then
		execute_command("ammo " .. PlayerIndex .. " 0 5")
		execute_command("mag " .. PlayerIndex .. " 0 5")
	end
end

function applyscore(Killer) -- Give these players some score for doing stuff and make sure team scores dont move anywhere.
	local name = getname(Killer)
	if score[name] and gamescore[name] then
		if getteam(Killer) == human_team then
			score[name] = tonumber(score[name]) + human_score_per_kill
			gamescore[name] = tonumber(gamescore[name]) + human_score_per_kill
		else
			score[name] = tonumber(score[name]) + zombie_score_per_kill
			gamescore[name] = tonumber(gamescore[name]) + zombie_score_per_kill
		end
	else
		score[name] = 0
		gamescore[name] = 0
	end
end

function applyscorepersistent() -- Give the players score for just playing in the server, for being great clients.
	for i = 0,15 do
		local PlayerIndex = to_player_index(i)
		if player_alive(PlayerIndex) then
			if gamestarted then
				local name = getname(PlayerIndex)
				if score[name] and gamescore[name] then
					if getteam(PlayerIndex) == human_team then
						score[name] = tonumber(score[name]) + human_score_per_second
						gamescore[name] = tonumber(gamescore[name]) + human_score_per_second
					else
						score[name] = tonumber(score[name]) + zombie_score_per_second
						gamescore[name] = tonumber(gamescore[name]) + zombie_score_per_second
					end
					local gametype = get_var(PlayerIndex, "$gt")
					if gametype == "ctf" then
						execute_command("ctf_score " .. PlayerIndex .. " " .. math.floor(tonumber(gamescore[name])))
						execute_command("ctf_score_team rt 0")
						execute_command("ctf_score_team bt 0")
					else
						execute_command("slayer_score " .. PlayerIndex .. " " .. math.floor(tonumber(gamescore[name])))
						execute_command("slayer_score_team bt 0")
						execute_command("slayer_score_team rt 0")
					end
				else
					score[name] = 0
					gamescore[name] = 0
				end
			end
		end
	end
	return true
end

function checkgamestate(PlayerIndex) -- We need to check how this game is progressing and make sure to know when to end it.
	local huamn_count, zombie_count, player_count = getteamsizes(PlayerIndex)
	if player_count > 1 then
		if gamestarted then
			if tonumber(human_count) > 1 and tonumber(zombie_count) == 0 then
				timer(1000, "nozombiesleft")
			elseif tonumber(human_count) == 1 and tonumber(zombie_count) > 1 and not onlastmanactive then
				onlastman()
			elseif tonumber(human_count) == 2 and tonumber(zombie_count) > 1 and onlastmanactive then
				onlastmanactive = false
				takenavsaway()
			elseif tonumber(human_count) == 0 and tonumber(zombie_count) > 1 then
				execute_command("sv_map_next")
				say_all(end_msg)
			end
		end
	end
end

function onlastman() -- There is only one human, lets give him the tools to concure.
	onlastmanactive = true
	for i = 0,15 do
		local PlayerIndex = to_player_index(i)
		if player_alive(PlayerIndex) then
			if getteam(PlayerIndex) == human_team then
				execute_command("ammo " .. PlayerIndex .. " " .. last_man_ammo .. " 5")
				execute_command("mag " .. PlayerIndex .. " " .. last_man_mag .. " 5")
				camo(PlayerIndex, last_man_camo_time)
				say_all(getname(PlayerIndex) .. " " .. lastman_msg)
				setnavesto(PlayerIndex) -- Last man is this player and we want to know where this cowering sucker is.. Lets put a nav right above his head.
			end
		end
	end
end

function nozombiesleft() -- This is called if there is no zombies.
	local allow_return = false
	if count then
		count = tonumber(count) + 1
		if count >= 6 then
			getrandomplayer(zombie_team, true) -- This picks a random player to be zombie.
			count = 0
		else
			allow_return = true
		end
	else
		allow_return = true
		count = 1
	end
	say_all(nozombies_msg .. " " .. 6 - count)
	return allow_return
end

function getrandomplayer(NewTeam, ForceKill) -- Lets get a random player + change his team.
	if allow_getrandplayer then
		allow_getrandplayer = false
		local huamn_count, zombie_count, player_count = getteamsizes(1)
		if tonumber(player_count) > 1 then else player_count = 2 end
		local rand_player = rand(1, tonumber(player_count))
		if player_present(rand_player) then
			if getteam(rand_player) ~= NewTeam then
				setteam(rand_player, NewTeam, ForceKill)
				rand_max = 0
				allow_getrandplayer = true
			else
				allow_getrandplayer = true
				getrandomplayer(NewTeam, ForceKill)
			end
		else
			allow_getrandplayer = true
			getrandomplayer(NewTeam, ForceKill)
		end
		return rand_player
	end
end

function loadgamesettings() -- Applys game settings

	execute_command("block_tc enabled")
	execute_command("disable_object 'weapons\\ball\\ball' 0")
	execute_command("disable_object 'weapons\\flag\\flag' 0")



	if enable_anticamp then
		execute_command("anticamp " .. anticamp_time .." " .. anticamp_distance)
	end

	if disable_vehicles then
		execute_command("disable_all_vehicles 0 1")
	end

	if human_team == "red" then
		if disable_os_for_humans then
			execute_command("disable_object 'powerups\\over shield' 1")
		end
		execute_command("disable_object 'powerups\\health pack' 2")
		execute_command("disable_object 'weapons\\assault rifle\\assault rifle' 2")
		execute_command("disable_object 'weapons\\flamethrower\\flamethrower' 2")
		execute_command("disable_object 'weapons\\plasma_cannon\\plasma_cannon' 2")
		execute_command("disable_object 'weapons\\needler\\mp_needler' 2")
		execute_command("disable_object 'weapons\\pistol\\pistol' 2")
		execute_command("disable_object 'weapons\\plasma pistol\\plasma pistol' 2")
		execute_command("disable_object 'weapons\\plasma rifle\\plasma rifle' 2")
		execute_command("disable_object 'weapons\\rocket launcher\\rocket launcher' 2")
		execute_command("disable_object 'weapons\\shotgun\\shotgun' 2")
		execute_command("disable_object 'weapons\\sniper rifle\\sniper rifle' 2")
		execute_command("disable_object 'weapons\\frag grenade\\frag grenade' 2")
		execute_command("disable_object 'weapons\\plasma grenade\\plasma grenade' 2")
	else
		if disable_os_for_humans then
			execute_command("disable_object 'powerups\\over shield' 2")
		end
		execute_command("disable_object 'powerups\\health pack' 1")
		execute_command("disable_object 'weapons\\assault rifle\\assault rifle' 1")
		execute_command("disable_object 'weapons\\flamethrower\\flamethrower' 1")
		execute_command("disable_object 'weapons\\plasma_cannon\\plasma_cannon' 1")
		execute_command("disable_object 'weapons\\needler\\mp_needler' 1")
		execute_command("disable_object 'weapons\\pistol\\pistol' 1")
		execute_command("disable_object 'weapons\\plasma pistol\\plasma pistol' 1")
		execute_command("disable_object 'weapons\\plasma rifle\\plasma rifle' 1")
		execute_command("disable_object 'weapons\\rocket launcher\\rocket launcher' 1")
		execute_command("disable_object 'weapons\\shotgun\\shotgun' 1")
		execute_command("disable_object 'weapons\\sniper rifle\\sniper rifle' 1")
		execute_command("disable_object 'weapons\\frag grenade\\frag grenade' 1")
		execute_command("disable_object 'weapons\\plasma grenade\\plasma grenade' 1")
	end
end

--[[ Helping function(s) ]]--

function setteam(PlayerIndex, NewTeam, ForceKill) -- Sets the players team via their team address so we can have full control over what team they will be on.
	if PlayerIndex ~= nil or PlayerIndex ~= "-1" then
		if player_present(PlayerIndex) then
			local m_player = get_player(PlayerIndex)
			if m_player ~= 0 then
				if NewTeam == "red" then
					write_byte(m_player + 0x20, 0)
				else
					write_byte(m_player + 0x20, 1)
				end
				if ForceKill then
					kill(PlayerIndex)
				end
			end
		end
	end
end

function takenavsaway() -- Puts navs above players heads.
	for i = 0,15 do
		local PlayerIndex = to_player_index(i)
		if player_present(PlayerIndex) then
			local m_player = get_player(PlayerIndex)
			local player = to_real_index(PlayerIndex)
			if m_player ~= 0 then
				write_word(m_player + 0x88, player)
			end
		end
	end
end

function setnavesto(LastAlive) -- Puts nav above last man.
	for i = 0,15 do
		local PlayerIndex = to_player_index(i)
		if player_present(PlayerIndex) then
			local m_player = get_player(PlayerIndex)
			local player = to_real_index(LastAlive)
			if m_player ~= 0 then
				write_word(m_player + 0x88, player)
			end
		end
	end
end

function getteamsizes(PlayerIndex) -- Gets the size of both teams.
	if PlayerIndex ~= nil and PlayerIndex ~= "-1" then
		human_count = get_var(PlayerIndex, "$"..human_team.."s")
		zombie_count = get_var(PlayerIndex, "$"..zombie_team.."s")
		if tonumber(human_count) then else human_count = 0 end
		if tonumber(zombie_count) then else zombie_count = 0 end
		player_count = tonumber(human_count) + tonumber(zombie_count)
		return human_count, zombie_count, player_count
	end
end


function getteam(PlayerIndex) -- Gets the team of the player.
	if PlayerIndex ~= nil and PlayerIndex ~= "-1" then
		local team = get_var(PlayerIndex, "$team")
		return team
	else
		return nil -- I don't want to send nil cause i don't want sapp to crash lol.
	end
end

function getname(PlayerIndex) -- Gets the name of the player.
	if PlayerIndex ~= nil and PlayerIndex ~= "-1" then
		local name = get_var(PlayerIndex, "$name")
		return name
	else
		return nil
	end
end

function setspeed(PlayerIndex, Speed) -- Sets the speed of the player.
	execute_command("s " .. PlayerIndex .. " " .. Speed)
end

function getloc(PlayerIndex) -- Gets players xyz location.
	if PlayerIndex ~= nil and PlayerIndex ~= "-1" then
		local x = get_var(PlayerIndex, "$x")
		local y = get_var(PlayerIndex, "$y")
		local z = get_var(PlayerIndex, "$z")
		return x, y, z
	else
		return nil
	end
end

function GetTag(class,path) -- Thanks to 002
    local tagarray = read_dword(0x40440000)
    for i=0,read_word(0x4044000C)-1 do
        local tag = tagarray + i * 0x20
        local tagclass = string.reverse(string.sub(read_string(tag),1,4))
        if(tagclass == class) then
            if(read_string(read_dword(tag + 0x10)) == path) then
                return read_dword(tag + 0xC)
            end
        end
    end
    return nil
end

------------------------------------------------------------------------------------------
-------------------------------- [[Nuggets table saving]] --------------------------------
------------------------------------------------------------------------------------------

function tablesave(t, filename)
	local file = io.open(filename, "w")
	local spaces = 0
	local function tab()
		local str = ""
		for i = 1,spaces do
			str = str .. " "
		end
		return str
	end
	local function format(t)
		spaces = spaces + 4
		local str = "{ "
		for k,v in opairs(t) do
			-- Key datatypes
			if type(k) == "string" then
				k = string.format("%q", k)
			elseif k == math.inf then
				k = "1 / 0"
			end
			k = tostring(k)
			-- Value datatypes
			if type(v) == "string" then
				v = string.format("%q", v)
			elseif v == math.inf then
				v = "1 / 0"
			end
			if type(v) == "table" then
				if tablelen(v) > 0 then
					str = str .. "\n" .. tab() .. "[" .. k .. "] = " .. format(v) .. ","
				else
					str = str .. "\n" .. tab() .. "[" .. k .. "] = {},"
				end
			else
				str = str .. "\n" .. tab() .. "[" .. k .. "] = " .. tostring(v) .. ","
			end
		end
		spaces = spaces - 4
		return string.sub(str, 1, string.len(str) - 1) .. "\n" .. tab() .. "}"
	end
	file:write("return " .. format(t))
	file:close()
end

function tableload(filename)
	local file = loadfile(filename)
	if file then
		return file() or {}
	end
	return {}
end

function tablelen(t)
	local count = 0
	for k,v in pairs(t) do
		count = count + 1
	end
	return count
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
		if unpack(keys) then
			local key = keys[count]
			local value = t[key]
			count = count + 1
			return key,value
		end
	end
end

function spaces(n, delimiter)
	delimiter = delimiter or ""
	local str = ""
	for i = 1, n do
		if i == math.floor(n / 2) then
			str = str .. delimiter
		end
		str = str .. " "
	end
	return str
end
