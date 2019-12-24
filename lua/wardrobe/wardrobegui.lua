local L = wardrobe.language and wardrobe.language.get or function(s) return s end

wardrobe.helpUrl = "http://hexahedron.pw/wardrobe.html"

if wardrobe.helpPanel and IsValid(wardrobe.helpPanel) then wardrobe.helpPanel:Remove() end
function wardrobe.constructHelp()
	if wardrobe.helpPanel and IsValid(wardrobe.helpPanel) then return end

	wardrobe.helpPanel = vgui.Create("DFrame")
	local f = wardrobe.helpPanel

	f:SetSize(800, 600)
	f:Center()
	f:MakePopup()
	f:SetVisible(false)
	f:SetDeleteOnClose(false)

	function f:OnClose()
		if not wardrobe.helpPanel.closedByOther then
			wardrobe.modelSelector.shouldHelp = false
		end
	end

	f:SetTitle(L"Wardrobe - Help")
	f:SetIcon("icon16/user_suit.png")

	wardrobe.helpPanel.html = vgui.Create("DHTML", wardrobe.helpPanel)
	local h = wardrobe.helpPanel.html

	h:Dock(FILL)
	h:OpenURL(wardrobe.helpUrl)
end

function wardrobe.openHelp()
	if not (wardrobe.helpPanel and IsValid(wardrobe.helpPanel)) then
		wardrobe.constructHelp()
	end

	wardrobe.helpPanel.closedByOther = nil
	wardrobe.helpPanel:SetVisible(true)

	wardrobe.helpPanel:MoveToFront()
end

