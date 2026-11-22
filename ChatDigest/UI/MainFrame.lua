-- ChatDigest: ventana principal con la lista de mensajes agrupados

local ChatDigest = LibStub("AceAddon-3.0"):GetAddon("ChatDigest")
local L = LibStub("AceLocale-3.0"):GetLocale("ChatDigest")

local format, floor, date = string.format, math.floor, date
local find, gmatch, strlower = string.find, string.gmatch, string.lower

local FRAME_NAME = "ChatDigestMainFrame"
local MIN_WIDTH, MIN_HEIGHT = 440, 160
local MAX_WIDTH, MAX_HEIGHT = 1200, 900
local HOVER_CHECK = 0.1

local TEXT_R, TEXT_G, TEXT_B = 255 / 255, 192 / 255, 192 / 255

local FILTERS = { "all", "raid", "dungeon", "trade", "guild", "other" }

local SOLID_TEXTURE = "Interface\\ChatFrame\\ChatFrameBackground"

local BLIZZARD_BACKDROP = {
	bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local function BuildBackdrop(style, size)
	if style == "blizzard" then
		return BLIZZARD_BACKDROP
	elseif style == "none" then
		return { bgFile = SOLID_TEXTURE, insets = { left = 0, right = 0, top = 0, bottom = 0 } }
	end
	return {
		bgFile   = SOLID_TEXTURE,
		edgeFile = SOLID_TEXTURE,
		edgeSize = size,
		insets   = { left = size, right = size, top = size, bottom = size },
	}
end

local TOOLTIP_LINKS = {
	item = true, spell = true, enchant = true, quest = true,
	achievement = true, talent = true, glyph = true,
}

local BUILTIN_FONTS = {
	["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
	["Arial Narrow"]     = "Fonts\\ARIALN.TTF",
	["Skurri"]           = "Fonts\\skurri.ttf",
	["Morpheus"]         = "Fonts\\MORPHEUS.ttf",
}

local function GetLSM()
	return LibStub("LibSharedMedia-3.0", true)
end

function ChatDigest:GetFontList()
	local list = { [""] = L["Chat font (default)"] }
	for name in pairs(BUILTIN_FONTS) do
		list[name] = name
	end
	local lsm = GetLSM()
	if lsm then
		for _, name in ipairs(lsm:List("font")) do
			list[name] = name
		end
	end
	return list
end

local function GetFontPath(name)
	if not name or name == "" then return nil end
	local lsm = GetLSM()
	if lsm and lsm:IsValid("font", name) then
		return lsm:Fetch("font", name)
	end
	return BUILTIN_FONTS[name]
end

local RAID_ICON_PATH = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:0|t"

local raidIconTags

local function BuildRaidIconTags()
	raidIconTags = {}
	for i = 1, 8 do
		raidIconTags["rt" .. i] = i
		local localized = _G["RAID_TARGET_" .. i]
		if localized then
			raidIconTags[strlower(localized)] = i
		end
	end
	if type(ICON_TAG_LIST) == "table" then
		for tag, index in pairs(ICON_TAG_LIST) do
			raidIconTags[strlower(tag)] = index
		end
	end
end

local function ReplaceRaidIcons(text)
	if not raidIconTags then BuildRaidIconTags() end
	return (text:gsub("%b{}", function(tag)
		local index = raidIconTags[strlower(tag:sub(2, -2))]
		if index then
			return format(RAID_ICON_PATH, index)
		end
	end))
end

local function ClassColorHex(class)
	local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	local c = class and colors[class]
	if not c then return "ffffff" end
	return format("%02x%02x%02x", floor(c.r * 255), floor(c.g * 255), floor(c.b * 255))
end

local function FormatEntry(e)
	local line = format("|cffcaf7fa[%s]|r |Hplayer:%s|h[|cff%s%s|r]|h",
		e.channelTag or "?", e.author, ClassColorHex(e.class), e.author)
	local timeFormat = ChatDigest.db.profile.window.timeFormat
	if timeFormat and timeFormat ~= "" then
		line = "[" .. date(timeFormat, e.lastSeen) .. "] " .. line
	end
	if e.count > 1 then
		line = line .. " |cffffd100x" .. e.count .. "|r"
	end
	if e.edited then
		line = line .. " |cff808080" .. L["(edited)"] .. "|r"
	end
	local text = e.text
	if e.alert then
		text = ChatDigest:HighlightAlerts(text, ChatDigest:GetAlertColorHex())
	end
	return line .. ": " .. ReplaceRaidIcons(text)
end

StaticPopupDialogs["CHATDIGEST_COPY_NAME"] = {
	text = L["COPY_NAME_TEXT"],
	button1 = OKAY,
	hasEditBox = 1,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

local function ShowCopyName(name)
	local dialog = StaticPopup_Show("CHATDIGEST_COPY_NAME")
	if not dialog then return end
	local editBox = _G[dialog:GetName() .. "EditBox"]
	editBox:SetText(name)
	editBox:SetFocus()
	editBox:HighlightText()
end

hooksecurefunc("UnitPopup_ShowMenu", function(_, which)
	local menuName = ChatDigest.openingPlayerMenu
	if not menuName or which ~= "FRIEND" or UIDROPDOWNMENU_MENU_LEVEL ~= 1 then return end
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["Copy name"]
	info.notCheckable = 1
	info.func = function() ShowCopyName(menuName) end
	UIDropDownMenu_AddButton(info)
end)

local function AgeText(seconds)
	if seconds < 60 then return L["just now"] end
	local minutes = floor(seconds / 60)
	if minutes < 60 then
		return format(L["%d min ago"], minutes)
	end
	return format(L["%d h %d min ago"], floor(minutes / 60), minutes % 60)
end

function ChatDigest:ShowPlayerTooltip(owner, name)
	local e = self.entries[name]
	local who = self.whoCache[name]
	self.tooltipName, self.tooltipOwner = name, owner

	GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
	local class = (e and e.class) or (who and who.classFile)
	GameTooltip:AddLine("|cff" .. ClassColorHex(class) .. name .. "|r")

	if who and not who.notFound then
		GameTooltip:AddLine(format(L["Level %d %s %s"], who.level, who.race, who.class), 1, 1, 1)
		if who.guild and who.guild ~= "" then
			GameTooltip:AddLine("<" .. who.guild .. ">", 0.25, 1, 0.25)
		end
		GameTooltip:AddLine(format("%s |cff808080(%s)|r", who.zone or "?", AgeText(time() - who.time)), 1, 0.82, 0)
	else
		if e and e.guid and e.guid ~= "" then
			local className, _, raceName = GetPlayerInfoByGUID(e.guid)
			if className and raceName then
				GameTooltip:AddLine(raceName .. " " .. className, 1, 1, 1)
			end
		end
		if who and who.notFound then
			GameTooltip:AddLine(L["WHO_NOT_FOUND"], 1, 0.3, 0.3, true)
		end
	end

	if e then
		local timeFormat = self.db.profile.window.timeFormat
		if not timeFormat or timeFormat == "" then timeFormat = "%H:%M:%S" end
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(L["Channel"], e.channelTag or "?", 0.7, 0.7, 0.7, 1, 1, 1)
		GameTooltip:AddDoubleLine(L["First seen"],
			date(timeFormat, e.firstSeen) .. " |cff808080(" .. AgeText(time() - e.firstSeen) .. ")|r",
			0.7, 0.7, 0.7, 1, 1, 1)
		GameTooltip:AddDoubleLine(L["Repeats"], e.count, 0.7, 0.7, 0.7, 1, 1, 1)
		if e.edited and e.previousText then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["Previous message:"], 0.7, 0.7, 0.7)
			GameTooltip:AddLine(ReplaceRaidIcons(e.previousText), 1, 0.75, 0.75, true)
		end
	end

	GameTooltip:AddLine(" ")
	if self:IsWhoPending(name) then
		GameTooltip:AddLine(L["Querying..."], 1, 0.82, 0)
	elseif who then
		GameTooltip:AddLine(L["SHIFT_CLICK_REFRESH"], 0.5, 0.5, 0.5)
	else
		GameTooltip:AddLine(L["SHIFT_CLICK_WHO"], 0.5, 0.5, 0.5)
	end
	GameTooltip:Show()
end

function ChatDigest:OnPlayerInfoUpdated(name)
	local owner = self.tooltipOwner
	if self.tooltipName == name and owner and GameTooltip:IsShown()
		and GameTooltip:GetOwner() == owner then
		self:ShowPlayerTooltip(owner, name)
	end
end

local function OnPlayerClick(name, button)
	local chatFrame = DEFAULT_CHAT_FRAME
	if button == "RightButton" then
		local e = ChatDigest.entries[name]
		ChatDigest.openingPlayerMenu = name
		FriendsFrame_ShowDropdown(name, 1, e and e.lineID, e and e.chatType, chatFrame)
		ChatDigest.openingPlayerMenu = nil
	elseif IsModifiedClick("CHATLINK") then
		local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
		if editBox then
			ChatEdit_InsertLink(name)
		elseif ChatDigest.db.profile.window.playerTooltip then
			if ChatDigest:QueryWho(name) then
				ChatDigest:OnPlayerInfoUpdated(name)
			end
		else
			SendWho(WHO_TAG_NAME .. name)
		end
	else
		ChatFrame_SendTell(name, chatFrame)
	end
end

local function OnHyperlinkClick(_, link, text, button)
	local linkType, rest = link:match("^([^:]+):(.*)$")
	if linkType == "player" then
		local name = rest:match("^([^:]+)")
		if name and name ~= "" then
			OnPlayerClick(name, button)
		end
	else
		SetItemRef(link, text, button)
	end
end

local function OnHyperlinkEnter(frame, link)
	local linkType = link:match("^([^:]+)")
	if linkType == "player" then
		local name = link:match("^player:([^:]+)")
		if name and ChatDigest.db.profile.window.playerTooltip then
			ChatDigest:ShowPlayerTooltip(frame, name)
		end
	elseif linkType and TOOLTIP_LINKS[linkType] then
		GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
		if pcall(GameTooltip.SetHyperlink, GameTooltip, link) then
			GameTooltip:Show()
		else
			GameTooltip:Hide()
		end
	end
end

local function OnHyperlinkLeave()
	ChatDigest.tooltipName = nil
	GameTooltip:Hide()
end

local function OnMouseWheel(frame, delta)
	if delta > 0 then
		if IsShiftKeyDown() then frame:ScrollToBottom() else frame:ScrollDown() end
	else
		if IsShiftKeyDown() then frame:ScrollToTop() else frame:ScrollUp() end
	end
end

local function CreateMessageList(f, content)
	local smf = CreateFrame("ScrollingMessageFrame", nil, content)
	smf:SetPoint("TOPLEFT", 2, -2)
	smf:SetPoint("BOTTOMRIGHT", -2, 12)
	smf:SetFontObject(ChatFontNormal)
	smf:SetJustifyH("LEFT")
	smf:SetFading(false)
	if smf.SetInsertMode then smf:SetInsertMode("TOP") end
	if smf.SetIndentedWordWrap then smf:SetIndentedWordWrap(true) end
	if smf.SetHyperlinksEnabled then smf:SetHyperlinksEnabled(true) end

	smf:EnableMouse(true)
	smf:EnableMouseWheel(true)
	smf:SetScript("OnMouseWheel", OnMouseWheel)
	smf:SetScript("OnHyperlinkClick", OnHyperlinkClick)
	smf:SetScript("OnHyperlinkEnter", OnHyperlinkEnter)
	smf:SetScript("OnHyperlinkLeave", OnHyperlinkLeave)

	smf:RegisterForDrag("LeftButton")
	smf:SetScript("OnDragStart", function() f:GetScript("OnDragStart")(f) end)
	smf:SetScript("OnDragStop", function() f:GetScript("OnDragStop")(f) end)

	return smf
end

local function SetEscapeCloses(enabled)
	for i = #UISpecialFrames, 1, -1 do
		if UISpecialFrames[i] == FRAME_NAME then
			tremove(UISpecialFrames, i)
		end
	end
	if enabled then
		tinsert(UISpecialFrames, FRAME_NAME)
	end
end

local function CreateFilterTabs(f, addon)
	local tabs = {}
	for i, filter in ipairs(FILTERS) do
		local b = CreateFrame("Button", nil, f)
		b:SetHeight(18)
		b.filter = filter

		local selected = b:CreateTexture(nil, "BACKGROUND")
		selected:SetAllPoints()
		selected:SetTexture(1, 1, 1, 0.15)
		b.selectedBg = selected

		local highlight = b:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetAllPoints()
		highlight:SetTexture(1, 1, 1, 0.08)

		local label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("CENTER")
		b.label = label

		b:SetScript("OnClick", function() addon:SetFilter(filter) end)
		tabs[i] = b
	end
	f.filterTabs = tabs
end

local function FilterLabel(filter)
	if filter == "all" then return L["All"] end
	return ChatDigest:GetCategoryLabel(filter)
end

function ChatDigest:GetFilter()
	local filter = self.db.profile.window.filter
	for _, f in ipairs(FILTERS) do
		if f == filter then return filter end
	end
	return "all"
end

function ChatDigest:SetFilter(filter)
	self.db.profile.window.filter = filter
	if self.frame then self.frame.resetScroll = true end
	self:RefreshList()
end

function ChatDigest:UpdateFilterTabs(counts)
	local f = self.frame
	local current = self:GetFilter()
	local prev
	for _, b in ipairs(f.filterTabs) do
		local isSelected = b.filter == current
		local color = isSelected and "|cffffd100" or "|cffa0a0a0"
		b.label:SetText(format("%s%s (%d)|r", color, FilterLabel(b.filter), counts[b.filter] or 0))
		b:SetWidth(b.label:GetStringWidth() + 12)
		b:ClearAllPoints()
		if prev then
			b:SetPoint("LEFT", prev, "RIGHT", 2, 0)
		else
			b:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -30)
		end
		if isSelected then b.selectedBg:Show() else b.selectedBg:Hide() end
		prev = b
	end
end

local function CreateSearchBox(f, leftOf, rightOf, addon)
	local box = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	box:SetHeight(18)
	box:SetAutoFocus(false)
	box:SetPoint("LEFT", leftOf, "RIGHT", 12, 0)
	box:SetPoint("RIGHT", rightOf, "LEFT", -4, 0)
	box:SetTextInsets(0, 16, 0, 0)

	local hint = box:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("LEFT", 0, 0)
	hint:SetText(L["Search..."])

	local clear = CreateFrame("Button", nil, box)
	clear:SetWidth(16)
	clear:SetHeight(16)
	clear:SetPoint("RIGHT", -2, 0)
	local x = clear:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	x:SetPoint("CENTER")
	x:SetText("X")
	clear:SetScript("OnEnter", function(self)
		x:SetTextColor(1, 1, 1)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L["Clear search"])
		GameTooltip:Show()
	end)
	clear:SetScript("OnLeave", function()
		x:SetTextColor(1, 0.82, 0)
		GameTooltip:Hide()
	end)
	clear:SetScript("OnClick", function()
		box:SetText("")
		box:ClearFocus()
	end)
	clear:Hide()

	local hasFocus = false
	local function UpdateDecorations()
		local empty = box:GetText() == ""
		if empty and not hasFocus then hint:Show() else hint:Hide() end
		if empty then clear:Hide() else clear:Show() end
	end

	box:SetScript("OnEditFocusGained", function()
		hasFocus = true
		UpdateDecorations()
	end)
	box:SetScript("OnEditFocusLost", function()
		hasFocus = false
		UpdateDecorations()
	end)
	box:SetScript("OnEscapePressed", box.ClearFocus)
	box:SetScript("OnEnterPressed", box.ClearFocus)
	box:SetScript("OnTextChanged", function(self)
		UpdateDecorations()
		addon:SetSearch(self:GetText())
	end)

	return box
