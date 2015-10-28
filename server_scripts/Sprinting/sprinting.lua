-- Sprinting v2.0.2 by 002
-- Configuration

-- Set the base walking speed
normal_speed = 1.0

-- Set the sprinting speed increase
sprint_increase = 0.5

-- Set the minimum speed when out of energy. Set to normal_speed to prevent tiredness
tired_speed = 0.7

-- Player cannot start sprinting if less than this percentage of energy
minimum_energy = 30

-- This is how long you can sprint before running out of energy
sprint_time = 20.0

-- This controls how players can regain energy
--      0 = Players will regain energy over time if they aren't sprinting.
--      1 = Player must not move forward/backward/sideways.
--      2 = Energy will not increase over time. It is only restored to 100% upon respawn.
energy_renew = 0

-- This controls how much time it takes for energy to renew to 100% in seconds
energy_renew_time = 30.0

-- This controls how much damage the player takes when sprinting (percentage).
damage_health_increase = 100
damage_shield_increase = 100

-- The plugin will only affect players with this admin level (or higher). Set to -1 to affect everyone
admin_level = -1

-- Show a meter when sprinting. This can be blocked manually by players with /stfu_sprint (script command) or /stfu (SAPP command).
sprinting_meter = false

-- How many messages until the "Use /stfu_sprint to hide" message goes away? Set to 0 to never show it. Set to -1 to always show it.
stfu_sprint_hide = 7


-- End of configuration

api_version = "1.7.0.0"
player_energy = {}

-- Iterations per second. Halo does not do ticks faster than 30 per second, so do not set it higher than 30.
n_per_second = 30

function OnScriptLoad()
    register_callback(cb["EVENT_SPAWN"],"PlayerSpawn")
    register_callback(cb["EVENT_TICK"],"OnTick")
    if(sprinting_meter) then
        register_callback(cb['EVENT_ALIVE'],"ShowSprintingMeter")
        register_callback(cb['EVENT_COMMAND'],"OnCommand")
    end
end
function OnScriptUnload()

end

stopped_moving = {}
started_moving = {}
sprinting = {}
moving = {}
message_hide = {}
hide_message = {}

function PlayerSpawn(PlayerIndex)
    player_energy[PlayerIndex] = 1.0
    stopped_moving[PlayerIndex] = 0
    started_moving[PlayerIndex] = 0
    sprinting[PlayerIndex] = false
    moving[PlayerIndex] = false
end

function GetDefaultHealthShieldOfPlayer(PlayerIndex)
    local stats = {}
    if(player_alive(PlayerIndex) == false) then return stats end
    local player_data = get_dynamic_player(PlayerIndex)
    local unit_tag_index = read_word(player_data)
    local tag_array = read_dword(0x40440000)
    local unit_data = read_dword(tag_array + 0x20 * unit_tag_index + 0x14)
    local coll_tag_index = read_word(unit_data + 0x70 + 0xC)
    if(coll_tag_index == 0xFFFF) then return stats end -- No shirt? No collision model? No service!
    local coll_tag_data = read_dword(tag_array + 0x20 * coll_tag_index + 0x14)
    stats["health"] = read_float(coll_tag_data + 0x8)
    stats["shield"] = read_float(coll_tag_data + 0xCC)
    return stats
end

function SetSpeedOfPlayer(PlayerIndex,Speed)
    Speed = math.floor(Speed * 40 + 0.5) / 40
    local player = get_player(PlayerIndex)
    local player_speed = (read_float(get_player(PlayerIndex)) * 40 + 0.5) / 40
    if(player_speed ~= Speed) then
        write_float(get_player(PlayerIndex) + 0x6C, Speed)
    end
end


function CheckSprint(PlayerIndex)
    if(stopped_moving[PlayerIndex] == nil) then PlayerSpawn(PlayerIndex) end -- In case the host added the script late
    local player_address = get_dynamic_player(PlayerIndex)
    local runningforward = read_float(player_address + 0x278) > 0.0
    local invehicle = read_dword(player_address + 0x11C) ~= 0xFFFFFFFF

    local stopped_moving_time = os.clock() - stopped_moving[PlayerIndex] -- Time since stopped moving (sec)
    local started_moving_time = os.clock() - started_moving[PlayerIndex] -- Time since started moving (sec)

    if(runningforward and moving[PlayerIndex] == false and invehicle == false) then -- Player just started moving
        moving[PlayerIndex] = true
        local last_moving_duration = started_moving_time - stopped_moving_time

        if(last_moving_duration < 0.5 and stopped_moving_time < 0.5 and player_energy[PlayerIndex] >= (minimum_energy/100)) then -- Player wants to sprint
            sprinting[PlayerIndex] = true
            ShowSprintingMeter(PlayerIndex)
            local healthshield = GetDefaultHealthShieldOfPlayer(PlayerIndex)

            if(healthshield["shield"] ~= nil) then
                local newshield = healthshield["shield"] / (damage_shield_increase / 100.0)
                local newhealth = healthshield["health"] / (damage_health_increase / 100.0)

                write_float(player_address + 0xD8,newhealth)
                write_float(player_address + 0xDC,newshield)
            end
        end

        started_moving[PlayerIndex] = os.clock()

    elseif((runningforward == false and moving[PlayerIndex] == true) or invehicle == true) then -- Player stopped moving
        moving[PlayerIndex] = false
        stopped_moving[PlayerIndex] = os.clock()
        if(sprinting[PlayerIndex]) then
            sprinting[PlayerIndex] = false
            ShowSprintingMeter(PlayerIndex,"You stopped sprinting.")
            local healthshield = GetDefaultHealthShieldOfPlayer(PlayerIndex)
            if(healthshield["shield"] ~= nil) then
                write_float(player_address + 0xD8,healthshield["health"])
                write_float(player_address + 0xDC,healthshield["shield"])
            end
        end
    end
