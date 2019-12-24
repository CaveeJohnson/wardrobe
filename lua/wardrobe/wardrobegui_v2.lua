local L = wardrobe.language and wardrobe.language.get or function(s) return s end
wardrobe.gui = {}

function wardrobe.gui.buildNewSheet(name, icon, pan)
	if not IsValid(wardrobe.gui.frame) then
		wardrobe.gui.constructFramework()
		wardrobe.gui.buildDefaultSheets()
	end

	local panel = vgui.Create(pan or "DScrollPanel", wardrobe.gui.frame.sheet)
		function panel:Paint(w, h) end

		panel:Dock(FILL)
		panel:DockMargin(8, 8, 8, 8)

	local newSheet = wardrobe.gui.frame.sheet:AddSheet(name, panel, icon)

	return panel, newSheet
end

function wardrobe.gui.buildNewSettingsSheet(name, icon, pan)
	if not IsValid(wardrobe.gui.frame) then
		wardrobe.gui.constructFramework()
		wardrobe.gui.buildDefaultSheets()
	end

	local panel = vgui.Create(pan or "DScrollPanel", wardrobe.gui.frame.sheet.settings)
		function panel:Paint(w, h) end

		panel:Dock(FILL)
		panel:DockMargin(8, 8, 8, 8)

	local newSheet = wardrobe.gui.frame.sheet.settings:AddSheet(name, panel, icon)

	return panel, newSheet
end

function wardrobe.gui.getModel()
	local pmdl = LocalPlayer():GetModel()

	local frame = wardrobe.gui.frame
	if not IsValid(frame) then return pmdl end

	return frame.model:GetModel() or pmdl
end

function wardrobe.gui.getModelEntity()
	local frame = wardrobe.gui.frame
	if not IsValid(frame) then return end

	return frame.model.Entity
end

do
	local function _niceBodygroupName(name)
		name = name:gsub("_", " ")
		name = name:gsub("^%l", string.upper)

		return name:Trim()
	end

	function wardrobe.gui.populateBodygroupsPanel(fromCurrent)
		local ent = wardrobe.gui.getModelEntity()
		if not IsValid(ent) then return end

		print("populateBodygroupsPanel", fromCurrent)

		local model = ent:GetModel()

		local frame = wardrobe.gui.frame
		local panel = frame.sheet.selector.bodygroups

		panel:Clear()

		wardrobe.gui.skinUpdate = 0
		wardrobe.gui.shouldUpdateSkin = false

		local skinCount = (fromCurrent and ply or ent):SkinCount() - 1
		local ply = LocalPlayer()

		do
			local row = vgui.Create("DPanel", panel)
				row:Dock(TOP)
				row:DockPadding(0, 0, 0, 4)
				row:SetHeight(24)

				function row:Paint(w, h) end

				local label = vgui.Create("DLabel", row)
					label:SetPos(10, 4)
					label:SetWide(100)

					label:SetText(L"Skin")
					label:SetDark(true)

				local wang = vgui.Create("DNumberWang", row)
					wang:SetMinMax(0, skinCount)
					if fromCurrent then
						wang:SetValue(ply:GetSkin())
					end
					if skinCount == 0 then
						wang:SetEnabled(false)
					end

					function wang:OnValueChanged(val)
						wardrobe.gui.shouldUpdateSkin = true
						wardrobe.gui.skinUpdate = math.floor(val)

						local ent = wardrobe.gui.getModelEntity()
						if not IsValid(ent) then return end

						ent:SetSkin(math.floor(val))
					end

				function row:PerformLayout(w, h)
					wang:SetPos(w - wang:GetWide() - 10, (24 - wang:GetTall()) / 2)
				end
		end

		if fromCurrent then
			local ent = frame.model.Entity

			ent:SetSkin(ply:GetSkin())
			for i = 0, ply:GetNumBodyGroups() - 1 do
				ent:SetBodygroup(i, ply:GetBodygroup(i))
			end
		end

		local mdl = mdlparser.open(model)
		if not mdl then return end

		pcall(mdl.parse, mdl)
		if not mdl:isValid() then return end

		local bodyparts = mdl:getBodyparts()

		wardrobe.gui.bodygroupUpdate = {}
		wardrobe.gui.shouldUpdateBodygroups = false

		for i = 2, mdl.bodypart_count do
			local part = bodyparts[i]

			if part and part.nummodels > 1 then
				local groupName = part.name

				local row = vgui.Create("DPanel", panel)
					row:Dock(TOP)
					row:DockPadding(0, 0, 0, 4)
					row:SetHeight(24)

					function row:Paint(w, h)
						surface.SetDrawColor(0, 0, 0, 200)
						surface.DrawLine(0, 0, w, 0)
					end

					local label = vgui.Create("DLabel", row)
						label:SetPos(10, 4)
						label:SetWide(100)

						label:SetText(_niceBodygroupName(groupName))
						label:SetDark(true)

					local current = fromCurrent and ply:GetBodygroup(i - 1) or 0

					if part.nummodels == 2 then
						local check = vgui.Create("DCheckBox", row)
							check:SetChecked(current == 0 and 0 or 1)

							function check:OnChange(val)
								wardrobe.gui.shouldUpdateBodygroups = true
								wardrobe.gui.bodygroupUpdate[groupName] = val and 1 or 0

								local ent = wardrobe.gui.getModelEntity()
								if not IsValid(ent) then return end

								ent:SetBodygroup(i - 1, val and 1 or 0)
							end

						function row:PerformLayout(w, h)
							check:SetPos(w - check:GetWide() - 10, (24 - check:GetTall()) / 2)
						end
					else
						local wang = vgui.Create("DNumberWang", row)
							wang:SetMinMax(0, part.nummodels - 1)
							wang:SetValue(current)

							function wang:OnValueChanged(val)
								wardrobe.gui.shouldUpdateBodygroups = true
								wardrobe.gui.bodygroupUpdate[groupName] = math.floor(val)

								local ent = wardrobe.gui.getModelEntity()
								if not IsValid(ent) then return end

								ent:SetBodygroup(i - 1, math.floor(val))
							end

						function row:PerformLayout(w, h)
							wang:SetPos(w - wang:GetWide() - 10, (24 - wang:GetTall()) / 2)
						end
					end

				panel:AddItem(row)
			end
		end
	end
