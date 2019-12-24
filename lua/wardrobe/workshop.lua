local print = wardrobe and wardrobe.dbg or print
local err = wardrobe and wardrobe.err or function(a) ErrorNoHalt(a .. "\n") end

workshop = workshop or {}

workshop.got = {}
workshop.reasons = {}
workshop.fileInfo = workshop.fileInfo or {}
workshop.mounting = workshop.mounting or {}
workshop.mounted = workshop.mounted or {}

workshop.currentQueueSize = 0

WS_NOFILEINFO     = 1
WS_FILETOOBIG     = 2
WS_DOWNLOADFAILED = 3
WS_MISSINGFILE    = 4

workshop.reverseEnum = {
	[-1] = "Unknown",
	"WS_NOFILEINFO",
	"WS_FILETOOBIG",
	"WS_DOWNLOADFAILED",
	"WS_MISSINGFILE",
}

local IGNORE = function() end

function workshop.err(wsid, reason)
	workshop.currentQueueSize = workshop.currentQueueSize - 1

	workshop.got[wsid] = false
	workshop.reasons[wsid] = reason

	err("Workshop | Error getting '" .. wsid  .. "', code: ", reason, " (" .. workshop.reverseEnum[reason] .. ")")
end

workshop.maxsize = wardrobe and wardrobe.config.maxFileSize or 0
workshop.whitelist = wardrobe and wardrobe.config.whitelistIds or {}

local function _fetch(wsid, fileInfo, validate, callback)
	if not fileInfo or not fileInfo.fileid then
		return workshop.err(wsid, WS_NOFILEINFO)
	end

	local maxsz = bit.lshift(workshop.maxsize, 20)

	if math.floor(maxsz) > 0 and (fileInfo.size or 0) > maxsz and not workshop.whitelist[wsid] then
		return workshop.err(wsid, WS_FILETOOBIG)
	end

	local ok, _err = validate(wsid, fileInfo)
	if ok == false then
		return workshop.err(wsid, _err or -1)
	end

	print("Workshop | Downloading", wsid)

	steamworks.Download(fileInfo.fileid, true, function(path)
		if not path then
			return workshop.err(wsid, WS_DOWNLOADFAILED)
		end

		if not file.Exists(path, "MOD") then
			return workshop.err(wsid, WS_MISSINGFILE)
		end

		print("Workshop | Path:", path)

		workshop.got[wsid] = true
		workshop.reasons[wsid] = path

		callback(path, fileInfo)
	end)
end

local function _getAddon(wsid, validate, callback)
	local dat = workshop.got[wsid]
	local info = workshop.fileInfo[wsid]

	if dat ~= nil then
		if dat then
			callback(workshop.reasons[wsid], info, true)
			return true
		else
			workshop.currentQueueSize = workshop.currentQueueSize - 1
			return false
		end
	end

	print("Workshop | Getting info for ", wsid)

	if info then
		_fetch(wsid, info, validate, callback)
	else
		print("Workshop | Cache not found, finding info for", wsid)

		steamworks.FileInfo(wsid, function(result)
			workshop.fileInfo[wsid] = result
			_fetch(wsid, result, validate, callback)
		end)
	end

	return nil
end

local crashPath = "workshop_crashed_while_mounting.dat"
function workshop.crashed()
	if file.Exists(crashPath, "DATA") then
		local data = file.Read(crashPath, "DATA")
		file.Delete(crashPath)

		return data
	end

	return false
end

function workshop.isWorking()
	return workshop.currentQueueSize > 0
end

local function _mount(wsid, info, path, post)
	local c = workshop.mounted[wsid]
	if c then
		workshop.currentQueueSize = workshop.currentQueueSize - 1
		return post(wsid, info, path, c[1], c[2], c[3])
	end

	workshop.mounting[#workshop.mounting + 1] = {wsid, info, path, post}
end

local nextMount = 0
local function _performMount()
	if #workshop.mounting == 0 then
		nextMount = CurTime() + 3
		return
	end

	local tbl = table.remove(workshop.mounting, 1)
	if #workshop.mounting == 0 then
		workshop.currentQueueSize = 0
	end

	local gma = gmaparser and gmaparser.open(tbl[3])
	if gma then pcall(gma.parse, gma) end

	local t = SysTime()

	local ok, files
	if not (gma and gma:isValid() and gma:alreadyMounted(true)) then
		local last_mod_delta = os.time() - (file.Time(tbl[3], "GAME") or 0)
		file.Write(crashPath, "Addon: " .. tbl[1] .. ", Path: " .. tbl[3] .. "\nTime delta: " .. last_mod_delta)
			ok, files = game.MountGMA(tbl[3])
		timer.Simple(1, workshop.crashed) -- Let's be honest, if you crash within 1 second of mounting, I'm pretty sure we know what did you in
	else
		ok = true
		files = gma.fileNames

		print("Workshop | Addon is already mounted! Skipping.")
	end

	local took = SysTime() - t

	tbl[4](tbl[1], tbl[2], tbl[3], ok or false, files, took)
	workshop.mounted[tbl[1]] = {ok or false, files, took}

	print("Workshop | Mount function for addon took " .. math.Round(took, 3) .. " seconds.")
	nextMount = CurTime() + (took * 10) + 1
end

hook.Add("Think", "workshop.mounting", function()
	if CurTime() >= nextMount then _performMount() end
end)

function workshop.get(wsid, validateinfo, validatefile, postmount)
	validateinfo = validateinfo or IGNORE
	validatefile = validatefile or IGNORE
	postmount    = postmount or IGNORE

	workshop.currentQueueSize = workshop.currentQueueSize + 1
	print("Workshop | Attempting to get", wsid)

	return _getAddon(wsid, validateinfo, function(path, info, passedBefore)
		print("Workshop | Got, now validating", wsid)
		local ok = validatefile(wsid, info, path, passedBefore)
		if ok ~= false then
			_mount(wsid, info, path, postmount)
		else
			workshop.currentQueueSize = workshop.currentQueueSize - 1
		end
	end)
end

print("loaded workshop downloader")
