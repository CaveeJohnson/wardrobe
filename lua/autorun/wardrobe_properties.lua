if CLIENT then
	concommand.Add("wardrobe_myinfo", function()
		local p = LocalPlayer()
		local mdl = p.wardrobe or p:GetModel()
		local wsid = p.wardrobeWsid or "No addon active"
		local hands = p.wardrobeHands and p.wardrobeHands[1] or (IsValid(p:GetHands()) and p:GetHands():GetModel()) or "No hands entity"

		print("mdl  : " .. mdl .. "\nwsid : " .. wsid .. "\nhands: " .. hands)
	end)
end

if not properties then
	return -- Maybe they run some wierd custom base gm?
end

properties.Add("wardrobe_reload", {
	MenuLabel = "Reload Wardrobe",
	MenuIcon = "icon16/script_code_red.png",
	Order =	-110,

	Filter = function(self, ent, ply)
		if not (IsValid(ent) and ent:IsPlayer()) then return false end

		return true
	end,

	Action = function(self, ent)
		wardrobe.requestSingle(ent)
	end,
})

properties.Add("wardrobe_copymodel", {
	MenuLabel = "Copy Model",
	MenuIcon = "icon16/page_copy.png",
	Order =	-100,

	Filter = function(self, ent, ply)
		if not IsValid(ent) then return false end

		return true
	end,

	Action = function(self, ent)
		local model = ent.wardrobe or ent:GetModel()
		SetClipboardText(model)
	end,
})

properties.Add("wardrobe_copywsid", {
	MenuLabel = "Copy Workshop ID",
	MenuIcon = "icon16/page_code.png",
	Order =	-90,

	Filter = function(self, ent, ply)
		if not (IsValid(ent) and ent:IsPlayer()) then return false end
		if not ent.wardrobeWsid then return false end

		return true
	end,

	Action = function(self, ent)
		local wsid = ent.wardrobeWsid or "error"
		SetClipboardText(wsid)
	end,
})

properties.Add("wardrobe_blacklistply", {
	MenuLabel = "Wardrobe Blacklist Player",
	MenuIcon = "icon16/user_delete.png",
	Order =	-80,

	Filter = function(self, ent, ply)
		if not (IsValid(ent) and ent:IsPlayer() and not ent:IsBot()) then return false end
		if wardrobe.ignorePlayers[ent:SteamID()] then return false end

		return true
	end,

	Action = function(self, ent)
		wardrobe.frontend.blacklistPly(ent)
	end,
})

properties.Add("wardrobe_unblacklistply", {
	MenuLabel = "Wardrobe UnBlacklist Player",
	MenuIcon = "icon16/user_add.png",
	Order =	-80,

	Filter = function(self, ent, ply)
		if not (IsValid(ent) and ent:IsPlayer() and not ent:IsBot()) then return false end
		if not wardrobe.ignorePlayers[ent:SteamID()] then return false end

		return true
	end,

	Action = function(self, ent)
		wardrobe.frontend.unBlacklist(ent)
	end,
})

properties.Add("wardrobe_blacklistmodel", {
	MenuLabel = "Wardrobe Blacklist Model",
	MenuIcon = "icon16/page_delete.png",
	Order =	-70,

	Filter = function(self, ent, ply)
		if not (IsValid(ent) and ent:IsPlayer()) then return false end
		if not ent.wardrobe then return false end

		return true
	end,

	Action = function(self, ent)
		if ent.wardrobe then
			wardrobe.frontend.blacklistModel(ent.wardrobe)
		end
	end,
})

properties.Add("wardrobe_blacklistaddon", {
	MenuLabel = "Wardrobe Blacklist Addon",
	MenuIcon = "icon16/page_red.png",
	Order =	-60,

	Filter = function(self, ent, ply)
		if not (IsValid(ent) and ent:IsPlayer()) then return false end
		if not ent.wardrobeWsid then return false end

		return true
	end,

	Action = function(self, ent)
		if ent.wardrobeWsid then
			wardrobe.frontend.blacklistWsid(ent.wardrobeWsid)
		end
	end,
})


timer.Simple(1, function()
	if properties.List and properties.List.bwa_copymodel then
		properties.List.bwa_copymodel = nil
	end
end)