end

function ChatDigest:SetSearch(text)
	local words = {}
	for word in gmatch(self:NormalizeText(text or ""), "%S+") do
		words[#words + 1] = word
	end
	local key = table.concat(words, " ")
	if key == (self.searchKey or "") then return end
	self.searchKey = key
	self.searchWords = (#words > 0) and words or nil
	if self.frame then self.frame.resetScroll = true end
	self:RefreshList()
end

local function MatchesSearch(e, words)
	local author = strlower(e.author)
	for _, word in ipairs(words) do
		if not find(e.normText, word, 1, true) and not find(author, word, 1, true) then
			return false
		end
	end
	return true
end

function ChatDigest:CreateMainFrame()
	if self.frame then return self.frame end
	local addon = self

	local f = CreateFrame("Frame", FRAME_NAME, UIParent)
	f:Hide()
	f:SetFrameStrata("MEDIUM")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:SetResizable(true)
	f:SetMinResize(MIN_WIDTH, MIN_HEIGHT)
	f:SetMaxResize(MAX_WIDTH, MAX_HEIGHT)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(frame)
		if not addon.db.profile.window.locked then
			frame:StartMoving()
		end
	end)
	f:SetScript("OnDragStop", function(frame)
		frame:StopMovingOrSizing()
		addon:SaveWindowGeometry()
	end)

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 12, -10)
	title:SetText("ChatDigest")
	f.title = title

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 2)
	close:SetScript("OnClick", function() addon:HideWindow() end)
	f.closeButton = close

	local options = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	options:SetText(L["Options"])
	options:SetWidth(options:GetFontString():GetStringWidth() + 24)
	options:SetHeight(18)
	options:SetPoint("TOP", 0, -6)
	options:SetScript("OnClick", function() addon:OpenConfig() end)
	f.optionsButton = options

	local paused = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	paused:SetPoint("LEFT", title, "RIGHT", 6, 0)
	paused:SetText("|cffffd100(" .. L["Paused"] .. ")|r")
	paused:Hide()
	f.pausedText = paused

	f.searchBox = CreateSearchBox(f, options, close, addon)

	CreateFilterTabs(f, addon)

	local sep = f:CreateTexture(nil, "ARTWORK")
	sep:SetTexture(1, 1, 1, 0.15)
	sep:SetHeight(1)
	sep:SetPoint("TOPLEFT", 8, -50)
	sep:SetPoint("TOPRIGHT", -8, -50)

	local content = CreateFrame("Frame", nil, f)
	content:SetPoint("TOPLEFT", 8, -54)
	content:SetPoint("BOTTOMRIGHT", -8, 8)
	f.content = content

	f.messages = CreateMessageList(f, content)

	local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	empty:SetPoint("CENTER")
	empty:SetText(L["No messages yet."])
	f.emptyText = empty
	f.isEmpty = true

	local grip = CreateFrame("Button", nil, f)
	grip:SetWidth(16)
	grip:SetHeight(16)
	grip:SetPoint("BOTTOMRIGHT", -4, 4)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" and not addon.db.profile.window.locked then
			f:StartSizing("BOTTOMRIGHT")
		end
	end)
	grip:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		addon:SaveWindowGeometry()
	end)
	f.resizeGrip = grip

	f:SetScript("OnHide", function(frame)
		frame:StopMovingOrSizing()
		frame.hovered = false
		frame.pausedText:Hide()
		if not frame:IsShown() and not frame.autoHiding then
			addon.db.profile.window.shown = false
		end
	end)

	f:SetScript("OnShow", function()
		addon:PruneEntries()
		addon:RefreshList()
	end)

	local elapsedSinceCheck = 0
	f:SetScript("OnUpdate", function(_, elapsed)
		elapsedSinceCheck = elapsedSinceCheck + elapsed
		if elapsedSinceCheck < HOVER_CHECK then return end
		elapsedSinceCheck = 0
		addon:UpdateHoverState()
	end)

	SetEscapeCloses(true)
	InterfaceOptionsFrame:HookScript("OnShow", function()
		SetEscapeCloses(false)
	end)
	InterfaceOptionsFrame:HookScript("OnHide", function()
		addon:ScheduleTimer(function()
			if not InterfaceOptionsFrame:IsShown() then
				SetEscapeCloses(true)
			end
		end, 0.1)
	end)

	self.frame = f
	self:ApplyWindowSettings()
	self:ApplyMessageSettings()
	return f