if wardrobe.blacklistPanel and IsValid(wardrobe.blacklistPanel) then wardrobe.blacklistPanel:Remove() end
function wardrobe.constructBlacklist()
	if wardrobe.blacklistPanel and IsValid(wardrobe.blacklistPanel) then return end

	wardrobe.blacklistPanel = vgui.Create("DFrame")
	local f = wardrobe.blacklistPanel

	f:SetSize(800, 600)
	f:Center()
	f:MakePopup()
	f:SetVisible(false)
	f:SetDeleteOnClose(false)

	function f:OnClose()
		if not wardrobe.blacklistPanel.closedByOther then
			wardrobe.modelSelector.shouldBlack = false
		end

		if IsValid(self.listMenu) then
			self.listMenu:Remove()
		end
	end

	f:SetTitle(L"Wardrobe - Blacklist")
	f:SetIcon("icon16/user_suit.png")

	wardrobe.blacklistPanel.listDock = vgui.Create("DPanel", wardrobe.blacklistPanel)
	local d = wardrobe.blacklistPanel.listDock

	d:Dock(FILL)
	d:DockMargin(0, 0, 0, 2)

	function d:Paint()
	end

	wardrobe.blacklistPanel.list = vgui.Create("DListView", wardrobe.blacklistPanel)
	local l = wardrobe.blacklistPanel.list

	l:Dock(TOP)
	l:AddColumn(L"Name"):SetFixedWidth(140)
	l:AddColumn(L"Workshop ID"):SetFixedWidth(95)
	l:AddColumn(L"Path")

	l:SetHeight(275)

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

		local a = wardrobe.blacklistPanel.listDock
		a.Players.list:update()
		a.Addons.list:update()
		a.Models.list:update()
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

		f.listMenu = menu
	end

	wardrobe.blacklistPanel.cbPanel = vgui.Create("DPanel", wardrobe.blacklistPanel)
	local p = wardrobe.blacklistPanel.cbPanel

	p:SetHeight(22)
	p:Dock(TOP)
	p:DockMargin(0, 0, 0, 2)

	function p:Paint()
	end

	wardrobe.blacklistPanel.cbPanel.ignoreUser = vgui.Create("DButton", wardrobe.blacklistPanel.cbPanel)
	local pc = wardrobe.blacklistPanel.cbPanel.ignoreUser

	pc:SetText(L"Ignore player")
	pc:SetEnabled(false)

	pc:SetWidth(125)
	pc:Dock(LEFT)

	function pc:DoClick()
		if not IsValid(f.ply) then return end
		wardrobe.frontend.blacklistPly(f.ply)

		l:update()
	end

	wardrobe.blacklistPanel.cbPanel.ignoreAddon = vgui.Create("DButton", wardrobe.blacklistPanel.cbPanel)
	local pa = wardrobe.blacklistPanel.cbPanel.ignoreAddon

	pa:SetText(L"Ignore addon")
	pa:SetEnabled(false)

	pa:SetWidth(125)
	pa:Dock(LEFT)

	function pa:DoClick()
		wardrobe.frontend.blacklistWsid(f.wsid)

		l:update()
	end

	wardrobe.blacklistPanel.cbPanel.ignoreModel = vgui.Create("DButton", wardrobe.blacklistPanel.cbPanel)
	local pm = wardrobe.blacklistPanel.cbPanel.ignoreModel

	pm:SetText(L"Ignore model")
	pm:SetEnabled(false)

	pm:SetWidth(125)
	pm:Dock(LEFT)

	function pm:DoClick()
		wardrobe.frontend.blacklistModel(path)

		l:update()
	end

	function l:OnRowSelected(i, r)
		f.wsid = r:GetColumnText(2)
		f.path = r:GetColumnText(3)
		f.ply  = self.plys[i]

		pc:SetEnabled(true)
		pa:SetEnabled(true)
		pm:SetEnabled(true)

		return DListView.OnRowSelected(self, i, r)
	end

	wardrobe.blacklistPanel.cbPanel.refresh = vgui.Create("DButton", wardrobe.blacklistPanel.cbPanel)
	local pr = wardrobe.blacklistPanel.cbPanel.refresh

	pr:SetText(L"Refresh")

	pr:SetWidth(125)
	pr:Dock(RIGHT)

	function pr:DoClick()
		l:update()
	end

	local blackTypes = {
		{"Players",{"SteamID", "Name"}},
		{"Addons", {"Workshop ID"}},
		{"Models", {"Path"}},
	}

	for k, v in ipairs(blackTypes) do
		wardrobe.blacklistPanel.listDock[v[1]] = vgui.Create("DPanel", wardrobe.blacklistPanel.listDock)
		local dv = wardrobe.blacklistPanel.listDock[v[1]]

		dv:Dock(LEFT)
		dv:DockMargin(2, 0, 2, 2)
		dv:SetWidth(800 / #blackTypes - #blackTypes * 2)

		function dv:Paint()
		end

		wardrobe.blacklistPanel.listDock[v[1]].list = vgui.Create("DListView", wardrobe.blacklistPanel.listDock[v[1]])
		local lv = wardrobe.blacklistPanel.listDock[v[1]].list

		lv:Dock(FILL)

		for k2, v2 in ipairs(v[2]) do
			lv:AddColumn(L(v2))
		end

		wardrobe.blacklistPanel.listDock[v[1]].removeElement = vgui.Create("DButton", wardrobe.blacklistPanel.listDock[v[1]])
		local pv = wardrobe.blacklistPanel.listDock[v[1]].removeElement

		pv:SetText(L"Remove Selected")
		pv:SetEnabled(false)

		pv:Dock(BOTTOM)

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

function wardrobe.openBlacklist()
	if not (wardrobe.blacklistPanel and IsValid(wardrobe.blacklistPanel)) then
		wardrobe.constructBlacklist()
	end

	wardrobe.blacklistPanel.closedByOther = nil
	wardrobe.blacklistPanel:SetVisible(true)

	wardrobe.blacklistPanel:MoveToFront()
end

-- https://github.com/robotboy655/gmod-lua-menu/blob/3e80b5c340d10e725e48189264919f2b2a5c1520/lua/menu/custom/mainmenu.lua#L236
-- heavily modified veversion of lua menu's language panel
function wardrobe.openLanguages(pnl)
	local panel = vgui.Create("DScrollPanel", pnl)
	panel:SetSize(157, 90)
	panel:SetPos(pnl:GetWide() - panel:GetWide(), 50)

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

		f.DoClick = function()
			wardrobe.frontend.setLanguage(id)

			panel:Remove()
			wardrobe.rebuildMenu()
		end
	end

	return panel
end

if wardrobe.settingsPanel and IsValid(wardrobe.settingsPanel) then wardrobe.settingsPanel:Remove() end
function wardrobe.constructSettings()
	if wardrobe.settingsPanel and IsValid(wardrobe.settingsPanel) then return end

	wardrobe.settingsPanel = vgui.Create("DFrame")
	local f = wardrobe.settingsPanel

	f:SetSize(450, 500)
	f:Center()
	f:MakePopup()
	f:SetVisible(false)
	f:SetDeleteOnClose(false)

	function f:OnClose()
		if not wardrobe.settingsPanel.closedByOther then
			wardrobe.modelSelector.shouldSettings = false
		end
	end

	f:SetTitle(L"Wardrobe - Settings")
	f:SetIcon("icon16/user_suit.png")

	wardrobe.settingsPanel.list = vgui.Create("DListView", wardrobe.settingsPanel)
	local l = wardrobe.settingsPanel.list

	if wardrobe.logTemp then
		for k, v in ipairs(wardrobe.logTemp) do
			l:AddLine(v[1], v[2])
		end

		wardrobe.logTemp = nil
	end

	l:Dock(FILL)
	l:AddColumn(L"Type"):SetFixedWidth(45)
	l:AddColumn(L"Info")
	l:SetSortable(false) -- its time based (whats printed first in console)

	wardrobe.settingsPanel.cbPanel = vgui.Create("DPanel", wardrobe.settingsPanel)
	local p = wardrobe.settingsPanel.cbPanel

	p:SetHeight(22)
	p:Dock(TOP)
	p:DockMargin(0, 0, 0, 0)

	function p:Paint()
	end

	wardrobe.settingsPanel.cbPanel2 = vgui.Create("DPanel", wardrobe.settingsPanel)
	local p2 = wardrobe.settingsPanel.cbPanel2

	p2:SetHeight(22)
	p2:Dock(TOP)
	p2:DockMargin(0, 0, 0, 2)

	function p2:Paint()
	end

	wardrobe.settingsPanel.cbPanel.enabled = vgui.Create("DButton", wardrobe.settingsPanel.cbPanel)
	local pc = wardrobe.settingsPanel.cbPanel.enabled

	local b = wardrobe.enabled:GetBool()
	pc:SetText(b and L"Disable wardrobe" or L"Enable wardrobe")

	pc:SetWidth(125)
	pc:Dock(LEFT)

	function pc:DoClick()
		local a = wardrobe.enabled:GetBool()
		RunConsoleCommand("wardrobe_enabled", a and "0" or "1")
	end

	function pc:Think()
		local a = wardrobe.enabled:GetBool()
		self:SetText(a and L"Disable wardrobe" or L"Enable wardrobe")

		DButton.Think(self)
	end

	wardrobe.settingsPanel.cbPanel.friends = vgui.Create("DButton", wardrobe.settingsPanel.cbPanel)
	local pf = wardrobe.settingsPanel.cbPanel.friends

	b = wardrobe.friendsonly:GetBool()
	pf:SetText(b and L"See Everyone" or L"See Friends only")

	pf:SetWidth(125)
	pf:Dock(LEFT)

	function pf:DoClick()
		local a = wardrobe.friendsonly:GetBool()
		RunConsoleCommand("wardrobe_friendsonly", a and "0" or "1")
	end

	function pf:Think()
		local a = wardrobe.friendsonly:GetBool()
		self:SetText(a and L"See Everyone" or L"See Friends only")

		DButton.Think(self)
	end

	wardrobe.settingsPanel.cbPanel.autoLoad = vgui.Create("DButton", wardrobe.settingsPanel.cbPanel)
	local pa = wardrobe.settingsPanel.cbPanel.autoLoad

	local bool = wardrobe.autoLoad:GetBool()
	pa:SetText(bool and L"Disable Autoload" or L"Enable Autoload")

	pa:SetWidth(125)
	pa:Dock(LEFT)

	function pa:DoClick()
		local a = wardrobe.autoLoad:GetBool()
		RunConsoleCommand("wardrobe_requestlastmodel", a and "0" or "1")
	end

	function pa:Think()
		local a = wardrobe.autoLoad:GetBool()
		self:SetText(a and L"Disable Autoload" or L"Enable Autoload")

		DButton.Think(self)
	end

	wardrobe.settingsPanel.cbPanel.showUnlikely = vgui.Create("DButton", wardrobe.settingsPanel.cbPanel2)
	local pu = wardrobe.settingsPanel.cbPanel.showUnlikely

	bool = wardrobe.showMetaLess:GetBool()
	pu:SetText(bool and L"Hide Unlikely" or L"Show Unlikely")

	pu:SetWidth(125)
	pu:Dock(LEFT)

	function pu:DoClick()
		local a = wardrobe.showMetaLess:GetBool()
		RunConsoleCommand("wardrobe_showunlikelymodels", a and "0" or "1")
	end

	function pu:Think()
		local a = wardrobe.showMetaLess:GetBool()
		self:SetText(a and L"Hide Unlikely" or L"Show Unlikely")

		DButton.Think(self)
	end

	local legs = GetConVar("wardrobe_loadgmodlegs")
	if legs then
		wardrobe.settingsPanel.cbPanel.loadLegs = vgui.Create("DButton", wardrobe.settingsPanel.cbPanel2)
		local pl = wardrobe.settingsPanel.cbPanel.loadLegs

		bool = legs:GetBool()
		pl:SetText(bool and L"Don't Load Legs" or L"Load Legs")

		pl:SetWidth(125)
		pl:Dock(LEFT)

		function pl:DoClick()
			local a = legs:GetBool()
			RunConsoleCommand("wardrobe_loadgmodlegs", a and "0" or "1")
		end

		function pl:Think()
			local a = legs:GetBool()
			self:SetText(a and L"Don't Load Legs" or L"Load Legs")

			DButton.Think(self)
		end
	end

	wardrobe.settingsPanel.cbPanel.blacklist = vgui.Create("DButton", wardrobe.settingsPanel.cbPanel)
	local pbl = wardrobe.settingsPanel.cbPanel.blacklist

	pbl:SetIcon("icon16/picture_key.png")

	pbl:Dock(LEFT)
	pbl:SetWidth(25)

	function pbl:DoClick()
		wardrobe.modelSelector.shouldBlack = not wardrobe.modelSelector.shouldBlack

		if wardrobe.modelSelector.shouldBlack then
			wardrobe.openBlacklist()
		elseif IsValid(wardrobe.blacklistPanel) and wardrobe.blacklistPanel:IsVisible() then
			wardrobe.blacklistPanel:Close()
		end
	end

	wardrobe.settingsPanel.cbPanel.language = vgui.Create("DImageButton", wardrobe.settingsPanel.cbPanel)
	local pb = wardrobe.settingsPanel.cbPanel.language

	pb:SetIcon("flags16/" .. wardrobe.language.icon() .. ".png")

	pb:Dock(RIGHT)
	pb:SetWidth(30)

	function pb:DoClick()
		if IsValid(self.langs) then
			return self.langs:Remove()
		end

		self.langs = wardrobe.openLanguages(wardrobe.settingsPanel)
	end
end

function wardrobe.openSettings()
	if not (wardrobe.settingsPanel and IsValid(wardrobe.settingsPanel)) then
		wardrobe.constructSettings()
	end

	wardrobe.settingsPanel.closedByOther = nil
	wardrobe.settingsPanel:SetVisible(true)

	wardrobe.settingsPanel:MoveToFront()
end

if wardrobe.previewClicker and IsValid(wardrobe.previewClicker) then wardrobe.previewClicker:Remove() end
function wardrobe.constructPreviewClicker(wsid, selected, hands)
	surface.PlaySound("npc/vort/claw_swing1.wav")

	if wardrobe.previewClicker and IsValid(wardrobe.previewClicker) then
		local f = wardrobe.previewClicker
		f.wsid = wsid
		f.selected = selected
		f.hands = hands

		f.done = false

		return
	end

	wardrobe.previewClicker = vgui.Create("DFrame")
	local f = wardrobe.previewClicker

	function f:OnClose()
		wardrobe.preview.toggle(nil, true, f.done)

		if not f.done then
			wardrobe.openMenu()
		else
			f.done = false
		end
	end

	f:SetSize(200, 54)
	f:SetPos(ScrW() / 2 - 100, 54 + ScrH() * 0.1)
	f:MakePopup()
	f:SetVisible(false)
	f:SetDeleteOnClose(false)
	f.btnMaxim:SetVisible(false)
	f.btnMinim:SetVisible(false)

	f.wsid = wsid
	f.selected = selected
	f.hands = hands

	f.done = false

	f:SetTitle(L"Wardrobe - Preview")
	f:SetIcon("icon16/user_suit.png")

	wardrobe.previewClicker.request = vgui.Create("DButton", wardrobe.previewClicker)
	local r = wardrobe.previewClicker.request

	r:SetText(L"Request Model")
	r:Dock(FILL)

	function r:DoClick()
		local wsid = tonumber(f.wsid)
		if not wsid or not f.selected then return end

		if wardrobe.frontend.makeRequest(wsid, f.selected, f.hands) then
			f.done = true
			f:Close()
		end
	end

	wardrobe.previewClicker.skinSelector = vgui.Create("DNumberWang", wardrobe.previewClicker)
	local nw = wardrobe.previewClicker.skinSelector

	nw:SetWidth(45)
	nw:Dock(RIGHT)

	nw:SetMin(0)
	nw:SetValue(0)

	wardrobe.previewClicker.skinSelectorLabel = vgui.Create("DLabel", wardrobe.previewClicker)
	local sl = wardrobe.previewClicker.skinSelectorLabel

	sl:SetWidth(30)
	sl:Dock(RIGHT)

	sl:SetText(L"Skin")
	sl:DockMargin(4, 0, 0, 0)

	function nw:OnValueChanged(v)
		wardrobe.requestSkin(v)
	end

	function nw:Think()
		local num = LocalPlayer():SkinCount()

		self:SetMax(num - 1)
		DNumberWang.Think(self)
	end
end

function wardrobe.openPreviewClicker(wsid, selected, hands)
	wardrobe.constructPreviewClicker(wsid, selected, hands)

	wardrobe.previewClicker:SetVisible(true)
	wardrobe.previewClicker:MoveToFront()
end

if wardrobe.browserPanel and IsValid(wardrobe.browserPanel) then wardrobe.browserPanel:Remove() end
function wardrobe.constructBrowser()
	if wardrobe.browserPanel and IsValid(wardrobe.browserPanel) then return end

	wardrobe.browserPanel = vgui.Create("DFrame")
	local f = wardrobe.browserPanel

	f:SetSize(ScrW() - 100, ScrH() - 130)
	f:Center()
	f:MakePopup()
	f:SetVisible(false)
	f:SetDeleteOnClose(false)

	function f:OnClose()
		if not wardrobe.browserPanel.closedByOther then
			wardrobe.modelSelector.shouldBrowser = false
		end
	end

	f:SetTitle(L"Wardrobe - Addon Browser")
	f:SetIcon("icon16/user_suit.png")

	wardrobe.browserPanel.controls = vgui.Create("DHTMLControls", wardrobe.browserPanel)
	local c = wardrobe.browserPanel.controls

	c:Dock(TOP)

	wardrobe.browserPanel.html = vgui.Create("DHTML", wardrobe.browserPanel)
	local h = wardrobe.browserPanel.html

	c:SetHTML(h)
	c.AddressBar:SetText(wardrobe.config.workshopDefaultUrl)

	h:Dock(FILL)
	h:OpenURL(wardrobe.config.workshopDefaultUrl)
	h:SetAllowLua(true)

	h:AddFunction("wardrobe", "selectAddon", function()
		if h.addon then
			wardrobe.getAddon(h.addon, function(_, _, _, mdls, meta)
				if IsValid(wardrobe.modelSelector) then
					wardrobe.modelSelector:addModels(h.addon, mdls, meta)
				end
			end, not wardrobe.showMetaLess:GetBool())

			f:Close()
			h:OpenURL(wardrobe.config.workshopDefaultUrl)
			c.AddressBar:SetText(wardrobe.config.workshopDefaultUrl)
		end
	end)

	function h:OnFinishLoadingDocument(str)
		local wsid = str
		wsid = wsid:Trim():gsub("https?://steamcommunity%.com/sharedfiles/filedetails/%?id=", "")
		wsid = wsid:gsub("&searchtext=.*", "")

		wsid = tonumber(wsid or -1)
		if not wsid or wsid < 1 then return end

		self.addon = wsid
		self:RunJavascript([[document.getElementById("SubscribeItemOptionAdd").innerText = "Select Addon";]])
		self:RunJavascript([[document.getElementById("SubscribeItemBtn").setAttribute("onclick", "wardrobe.selectAddon();");]])
	end
end

function wardrobe.openBrowser()
	if not (wardrobe.browserPanel and IsValid(wardrobe.browserPanel)) then
		wardrobe.constructBrowser()
	end

	wardrobe.browserPanel.closedByOther = nil
	wardrobe.browserPanel:SetVisible(true)

	wardrobe.browserPanel:MoveToFront()
end

local workshop_working = Color(0  , 255, 0  , 255)
local workshop_idle    = Color(220, 220, 250, 255)

if wardrobe.modelSelector and IsValid(wardrobe.modelSelector) then wardrobe.modelSelector:Remove() end
function wardrobe.constructMenu()
	if wardrobe.modelSelector and IsValid(wardrobe.modelSelector) then return end

	wardrobe.modelSelector = vgui.Create("DFrame")
	local f = wardrobe.modelSelector

	f:SetSize(800, 500)
	f:Center()
	f:MakePopup()
	f:SetVisible(false)
	f:SetDeleteOnClose(false)

	f.handslookup = {}

	function f:OnClose()
		if IsValid(wardrobe.settingsPanel) then
			wardrobe.settingsPanel.closedByOther = true
			wardrobe.settingsPanel:Close()
		end

		if IsValid(wardrobe.helpPanel) then
			wardrobe.helpPanel.closedByOther = true
			wardrobe.helpPanel:Close()
		end

		if IsValid(wardrobe.blacklistPanel) then
			wardrobe.blacklistPanel.closedByOther = true
			wardrobe.blacklistPanel:Close()
		end

		if IsValid(wardrobe.browserPanel) then
			wardrobe.browserPanel.closedByOther = true
			wardrobe.browserPanel:Close()
		end

		if IsValid(self.listMenu) then
			self.listMenu:Remove()
		end
	end

	f:SetTitle(L"Wardrobe - Main Menu" .. " (" .. wardrobe.version .. ")")
	f:SetIcon("icon16/user_suit.png")

	wardrobe.modelSelector.workIndicator = vgui.Create("DLabel", wardrobe.modelSelector)
	local wk = wardrobe.modelSelector.workIndicator

	wk:SetText(L"Workshop: Idle")
	wk:SetTextColor(workshop_idle)

	surface.SetFont("DermaDefault")
	local w, _ = surface.GetTextSize(L"Workshop: Working...")

	wk:SetPos(f:GetWide() - w - 100, 2)
	wk:SetWidth(w)

	function wk:Think()
		local state = workshop.isWorking()

		if state ~= self.state then
			if state then
				wk:SetText(L"Workshop: Working...")
				wk:SetTextColor(workshop_working)
			else
				wk:SetText(L"Workshop: Idle")
				wk:SetTextColor(workshop_idle)
			end
			self.state = state
		end

		DLabel.Think(self)
	end

	wardrobe.modelSelector.list = vgui.Create("DListView", wardrobe.modelSelector)
	local l = wardrobe.modelSelector.list

	l:Dock(FILL)
	l:AddColumn(L"Workshop ID"):SetFixedWidth(95)
	l:AddColumn(L"Name"):SetFixedWidth(140)
	l:AddColumn(L"Path")
	l:AddColumn(L"Hands?"):SetFixedWidth(60)

	function l:OnRowRightClick(i, r)
		local wsid = r:GetColumnText(1)
		local path = r:GetColumnText(3)

		local menu = DermaMenu(self)
		if path then    menu:AddOption(L"Copy Model",       function() SetClipboardText(path) end)   :SetIcon("icon16/page_copy.png") end
		if wsid then    menu:AddOption(L"Copy Workshop ID", function() SetClipboardText(wsid) end)   :SetIcon("icon16/page_code.png") end
		menu:Open()

		f.listMenu = menu
	end

	function wardrobe.modelSelector:addModels(id, md, meta)
		surface.PlaySound("buttons/button14.wav")

		local c = function(path, name, hands)
			f.handslookup[path] = hands
			self.list:AddLine(id, name or "???", path, hands and L"Yes" or L"No")
		end
		wardrobe.frontend.parseModels(md, meta, c)
	end

	wardrobe.modelSelector.bottom = vgui.Create("DPanel", wardrobe.modelSelector)
	local b = wardrobe.modelSelector.bottom

	function b:Paint()
	end

	b:Dock(BOTTOM)
	b:DockMargin(0, 2, 0, 0)

	wardrobe.modelSelector.bottom.request = vgui.Create("DButton", wardrobe.modelSelector.bottom)
	local br = wardrobe.modelSelector.bottom.request

	br:SetText(L"Request Model")
	br:SetEnabled(false)

	br:Dock(FILL)

	function br:DoClick()
		local wsid = tonumber(f.wsid)
		if not wsid or not f.selected then return end

		if wardrobe.frontend.makeRequest(wsid, f.selected, f.hands) then
			f:Close()
		end
	end

	wardrobe.modelSelector.bottom.preview = vgui.Create("DButton", wardrobe.modelSelector.bottom)
	local bp = wardrobe.modelSelector.bottom.preview

	bp:SetText(L"Preview")
	bp:SetEnabled(false)

	bp:SetWidth(150)
	bp:Dock(LEFT)
	bp:DockMargin(0, 0, 2, 0)

	function bp:DoClick()
		local wsid = tonumber(f.wsid)
		if not wsid or not f.selected then return end

		wardrobe.preview.toggle(f.selected)
		wardrobe.openPreviewClicker(wsid, f.selected, f.hands)
		f:Close()
	end

	wardrobe.modelSelector.bottom.skinSelector = vgui.Create("DNumberWang", wardrobe.modelSelector.bottom)
	local nw = wardrobe.modelSelector.bottom.skinSelector

	nw:SetWidth(45)
	nw:Dock(RIGHT)

	nw:SetMin(0)
	nw:SetValue(0)

	wardrobe.modelSelector.bottom.skinSelectorLabel = vgui.Create("DLabel", wardrobe.modelSelector.bottom)
	local sl = wardrobe.modelSelector.bottom.skinSelectorLabel

	sl:SetWidth(30)
	sl:Dock(RIGHT)

	sl:SetText(L"Skin")
	sl:DockMargin(4, 0, 0, 0)

	function nw:OnValueChanged(v)
		wardrobe.requestSkin(v)
	end

	function nw:Think()
		local num = LocalPlayer():SkinCount()

		self:SetMax(num - 1)
		DNumberWang.Think(self)
	end

	function l:OnRowSelected(i, r)
		f.selected = r:GetColumnText(3)
		f.wsid = r:GetColumnText(1)
		f.hands = f.handslookup[f.selected]

		br:SetText(L"Request" .. " '" .. r:GetColumnText(2) .. "'")

		br:SetEnabled(true)
		bp:SetEnabled(true)

		return DListView.OnRowSelected(self, i, r)
	end

	wardrobe.modelSelector.wsPanel = vgui.Create("DPanel", wardrobe.modelSelector)
	local p = wardrobe.modelSelector.wsPanel

	p:SetHeight(22)
	p:Dock(TOP)
	p:DockMargin(0, 0, 0, 2)

	function p:Paint()
	end

	wardrobe.modelSelector.wsPanel.input = vgui.Create("DTextEntry", wardrobe.modelSelector.wsPanel)
	local pi = wardrobe.modelSelector.wsPanel.input

	pi:SetWidth(200)
	pi:SetUpdateOnType(true)
	pi:Dock(LEFT)

	wardrobe.modelSelector.wsPanel.getAddon = vgui.Create("DButton", wardrobe.modelSelector.wsPanel)
	local pb = wardrobe.modelSelector.wsPanel.getAddon

	pb:SetText("")
	pb:SetIcon("icon16/arrow_right.png")

	pb:Dock(LEFT)
	pb:SetWidth(25)

	function pi:OnValueChange(str)
		local wsid = str
		wsid = wsid:Trim():gsub("https?://steamcommunity%.com/sharedfiles/filedetails/%?id=", "")
		wsid = wsid:gsub("&searchtext=.*", "")

		wsid = tonumber(wsid or -1)
		if not wsid or wsid < 1 then return pb:SetEnabled(false) end

		pb:SetEnabled(true)
	end

	wardrobe.modelSelector.wsPanel.reset = vgui.Create("DButton", wardrobe.modelSelector.wsPanel)
	local pr = wardrobe.modelSelector.wsPanel.reset

	pr:SetText(L"Reset Model")
	pr:Dock(LEFT)
	pr:SetWidth(125)

	function pr:Think()
		self:SetEnabled(LocalPlayer().wardrobe ~= nil)

		return DButton.Think(self)
	end

	function pr:DoClick()
		wardrobe.requestModel(nil)
	end

	function pb:DoClick()
		local wsid = pi:GetValue()
		wsid = wsid:Trim():gsub("https?://steamcommunity%.com/sharedfiles/filedetails/%?id=", "")
		wsid = wsid:gsub("&searchtext=.*", "")

		wsid = tonumber(wsid or -1)
		if not wsid or wsid < 1 then return end

		wardrobe.getAddon(wsid, function(_, _, _, mdls, meta)
			f:addModels(wsid, mdls, meta)
			if IsValid(pi) then pi:SetValue("") end
		end, not wardrobe.showMetaLess:GetBool())
	end

	pb:SetEnabled(false)

	wardrobe.modelSelector.wsPanel.help = vgui.Create("DButton", wardrobe.modelSelector.wsPanel)
	local pe = wardrobe.modelSelector.wsPanel.help

	pe:SetText("")
	pe:SetIcon("icon16/help.png")

	pe:Dock(RIGHT)
	pe:SetWidth(25)

	function pe:DoClick()
		wardrobe.modelSelector.shouldHelp = not wardrobe.modelSelector.shouldHelp

		if wardrobe.modelSelector.shouldHelp then
			wardrobe.openHelp()
		elseif IsValid(wardrobe.helpPanel) and wardrobe.helpPanel:IsVisible() then
			wardrobe.helpPanel:Close()
		end
	end

	wardrobe.modelSelector.wsPanel.settings = vgui.Create("DButton", wardrobe.modelSelector.wsPanel)
	local ps = wardrobe.modelSelector.wsPanel.settings

	ps:SetText("")
	ps:SetIcon("icon16/table_gear.png")

	ps:Dock(RIGHT)
	ps:SetWidth(25)

	function ps:DoClick()
		wardrobe.modelSelector.shouldSettings = not wardrobe.modelSelector.shouldSettings

		if wardrobe.modelSelector.shouldSettings then
			wardrobe.openSettings()
		elseif IsValid(wardrobe.settingsPanel) and wardrobe.settingsPanel:IsVisible() then
			wardrobe.settingsPanel:Close()
		end
	end

	wardrobe.modelSelector.wsPanel.clearList = vgui.Create("DButton", wardrobe.modelSelector.wsPanel)
	local pc = wardrobe.modelSelector.wsPanel.clearList

	pc:SetText(L"Clear model list")
	pc:SetWidth(140)
	pc:Dock(RIGHT)

	function pc:DoClick()
		surface.PlaySound("buttons/button15.wav")

		l:Clear()
		f.handslookup = {}
	end

	wardrobe.modelSelector.wsPanel.openWs = vgui.Create("DButton", wardrobe.modelSelector.wsPanel)
	local pd = wardrobe.modelSelector.wsPanel.openWs

	pd:SetText(L"Open workshop")
	pd:SetWidth(140)
	pd:Dock(RIGHT)

	function pd:DoClick()
		wardrobe.modelSelector.shouldBrowser = not wardrobe.modelSelector.shouldBrowser

		if wardrobe.modelSelector.shouldBrowser then
			wardrobe.openBrowser()
		elseif IsValid(wardrobe.browserPanel) and wardrobe.browserPanel:IsVisible() then
			wardrobe.browserPanel:Close()
		end
	end
end

local doIgnore
function wardrobe.escapeMenu()
	if not (gui.IsGameUIVisible() and input.IsKeyDown(KEY_ESCAPE)) then return end

	if wardrobe.browserPanel and IsValid(wardrobe.browserPanel) and wardrobe.browserPanel:IsVisible() then
		gui.HideGameUI()
		wardrobe.browserPanel:Close()

		doIgnore = true
	elseif wardrobe.modelSelector and IsValid(wardrobe.modelSelector) and wardrobe.modelSelector:IsVisible() then
		if not doIgnore then
			gui.HideGameUI()
			wardrobe.modelSelector:Close()
		else
			doIgnore = false
		end
	elseif wardrobe.previewClicker and IsValid(wardrobe.previewClicker) and wardrobe.previewClicker:IsVisible() then
		gui.HideGameUI()
		wardrobe.previewClicker:Close()

		doIgnore = true
	end
end
hook.Add("PreRender", "wardrobe", wardrobe.escapeMenu)

function wardrobe.rebuildMenu()
	wardrobe.guiLoaded = false

	if wardrobe.helpPanel and IsValid(wardrobe.helpPanel) then           wardrobe.helpPanel:Remove()      end
	if wardrobe.blacklistPanel and IsValid(wardrobe.blacklistPanel) then wardrobe.blacklistPanel:Remove() end
	if wardrobe.modelSelector and IsValid(wardrobe.modelSelector) then   wardrobe.modelSelector:Remove()  end
	if wardrobe.previewClicker and IsValid(wardrobe.previewClicker) then wardrobe.previewClicker:Remove() end
	if wardrobe.settingsPanel and IsValid(wardrobe.settingsPanel) then   wardrobe.settingsPanel:Remove()  end
	if wardrobe.browserPanel and IsValid(wardrobe.browserPanel) then     wardrobe.browserPanel:Remove()   end

	wardrobe.guiLoaded = true
	wardrobe.openMenu()
end

function wardrobe.openMenu()
	if not (wardrobe.modelSelector and IsValid(wardrobe.modelSelector)) then
		wardrobe.constructMenu()

		if wardrobe.config.whitelistMode and wardrobe.config.whitelistMode > 0 then
			-- If the whitelist is in 'only use these' mode then preload them all

			for k, v in pairs(wardrobe.config.whitelistIds) do
				wardrobe.getAddon(k, function(_, _, _, mdls, meta)
					wardrobe.modelSelector:addModels(k, mdls, meta)
				end, not wardrobe.showMetaLess:GetBool())
			end
		elseif wardrobe.lastAddon then
			-- Load the last addon into the list

			if wardrobe.lastAddonInfo then
				wardrobe.modelSelector:addModels(wardrobe.lastAddon, wardrobe.lastAddonInfo[4], wardrobe.lastAddonInfo[5])
			else
				wardrobe.getAddon(wardrobe.lastAddon, function(_, _, _, mdls, meta)
					wardrobe.modelSelector:addModels(wardrobe.lastAddon, mdls, meta)
				end, not wardrobe.showMetaLess:GetBool())
			end
		end

		wardrobe.guiLoaded = true
	end

	wardrobe.modelSelector:SetVisible(true)
	wardrobe.modelSelector:MoveToFront()

	if wardrobe.modelSelector.shouldSettings and not (IsValid(wardrobe.settingsPanel) and wardrobe.settingsPanel:IsVisible()) then
		wardrobe.openSettings()
	end

	if wardrobe.modelSelector.shouldHelp and not (IsValid(wardrobe.helpPanel) and wardrobe.helpPanel:IsVisible()) then
		wardrobe.openHelp()
	end

	if wardrobe.modelSelector.shouldBlack and not (IsValid(wardrobe.blacklistPanel) and wardrobe.blacklistPanel:IsVisible()) then
		wardrobe.openBlacklist()
	end

	if wardrobe.modelSelector.shouldBrowser and not (IsValid(wardrobe.browserPanel) and wardrobe.browserPanel:IsVisible()) then
		wardrobe.openBrowser()
	end
end
concommand.Add("wardrobe", wardrobe.openMenu)

function wardrobe.menuCommand(ply, str)
	if ply ~= LocalPlayer() then return end

	str = str:Trim()
	local f = str:find((wardrobe.config.commandPrefix or "[!|/]") .. (wardrobe.config.command or "wardrobe"))
	if f == 1 then
		wardrobe.openMenu()
	end
end
hook.Add("OnPlayerChat", "wardrobe.gui", wardrobe.menuCommand)

function wardrobe.guiOutput(code, text)
	if wardrobe.guiLoaded then
		wardrobe.constructSettings()

		if IsValid(wardrobe.settingsPanel) and IsValid(wardrobe.settingsPanel.list) then
			wardrobe.settingsPanel.list:AddLine(code, text)
		end

		if wardrobe.printlogs:GetBool() then
			print(text)
		end
	else
		wardrobe.logTemp = wardrobe.logTemp or {}
		wardrobe.logTemp[#wardrobe.logTemp + 1] = {code, text}

		if wardrobe.printlogs:GetBool() then
			print(text)
		end
	end
end
hook.Add("Wardrobe_Output", "wardrobe.gui", wardrobe.guiOutput)

function wardrobe.guiNotif(msg)
	notification.AddLegacy(L(msg), NOTIFY_HINT, 6)
	surface.PlaySound("buttons/button11.wav")
end
hook.Add("Wardrobe_Notification", "wardrobe.gui", wardrobe.guiNotif)

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

wardrobe.dbg("loaded wardrobe gui")
