-- Wardrobe load file, lua in lua/wardrobe

local function _loadExtensions(ext)
	if not ext then return function() end end

	return function()
		for i, v in ipairs(wardrobe.config.extensions) do
			include("wardrobe/extensions/" .. v .. ".lua")
		end
	end
end

local newMenu = CreateClientConVar("wardrobe_useNewMenu", "0", true, true, "Should wardrobe be use the experimental new menu?")

local function _load()
	print("Loading wardrobe")

	if SERVER then
		include("wardrobe/sv.lua")
		include("wardrobe_config.lua")

		AddCSLuaFile("wardrobe/wardrobe.lua")
		AddCSLuaFile("wardrobe_config.lua")
		AddCSLuaFile("wardrobe_language.lua")

		AddCSLuaFile("wardrobe/bodygroups.lua")
		AddCSLuaFile("wardrobe/blacklist.lua")

		AddCSLuaFile("wardrobe/gmaparser.lua")
		AddCSLuaFile("wardrobe/mdlparser.lua")
		AddCSLuaFile("wardrobe/gmamalicious.lua")
		AddCSLuaFile("wardrobe/workshop.lua")

		AddCSLuaFile("wardrobe/frontend.lua")
		AddCSLuaFile("wardrobe/wardrobegui.lua")
		AddCSLuaFile("wardrobe/wardrobegui_v2.lua")
		AddCSLuaFile("wardrobe/preview.lua")

		resource.AddSingleFile("materials/icon64/wardrobe64.png")
		resource.AddSingleFile("materials/wardrobeico.png")
	else
		include("wardrobe/wardrobe.lua")
		include("wardrobe_config.lua")
		include("wardrobe_language.lua")

		include("wardrobe/bodygroups.lua")
		include("wardrobe/blacklist.lua")

		include("wardrobe/gmaparser.lua")
		include("wardrobe/mdlparser.lua")
		include("wardrobe/gmamalicious.lua")
		include("wardrobe/workshop.lua")

		include("wardrobe/frontend.lua")

		if newMenu:GetBool() then
			include("wardrobe/wardrobegui_v2.lua")
		else
			include("wardrobe/wardrobegui.lua")
		end

		include("wardrobe/preview.lua")

		if not (wardrobe and wardrobe.dbg) then
			return ErrorNoHalt("Wardrobe | Failed to load!\n")
		end

		local id = tonumber("{{ user_id }}") and "{{ user_id }}" or "CORE"

		wardrobe.dbg("Wardrobe | Licensed to " .. id)
	end

	local ext = wardrobe and wardrobe.config.extensions and #wardrobe.config.extensions > 0 and wardrobe.config.extensions
	if ext then
		print("Loading " .. #ext .. " extensions for wardrobe")

		if SERVER then
			for i, v in ipairs(ext) do
				AddCSLuaFile("wardrobe/extensions/" .. v .. ".lua")
			end
		end

		timer.Simple(1, _loadExtensions(ext))
	else
		print("No wardrobe extensions detected")
	end
end
_load()

concommand.Add("wardrobe_reload", _load)
cvars.AddChangeCallback("wardrobe_useNewMenu", _load, "wardrobe")
