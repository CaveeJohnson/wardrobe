if not (PS and PS.Config) then
	return
end

-- chargeAmtForUsing: Amount of points charged for using wardrobe
wardrobe.config.chargeAmtForUsing = 0
-- pointsName: You shouldn't have to change this because it should use the config value
wardrobe.config.pointsName = PS.Config.PointsName or "Points"
-- saveOwnership: Should you only have to buy a costume once?
wardrobe.config.saveOwnership = true

print("Wardrobe | Loaded Pointshop extension!")

if wardrobe.config.saveOwnership then file.CreateDir("wardrobe_pointshop") end

if SERVER then
	hook.Add("Wardrobe_RecieveModel", "extensions.pointshop", function(ply, wsid, mdl)
		local reset = not wsid or wsid == 0 or not mdl or mdl == ""
		if reset then return end

		local amt = wardrobe.config.chargeAmtForUsing or 0
		if amt == 0 then return end

		if wardrobe.config.saveOwnership then
			local res = file.Read("wardrobe_pointshop/" .. ply:SteamID64() .. ".dat", "DATA")
			if res then res = res:Split("\n") end
			if res and table.HasValue(res, mdl) then
				return ply:PS_Notify("You already own this costume, you changed for free!")
			end
		end

		if not ply:PS_HasPoints(amt) then
			ply:SendLua[[surface.PlaySound"buttons/button11.wav"]]
			return false, ply:PS_Notify("Not enough " .. wardrobe.config.pointsName .. "! (" .. amt .. " required)")
		else
			ply:PS_TakePoints(amt)
			ply:PS_Notify("You have purchased a new costume for ", amt, " ", wardrobe.config.pointsName, ".")

			hook.Run("Wardrobe_PurchasedModel", ply, wsid, mdl, amt)

			if wardrobe.config.saveOwnership then
				file.Append("wardrobe_pointshop/" .. ply:SteamID64() .. ".dat", mdl .. "\n")
			end
		end
	end)
end