end

function wardrobe.gui.setPreviewModel(mdl)
	local frame = wardrobe.gui.frame
	if not IsValid(frame) then return end

	wardrobe.gui.previewing = true

	local panel = frame.model
	DModelPanel.SetModel(panel, mdl)

	wardrobe.gui.populateBodygroupsPanel(false)
end

function wardrobe.gui.resetPreviewModel(dontUsePly)
	local frame = wardrobe.gui.frame
	if not IsValid(frame) then return end

	wardrobe.gui.previewing = false

	frame.sheet.selector.list:ClearSelection()

	frame.sheet.selector.request:SetText(L"Request Model")
	frame.sheet.selector.request:SetEnabled(false)

	frame.sheet.selector.preview:SetText(L"Preview Model")
	frame.sheet.selector.preview:SetEnabled(false)

	frame.model:SetModel(LocalPlayer():GetModel())

	wardrobe.gui.populateBodygroupsPanel(not dontUsePly)
end

function wardrobe.gui.previewModelRequestDone()
	local frame = wardrobe.gui.frame
	if not IsValid(frame) then return end

	wardrobe.gui.previewing = false

	frame.sheet.selector.list:ClearSelection()

	frame.sheet.selector.request:SetText(L"Request Model")
	frame.sheet.selector.request:SetEnabled(false)

	frame.sheet.selector.preview:SetText(L"Preview Model")
	frame.sheet.selector.preview:SetEnabled(false)

	wardrobe.gui.updateSkinAndBodygroups(true)
end

function wardrobe.gui.updateSkinAndBodygroups(updateFromZero)
	if wardrobe.gui.shouldUpdateBodygroups then
		if updateFromZero then
			wardrobe.requestBodygroups(wardrobe.gui.bodygroupUpdate)
		else
			wardrobe.updateBodygroups(wardrobe.gui.bodygroupUpdate)
		end
	else
		wardrobe.resetBodygroups()
	end

	if wardrobe.gui.shouldUpdateSkin then
		wardrobe.requestSkin(wardrobe.gui.skinUpdate)
	else
		wardrobe.requestSkin(0)
	end

	wardrobe.gui.bodygroupUpdate = {}
	wardrobe.gui.shouldUpdateBodygroups = false

	wardrobe.gui.skinUpdate = 0
	wardrobe.gui.shouldUpdateSkin = false
end

