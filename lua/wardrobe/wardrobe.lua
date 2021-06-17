wardrobe = wardrobe or {}
wardrobe.config = wardrobe.config or {}

--[[
Hi there, I see you've filestolen wardrobe, well you are in luck, there is no DRM and basically
all of the code, excluding the net message relay and a few fixes, is clientside.

Wardrobe was created by and is maintained entirely by Orbitei (/id/q2f2), I don't mind if you
use this code for learning or to enhance your own code, just please don't leak it, I'm not
in it for the money.

Contact me if you see this and want the serverside code for free.
]]

wardrobe.ragdolls = wardrobe.ragdolls or {}
wardrobe.players = wardrobe.players or {}

wardrobe.enabled      = CreateClientConVar("wardrobe_enabled",            "1" , true, true, "Should wardrobe be enabled? (Turning this on will full-sync)")
wardrobe.friendsonly  = CreateClientConVar("wardrobe_friendsonly",        "0" , true, true, "Should wardrobe only load the models of your friends?")
wardrobe.printlogs    = CreateClientConVar("wardrobe_printlogs",          "0" , true, true, "Should wardrobe's logs be printed to the console?")
wardrobe.alwaysLoad   = CreateClientConVar("wardrobe_ignorepvsloading",   "0" , true, true, "Should wardrobe load people's models IMMEDIATELY upon recieving the request?")
wardrobe.autoLoad     = CreateClientConVar("wardrobe_requestlastmodel",   "0" , true, true, "Should wardrobe ask the server to give you your last model back?")
wardrobe.showMetaLess = CreateClientConVar("wardrobe_showunlikelymodels", "0" , true, true, "Should wardrobe's menu show unlikely models when loading an addon?")
wardrobe.maxFileSize  = CreateClientConVar("wardrobe_maxfilesize",        "-1", true, true, "What is the maximum size an addon should be (in MiB)? -1 means the server decides.")

wardrobe.forceRetries = 33

wardrobe.major = 1
wardrobe.minor = 6
wardrobe.patch = 0
wardrobe.isBeta = true

wardrobe.version = wardrobe.major .. "." .. wardrobe.minor .. "." .. wardrobe.patch
if wardrobe.isBeta then
	wardrobe.version = wardrobe.version .. " BETA"
end

wardrobe.reloaded = false
if wardrobe.hasLoaded then
	wardrobe.reloaded = true
end

wardrobe.hasLoaded = false
wardrobe.guiLoaded = false

function wardrobe.notif(msg)
	hook.Run("Wardrobe_Notification", msg)
end

local function _concat(tbl, sep)
	local s = tostring(tbl[1])
	for i = 2, #tbl do
		s = s .. sep .. tostring(tbl[i])
	end
	return s
end

function wardrobe.err(...)
	local text = _concat({...}, " ")

	wardrobe.notif(text)
	hook.Run("Wardrobe_Output", "ERR", text)
end

function wardrobe.log(...)
	hook.Run("Wardrobe_Output", "LOG", _concat({...}, " "))
end

function wardrobe.dbg(...)
	hook.Run("Wardrobe_Output", "DBG", _concat({...}, " "))
end

function wardrobe.getAddon(wsid, callback, ignoreMetaLess)
	hook.Run("Wardrobe_GetAddon", wsid)
	local white = wardrobe.config.whitelistIds and wardrobe.config.whitelistIds[wsid]

	workshop.get(
		wsid,

		function(_, info)
			if hook.Run("Wardrobe_ValidateInfo", wsid, info) == false then return false end

			if not white then
				local ok, err = gmamalicious.preDownload(wsid, info)
				err = gmamalicious.reverseEnum[err] or gmaparser.reverseEnum[err] or err
				if not ok then
					wardrobe.err("Wardrobe | GMAM refused download with error code '" .. err .. "'.")

					return false
				end
			end
		end,

		function(_, info, path, done, handle)
			if hook.Run("Wardrobe_ValidateGMA", wsid, info, path, done) == false then return false end

			if not done and not white then
				local ok, err = gmamalicious.isGMAOkay(path, handle, wardrobe.config.aggressive, wardrobe.config.maxFileSize)
				err = gmamalicious.reverseEnum[err] or gmaparser.reverseEnum[err] or err
				if not ok then
					wardrobe.err("Wardrobe | GMAM rejected addon with error code '" .. err .. "'.")

					return false
				end
			end
		end,

		function(_, info, path, mountok, files, took, handle)
			wardrobe.dbg("Wardrobe | Done loading addon", wsid)

			if mountok then
				hook.Run("Wardrobe_MountPassed", wsid, info, path, files, took)

				local mdls, err = gmamalicious.getPlayerModels(path, handle, not ignoreMetaLess) -- if mdls then err is metadata
				err = gmamalicious.reverseEnum[err] or mdlparser.reverseEnum[err] or err
				if not mdls then return wardrobe.err("Wardrobe | Error getting player models from addon. (Are there any? code: " .. err .. ")") end

				hook.Run("Wardrobe_ModelsLoaded", mdls, err) -- mdls, meta

				callback(wsid, info, path, mdls, err)
			else
				hook.Run("Wardrobe_MountFailed", wsid, info, path)
				wardrobe.err("Wardrobe | Failed to mount addon ", wsid)
			end
		end
	)
