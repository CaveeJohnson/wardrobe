if not Clockwork then
	return
end

print("Wardrobe | Loaded Clockwork extension!")

-- Untested
if SERVER then
	hook.Add("PlayerCharacterInitialized", "wardrobe.extensions.clockwork", function(ply)
		wardrobe.setModel(ply)
	end)
end
