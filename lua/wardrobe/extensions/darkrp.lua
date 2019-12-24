if not DarkRP then
	return
end

-- To enable/disable a specific job using wardrobe set
-- wardrobe = true/false in the job table, it may also be a function which returns true or false and a fail message

-- To set a specific model to use with wardrobe when they become that job set
-- wardrobe_default = {id, "model"}

-- You can also restrict a job to using specific wsids and models, this may be a table, function or single value
-- wardrobe_restrict = {id, id2, "model", "model2", id3, etc},
--[[
	wardrobe_restrict = function(ply, wsid, mdl)
		if wsid ~= 1337 then
			return false, "This job can only use addon 1337"
		end
	end,
]]

-- To stop a job from removing their wardrobe model, set
-- wardrobe_preventRemoval = true in the job table

-- To return a failure message other than "No access! ..." you can use
-- wardrobe_failmsg = "msg" in the job table, or a function to return a message
--[[
	wardrobe_failmsg = function(ply, wsid, mdl)
		return "Oh no, you can't use this!"
	end,
]]


-- resetOnJobChange: Should the model be reset on job change, regardless of if they still
-- have access to wardrobe?
wardrobe.config.resetOnJobChange = false

-- blockByDefault: Should the default state be to block wardrobe unless jobs explicitly
-- enable wardrobe via wardrobe = true?
wardrobe.config.blockByDefault = false


-- Do not go further than this unless you know what you are doing.
-- No, seriously. Stop.


-- S T O P.


print("Wardrobe | Loaded DarkRP extension (v2)!")

hook.Add("Wardrobe_AccessAllowed", "extensions.darkrp", function(ply, wsid, mdl)
	local job = ply.getJobTable and ply:getJobTable() or {}
	local jbwd = wardrobe.config.blockByDefault

	local fail = "No access! (Wrong job)"
	if job.wardrobe_failmsg then
		if isfunction(job.wardrobe_failmsg) then
			fail = job.wardrobe_failmsg(ply, wsid, mdl) or fail
		else
			fail = job.wardrobe_failmsg
		end
	end

	if not wsid or wsid == 0 or not mdl then
		if job.wardrobe_preventRemoval then
			return false, fail
		else
			return true
		end
	end

	if     job.wardrobe and isfunction(job.wardrobe) then
		return job.wardrobe(ply, wsid, mdl)
	elseif job.wardrobe == false then
		return false, fail
	elseif job.wardrobe ~= true and jbwd then
		return false, fail
	end

	if job.wardrobe_restrict then
		local restrict = job.wardrobe_restrict

		if isfunction(restrict) then
			local res, msg = restrict(ply, wsid, mdl)

			if res == false then
				return res, msg
			end
		elseif istable(restrict) then
			if not (table.HasValue(restrict, wsid) or table.HasValue(restrict, mdl)) then
				return false, "This addon is not on the whitelist!"
			end
		elseif not (restrict == wsid or restrict == mdl) then
			return false, "This addon is not on the whitelist!"
		end
	end
end)

if SERVER then
	hook.Add("OnPlayerChangedTeam", "wardrobe.extensions.darkrp", function(ply)
		local job = ply.getJobTable and ply:getJobTable() or {}

		if istable(job.wardrobe_default) and #job.wardrobe_default == 2 and tonumber(job.wardrobe_default[1]) then
			wardrobe.setModel(ply, tonumber(job.wardrobe_default[1]), job.wardrobe_default[2]) -- Set the wardrobe model to the default
		elseif ply.wardrobe and (hook.Run("Wardrobe_AccessAllowed", ply) == false or wardrobe.config.resetOnJobChange) then
			wardrobe.setModel(ply) -- Reset their model because it isn't allowed anymore
		end
	end)
end