end

local function _fullUpdate()
	timer.Create("wardrobe_fullupdate", .9, 1, function() -- in case this gets fired more than once synchronously
		LocalPlayer():ConCommand("record sourcepls;stop") -- source pls

		hook.Run("Wardrobe_FullUpdate")
	end)
end

local function _renderRagdoll(rag)
	if rag.wardrobe then
		rag:SetModel(rag.wardrobe)

		if wardrobe.ragdolls[rag] then
			rag:InvalidateBoneCache()
		end
	end

	rag:DrawModel()
end

local function _forceModel(ply)
	local mdl = ply.wardrobe
	if mdl then
		ply:SetModel(mdl)
		ply:ResetHull()
	end
end

local function _forceRag(rag)
	local mdl = rag.wardrobe
	if mdl then
		rag:InvalidateBoneCache()
			rag:SetModel(mdl)
		rag:InvalidateBoneCache()
	end
end

function wardrobe.forcefor(ply, noEffect)
	wardrobe.players[ply] = wardrobe.forceRetries
	_forceModel(ply)

	if not noEffect then
		local ed = EffectData()
			ed:SetOrigin(ply:GetPos())
			ed:SetEntity(ply)
		util.Effect("propspawn", ed)
	end
end

-- The game has a tendency to not do it when you want it to or to leave the job half done
-- this may look horrible but it works
local function _ragdolls()
	for rag, retry in pairs(wardrobe.ragdolls) do
		if rag:IsValid() and retry > 0 then
			wardrobe.ragdolls[rag] = retry - 1

			_forceRag(rag)
		elseif wardrobe.ragdolls[rag] then
			wardrobe.ragdolls[rag] = nil
		end
	end
end

local function _players()
	for ply, retry in pairs(wardrobe.players) do
		if ply:IsValid() and retry > 0 then
			wardrobe.players[ply] = retry - 1

			_forceModel(ply)
		elseif wardrobe.players[ply] then
			wardrobe.players[ply] = nil
		end
	end
end

function wardrobe.doThink()
	_players()
	_ragdolls()
end
hook.Add("Think", "wardrobe", wardrobe.doThink)

function wardrobe.onCreateClientsideRagdoll(rag)
	-- 14C_HL2MPRagdoll     <- linux ragdoll
	-- class C_HL2MPRagdoll <- wangblows ragdoll
	-- W h a t

	local class = rag:GetClass()
	if not class:match("^.+C_HL2MPRagdoll") then return end

	local ply = rag:GetRagdollOwner()
	if not (ply:IsValid() and ply:IsPlayer()) then return end

	local mdl = ply.wardrobe
	if not mdl then return end

	hook.Run("Wardrobe_RagdollModelChanged", ply, rag)

	rag.wardrobe = mdl
	wardrobe.ragdolls[rag] = wardrobe.forceRetries

	_forceRag(rag)
	rag.RenderOverride = _renderRagdoll
end
hook.Add("NetworkEntityCreated", "wardrobe", wardrobe.onCreateClientsideRagdoll)

local recursing
function wardrobe.localPlayerFix(ply)
	if ply ~= LocalPlayer() then
		return
	end

	if recursing then return end
	recursing = true
		_forceModel(ply)
	recursing = false
end
hook.Add("PrePlayerDraw", "wardrobe", wardrobe.localPlayerFix)