end

function RestPlayer(PlayerIndex)
    if(sprinting[PlayerIndex]) then return end
    local increase_energy = false
    if(energy_renew == 0) then
        increase_energy = true
    elseif(energy_renew == 1) then
        local player_address = get_dynamic_player(PlayerIndex)
        local moving = read_float(player_address + 0x278) ~= 0.0 or read_float(player_address + 0x27C) ~= 0.0
        if(moving == false) then increase_energy = true end
    end
    if(increase_energy) then
        player_energy[PlayerIndex] = player_energy[PlayerIndex] + (1.0/energy_renew_time)/n_per_second
        if(player_energy[PlayerIndex] > 1.0) then
            player_energy[PlayerIndex] = 1.0
        end
    end
end

function OnTick()
    for PlayerIndex = 1,16 do
        if(player_alive(PlayerIndex) == true) then
            if(player_energy[PlayerIndex] == nil) then -- prevent error if plugin is loaded during a game
                player_energy[PlayerIndex] = 1.0
            end
            if(tonumber(get_var(PlayerIndex,"$lvl")) >= admin_level) then
                CheckSprint(PlayerIndex)
                RestPlayer(PlayerIndex)
                local boost = 0.0
                if(sprinting[PlayerIndex] == true) then
                    if(player_energy[PlayerIndex] > 0) then
                        boost = sprint_increase
                        player_energy[PlayerIndex] = player_energy[PlayerIndex] - (1.0/sprint_time)/n_per_second
                        --say(PlayerIndex,"[DEBUG] " .. get_var(PlayerIndex,"$name") .. "'s energy: " .. math.floor(player_energy[PlayerIndex] * 100 + 0.5) .. "%")
                    else
                        ShowSprintingMeter(PlayerIndex,"You are out of energy.")
                        sprinting[PlayerIndex] = false
                        player_energy[PlayerIndex] = 0
                    end
                end
                local speed = tired_speed + (normal_speed - tired_speed) * player_energy[PlayerIndex] + boost
                SetSpeedOfPlayer(PlayerIndex,speed)
            end
        end
    end
end

function ShowSprintingMeter(PlayerIndex,Message)
    local hash = get_var(PlayerIndex,"$hash")
    if(sprinting_meter and message_hide[hash] ~= true and (sprinting[PlayerIndex] == true or Message)) then
        for i=1,20 do
            rprint(PlayerIndex,"|n")
        end
        if(Message == nil) then
            Message = "You are sprinting."
        end
        rprint(PlayerIndex,"|c" .. Message)
        local message = "|c|"
        if(player_energy[PlayerIndex] > 0) then
            for i=1,math.floor(10 * player_energy[PlayerIndex]) do
                message = message .. "||"
            end
            rprint(PlayerIndex,message)
        else
            rprint(PlayerIndex,"|n")
        end
        if(hide_message[hash] == nil) then
            hide_message[hash] = stfu_sprint_hide
        end
        if(hide_message[hash] == 0) then
            rprint(PlayerIndex,"|n")
        else
            hide_message[hash] = hide_message[hash] - 1
            rprint(PlayerIndex,"|cUse /stfu_sprint to hide.")
        end
        rprint(PlayerIndex,"|n")
    end
end

function OnCommand(PlayerIndex,Command,Environment,Password)
    if(Command == "stfu_sprint" and player_present(PlayerIndex)) then
        message_hide[get_var(PlayerIndex,"$hash")] = true
        say(PlayerIndex,"The sprinting meter has been hidden.")
    elseif(Command == "unstfu_sprint" and player_present(PlayerIndex)) then
        message_hide[get_var(PlayerIndex,"$hash")] = nil
        say(PlayerIndex,"The sprinting meter is no longer hidden.")
    else
        return true
    end
    return false
end