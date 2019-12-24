if not BaseWars then
	return
end

print("Wardrobe | Loaded BaseWars15 extension!")

if CLIENT then
	hook.Add("RaidStart", "wardrobe", function()
		local p = LocalPlayer()

		if p:InRaid() then
			for k, v in ipairs(player.GetAll()) do
				if v:InRaid() and p:IsEnemy(v) then
					v.wardrobeRaid = true
					wardrobe.tempDisable(v)
				end
			end
		end
	end)

	hook.Add("RaidEnded", "wardrobe", function()
		for k, v in ipairs(player.GetAll()) do
			if v.wardrobeRaid then
				wardrobe.reenable(v)
			end
		end
	end)
end