function wardrobe.getDistance()
	return 2047^2
end

function wardrobe.canSee(ply)
	local localPly = LocalPlayer()
	if localPly:GetPos():DistToSqr(ply:GetPos()) > wardrobe.getDistance() then return false end
	return true
end

-- so far unused ^, see how it works out, you will need to update everyone with inPvs every second or so and recheck canSee

local function _pvsEnter(ply)
	wardrobe.forcefor(ply, true)
end

function wardrobe.onPlayerEnterPvs(ply, enter)
	if not ply:IsPlayer() then return end
	ply.inPvs = enter

	hook.Run("Wardrobe_PlyPVSChanged", ply, enter)

	local data = ply.receivedData
	if data and data[2] then
		if enter then
			timer.Create("dormancyResetWorkaround_recieved" .. ply:SteamID(), 0.1, 1, function() -- I'm so sorry
				if not IsValid(ply) then return end

				wardrobe.setupReceived(ply, data[1], data[2], false)
				ply.receivedData = nil
			end)
		else
			timer.Remove("dormancyResetWorkaround_recieved" .. ply:SteamID())
		end

		return
	end

	if not ply.wardrobe then
		return
	end

	if not enter then
		if ply ~= LocalPlayer() then
			timer.Remove("dormancyResetWorkaround" .. ply:SteamID())
		end

		return
	end

	if ply == LocalPlayer() then
		_pvsEnter(ply)
	else
		timer.Create("dormancyResetWorkaround" .. ply:SteamID(), 0.1, 1, function()
			if not IsValid(ply) then return end

			_pvsEnter(ply)
		end)
	end
end
hook.Add("NotifyShouldTransmit", "wardrobe", wardrobe.onPlayerEnterPvs)

function wardrobe.patchVmHands(vm, _, weapon)
	local ply = LocalPlayer()
	local handsinfo = ply.wardrobeHands

	if handsinfo and handsinfo[1] then
		local hands = ply:GetHands()
		if IsValid(hands) then
			hands:SetModel(handsinfo[1])
		end
	end
end
hook.Add("PreDrawViewModel", "wardrobe", wardrobe.patchVmHands)

local function _stCache(mdl)
	net.Start("wardrobe.cache")
		net.WriteString(mdl)
	net.SendToServer()
end

function wardrobe.setModel(ply, mdl, wsid, handsinfo, ignoreMount, noEffect)
	hook.Run("Wardrobe_PreSetModel", ply, mdl, wsid, handsinfo)

	if not mdl or mdl == "" or wsid == 0 then
		if ply.originalModel then
			ply:SetModel(ply.originalModel)
			ply.originalModel = nil
		end

		ply.wardrobe = nil
		ply.wardrobeWsid = nil
		ply.wardrobeHands = nil
		if ply == LocalPlayer() then
			_fullUpdate()
		end

		hook.Run("Wardrobe_PostSetModel", ply, mdl, wsid, handsinfo)
		return true
	end

	if not ignoreMount then
		local exists = gmamalicious.modelExists(mdl)
		if not exists then return false end
	end

	local original = ply:GetModel()
	local oldOriginal = ply.originalModel

	if not oldOriginal then
		ply.originalModel = original
	end

	_stCache(mdl) -- Workaround for entities not updating
	ply.wardrobe = mdl
	ply.wardrobeWsid = wsid
	ply.wardrobeHands = handsinfo and table.Copy(handsinfo)
	wardrobe.forcefor(ply, noEffect)

	if ply == LocalPlayer() and original ~= mdl then
		_fullUpdate()
	end

	if not noEffect and original ~= mdl then
		ply:EmitSound("items/suitchargeok1.wav") -- TODO: Config
	end

	hook.Run("Wardrobe_PostSetModel", ply, mdl, wsid, handsinfo)
	return true
end

function wardrobe.lightSetLocal(mdl)
	local ply = LocalPlayer()

	if not mdl or mdl == "" then
		ply.wardrobe = ply.__wardrobe
		ply.__wardrobe = nil

		wardrobe.forcefor(ply)
		_fullUpdate()

		return
	end

	_stCache(mdl)
	ply.__wardrobe = ply.__wardrobe or ply.wardrobe
	ply.wardrobe = mdl
	wardrobe.forcefor(ply)

	_fullUpdate()
