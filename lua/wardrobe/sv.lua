util.AddNetworkString("wardrobe.cache")
util.AddNetworkString("wardrobe.requestmodel")
util.AddNetworkString("wardrobe.sync")
util.AddNetworkString("wardrobe.single")
util.AddNetworkString("wardrobe.realmodel")
util.AddNetworkString("wardrobe.requestskin")
util.AddNetworkString("wardrobe.requestbodygroup")

wardrobe = wardrobe or {}
wardrobe.version = "SV"
wardrobe.server  = true
wardrobe.config  = wardrobe.config or {}
wardrobe.done    = wardrobe.done or {}

-- Disableable print function
local print = function(...)
	if wardrobe.config.shouldPrintSv ~= false then
		_G.print(...)
	end
end

do
	local _R = debug.getregistry()

	do
		local ENT = _R.Entity

		ENT.__SetModel = ENT.__SetModel or ENT.SetModel

		local function _transmitModelChange(ply, mdl)
			if not (IsValid(ply) and ply:IsPlayer()) then return end

			if ply._wardrobeLastRealModel == mdl then return end
			ply._wardrobeLastRealModel = mdl

			timer.Create("wardrobe_sendRealModel_" .. ply:SteamID(), 0.2, 1, function() -- in case of rapid changes
				if not (IsValid(ply) and ply:IsPlayer()) then return end

				net.Start("wardrobe.realmodel")
					net.WriteUInt(ply:UserID(), 16)
					net.WriteString(mdl)
				net.Broadcast()
			end)
		end

		function ENT:SetModel(mdl, ...)
			pcall(_transmitModelChange, self, mdl)
			return self:__SetModel(mdl, ...)
		end
	end

	do
		local PLAYER = _R.Player

		function PLAYER:GetBodygroupValue()
			return self:GetSaveTable().SetBodyGroup
		end

		function PLAYER:SetBodygroupValue(val)
			assert(isnumber(val), "Argument #1 to SetBodygroupValue is not a number")
			self:SetSaveValue("SetBodyGroup", val)
		end
	end
end

wardrobe.blacklist = wardrobe.blacklist or {}

local meta = {}
	meta.add = function(ply, reason) wardrobe.blacklist[ply:SteamID()] = reason or "Blacklisted from using wardrobe" wardrobe.setModel(ply) end
	meta.remove = function(ply) wardrobe.blacklist[ply:SteamID()] = nil end
	meta.from = function(json) for k, v in ipairs(util.JSONToTable(json)) do wardrobe.blacklist[k] = v end end
	meta.empty = function() wardrobe.blacklist = {} end
	meta.save = function() local d = util.TableToJSON(wardrobe.blacklist) if d then file.Write("wardrobe_blacklist.txt", d) end end
	meta.load = function() local d = file.Read("wardrobe_blacklist.txt", "DATA") if d then wardrobe.blacklist.from(d) end end
setmetatable(wardrobe.blacklist, {__index = meta})

local function _addToPrecacheST(mdl)
	if not mdl then return false end

	local loaded = util.IsModelLoaded(mdl)
	if loaded then return true end

	if not wardrobe.precache_ent or not wardrobe.precache_ent:IsValid() then
		wardrobe.precache_ent = ents.Create("base_entity")
		if not IsValid(wardrobe.precache_ent) then return false end
			function wardrobe.precache_ent:UpdateTransmitState()
				return TRANSMIT_NEVER
			end
		wardrobe.precache_ent:Spawn()

		wardrobe.precache_ent:SetNoDraw(true)
		wardrobe.precache_ent:SetMoveType(MOVETYPE_NONE)
	end

	wardrobe.precache_ent:SetModel(mdl)
	return true
end

hook.Add("InitPostEntity", "wardrobe.blacklist", wardrobe.blacklist.load)
hook.Add("ShutDown", "wardrobe.blacklist", wardrobe.blacklist.save)

net.Receive("wardrobe.cache", function(len, ply)
	if wardrobe.blacklist[ply:SteamID()] then
		return print("Wardrobe | Blacklisted player " .. ply:Nick() .. " had their request ignored (" .. wardrobe.blacklist[ply:SteamID()] .. ")")
	end

	local mdl = net.ReadString()
	if wardrobe.done[mdl] then return end

	print("Wardrobe | " .. ply:Nick() .. " requested model '" .. mdl .. "' to be cached")

	local pass = _addToPrecacheST(mdl)
	if pass then wardrobe.done[mdl] = true end
end)

function wardrobe.setModel(ply, wsid, mdl)
	ply.wardrobeSkin = nil

	if not mdl or mdl == "" or wsid == 0 then
		ply.wardrobeWsid = nil
		ply.wardrobe = nil

		print("Wardrobe | " .. ply:Nick() .. " requested a model reset")
	elseif wsid then
		ply.wardrobeWsid = wsid
		ply.wardrobe = mdl

		print("Wardrobe | " .. ply:Nick() .. " requested model '" .. mdl .. "' from addon " .. wsid)
	else
		error("wardrobe.setModel: Trying to set a model without a workshop ID?")
	end

	net.Start("wardrobe.requestmodel")
		net.WriteUInt(ply:UserID(), 16)
		net.WriteString(tostring(wsid))
		net.WriteString(mdl or "")
	net.Broadcast()

	hook.Run("Wardrobe_PostSetModel", ply, mdl, wsid)