function wardrobe.gui.addNewModels(id, md, meta)
	local frame = wardrobe.gui.frame
	if not IsValid(frame) then return end

	surface.PlaySound("buttons/button14.wav")

	local panel = frame.sheet.selector.list

	local c = function(path, name, hands)
		panel.handslookup[path] = hands
		panel:AddLine(id, name or "???", path, hands and L"Yes" or L"No")
	end
	wardrobe.frontend.parseModels(md, meta, c)
end

function wardrobe.gui.constructBrowser()
	if IsValid(wardrobe.gui.browser) then return end

	wardrobe.gui.browser = vgui.Create("DFrame")
	local f = wardrobe.gui.browser
		f:SetSize(ScrW() - 100, ScrH() - 130)
		f:Center()
		f:MakePopup()
		f:SetVisible(false)
		f:SetDeleteOnClose(false)

		f:SetTitle("")

		function f:Paint() end

	f.controls = vgui.Create("DHTMLControls", f)
	local c = f.controls
		c:Dock(TOP)

	f.html = vgui.Create("DHTML", f)
	local h = f.html
		h:Dock(FILL)
		h:OpenURL(wardrobe.config.workshopDefaultUrl)
		h:SetAllowLua(true)

		h:AddFunction("wardrobe", "selectAddon", function()
			if h.addon then
				wardrobe.getAddon(h.addon, function(_, _, _, mdls, meta)
					if IsValid(wardrobe.gui.frame) then
						wardrobe.gui.addNewModels(h.addon, mdls, meta)
					end
				end, not wardrobe.showMetaLess:GetBool())

				f:Close()
				h:OpenURL(wardrobe.config.workshopDefaultUrl)
				c.AddressBar:SetText(wardrobe.config.workshopDefaultUrl)
			end
		end)

		function h:OnFinishLoadingDocument(str)
			local wsid = str
			wsid = wsid:gsub("https?://steamcommunity%.com/sharedfiles/filedetails/%?id=", "")
			wsid = wsid:gsub("&searchtext=.*", "")

			wsid = tonumber(wsid or -1)
			if not wsid or wsid <= 1 then return end

			self.addon = wsid
			self:RunJavascript(
				[[document.getElementById("SubscribeItemOptionAdd").innerText = "Select Addon";]]
			)
			self:RunJavascript(
				[[document.getElementById("SubscribeItemBtn").setAttribute("onclick", "wardrobe.selectAddon();");]]
			)
		end

	c:SetHTML(h)
	c.AddressBar:SetText(wardrobe.config.workshopDefaultUrl)
	h:OpenURL(wardrobe.config.workshopDefaultUrl)
end

function wardrobe.gui.openBrowser()
	if not IsValid(wardrobe.browser) then
		wardrobe.gui.constructBrowser()
	end

	wardrobe.gui.browser.controls.AddressBar:SetText(wardrobe.config.workshopDefaultUrl)
	wardrobe.gui.browser.html:OpenURL(wardrobe.config.workshopDefaultUrl)

	wardrobe.gui.browser:SetVisible(true)
	wardrobe.gui.browser:MoveToFront()
end

local workshop_working = Color(80 , 255, 80 , 170)