end

wardrobe.handsInfoLookup = wardrobe.handsInfoLookup or {}

function wardrobe.requestSkin(n)
	local re, m = hook.Run("Wardrobe_SkinAllowed", LocalPlayer(), n)
	if re == false then return wardrobe.notif(m) end

	net.Start("wardrobe.requestskin")
		net.WriteUInt(n, 8)
	net.SendToServer()
end

function wardrobe.requestModel(wsid, mdl, handsinfo)
	print("Wardrobe | Sending request to the server...")
	wardrobe.nextRequest = CurTime() + wardrobe.config.rateLimitTime + 1 -- + 1 so we don't get ignored by the server

	if not mdl or mdl == "" then
		hook.Run("Wardrobe_RequestModel", mdl, wsid, handsinfo)
		net.Start("wardrobe.requestmodel")
			net.WriteString("0")
			net.WriteString("")
		net.SendToServer()

		file.Delete("wardrobe_last.txt")
		return
	end

	hook.Run("Wardrobe_RequestModel", mdl, wsid, handsinfo)
	net.Start("wardrobe.requestmodel")
		net.WriteString(tostring(wsid))
		net.WriteString(mdl)
	net.SendToServer()

	wardrobe.handsInfoLookup[mdl] = handsinfo

	local serial = mdl .. ";" .. wsid -- TODO: Also need to store bodygroups here
	if handsinfo and handsinfo[1] then
		serial = serial .. ";" .. table.concat(handsinfo, ";")
	else
		serial = serial .. ";gone;0;0"
	end
	file.Write("wardrobe_last.txt", serial)
end

function wardrobe.isFriend(ply)
	return ply:GetFriendStatus() == "friend" or
		ply:GetFriendStatus() == "requested" or
		ply == LocalPlayer()
end

function wardrobe.setupReceived(ply, wsid, mdl, localPly)
	if not wardrobe.enabled:GetBool() then return end
	if not IsValid(ply) then return end

	if wsid == 0 or not mdl or mdl == "" then
		wardrobe.setModel(ply)

		return
	end

	-- We have requested this before so we know we don't need to get it again
	if wardrobe.handsInfoLookup[mdl] then
		wardrobe.setModel(ply, mdl, wsid, wardrobe.handsInfoLookup[mdl])

		return
	end

	wardrobe.getAddon(wsid, function(_, info, path, mdls, meta)
		if not IsValid(ply) then return end

		local ok = false
		local hands
		for k, v in ipairs(mdls) do
			if v.name:lower() == mdl:lower() then
				ok = true

				if meta and meta[k] then
					hands = meta[k][2]
					wardrobe.handsInfoLookup[mdl] = hands
				end

				break
			end
		end

		if not ok then
			return wardrobe.err("Wardrobe | Addon '" .. wsid .. "' appears to not contain the selected model.")
		end

		if ply.wardrobeTemp then
			ply.wardrobeTemp = mdl
			ply.wardrobeWsidTemp = wsid
		else
			wardrobe.setModel(ply, mdl, wsid, hands)
		end
	end)
end

function wardrobe.requestModelSimple(wsid, mdl)
	wardrobe.getAddon(wsid, function(_, info, path, mdls, meta)
		local ok = false
		local hands

		-- This loop gets the hands from the metadata and also makes sure the model exists
		for k, v in ipairs(mdls) do
			if v.name:lower() == mdl:lower() then
				ok = true

				if meta and meta[k] then
					hands = meta[k][2]
				end

				break
			end
		end

		if not ok then
			return wardrobe.err("Wardrobe | Addon '" .. wsid .. "' appears to not contain the selected model.")
		end

		wardrobe.requestModel(wsid, mdl, hands)
	end)
end

function wardrobe.receive(ply, wsid, mdl)
	if not wardrobe.enabled:GetBool() then return end
	if not IsValid(ply) then return end

	if wardrobe.ignorePlayers[ply:SteamID()] then return end
	if wardrobe.ignoreAddons[wsid] then return end
	if wardrobe.ignoreModels[mdl] then return end

	if wardrobe.friendsonly:GetBool() and not wardrobe.isFriend(ply) then return end
	if hook.Run("Wardrobe_RecieveModel", ply, wsid, mdl) == false then return end

	local isSelf = ply == LocalPlayer()
	if ply.inPvs or isSelf or wardrobe.alwaysLoad:GetBool() then
		wardrobe.setupReceived(ply, wsid, mdl, isSelf)
	else
		--print("addon select outside PVS for", ply)
		ply.receivedData = {wsid, mdl}
	end
