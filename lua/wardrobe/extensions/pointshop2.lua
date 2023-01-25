if not (Pointshop2 and Pointshop2Controller) then
	return
end

-- chargeAmtForUsing: Amount of points charged for using wardrobe
wardrobe.config.chargeAmtForUsing = 0
-- usePremimumPoints: Should we use premium points instead? (Make sure saveOwnership is on so donators dont kill you)
wardrobe.config.usePremimumPoints = false
-- pointsName: If you know how PS2 does this then let me know, for now change this to w/e
wardrobe.config.pointsName = "Points"
-- saveOwnership: Should you only have to buy a costume once?
wardrobe.config.saveOwnership = true

print("Wardrobe | Loaded Pointshop2 extension!")

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
				ply:SendLua([[notification.AddLegacy("You already own this costume, you changed for free!", NOTIFY_HINT, 3)]])

				return
			end
		end

		local points, premiumPoints = 0, 0
		if ply.PS2_Wallet then
			points, premiumPoints = ply.PS2_Wallet.points, ply.PS2_Wallet.premiumPoints
		end
		local pts = wardrobe.config.usePremimumPoints and premiumPoints or points

		if pts < amt then
			ply:SendLua[[surface.PlaySound"buttons/button11.wav"]]

			local str = "Not enough " .. wardrobe.config.pointsName .. "! (" .. amt .. " required)"
			ply:SendLua([[notification.AddLegacy("]] .. str .. [[", NOTIFY_HINT, 3)]])

			return false
		else
			local idx = wardrobe.config.usePremimumPoints and "premiumPoints" or "points"
			Pointshop2Controller:addToPlayerWallet(ply, idx, -amt)

			local str = "You have purchased a new costume for " .. amt .. " " .. wardrobe.config.pointsName .. "."
			ply:SendLua([[notification.AddLegacy("]] .. str .. [[", NOTIFY_HINT, 3)]])

			hook.Run("Wardrobe_PurchasedModel", ply, wsid, mdl, amt)

			if wardrobe.config.saveOwnership then
				file.Append("wardrobe_pointshop/" .. ply:SteamID64() .. ".dat", mdl .. "\n")
			end
		end
	end)
end