function wardrobe.gui.constructFramework()
	if wardrobe.gui.frame then wardrobe.gui.frame:Remove() end

	wardrobe.gui.frame = vgui.Create("DFrame")
	local f = wardrobe.gui.frame
		f:SetDeleteOnClose(false)
		f:SetTitle(L"Wardrobe - Main Menu" .. " (" .. wardrobe.version .. ")")
		f:SetIcon("icon64/wardrobe64.png")

		f:SetSize(800, 500)
		f:Center()

		f:MakePopup()
		f:SetVisible(false)

		do
			surface.SetFont("DermaDefault")
			local tw, _ = surface.GetTextSize(L"Workshop: Working...")
			tw = tw + 16

			local bgColor = Color(255, 255, 255, 155)
			function f:Paint(w, h)
				SKIN.tex.Window.Normal(4, 2, w - 8, 20, bgColor)

				local work = workshop.isWorking()
				draw.SimpleText(
					work and L"Workshop: Working..." or L"Workshop: Idle",
					"DermaDefault",
					w - tw - 100 + 8, 5,
					work and workshop_working or bgColor,
					TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
				)
			end
		end

	wardrobe.gui.frame.sheet = vgui.Create("DPropertySheet", f)
	local s = wardrobe.gui.frame.sheet
		s:Dock(FILL)
		s:DockMargin(4, 0, 0, 0)

	wardrobe.gui.frame.model = vgui.Create("DModelPanel", f)
	local m = wardrobe.gui.frame.model
		m:SetPaintBackgroundEnabled(false)
		m:SetPaintBorderEnabled(false)
		m:SetPaintBackground(false)

		m.pos = Vector(0, 0, 2)
		m.camAngles = Angle(-15, 20, 0)

		m.offset = 80

		m.rotateXScale = 0.8
		m.rotateYScale = 0.3
		m.scrollScale  = 1.1

		local bgColor = Color(255, 255, 255, 155)
		function m:Paint(w, h)
			SKIN.tex.Tab_Control(0, 0, w, h, bgColor)

			DModelPanel.Paint(self, w, h)
		end

		function m:LayoutEntity(ent)
			ent:SetPos(self.pos)

			if self.bAnimated then self:RunAnimation() end

			if self.pressed then
				local mx, my = gui.MousePos()
				self.camAngles = self.camAngles + Angle(
					((self.pressY or my) - my) * self.rotateYScale,
					((self.pressX or mx) - mx) * self.rotateXScale,
					0
				)

				self.pressX, self.pressY = gui.MousePos()
			end

			self.vCamPos = self.vLookatPos + (self.camAngles:Forward() * self.offset)
			self.aLookAngle = (self.vLookatPos - self.vCamPos):Angle()
		end

		function m:OnMouseWheeled(delta)
			self.offset = self.offset - (delta * self.scrollScale)
		end

		function m:DragMousePress()
			self.pressX, self.pressY = gui.MousePos()
			self.pressed = true
		end

		function m:DragMouseRelease()
			self.pressed = false
		end

		local ply = LocalPlayer()
		m:SetModel(ply:GetModel())

		for i = 0, ply:GetNumBodyGroups() - 1 do
			m.Entity:SetBodygroup(i, ply:GetBodygroup(i))
		end

		m:Dock(LEFT)
		m:SetWidth(300)

		m:SetFOV(35)
end

function wardrobe.gui.buildSelectionSheet(selector)
	selector.list = vgui.Create("DListView", selector)
	local l = selector.list
		l:Dock(TOP)
		l:SetHeight(150)

		l.handslookup = {}

		l:AddColumn(L"Workshop ID"):SetFixedWidth(95)
		l:AddColumn(L"Name"):SetFixedWidth(140)
		l:AddColumn(L"Path")
		l:AddColumn(L"Hands?"):SetFixedWidth(60)

		function l:OnRowRightClick(i, r)
			local wsid = r:GetColumnText(1)
			local path = r:GetColumnText(3)

			local menu = DermaMenu(self)
			if path then menu:AddOption(L"Copy Model",       function() SetClipboardText(path) end):SetIcon("icon16/page_copy.png") end
			if wsid then menu:AddOption(L"Copy Workshop ID", function() SetClipboardText(wsid) end):SetIcon("icon16/page_code.png") end
			menu:Open()

			self.listMenu = menu
		end

		function wardrobe.gui.addNewModels(id, md, meta)
			surface.PlaySound("buttons/button14.wav")

			local c = function(path, name, hands)
				l.handslookup[path] = hands
				l:AddLine(id, name or "???", path, hands and L"Yes" or L"No")
			end
			wardrobe.frontend.parseModels(md, meta, c)
		end

	selector.request = vgui.Create("DButton", selector)
	local rb = selector.request
		rb:Dock(TOP)
		rb:SetHeight(24)

		rb:SetText(L"Request Model")
		rb:SetEnabled(false)

		function rb:DoClick()
			local wsid = tonumber(l.wsid)
			if not wsid or not l.selected then return end

			self:SetText(L"Request Model")
			self:SetEnabled(false)

			if wardrobe.frontend.makeRequest(wsid, l.selected, l.hands) then
				wardrobe.gui.frame:Close()
			end
		end

	selector.preview = vgui.Create("DButton", selector)
	local pb = selector.preview
		pb:Dock(TOP)
		pb:SetHeight(24)

		pb:SetText(L"Preview Model")
		pb:SetEnabled(false)

	function l:OnRowSelected(i, r)
		local selected = r:GetColumnText(3)
		if selected == LocalPlayer():GetModel() then
			self.selected = nil
			self.wsid = nil
			self.hands = nil

			rb:SetText(L"Request Model")
			rb:SetEnabled(false)

			return
		end

		self.selected = selected
		self.wsid = r:GetColumnText(1)
		self.hands = self.handslookup[self.selected]

		rb:SetText(string.format("%s '%s'", L"Request", r:GetColumnText(2)))
		rb:SetEnabled(true)

		pb:SetEnabled(true)

		return DListView.OnRowSelected(self, i, r)
	end

	selector.spacer1 = vgui.Create("DPanel", selector)
	local sp1 = selector.spacer1
		function sp1:Paint() end
		sp1:Dock(TOP)
		sp1:SetHeight(24)

	selector.bodygroups = vgui.Create("DScrollPanel", selector)
	local bg = selector.bodygroups
		bg:Dock(TOP)
		bg:SetHeight(150)

		local bgColor = Color(255, 255, 255, 155)
		function bg:Paint(w, h)
			SKIN.tex.Tab_Control(0, 0, w, h, bgColor)
		end

	function pb:DoClick()
		if wardrobe.gui.previewing then
			wardrobe.gui.resetPreviewModel()
		elseif l.selected and l.selected ~= LocalPlayer():GetModel() then
			wardrobe.gui.setPreviewModel(l.selected)

			self:SetText(L"Cancel Previewing")
		end
	end

	selector.updateBodygroups = vgui.Create("DButton", selector)
	local ubgb = selector.updateBodygroups
		ubgb:Dock(TOP)
		ubgb:SetHeight(24)

		ubgb:SetText(L"Update Bodygroups")
		ubgb:SetEnabled(false)

		function ubgb:Think()
			if (wardrobe.gui.shouldUpdateBodygroups or wardrobe.gui.shouldUpdateSkin) and not wardrobe.gui.previewing then
				self:SetEnabled(true)
			else
				self:SetEnabled(false)
			end

			DButton.Think(self)
		end

		function ubgb:DoClick()
			wardrobe.gui.updateSkinAndBodygroups()

			self:SetEnabled(false)
		end

	selector:AddItem(l)
	selector:AddItem(rb)
	selector:AddItem(pb)

	selector:AddItem(sp1)

	selector:AddItem(bg)
	selector:AddItem(ubgb)

	wardrobe.gui.populateBodygroupsPanel(true)
