wardrobe.preview = {}
wardrobe.preview.on = false
wardrobe.preview.speed = 32

function wardrobe.preview.view(pl, pos, oang, fov)
	local v = {}
	local t = (RealTime() * wardrobe.preview.speed) % 360

	local ang = Angle(10, t, 0)
	v.origin = pos - ang:Forward() * 100
	v.fov = fov
	v.angles = ang

	return v
end

function wardrobe.preview.drawLocal()
	return wardrobe.preview.on
end

function wardrobe.preview.toggle(mdl, forceoff, ignoreReset)
	if wardrobe.preview.on or forceoff then
		hook.Remove("CalcView", "wardrobe_preview")
		hook.Remove("ShouldDrawLocalPlayer", "wardrobe_preview")

		if not ignoreReset then wardrobe.lightSetLocal() end
		wardrobe.preview.on = false
	else
		wardrobe.preview.on = true
		wardrobe.lightSetLocal(mdl)

		hook.Add("CalcView", "wardrobe_preview", wardrobe.preview.view)
		hook.Add("ShouldDrawLocalPlayer", "wardrobe_preview", wardrobe.preview.drawLocal)
	end
end
