-- ChatDigest: captura de mensajes del chat y agrupación por jugador

local ChatDigest = LibStub("AceAddon-3.0"):GetAddon("ChatDigest")
local L = LibStub("AceLocale-3.0"):GetLocale("ChatDigest")

local pairs, type, select, time = pairs, type, select, time
local gsub, match, strlower = string.gsub, string.match, string.lower
local tinsert, tsort = table.insert, table.sort

-- Tabla en memoria (no se guarda en SavedVariables): [autor] = entrada
--   author, guid, class, text, normText, channelTag, firstSeen, lastSeen,
--   count, edited, editedAt, seq (orden interno de llegada)
ChatDigest.entries = {}
local entries = ChatDigest.entries
local numEntries = 0
local sequence = 0

ChatDigest.joinedChannels = {}

local ignoredPlayers = {} -- [nombre en minúsculas] = true
local classByGUID = {}    -- caché de GetPlayerInfoByGUID

------------------------------------------------------------------------
-- Utilidades
------------------------------------------------------------------------

local function GetChannelKey(name)
	if type(name) ~= "string" then return nil end
	name = gsub(name, "^%d+%.%s*", "")
	local base = match(name, "^(.-) %- ") or name
	base = strtrim(base)
	if base == "" then return nil end
	return strlower(base), base
end
ChatDigest.GetChannelKey = GetChannelKey

local function GetClassFromGUID(guid)
	if not guid or guid == "" then return nil end
	local class = classByGUID[guid]
	if not class then
		class = select(2, GetPlayerInfoByGUID(guid))
		classByGUID[guid] = class
	end
	return class
end

function ChatDigest:NormalizeText(text)
	if type(text) ~= "string" then return "" end
	local s = text
	s = gsub(s, "|H.-|h", "")                    -- inicio de enlace |Hitem:...|h
	s = gsub(s, "|h", "")                        -- fin de enlace
	s = gsub(s, "|c%x%x%x%x%x%x%x%x", "")        -- inicio de color
	s = gsub(s, "|r", "")                        -- fin de color
	s = gsub(s, "|T.-|t", "")                    -- texturas incrustadas
	s = strlower(s)
	s = gsub(s, "{[^}]*}", "")                   -- iconos de banda {rt1}, {estrella}...
	s = gsub(s, "(%p)%1+", "%1")                 -- "!!!" -> "!", "...." -> "."
	s = gsub(s, "%s+", " ")
	return strtrim(s)
end

------------------------------------------------------------------------
-- Gestión de entradas
------------------------------------------------------------------------

local function RemoveEntry(author)
	if entries[author] then
		entries[author] = nil
		numEntries = numEntries - 1
	end
end

function ChatDigest:EnforceMaxEntries()
	local max = self.db.profile.messages.maxEntries
	while numEntries > max do
		local oldestAuthor, oldestSeq
		for author, e in pairs(entries) do
			if not oldestSeq or e.seq < oldestSeq then
				oldestAuthor, oldestSeq = author, e.seq
			end
		end
		if not oldestAuthor then break end
		RemoveEntry(oldestAuthor)
	end
end

function ChatDigest:PruneEntries()
	local limit = time() - self.db.profile.messages.expireMinutes * 60
	for author, e in pairs(entries) do
		if e.lastSeen < limit then
			RemoveEntry(author)
		end
	end
	self:EnforceMaxEntries()
end

function ChatDigest:ClearMessages()
	wipe(entries)
	numEntries = 0
	self:RefreshList()
end

function ChatDigest:GetNumEntries()
	return numEntries
end

local sorted = {}
local function SortByRecent(a, b) return a.seq > b.seq end

function ChatDigest:GetSortedEntries()
	wipe(sorted)
	for _, e in pairs(entries) do
		if not e.class then e.class = GetClassFromGUID(e.guid) end
		tinsert(sorted, e)
	end
	tsort(sorted, SortByRecent)
	return sorted
end