end

function wardrobe.gui.buildDownloadSheet(download)
	download.browser = vgui.Create("DButton", download)
	local b = download.browser
		b:Dock(TOP)
		b:SetHeight(24)

		b:SetText(L"Open Workshop Browser")

		function b:DoClick()
			wardrobe.gui.openBrowser()
		end

	download:AddItem(b)
end

function wardrobe.gui.buildBlacklistSheet(blacklist)
	blacklist.listDock = vgui.Create("DPanel", blacklist)
	local d = blacklist.listDock
		d:Dock(FILL)
		d:DockMargin(0, 0, 0, 2)

		function d:Paint() end

	blacklist.list = vgui.Create("DListView", blacklist)
	local l = blacklist.list
		l:Dock(TOP)
		l:SetHeight(120)

		l:AddColumn(L"Name"):SetFixedWidth(140)
		l:AddColumn(L"Workshop ID"):SetFixedWidth(95)
		l:AddColumn(L"Path")

		l.plys = {}

		function l:update()
			self:Clear()

			local i = 0
			for k, v in ipairs(player.GetAll()) do
				if v.wardrobe then
					i = i + 1

					self.plys[i] = v
					self:AddLine(v:Nick(), v.wardrobeWsid, v.wardrobe)
				end
			end

			d.Players.list:update()
			d.Addons.list:update()
			d.Models.list:update()
		end

		function l:OnRowRightClick(i, r)
			local wsid = r:GetColumnText(2)
			local path = r:GetColumnText(3)
			local ply  = self.plys[i]
			local steamid = IsValid(ply) and ply:SteamID()

			local menu = DermaMenu(self)
			if steamid then menu:AddOption(L"Copy SteamID",     function() SetClipboardText(steamid) end):SetIcon("icon16/vcard.png") end
			if path then    menu:AddOption(L"Copy Model",       function() SetClipboardText(path) end)   :SetIcon("icon16/page_copy.png") end
			if wsid then    menu:AddOption(L"Copy Workshop ID", function() SetClipboardText(wsid) end)   :SetIcon("icon16/page_code.png") end
			menu:Open()

			self.listMenu = menu
		end

	blacklist.cbPanel = vgui.Create("DPanel", blacklist)
	local p = blacklist.cbPanel
		p:Dock(TOP)
		p:DockMargin(0, 0, 0, 2)
		p:SetHeight(22)

		function p:Paint() end

	blacklist.cbPanel.ignoreUser = vgui.Create("DButton", blacklist.cbPanel)
	local pc = blacklist.cbPanel.ignoreUser
		pc:Dock(LEFT)
		pc:SetWidth(100)

		pc:SetText(L"Ignore player")
		pc:SetEnabled(false)

		function pc:DoClick()
			if not IsValid(l.ply) then return end
			wardrobe.frontend.blacklistPly(l.ply)

			l:update()
		end

	blacklist.cbPanel.ignoreAddon = vgui.Create("DButton", blacklist.cbPanel)
	local pa = blacklist.cbPanel.ignoreAddon
		pa:Dock(LEFT)
		pa:SetWidth(100)

		pa:SetText(L"Ignore addon")
		pa:SetEnabled(false)

		function pa:DoClick()
			wardrobe.frontend.blacklistWsid(l.wsid)

			l:update()
		end

	blacklist.cbPanel.ignoreModel = vgui.Create("DButton", blacklist.cbPanel)
	local pm = blacklist.cbPanel.ignoreModel
		pm:Dock(LEFT)
		pm:SetWidth(100)

		pm:SetText(L"Ignore model")
		pm:SetEnabled(false)

		function pm:DoClick()
			wardrobe.frontend.blacklistModel(l.path)

			l:update()
		end

	function l:OnRowSelected(i, r)
		self.wsid = r:GetColumnText(2)
		self.path = r:GetColumnText(3)
		self.ply  = self.plys[i]

		pc:SetEnabled(true)
		pa:SetEnabled(true)
		pm:SetEnabled(true)

		return DListView.OnRowSelected(self, i, r)
	end

	blacklist.cbPanel.refresh = vgui.Create("DButton", blacklist.cbPanel)
	local pr = blacklist.cbPanel.refresh
		pr:Dock(RIGHT)
		pr:SetWidth(100)

		pr:SetText(L"Refresh")

		function pr:DoClick()
			l:update()
		end

	local blackTypes = {
		{"Players",{"SteamID", "Name"}},
		{"Addons", {"Workshop ID"}},
		{"Models", {"Path"}},
	}

	for k, v in ipairs(blackTypes) do
		blacklist.listDock[v[1]] = vgui.Create("DPanel", blacklist.listDock)
		local dv = blacklist.listDock[v[1]]
			dv:Dock(LEFT)
			dv:DockMargin(2, 0, 2, 2)
			dv:SetWidth(462 / #blackTypes - #blackTypes * 2)

			function dv:Paint() end

		blacklist.listDock[v[1]].list = vgui.Create("DListView", blacklist.listDock[v[1]])
		local lv = blacklist.listDock[v[1]].list
			lv:Dock(FILL)

			for k2, v2 in ipairs(v[2]) do
				lv:AddColumn(L(v2))
			end

		blacklist.listDock[v[1]].removeElement = vgui.Create("DButton", blacklist.listDock[v[1]])
		local pv = blacklist.listDock[v[1]].removeElement
			pv:Dock(BOTTOM)

			pv:SetText(L"Remove Selected")
			pv:SetEnabled(false)

			function pv:DoClick()
				if lv.removid then
					lv:RemoveLine(lv.removid)
					wardrobe.frontend.unBlacklist(lv.toremove)

					pv:SetEnabled(false)
				end
			end

			function lv:OnRowSelected(i, r)
				lv.toremove = r:GetColumnText(1)
				lv.removid = i

				pv:SetEnabled(true)

				return DListView.OnRowSelected(self, i, r)
			end

			function lv:update()
				self:Clear()
				local a = wardrobe["ignore" .. v[1]]
				for i, b in pairs(a) do
					self:AddLine(i, b)
				end
			end

		lv:update()
	end

	l:update()
end

function wardrobe.gui.buildDownloadSheet(download)
	download.browser = vgui.Create("DButton", download)
	local b = download.browser
		b:Dock(TOP)
		b:SetHeight(24)

		b:SetText(L"Open Workshop Browser")

		function b:DoClick()
			wardrobe.gui.openBrowser()
		end

	download:AddItem(b)
end

wardrobe.gui.optionConvars = {
	{
		con = "wardrobe_enabled",
		off = "Completely Disable Wardrobe",
		on  = "Enable Wardrobe",
	},
	{
		con = "wardrobe_friendsonly",
		off = "Use Everyone's Custom Model",
		on  = "Only Use My Friends's Custom Models",
	},
	{
		con = "wardrobe_showunlikelymodels",
		off = "Hide Unlikely Models",
		on  = "Show Unlikely Models",
	},
	{
		con = "wardrobe_requestlastmodel",
		off = "Disable 'Last Model' Autoload",
		on  = "Enable 'Last Model' Autoload",
	},
	{
		con = "wardrobe_ignorepvsloading",
		off = "Load Custom Models As Players Become Visible",
		on  = "Load Custom Models Regardless of Visibility",
	},
}

if GetConVar("wardrobe_loadgmodlegs") then
	table.insert(wardrobe.gui.optionConvars, {
		con = "wardrobe_loadgmodlegs",
		off = "Don't Load Legs",
		on  = "Load Legs",
	})
end

function wardrobe.gui.buildOptionsSheet(options)
	for _, v in ipairs(wardrobe.gui.optionConvars) do
		local dcl = vgui.Create("DCheckBoxLabel", options)
			dcl:Dock(TOP)
			dcl:DockMargin(0, 0, 0, 4)

			dcl:SetConVar(v.con)

			function dcl:Think()
				self:SetText(self:GetChecked() and L(v.off) or L(v.on))
			end
	end
end

function wardrobe.rebuildMenu()
	wardrobe.guiLoaded = false

	if IsValid(wardrobe.gui.frame)   then wardrobe.gui.frame:Remove()   end
	if IsValid(wardrobe.gui.browser) then wardrobe.gui.browser:Remove() end

	wardrobe.guiLoaded = true
	wardrobe.openMenu()
end

-- https://github.com/robotboy655/gmod-lua-menu/blob/master/lua/menu/custom/mainmenu.lua#L236
-- heavily modified veversion of lua menu's language panel
function wardrobe.openLanguages(pnl)
	local panel = vgui.Create("DScrollPanel", pnl)
	panel:SetSize(157, 90)
	panel:SetPos(pnl:GetWide() - panel:GetWide(), 20)

	function panel:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 220)
		surface.DrawRect(0, 0, w - 5, h)
	end

	local p = vgui.Create("DIconLayout", panel)
		p:Dock(FILL)
		p:SetBorder(5)
		p:SetSpaceY(5)
		p:SetSpaceX(5)

	for id, flag in pairs(wardrobe.language.available) do
		local f = p:Add("DImageButton")
			f:SetIcon("flags16/" .. flag .. ".png")
			f:SetSize(16, 12)

			function f:DoClick()
				wardrobe.frontend.setLanguage(id)
				wardrobe.rebuildMenu()
			end
	end

	return panel
