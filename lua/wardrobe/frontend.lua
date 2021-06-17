local L = wardrobe.language and wardrobe.language.get or function(s) return s end

wardrobe.frontend = {}

function wardrobe.frontend.blacklistWsid(wsid)
	wardrobe.blacklist(wsid, true)

	for _, v in ipairs(player.GetAll()) do
		if v.wardrobeWsid == wsid then
			wardrobe.setModel(v)
		end
	end
end

function wardrobe.frontend.blacklistModel(path)
	wardrobe.blacklist(path, true)

	for _, v in ipairs(player.GetAll()) do
		if v.wardrobe == path then
			wardrobe.setModel(v)
		end
	end
end

function wardrobe.frontend.blacklistPly(ply)
	wardrobe.blacklist(ply, true)
	wardrobe.setModel(ply)
end

function wardrobe.frontend.unBlacklist(thing)
	local t = wardrobe.blacklist(thing, nil)

	if t == "player" then
		for _, v in ipairs(player.GetAll()) do
			if v == thing or v:SteamID() == thing then
				wardrobe.requestSingle(v)

				break
			end
		end
	else
		wardrobe.requestSync()
	end
end

function wardrobe.frontend.setLanguage(id)
	wardrobe.language.current = id

	file.Write("wardrobe_language.txt", id)
end

function wardrobe.frontend.makeRequest(wsid, model, hands)
	print("makerequest1")
	local re, m = hook.Run("Wardrobe_AccessAllowed", LocalPlayer(), wsid, model)
	if re == false then return wardrobe.notif(m) end

	print("makerequest2")
	if wardrobe.nextRequest and wardrobe.nextRequest > CurTime() then
		return wardrobe.notif(L"Requesting too fast!")
	end

	print("makerequest3")
	wardrobe.requestModel(wsid, model, hands)
	return true
end

function wardrobe.frontend.parseModels(models, meta, callback)
	for i, v in ipairs(models) do
		local path = v.name
		local name
		if meta and meta[i] then
			name = meta[i][1]
			wardrobe.dbg("Wardrobe | DEBUG: Found proper name for ", path, "(" .. name .. ")")
		else
			name = path:match("/[%a%d_]+%.")
			if name then name = name:gsub("/", ""):sub(1, -2) end
		end

		local hands
		if meta and meta[i] then
			hands = meta[i][2]
		end

		callback(path, name, hands)
	end
end
