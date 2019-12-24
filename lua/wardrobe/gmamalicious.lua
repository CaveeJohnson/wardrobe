local print = wardrobe and wardrobe.dbg or print

gmamalicious = gmamalicious or {}

GMAM_INVALIDGMA = -1
GMAM_NOMDLS     = -2
GMAM_BLACKLIST  = -3
GMAM_COLLISION  = -4

gmamalicious.reverseEnum = {
	[-1] = "GMAM_INVALIDGMA",
	[-2] = "GMAM_NOMDLS",
	[-3] = "GMAM_BLACKLIST",
	[-4] = "GMAM_COLLISION",
}

gmamalicious.blacklistFiles = wardrobe and wardrobe.config.blacklistFiles or {}
for k, v in ipairs(gmamalicious.blacklistFiles) do gmamalicious.blacklistFiles[v] = true end

gmamalicious.blacklistIds = wardrobe and wardrobe.config.blacklistIds or {}
for k, v in ipairs(gmamalicious.blacklistIds) do gmamalicious.blacklistIds[v] = true end

function gmamalicious.preDownload(wsid, info)
	if gmamalicious.blacklistIds[wsid] then return false, GMAM_BLACKLIST end
	return true
end

function gmamalicious.isGMAOkay(location, aggressive)
	local gma, err = gmaparser.open(location)
	if not gma then return nil, err end

	pcall(gma.parse, gma)
	if not gma:isValid() then return nil, GMAM_INVALIDGMA end

	local mounted = gma:alreadyMounted(true)
	for i = 1, #gma.files do
		local entryPath = gma.files[i].namesafe

		if gmamalicious.blacklistFiles[entryPath] then
			print("GMA Malicious | Blacklisted file:", entryPath)

			return false, GMAM_BLACKLIST
		end

		if aggressive and file.Exists(entryPath, "GAME") and not mounted then
			print("GMA Malicious | File collision (AGGRESSIVE):", entryPath)

			return false, GMAM_COLLISION
		end
	end

	return true
end

function gmamalicious.isPlayermodel(entry)
	local name = entry.name
	if name:find("/npc/", 1, true) or name:find("_npc", 1, true) then return false end -- eww gross

	local a, err = mdlparser.isPlayerModel(name, entry.size) -- util function so we don't have to make an object
	if not a then return false, err end -- mdlparser says no

	return true
end

function gmamalicious.modelExists(mdl)
	local m = mdl:gsub("%.mdl$", "")
	return file.Exists(m .. ".mdl", "GAME")
end

local pat  = [==[.+%(%s-["|'](.+)["|'],%s-["|'](.-)["|']%s-%)]==]
local pat2 = [==[.+%(%s-["|'](.+)["|'],%s-["|'](.-)["|'],%s-(%d+),%s-["|'](.+)["|']%s-%)]==]
local function _playermanagerMatch(s, ext)
	local name, mdl, a, b = s:match(ext and pat2 or pat)
	if not (name and mdl) then return end

	return name, mdl:lower(), a, b
end

function gmamalicious.getPlayerModels(location, showMetaLess)
	local gma, err = gmaparser.open(location)
	if not gma then return nil, err end

	pcall(gma.parse, gma)
	if not gma:isValid() then return nil, GMAM_INVALIDGMA end

	local mdls = {}
	local extraMdlFiles = {}
	for i, entry in ipairs(gma:filesMatching("models/.+")) do
		local path = entry.name
		local ext = path:sub(-4)

		if ext == ".mdl" and not IsUselessModel(path) then
			mdls[#mdls + 1] = table.Copy(entry)
		elseif ext == ".vvd" then
			extraMdlFiles[(path:match("(.+)%.vvd") or ""):lower()    ] = true
		elseif ext == ".vtx" then
			extraMdlFiles[(path:match("(.+)%..-%.vtx") or ""):lower()] = true
		end
	end

	-- hoho boy, time to try and find the hand models
	local nameToMdl = {}
	local nameToHands = {}
	local collate = false

	for i, entry in ipairs(gma:filesMatching("lua/autorun/.+%.lua")) do
		local path = entry.name

		local f = file.Read(path, "GAME")
		if f then
			local lines = f:Split("\n")

			if #lines < 1000 then
				for _, l in ipairs(lines) do
					l = l:Trim()

					if l ~= "" then
						if l:find("player_manager.AddValidModel", 1, true) then
							local name, mdl = _playermanagerMatch(l)

							if not (name and mdl) then
								print("GMA Malicious | Unparsable player_manager call: ", l)
							else
								nameToMdl[name:Trim()] = mdl:Trim()
								collate = true
							end
						elseif l:find("player_manager.AddValidHands", 1, true) then
							local name, hands, a, b = _playermanagerMatch(l, true) -- extended ver

							if not (name and hands) then
								print("GMA Malicious | Unparsable player_manager call: ", l)
							else
								nameToHands[name:Trim()] = {hands:Trim(), a, b}
								collate = true
							end
						end
					end
				end
			end
		end
	end

	local metaData = {}
	local ret = {}
	local pmerr

	for i, entry in pairs(mdls) do
		local noext = entry.name:sub(1, -5)
		local ok = extraMdlFiles[noext]

		if ok then
			local perr
			ok, perr = gmamalicious.isPlayermodel(entry)
			pmerr = perr or pmerr

			if ok then
				local n = entry.name
				if not (
					n:find("_arms."  , 1, true) or -- shit paths
					n:find("/c_arms/", 1, true) or
					n:find("_hands." , 1, true) or
					n:find("/c_"     , 1, true) or
					n:find("/w_"     , 1, true)
				) then
					if collate then -- Collate the metadata since (somehow) our shoddy patterns found some
						local name, hands
						for _n, m in pairs(nameToMdl) do
							if m == n then
								name = _n
								break
							end
						end

						if name then
							hands = nameToHands[name]
							metaData[#ret + 1] = {name, hands}
						end

						if name or showMetaLess then
							ret[#ret + 1]  = entry
						end
					else
						ret[#ret + 1]      = entry
					end
				end
			end
		end
	end

	if table.Count(metaData) == 0 then metaData = nil end
	if #ret > 0 then
		return ret, metaData
	else
		return nil, pmerr or GMAM_NOMDLS
	end
end

print("loaded gma malicious (utils)")