end

net.Receive("wardrobe.requestskin", function(len, ply)
	if wardrobe.blacklist[ply:SteamID()] then
		return print("Wardrobe | Blacklisted player " .. ply:Nick() .. " had their request ignored (" .. wardrobe.blacklist[ply:SteamID()] .. ")")
	end

	local skin = net.ReadUInt(8)
	if not skin or skin < 0 then return end

	local ok, res = hook.Run("Wardrobe_SkinAllowed", ply, skin)
	if ok == false then
		return print("Wardrobe | Denied request from player " .. ply:Nick() .. " (" .. (res or "unknown") .. ")")
	end

	ply.wardrobeSkin = skin
	ply:SetSkin(skin)
end)

hook.Add("PlayerSpawn", "wardrobe.requestskin", function(ply)
	if IsValid(ply) and ply.wardrobeSkin then
		timer.Simple(0, function()
			if IsValid(ply) and ply.wardrobeSkin then
				ply:SetSkin(ply.wardrobeSkin)
			end
		end)
	end
end)

net.Receive("wardrobe.requestbodygroup", function(len, ply)
	if wardrobe.blacklist[ply:SteamID()] then
		return print("Wardrobe | Blacklisted player " .. ply:Nick() .. " had their request ignored (" .. wardrobe.blacklist[ply:SteamID()] .. ")")
	end

	local bodygroup = net.ReadUInt(24)
	if not bodygroup or bodygroup < 0 then return end

	local ok, res = hook.Run("Wardrobe_BodygroupAllowed", ply, skin)
	if ok == false then
		return print("Wardrobe | Denied request from player " .. ply:Nick() .. " (" .. (res or "unknown") .. ")")
	end

	ply:SetBodygroupValue(bodygroup)
end)

net.Receive("wardrobe.requestmodel", function(len, ply)
	if wardrobe.blacklist[ply:SteamID()] then
		return print("Wardrobe | Blacklisted player " .. ply:Nick() .. " had their request ignored (" .. wardrobe.blacklist[ply:SteamID()] .. ")")
	end

	if ply.wardrobeNextRequest and ply.wardrobeNextRequest > CurTime() then
		return print("Wardrobe | Ignoring request from player " .. ply:Nick() .. " (rate limited)")
	end

	local wsid = tonumber(net.ReadString())
	local mdl = net.ReadString()

	local ok, res = hook.Run("Wardrobe_AccessAllowed", ply, wsid, mdl)
	if ok == false then
		return print("Wardrobe | Denied request from player " .. ply:Nick() .. " (" .. (res or "unknown") .. ")")
	end

	if ply.wardrobe == mdl then
		return print("Wardrobe | Ignoring request from player " .. ply:Nick() .. " (same model)")
	end

	if not wsid then return end

	if wardrobe.config.blacklistIds[wsid] then
		return print("Wardrobe | Blacklisted addon id was requested by player " .. ply:Nick() .. " (" .. wsid .. ")")
	end
	if wardrobe.config.blacklistFiles[mdl] then
		return print("Wardrobe | Blacklisted model was requested by player " .. ply:Nick() .. " (" .. mdl .. ")")
	end

	if hook.Run("Wardrobe_RecieveModel", ply, wsid, mdl) == false then return end

	ply.wardrobeNextRequest = CurTime() + wardrobe.config.rateLimitTime
	wardrobe.setModel(ply, wsid, mdl)
end)

net.Receive("wardrobe.sync", function(len, ply)
	print("Wardrobe | " .. ply:Nick() .. " requested a full sync")

	local r = {}
	for k, v in ipairs(player.GetAll()) do
		if v.wardrobeWsid and v.wardrobe then
			r[#r + 1] = {v, tostring(v.wardrobeWsid), v.wardrobe}
		end
	end

	net.Start("wardrobe.sync")
		net.WriteUInt(#r, 8)

		for i = 1, #r do
			net.WriteUInt(r[i][1]:UserID(), 16)
			net.WriteString(r[i][2])
			net.WriteString(r[i][3])
		end
	net.Send(ply)
end)

net.Receive("wardrobe.single", function(len, ply)
	local target = net.ReadEntity()
	if not (IsValid(target) and target:IsPlayer()) then return end
	if not (target.wardrobeWsid and target.wardrobe) then return end

	print("Wardrobe | " .. ply:Nick() .. " requested a single player sync for " .. target:Nick())

	net.Start("wardrobe.single")
		net.WriteUInt(target:UserID(), 16) -- we might know who we are targeting
			-- but this is asynchronous on the client
		net.WriteString(tostring(target.wardrobeWsid))
		net.WriteString(target.wardrobe)
	net.Send(ply)
end)

print("Wardrobe | SV loaded, wardrobe.blacklist.add to blacklist griefers.")