end

function wardrobe.gui.buildDefaultSheets()
	local sheet = wardrobe.gui.frame.sheet

	sheet.selector = wardrobe.gui.buildNewSheet(L"Select",   "icon16/basket_go.png")
	local selector = sheet.selector
		wardrobe.gui.buildSelectionSheet(selector)

	sheet.download = wardrobe.gui.buildNewSheet(L"Download", "icon16/basket_put.png")
	local download = sheet.download
		wardrobe.gui.buildDownloadSheet(download)

	local settingsTab
	sheet.settings, settingsTab = wardrobe.gui.buildNewSheet("", "icon16/cog.png", "DPropertySheet")
	local settings = sheet.settings
		function settingsTab.Tab:PerformLayout()
			self:ApplySchemeSettings()

			self.Image:SetPos(10, 3)

			if not self:IsActive() then
				self.Image:SetImageColor(Color(255, 255, 255, 155))
			else
				self.Image:SetImageColor(Color(255, 255, 255, 255))
			end
		end

		settings.language = vgui.Create("DImageButton", settings)
		local pb = settings.language
			pb:SetSize(28, 16)

			pb:SetIcon("flags16/" .. wardrobe.language.icon() .. ".png")

			function pb:DoClick()
				if IsValid(self.langs) then
					return self.langs:Remove()
				end

				self.langs = wardrobe.openLanguages(settings)
			end

		function settings:PerformLayout()
			pb:SetPos(self:GetWide() - 28 - 2, 2)

			DPropertySheet.PerformLayout(self)
		end

		settings.options   = wardrobe.gui.buildNewSettingsSheet(L"Options",   "icon16/wrench.png")
		local options      = settings.options
			wardrobe.gui.buildOptionsSheet(options)

		settings.blacklist = wardrobe.gui.buildNewSettingsSheet(L"Blacklist", "icon16/user_delete.png", "DPanel")
		local blacklist    = settings.blacklist
			wardrobe.gui.buildBlacklistSheet(blacklist)

		settings.about     = wardrobe.gui.buildNewSettingsSheet(L"About",     "icon16/help.png", "DPanel")
		local about        = settings.about
			about.html = vgui.Create("DHTML", about)
				local h = about.html
					h:Dock(FILL)

					h:OpenURL("http://hexahedron.pw/wardrobe.html")
