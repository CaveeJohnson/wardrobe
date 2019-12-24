-- A file to dump extensions which need not touch the core but are not large enough
-- to be considered an extension

hook.Add("Wardrobe_AccessAllowed", "wardrobe.adminonly", function(ply)
	if wardrobe.config.adminOnly and not ply:IsAdmin() then
		return false, "Wardrobe is admin only!"
	end
end)

hook.Add("Wardrobe_AccessAllowed", "wardrobe.specificModels", function(ply, wsid, mdl)
	local specific = (wsid and wardrobe.config.userSpecificModels[wsid]) or (mdl and wardrobe.config.userSpecificModels[mdl])
	if specific and #specific > 0 and not table.HasValue(specific, ply:SteamID()) then
		return false, "This model is for specific users only!"
	end
end)

hook.Add("Wardrobe_AccessAllowed", "wardrobe.whitelist", function(ply, wsid, mdl)
	local whiteOnly = wardrobe.config.whitelistMode and wardrobe.config.whitelistMode > 0
	local reset = not wsid or wsid == 0 or not mdl or mdl == ""
	local bypass = wardrobe.config.whitelistMode == 1 and ply:IsAdmin()

	if whiteOnly and not reset and not wardrobe.config.whitelistIds[wsid] and not bypass then
		return false, "This addon is not on the whitelist!"
	end
end)

if CLIENT then
	local function _fixLegs(legsDef)
		local PLAYER = debug.getregistry().Player

		function PLAYER:GetTrueModel()
			if wardrobe.enabled:GetBool() and self.wardrobe then return self.wardrobe end
			return self:GetNWString("GML:TruePlayerModel", legsDef and legsDef:GetString() or "models/player/Group01/male_09.mdl")
		end
	end

	local shouldLegs = CreateClientConVar("wardrobe_loadgmodlegs", "0", true, true, "Should wardrobe load Gmod Legs from the workshop?")
	local function _setupLegs()
		local legsDef = GetConVar("cl_defaultlegs")

		if shouldLegs:GetBool() and not legsDef then
			workshop.get(112806637, nil, nil, function(_, info, path, mountok, files, took)
				if mountok then
					print("Wardrobe | Loading gmod legs...")

					local gma = gmaparser.open(path)
					if not gma then return end

					pcall(gma.parse, gma)

					if gma:isValid() then
						for i, entry in ipairs(gma:filesMatching("lua/autorun/.+%.lua")) do
							if file.Exists(entry.name, "GAME") then
								local data = file.Read(entry.name, "GAME")

								RunString(data, "WARDROBE:gmod-legs/" .. entry.name, false)
							end
						end
					end

					legsDef = GetConVar("cl_defaultlegs")
					_fixLegs(legsDef)
					if CreateContextMenu then CreateContextMenu() end
				end
			end)
		elseif legsDef then
			_fixLegs(legsDef)
		end
	end
	hook.Add("Wardrobe_Loaded", "wardrobe.legs", _setupLegs)
	cvars.AddChangeCallback("wardrobe_loadgmodlegs", _setupLegs, "setuplegs")
end

--[[
local steamids = {"STEAM_0:1:62445445", "yoursteamid", "yourcoownerssteamid"}
hook.Add("Wardrobe_AccessAllowed", "OnlySpecificUsers", function(ply)
	if not table.HasValue(steamids, ply:SteamID()) then
		return false, "Wardrobe is used behind the scenes, sorry!"
	end
end)
]]
