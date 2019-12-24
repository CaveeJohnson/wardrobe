if --[[not PHE]] true then
	return
end

print("Wardrobe | Loaded PropHunt Enhanced extension!")

--[[hook.Add("PH_OnPreRoundStart", "wardrobe.extensions.ph_e", function()
	for _, v in ipairs(player.GetAll()) do
		wardrobe.tempDisable(v)
	end
end)

hook.Add("PlayerSetModel", "wardrobe.extensions.ph_e", function(ply)
	local t = IsValid(ply) and ply:Team()
	if not t or t ~= TEAM_PROPS then return end

	wardrobe.reenable(ply)
end)
]]