end

function wardrobe.openMenu()
	if not IsValid(wardrobe.gui.frame) then
		wardrobe.gui.constructFramework()
		wardrobe.gui.buildDefaultSheets()

		if wardrobe.config.whitelistMode and wardrobe.config.whitelistMode > 0 then
			-- If the whitelist is in 'only use these' mode then preload them all

			for k, v in pairs(wardrobe.config.whitelistIds) do
				wardrobe.getAddon(k, function(_, _, _, mdls, meta)
					wardrobe.gui.addNewModels(k, mdls, meta)
				end, not wardrobe.showMetaLess:GetBool())
			end
		elseif wardrobe.lastAddon then
			-- Load the last addon into the list

			if wardrobe.lastAddonInfo then
				wardrobe.gui.addNewModels(wardrobe.lastAddon, wardrobe.lastAddonInfo[4], wardrobe.lastAddonInfo[5])
			else
				wardrobe.getAddon(wardrobe.lastAddon, function(_, _, _, mdls, meta)
					wardrobe.gui.addNewModels(wardrobe.lastAddon, mdls, meta)
				end, not wardrobe.showMetaLess:GetBool())
			end
		end

		wardrobe.guiLoaded = true
	end

	wardrobe.gui.frame:SetVisible(true)
end

function wardrobe.gui.escapeMenu()
	if not (gui.IsGameUIVisible() and input.IsKeyDown(KEY_ESCAPE)) then return end

	if IsValid(wardrobe.gui.frame) and wardrobe.gui.frame:IsVisible() then
		gui.HideGameUI()
		wardrobe.gui.frame:Close()

		if IsValid(wardrobe.gui.browser) and wardrobe.gui.browser:IsVisible() then
			wardrobe.gui.browser:Close()
		end
	end