end

wardrobe.nullCache = wardrobe.nullCache or {}

local tries = 0
function wardrobe.processNullCache()
	if #wardrobe.nullCache < 1 then
		tries = 0
		return timer.Remove("wardrobe_nullcache")
	end

	local res  = {}

	for i, v in ipairs(wardrobe.nullCache) do
		local ply = Player(v[1])

		if IsValid(ply) then
			wardrobe.receive(ply, v[2], v[3])
		else
			res[#res + 1] = v
		end
	end

	if tries < 10 then
		wardrobe.nullCache = res
	else
		tries = 0
		wardrobe.nullCache = {}

		wardrobe.log("Wardrobe | Discarding cached NULL players after 10 tries.")
	end
end

net.Receive("wardrobe.realmodel", function()
	-- updated someones 'real' serverside model
	local id = net.ReadUInt(16)
	local mdl = net.ReadString()

	local ply = Player(id)
	if not (mdl and IsValid(ply)) then return end

	if ply.originalModel then
		ply.originalModel = mdl

		ply:SetModel(mdl)
		wardrobe.forcefor(ply, true)

		if ply == LocalPlayer() then
			_fullUpdate()
		end
	end
end)

net.Receive("wardrobe.requestmodel", function()
	-- someone asked to wear a model
	local id = net.ReadUInt(16)
	local wsid = tonumber(net.ReadString()) or 0
	local mdl = net.ReadString()

	local ply = Player(id)

	if IsValid(ply) then
		wardrobe.receive(ply, wsid, mdl)
	else
		wardrobe.nullCache[#wardrobe.nullCache + 1] = {id, wsid, mdl}
		timer.Create("wardrobe_nullcache", 10, 10, wardrobe.processNullCache)
	end
end)

local function _readSingle()
	local id = net.ReadUInt(16)
	local wsid = tonumber(net.ReadString())
	local mdl = net.ReadString()

	local ply = Player(id)

	if mdl and wsid then
		if IsValid(ply) then
			wardrobe.receive(ply, wsid, mdl)
		else
			wardrobe.nullCache[#wardrobe.nullCache + 1] = {id, wsid, mdl}
			timer.Create("wardrobe_nullcache", 10, 10, wardrobe.processNullCache)
		end
	end
end

net.Receive("wardrobe.sync", function()
	-- we asked for a full sync
	local amt = net.ReadUInt(8)

	for i = 1, amt do
		_readSingle()
	end
end)

net.Receive("wardrobe.single", _readSingle)

function wardrobe.requestSync()
	hook.Run("Wardrobe_RequestSync")

	net.Start("wardrobe.sync")
	net.SendToServer()
end

function wardrobe.requestSingle(ply)
	if not IsValid(ply) then return end

	hook.Run("Wardrobe_RequestSync", ply)

	net.Start("wardrobe.single")
		net.WriteEntity(ply)
	net.SendToServer()
end

local shouldSync = wardrobe.enabled:GetBool() and not wardrobe.reloaded
function wardrobe.load()
	if wardrobe.hasLoaded then return end

	if shouldSync then wardrobe.requestSync() end

	local s = file.Read("wardrobe_last.txt", "DATA") -- TODO: Update when new data is added
	if s and #s > 0 then
		local mdl, wsid, hands, skin, bodygroups = s:match([==[(.+);(%d+);(.+);(%d);(%d+)]==])
		wsid = tonumber(wsid)
		if not (mdl and wsid and bodygroups) then return end

		if shouldSync then
			local handsinfo
			if hands ~= "gone" then
				handsinfo = {hands, skin, bodygroups}
			end

			wardrobe.getAddon(wsid, function(...) -- Make sure its mounted for local client
				if wardrobe.autoLoad:GetBool() then
					wardrobe.requestModel(wsid, mdl, handsinfo)
				end

				wardrobe.lastAddonInfo = {...}
			end, not wardrobe.showMetaLess:GetBool())
		end

		wardrobe.lastAddon = wsid
	end

	hook.Run("Wardrobe_Loaded")
	wardrobe.hasLoaded = true

	local maxSizeOverride = wardrobe.maxFileSize:GetInt()
	if maxSizeOverride >= 0 then
		workshop.maxsize = maxSizeOverride
	end
end

do
	local color_1 = Color(255, 55, 55, 255)
	local color_2 = Color(255, 55, 255, 255)
	function wardrobe.printCrashLog(log)
		chat.AddText(color_1, "Wardrobe | Force disabled wardrobe, Garry's Mod crashed while mounting an addon. Re-enable at your own risk.")

		if isstring(log) and log ~= "" then
			chat.AddText(color_2, "Wardrobe | Crash information: " .. log)
		end
	end

	local crashlog_delay = 5
	local function _startupSync()
		hook.Remove("CalcView", "wardrobe.sync")

		local data = workshop.crashed()
		if data then
			timer.Simple(crashlog_delay, function() wardrobe.printCrashLog(data) end)
			wardrobe.enabled:SetBool(false)

			shouldSync = false
		end

		timer.Simple(0, wardrobe.load)
	end
	hook.Add("CalcView", "wardrobe.sync", _startupSync) -- When render starts up, after 'Sending Client Info'
end

function wardrobe.tempDisable(ply)
	if not IsValid(ply) or ply == LocalPlayer() then return end
	if ply.wardrobeTemp then return end
	if not ply.originalModel then return end

	ply.wardrobeTemp = ply.wardrobe
	ply.wardrobeWsidTemp = ply.wardrobeWsid

	wardrobe.setModel(ply)
end

function wardrobe.reenable(ply)
	if not IsValid(ply) or ply == LocalPlayer() then return end
	if not ply.wardrobeTemp then return end

	wardrobe.setModel(ply, ply.wardrobeTemp, ply.wardrobeWsidTemp)

	ply.wardrobeTemp = nil
	ply.wardrobeWsidTemp = nil
end

function wardrobe.toggle(on, friends)
	if not friends then wardrobe.log("Wardrobe | All systems " .. (on and "enabled" or "disabled")) end

	if on then
		wardrobe.requestSync()
	else
		for k, v in ipairs(player.GetAll()) do
			if v.originalModel and not (friends and wardrobe.isFriend(v)) then
				wardrobe.log("Wardrobe | Resetting model for", v:Nick())
				wardrobe.setModel(v)
			end
		end
	end
end

function wardrobe.clearCache()
	hook.Run("Wardrobe_PreClearCache")

	for k, v in pairs(mdlparser.cache) do
		v:terminate()
		print("Deleted '" .. k .. "' from mdl cache.")
	end

	for k, v in pairs(gmaparser.cache) do
		v:terminate()
		print("Deleted '" .. k .. "' from gma cache.")
	end

	for k, v in pairs(workshop.got) do
		workshop.got[k] = nil
		workshop.reasons[k] = nil
		print("Deleted '" .. k .. "' from download cache.")
	end

	print("Emptying mounted table of " .. table.Count(workshop.mounted) .. " entries.")
	workshop.mounted = {}

	print("Emptying handinfo cache of " .. table.Count(wardrobe.handsInfoLookup) .. " entries.")
	wardrobe.handsInfoLookup = {}

	hook.Run("Wardrobe_PostClearCache")
end

cvars.AddChangeCallback("wardrobe_enabled", function(c, o, n)
	local b = math.floor(n) ~= 0
	wardrobe.toggle(b)

	hook.Run("Wardrobe_Toggled", b)
end, "toggle")

cvars.AddChangeCallback("wardrobe_friendsonly", function(c, o, n)
	local b = math.floor(n) == 0
	wardrobe.toggle(b, true)

	hook.Run("Wardrobe_ToggledFriends", b)
end, "toggle")

concommand.Add("wardrobe_fullsync", wardrobe.requestSync)
concommand.Add("wardrobe_clearcache", wardrobe.clearCache)

cvars.AddChangeCallback("wardrobe_maxfilesize", function(_, _, val)
	if not tonumber(val) then return end

	local v = tonumber(val)
	if v < 0 then
		workshop.maxsize = wardrobe.config.maxFileSize or 0
	else
		workshop.maxsize = v
	end
end, "workshop.clientoveride")

wardrobe.dbg("loaded wardrobe core")
