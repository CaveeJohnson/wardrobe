-- Blacklisting menu

local IGNORE_PLAYERS_FILE = "wardrobe_ignoreplayers.txt"
wardrobe.ignorePlayers = {}

if file.Exists(IGNORE_PLAYERS_FILE, "DATA") then
	local s = file.Read(IGNORE_PLAYERS_FILE, "DATA")

	if s and #s > 0 then
		local tbl = util.JSONToTable(s)

		if tbl then
			wardrobe.ignorePlayers = tbl
		end
	end
end

local IGNORE_MODELS_FILE = "wardrobe_ignoremodels.txt"
wardrobe.ignoreModels = {}

if file.Exists(IGNORE_MODELS_FILE, "DATA") then
	local s = file.Read(IGNORE_MODELS_FILE, "DATA")

	if s and #s > 0 then
		local tbl = util.JSONToTable(s)

		if tbl then
			wardrobe.ignoreModels = tbl
		end
	end
end

local IGNORE_ADDONS_FILE = "wardrobe_ignoreaddons.txt"
wardrobe.ignoreAddons = {}

if file.Exists(IGNORE_ADDONS_FILE, "DATA") then
	local s = file.Read(IGNORE_ADDONS_FILE, "DATA")

	if s and #s > 0 then
		local tbl = util.JSONToTable(s)

		if tbl then
			wardrobe.ignoreAddons = tbl
		end
	end
end

function wardrobe.blacklist(thing, add)
	if isnumber(thing) or tonumber(thing) then
		local t = tonumber(thing)
		wardrobe.ignoreAddons[t] = add or nil
		file.Write(IGNORE_ADDONS_FILE, util.TableToJSON(wardrobe.ignoreAddons))

		return "addon"
	elseif isentity(thing) or (isstring(thing) and thing:match("^STEAM_")) then
		wardrobe.ignorePlayers[isstring(thing) and thing or thing:SteamID()] = add and thing:Nick() or nil
		file.Write(IGNORE_PLAYERS_FILE, util.TableToJSON(wardrobe.ignorePlayers))

		return "player"
	elseif isstring(thing) then
		wardrobe.ignoreModels[thing] = add or nil
		file.Write(IGNORE_MODELS_FILE, util.TableToJSON(wardrobe.ignoreModels))

		return "model"
	end

	return false
end
