-- Kill Spree Messages via Console Text by Skylace

-- Alignment of the messages.
-- r = right | c = center | l = left | t = tab
alignment = "c"

-- Should double kill message not be said?
exclude_double = true

-- Should tripple kill message not be said?
exclude_triple = true

api_version = "1.7.0.0"

function OnScriptLoad()
	register_callback(cb['EVENT_KILL'], "OnPlayerKill")
end

function OnPlayerKill(PlayerIndex, VictimIndex)
	local combo = get_var(PlayerIndex, "$combo")
	local spree = get_var(PlayerIndex, "$streak")

	if tonumber(combo) == 2 then
		if not exclude_double then
			sct(PlayerIndex, "Double Kill!")
		end
	elseif tonumber(combo) == 3 then
		if not exclude_triple then
			sct(PlayerIndex, "Triple Kill!")
		end
	elseif tonumber(combo) == 4 then
		sct(PlayerIndex, "Overkill!")
	elseif tonumber(combo) == 5 then
		sct(PlayerIndex, "Killtacular!")
	elseif tonumber(combo) == 6 then
		sct(PlayerIndex, "Killtrocity!")
	elseif tonumber(combo) == 7 then
		sct(PlayerIndex, "Killimanjaro!")
	elseif tonumber(combo) == 8 then
		sct(PlayerIndex, "Killtastrophe!")
	elseif tonumber(combo) == 9 then
		sct(PlayerIndex, "Killpocalypse!")
	elseif tonumber(combo) == 10 then
		sct(PlayerIndex, "Killionaire!")
	end

	if tonumber(spree) == 5 then
		sct(PlayerIndex, "Killing Spree!")
	elseif tonumber(spree) == 10 then
		sct(PlayerIndex, "Killing Frenzy!")
	elseif tonumber(spree) == 15 then
		sct(PlayerIndex, "Running Riot!")
	elseif tonumber(spree) == 20 then
		sct(PlayerIndex, "Rampage!")
	elseif tonumber(spree) == 25 then
		sct(PlayerIndex, "Untouchable!")
	elseif tonumber(spree) == 30 then
		sct(PlayerIndex, "Invincible!")
	elseif tonumber(spree) == 35 then
		sct(PlayerIndex, "Inconceivable!")
	end
end

function sct(PlayerIndex, Message)
	for i = 1,16 do
		if player_present(i) then
			local name = get_var(PlayerIndex, "$name")
			rprint(i, "|" .. alignment .. " " .. name .. " - ".. Message)
		end
	end
end