end

local function GetScrollAnchor(f)
	local smf = f.messages
	if not f.displayed or not smf.GetCurrentScroll then return nil, 0 end
	local offset = smf:GetCurrentScroll() or 0
	if offset <= 0 then return nil, 0 end
	return f.displayed[offset + 1], offset
end

local function SetScrollOffset(smf, offset)
	if smf.SetScrollOffset then
		smf:SetScrollOffset(offset)
	else
		smf:ScrollToBottom()
		for _ = 1, offset do smf:ScrollUp() end
	end
end

local function RestoreScrollAnchor(f, list, anchorAuthor, oldOffset)
	local displayed = {}
	local target
	for i, e in ipairs(list) do
		displayed[i] = e.author
		if e.author == anchorAuthor then target = i - 1 end
	end
	f.displayed = displayed

	if not target then
		target = math.min(oldOffset or 0, #list - 1)
	end
	if target > 0 then
		SetScrollOffset(f.messages, target)
	end
end

function ChatDigest:RefreshList()
	local f = self.frame
	if not f or not f:IsShown() then return end
	local smf = f.messages

	local anchorAuthor, oldOffset = GetScrollAnchor(f)
	if f.resetScroll then
		anchorAuthor, oldOffset = nil, 0
		f.resetScroll = false
	end

	f.pendingRefresh = false
	smf:Clear()
	f.displayed = nil

	local all = self:GetSortedEntries()
	local filter = self:GetFilter()
	local words = self.searchWords
	local counts = { all = 0 }
	local list = {}
	for _, e in ipairs(all) do
		if not words or MatchesSearch(e, words) then
			counts.all = counts.all + 1
			local cats = e.categories or { other = true }
			for cat in pairs(cats) do
				counts[cat] = (counts[cat] or 0) + 1
			end
			if filter == "all" or cats[filter] then
				list[#list + 1] = e
			end
		end
	end
	self:UpdateFilterTabs(counts)

	if #list == 0 then
		if #all == 0 then
			f.emptyText:SetText(L["No messages yet."])
		elseif words then
			f.emptyText:SetText(L["No messages match the search."])
		else
			f.emptyText:SetText(L["No messages in this category."])
		end
		f.emptyText:Show()
		f.isEmpty = true
		return
	end
	f.emptyText:Hide()
	f.isEmpty = false

	if smf.SetInsertMode then
		for i = #list, 1, -1 do
			smf:AddMessage(FormatEntry(list[i]), TEXT_R, TEXT_G, TEXT_B)
		end
		RestoreScrollAnchor(f, list, anchorAuthor, oldOffset)
	else
		for i = 1, #list do
			smf:AddMessage(FormatEntry(list[i]), TEXT_R, TEXT_G, TEXT_B)
		end
		smf:ScrollToTop()
	end
end

function ChatDigest:IsRefreshPaused()
	local f = self.frame
	return f and f.hovered and self.db.profile.messages.pauseOnHover
end

function ChatDigest:OnRefreshTimer()
	self:PruneEntries()
	if self:IsRefreshPaused() then
		self.frame.pendingRefresh = true
		return
	end
	self:RefreshList()
end

function ChatDigest:UpdateHoverState()
	local f = self.frame
	if not f then return end

	local hovered = f:IsShown() and MouseIsOver(f) and true or false
	if hovered ~= f.hovered then
		f.hovered = hovered
		if not hovered and f.pendingRefresh then
			self:PruneEntries()
			self:RefreshList()
		end
	end

	if self:IsRefreshPaused() then
		f.pausedText:Show()
	else
		f.pausedText:Hide()
	end
end

function ChatDigest:StartRefreshTimer()
	if self.refreshTimer then
		self:CancelTimer(self.refreshTimer, true)
	end
	self.refreshTimer = self:ScheduleRepeatingTimer("OnRefreshTimer",
		self.db.profile.messages.refreshInterval)
end

function ChatDigest:ApplyMessageSettings()
	if self.frame then
		self.frame.messages:SetMaxLines(self.db.profile.messages.maxEntries)
	end
	if self.refreshTimer then
		self:StartRefreshTimer()
	end
	self:PruneEntries()
	self:RefreshList()
end

function ChatDigest:ApplyWindowSettings()
	local f = self.frame
	if not f then return end
	local w = self.db.profile.window

	f:SetScale(w.scale)
	f:SetWidth(math.max(w.width, MIN_WIDTH))
	f:SetHeight(math.max(w.height, MIN_HEIGHT))
	f:ClearAllPoints()
	f:SetPoint(w.point, UIParent, w.relPoint, w.x, w.y)
	f:SetBackdrop(BuildBackdrop(w.borderStyle, w.borderSize))
	f:SetBackdropColor(0, 0, 0, w.alpha)
	if w.borderStyle == "blizzard" then
		f:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
	else
		local c = w.borderColor
		f:SetBackdropBorderColor(c.r, c.g, c.b, 1)
	end

	local chatFont, _, chatFlags = ChatFontNormal:GetFont()
	f.messages:SetFont(GetFontPath(w.font) or chatFont, w.fontSize, chatFlags)

	if w.locked then
		f.resizeGrip:Hide()
	else
		f.resizeGrip:Show()
	end
end

function ChatDigest:SaveWindowGeometry()
	local f = self.frame
	if not f then return end
	local w = self.db.profile.window

	local point, _, relPoint, x, y = f:GetPoint(1)
	w.point    = point or "CENTER"
	w.relPoint = relPoint or "CENTER"
	w.x        = x or 0
	w.y        = y or 0
	w.width    = f:GetWidth()
	w.height   = f:GetHeight()
end

function ChatDigest:ResetWindow()
	local w = self.db.profile.window
	local d = self.defaults.profile.window
	for _, key in ipairs({ "point", "relPoint", "x", "y", "width", "height", "scale" }) do
		w[key] = d[key]
	end
	self:ApplyWindowSettings()
	self:NotifyConfigChanged()
end

local inCombat = false

function ChatDigest:ShouldAutoHide()
	local w = self.db.profile.window
	if w.hideInCombat and inCombat then return true end
	if w.hideInInstance then
		local inInstance, instanceType = IsInInstance()
		if inInstance and (instanceType == "party" or instanceType == "raid") then
			return true
		end
	end
	return false
end

function ChatDigest:UpdateAutoHide()
	local f = self.frame
	if not f then return end
	if self:ShouldAutoHide() then
		if f:IsShown() then
			f.autoHiding = true
			f:Hide()
			f.autoHiding = false
		end
	elseif self.db.profile.window.shown and not f:IsShown() then
		f:Show()
	end
end

function ChatDigest:OnCombatStart()
	inCombat = true
	self:UpdateAutoHide()
end

function ChatDigest:OnCombatEnd()
	inCombat = false
	self:UpdateAutoHide()
end

function ChatDigest:EnableAutoHide()
	inCombat = UnitAffectingCombat("player") and true or false
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatStart")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEnd")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateAutoHide")
end

function ChatDigest:ShowWindow()
	self:CreateMainFrame():Show()
	self.db.profile.window.shown = true
end

function ChatDigest:HideWindow()
	if self.frame then self.frame:Hide() end
	self.db.profile.window.shown = false
end

function ChatDigest:ToggleWindow()
	if self.frame and self.frame:IsShown() then
		self:HideWindow()
	else
		self:ShowWindow()
	end
end
