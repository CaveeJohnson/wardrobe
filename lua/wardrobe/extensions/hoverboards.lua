if SERVER then return end
wardrobe.hoverboards = {}

local function _renderBoard(ent)
	if ent.wardrobe then
		ent:SetModel(ent.wardrobe)

		if wardrobe.hoverboards[ent] then
			ent:InvalidateBoneCache()
		end
	end

	ent:DrawModel()
end

local function _forceBoard(ent)
    local mdl = ent.wardrobe
    if mdl then
		ent:InvalidateBoneCache()
			ent:SetModel(mdl)
		ent:InvalidateBoneCache()
	end
end

local function _onHoverPlyChange(ent, name, old, new)
	if not (new:IsValid() and new:IsPlayer()) then return end

	local mdl = new.wardrobe
	if not mdl then return end

	ent.wardrobe = mdl
	wardrobe.hoverboards[ent] = wardrobe.forceRetries

	_forceBoard(ent)
	ent.RenderOverride = _renderBoard
end

local function _hoverboards()
	for ent, retry in pairs(wardrobe.hoverboards) do
		if ent:IsValid() and retry > 0 then
			wardrobe.hoverboards[ent] = retry - 1

			_forceBoard(ent)
		elseif wardrobe.hoverboards[ent] then
			wardrobe.hoverboards[ent] = nil
		end
	end
end

function wardrobe.fixHoverboardAvatar(ent)
	local class = ent:GetClass()
	if not class:match("^.*modulus_hoverboard_avatar") then return end

    ent:SetNWVarProxy("Player", _onHoverPlyChange)
end
hook.Add("NetworkEntityCreated", "wardrobe.hover", wardrobe.fixHoverboardAvatar)

function wardrobe.doThinkHover()
	_hoverboards()
end
hook.Add("Think", "wardrobe.hover", wardrobe.doThinkHover)
