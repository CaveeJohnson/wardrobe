if not serverguard then
	return
end

print("Wardrobe | Loading SG extension!")

if not serverguard.permission:Exists("wardrobe") then
	serverguard.permission:Add("wardrobe")
end

hook.Add("Wardrobe_AccessAllowed", "extensions.sg", function(ply)
	if not serverguard.player:HasPermission(ply, "wardrobe") then
		return false, "No access! (Wrong usergroup)"
	end
end)