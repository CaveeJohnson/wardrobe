function wardrobe.getBodypartByName(ply, name)
	local parts = wardrobe.getBodyparts(ply)
	if not parts then return nil end

	for _, v in ipairs(parts) do
		if v.name == name then
			return v
		end
	end

	return nil
end

function wardrobe.calculateBodygroup(ply, body, name, val)
	if not ply then
		return nil
	end

	local pbodypart = wardrobe.getBodypartByName(ply, name)
	if not pbodypart then return nil end

	if val >= pbodypart.nummodels then
		return nil
	end

	local current = math.floor(body / pbodypart.base) % pbodypart.nummodels
	return body - (current * pbodypart.base) + (val * pbodypart.base)
end

function wardrobe.getBodyparts(ply)
	local mdl_parse = mdlparser.open(ply:GetModel())
	if not mdl_parse then return nil end

	pcall(mdl_parse.parse, mdl_parse)
	if not mdl_parse:isValid() then return nil end

	return mdl_parse:getBodyparts()
end

function wardrobe.resetBodygroups()
	net.Start("wardrobe.requestbodygroup")
		net.WriteUInt(0, 24)
	net.SendToServer()
end

function wardrobe.updateBodygroups(tbl)
	if not tbl then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local body = ply.wardrobeBodygroups or 0
	for name, val in pairs(tbl) do
		local res = wardrobe.calculateBodygroup(ply, body, name, val)
		if res then body = res end
	end

	ply.wardrobeBodygroups = body

	net.Start("wardrobe.requestbodygroup")
		net.WriteUInt(body, 24)
	net.SendToServer()

	return body
end

function wardrobe.requestBodygroups(tbl)
	if not tbl then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local body = 0
	for name, val in pairs(tbl) do
		local res = wardrobe.calculateBodygroup(ply, body, name, val)
		if res then body = res end
	end

	ply.wardrobeBodygroups = body

	net.Start("wardrobe.requestbodygroup")
		net.WriteUInt(body, 24)
	net.SendToServer()

	return body
end
