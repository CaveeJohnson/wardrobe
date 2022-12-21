if not sam then
	return
end

print("Wardrobe | Loading SAM extension!")

sam.command.set_category("Wardrobe")

--Added Permission to only allow certain groups to use Wardrobe
sam.permissions.add("wardrobe", "Wardrobe", "admin")

hook.Add("Wardrobe_AccessAllowed", "extensions.sam", function(ply)
	if not ply:HasPermission("wardrobe") then
		return false, "No access! (Wrong usergroup)"
	end
end)

sam.command.new("forcewardrobe")
	:Help("Force a player to wear a chosen model from a specified addon.")
	:SetPermission("forcewardrobe", "superadmin")

	:AddArg("player")
	:AddArg("number", {hint = "workshop id", min = 0, round = true})
	:AddArg("text", {hint = "model path"})

	:OnExecute(function(ply, targets, workshopId, modelPath)
		for _, target in ipairs(targets) do
			wardrobe.setModel(target, workshopId, modelPath)
		end

		sam.player.send_message(nil, "{A} forced the model of {T} to {S} from addon {V}.", {
			A = ply, T = targets, S = modelPath, V = workshopId
		})
	end)
:End()

sam.command.new("forceresetwardrobe")
	:Help("Force a player to wear their normal model.")
	:SetPermission("forceresetwardrobe", "admin")

	:AddArg("player")

	:OnExecute(function(ply, targets)
		for _, target in ipairs(targets) do
			wardrobe.setModel(target)
		end

		sam.player.send_message(nil, "{A} force reset the model of {T}.", {
			A = ply, T = targets
		})
	end)
:End()

sam.command.new("wardrobeblacklist")
	:Help("Blacklist a player from using wardrobe.")
	:SetPermission("wardrobeblacklist", "admin")

	:AddArg("player")
	:AddArg("text", {
		optional = true,
		default = "N/A",
		hint = "reason"
	})

	:GetRestArgs(true)

	:OnExecute(function(ply, targets, reason)
		for _, target in ipairs(targets) do
			wardrobe.blacklist.add(target, reason)
		end

		sam.player.send_message(nil, "{A} blacklisted {T} from using wardrobe for {S}.", {
			A = ply, T = targets, S = reason
		})
	end)
:End()

sam.command.new("wardrobeunblacklist")
	:Help("Remove a player from the wardrobe usage blacklist.")
	:SetPermission("wardrobeunblacklist", "admin")

	:AddArg("player")

	:OnExecute(function(ply, targets, reason)
		for _, target in ipairs(targets) do
			wardrobe.blacklist.remove(target, reason)
		end

		sam.player.send_message(nil, "{A} unblacklisted {T} from using wardrobe.", {
			A = ply, T = targets
		})
	end)
:End()