end
hook.Add("PreRender", "wardrobe", wardrobe.gui.escapeMenu)

-- Binding to the backend below.

concommand.Add("wardrobe", wardrobe.openMenu)

function wardrobe.gui.receiveUpdate(ply, model)
	if ply ~= LocalPlayer() then return end

	if model == wardrobe.gui.getModel() then
		wardrobe.gui.previewModelRequestDone()
	else
		wardrobe.resetBodygroups()
		wardrobe.requestSkin(0)

		wardrobe.gui.resetPreviewModel(true)
	end
end
hook.Add("Wardrobe_PostSetModel", "wardrobe", wardrobe.gui.receiveUpdate)

function wardrobe.gui.menuCommand(ply, str)
	if ply ~= LocalPlayer() then return end

	str = str:Trim()
	local f = str:find((wardrobe.config.commandPrefix or "[!|/]") .. (wardrobe.config.command or "wardrobe"))
	if f == 1 then
		wardrobe.openMenu()
	end
end
hook.Add("OnPlayerChat", "wardrobe", wardrobe.gui.menuCommand)

function wardrobe.gui.output(code, text)
	-- not much yet

	--if wardrobe.printlogs:GetBool() then
		print(text)
	--end
end
hook.Add("Wardrobe_Output", "wardrobe.gui", wardrobe.gui.output)

function wardrobe.gui.notif(msg)
	notification.AddLegacy(L(msg), NOTIFY_HINT, 6)
	surface.PlaySound("buttons/button11.wav")
end
hook.Add("Wardrobe_Notification", "wardrobe.gui", wardrobe.gui.notif)

local icon = "icon64/wardrobe64.png" -- Thanks PAC
	icon = file.Exists("materials/" .. icon, "GAME")
	and not Material(icon):IsError() -- Some fucking moron served the 404 html in his fastdl
	and icon
	or "icon64/playermodel.png"

list.Set("DesktopWindows", "Wardrobe", {
	title		= L"Wardrobe",
	icon		= icon,
	width		= 960,
	height		= 700,
	onewindow	= true,
	init		= function(_, window)
		window:Remove()
		wardrobe.openMenu()
	end
})

wardrobe.dbg("loaded wardrobe gui (v2)")