function ChatDigest:AddEntry(author, guid, text, channelTag, lineID, chatType)
	local norm = self:NormalizeText(text)
	if norm == "" then return end

	local now = time()
	sequence = sequence + 1

	local e = entries[author]
	local isNewText = true
	if e then
		if e.normText == norm then
			e.count = e.count + 1
			isNewText = false
		else
			e.previousText = e.text
			e.text     = text
			e.normText = norm
			e.count    = 1
			e.edited   = true
			e.editedAt = now
			e.categories = self:Categorize(norm)
			e.alert      = self:MatchesAlert(text)
		end
		e.lastSeen   = now
		e.seq        = sequence
		e.channelTag = channelTag
		e.lineID     = lineID
		e.chatType   = chatType
		if guid and guid ~= "" then
			e.guid  = guid
			e.class = e.class or GetClassFromGUID(guid)
		end
	else
		entries[author] = {
			author     = author,
			guid       = guid,
			class      = GetClassFromGUID(guid),
			text       = text,
			normText   = norm,
			channelTag = channelTag,
			lineID     = lineID,
			chatType   = chatType,
			firstSeen  = now,
			lastSeen   = now,
			count      = 1,
			edited     = false,
			editedAt   = nil,
			seq        = sequence,
			categories = self:Categorize(norm),
			alert      = self:MatchesAlert(text),
		}
		e = entries[author]
		numEntries = numEntries + 1
		self:EnforceMaxEntries()
	end

	if isNewText and e.alert then
		self:TriggerAlert(e)
	end

	local f = self.frame
	if f and f:IsShown() and f.isEmpty then
		self:RefreshList()
	end
end

------------------------------------------------------------------------
-- Captura de eventos
------------------------------------------------------------------------

-- CHAT_MSG_CHANNEL:
--   msg, author, language, channelString, target, flags, zoneChannelID,
--   channelNumber, channelName, unused, lineID, guid
-- CHAT_MSG_YELL / CHAT_MSG_SAY:
--   msg, author, language, unused, target, flags, unused, unused, unused, unused, lineID, guid
function ChatDigest:OnChatMessage(event, msg, author, _, channelString, _, _, _, _, channelName, _, lineID, guid)
	if type(msg) ~= "string" or type(author) ~= "string" or author == "" then return end
	local cap = self.db.profile.capture

	local tag
	if event == "CHAT_MSG_CHANNEL" then
		local key, display = GetChannelKey(channelName)
		if not key then key, display = GetChannelKey(channelString) end
		if not key then return end
		if not cap.allChannels and not cap.channels[key] then return end
		tag = display
	elseif event == "CHAT_MSG_YELL" then
		if not cap.yell then return end
		tag = L["Yell"]
	elseif event == "CHAT_MSG_SAY" then
		if not cap.say then return end
		tag = L["Say"]
	else
		return
	end

	local shortName = match(author, "^([^%-]+)") or author
	if cap.ignoreSelf and (author == self.playerName or shortName == self.playerName) then return end
	if ignoredPlayers[strlower(author)] or ignoredPlayers[strlower(shortName)] then return end

	self:AddEntry(author, guid, msg, tag, lineID, event:sub(10))
end

function ChatDigest:UpdateChannelList()
	local list = self.joinedChannels
	wipe(list)
	local data = { GetChannelList() }
	for i = 1, #data do
		local value = data[i]
		if type(value) == "string" then
			local key, display = GetChannelKey(value)
			if key then list[key] = display end
		end
	end
	self:NotifyConfigChanged()
end

function ChatDigest:UpdateIgnoreList()
	wipe(ignoredPlayers)
	for i = 1, GetNumIgnores() do
		local name = GetIgnoreName(i)
		if name then ignoredPlayers[strlower(name)] = true end
	end
	for author in pairs(entries) do
		if ignoredPlayers[strlower(author)] then
			RemoveEntry(author)
		end
	end
end

function ChatDigest:EnableCapture()
	self.playerName = UnitName("player")

	self:RegisterEvent("CHAT_MSG_CHANNEL", "OnChatMessage")
	self:RegisterEvent("CHAT_MSG_YELL", "OnChatMessage")
	self:RegisterEvent("CHAT_MSG_SAY", "OnChatMessage")
	self:RegisterEvent("CHANNEL_UI_UPDATE", "UpdateChannelList")
	self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE", "UpdateChannelList")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
	self:RegisterEvent("IGNORELIST_UPDATE", "UpdateIgnoreList")

	self:UpdateChannelList()
	self:UpdateIgnoreList()
end
