if not ulx then
	return
end

print("Wardrobe | Loading ULX extension!")

local CATEGORY_NAME = "Wardrobe"

if SERVER then
	ULib.ucl.registerAccess("wardrobe", "user", "Can the user use wardrobe?", CATEGORY_NAME)
end

hook.Add("Wardrobe_AccessAllowed", "extensions.ulx", function(ply)
	if not ULib.ucl.query(ply, "wardrobe") then
		return false, "No access! (Wrong usergroup)"
	end
end)

function ulx.forcewardrobe(calling_ply, target_plys, wsid, mdl)
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]

		wardrobe.setModel(v, tonumber(wsid) or 0, mdl)
		table.insert(affected_plys, v)
	end

	ulx.fancyLogAdmin(calling_ply, "#A forced the model of #T to #s from addon #s", affected_plys, mdl, wsid)
end

local forcewardrobe = ulx.command(CATEGORY_NAME, "ulx forcewardrobe", ulx.forcewardrobe, "!forcewardrobe")
	forcewardrobe:addParam{type = ULib.cmds.PlayersArg}
	forcewardrobe:addParam{type = ULib.cmds.StringArg, hint = "Workshop ID"}
	forcewardrobe:addParam{type = ULib.cmds.StringArg, hint = "Model"}
	forcewardrobe:defaultAccess(ULib.ACCESS_SUPERADMIN)
	forcewardrobe:help("Force a player to wear a chosen model from a specified addon.")

function ulx.forceresetwardrobe(calling_ply, target_plys)
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]

		wardrobe.setModel(v)
		table.insert(affected_plys, v)
	end

	ulx.fancyLogAdmin(calling_ply, "#A forced reset the model of #T", affected_plys)
end

local forceresetwardrobe = ulx.command(CATEGORY_NAME, "ulx forceresetwardrobe", ulx.forceresetwardrobe, "!forceresetwardrobe")
	forceresetwardrobe:addParam{type = ULib.cmds.PlayersArg}
	forceresetwardrobe:defaultAccess(ULib.ACCESS_ADMIN)
	forceresetwardrobe:help("Force a player to wear their normal model.")


function ulx.wardrobeblacklist(calling_ply, target_plys, res)
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]

		wardrobe.blacklist.add(v, res)
		table.insert(affected_plys, v)
	end

	ulx.fancyLogAdmin(calling_ply, "#A blacklisted #T from using wardrobe for #s", affected_plys, res)
end

local wardrobeblacklist = ulx.command(CATEGORY_NAME, "ulx wardrobeblacklist", ulx.wardrobeblacklist, "!wardrobeblacklist")
	wardrobeblacklist:addParam{type = ULib.cmds.PlayersArg}
	wardrobeblacklist:addParam{type = ULib.cmds.StringArg, hint = "Reason", ULib.cmds.takeRestOfLine}
	wardrobeblacklist:defaultAccess(ULib.ACCESS_ADMIN)
	wardrobeblacklist:help("Blacklist a player from using wardrobe.")

function ulx.wardrobeunblacklist(calling_ply, target_plys)
	local affected_plys = {}
	for i = 1, #target_plys do
		local v = target_plys[i]

		wardrobe.blacklist.remove(v)
		table.insert(affected_plys, v)
	end

	ulx.fancyLogAdmin(calling_ply, "#A unblacklisted #T from using wardrobe", affected_plys, mdl, wsid)
end

local wardrobeunblacklist = ulx.command(CATEGORY_NAME, "ulx wardrobeunblacklist", ulx.wardrobeunblacklist, "!wardrobeunblacklist")
	wardrobeunblacklist:addParam{type = ULib.cmds.PlayersArg}
	wardrobeunblacklist:defaultAccess(ULib.ACCESS_ADMIN)
	wardrobeunblacklist:help("Remove a player from the wardrobe usage blacklist.")
