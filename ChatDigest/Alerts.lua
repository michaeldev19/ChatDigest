-- ChatDigest: alertas por palabras clave (paso 6)
--
-- El usuario escribe palabras o frases (una por línea o separadas por comas).
-- Si un mensaje las contiene, ese texto se resalta en la ventana y, si está
-- activado, suena un aviso (salvo en combate, si así se elige).
--
-- Coincidencia:
--   - Sin distinguir mayúsculas.
--   - Los espacios de la palabra clave son flexibles: "icc 25n" coincide con
--     "ICC 25N", "ICC25N", "icc  25n" e "ICC-25N".
--   - Debe empezar en el inicio de una palabra ("icc" no coincide en "ricc"),
--     pero puede acabar en mitad de una: "icc 25n" resalta "ICC 25N" dentro de
--     "ICC 25NLK" (cuando falta el espacio).
--   - Solo se busca en el texto normal del mensaje, nunca dentro de enlaces
--     de objetos ni de códigos de color, para no romperlos.

local ChatDigest = LibStub("AceAddon-3.0"):GetAddon("ChatDigest")
local L = LibStub("AceLocale-3.0"):GetLocale("ChatDigest")

local ipairs, pairs, type = ipairs, pairs, type
local find, sub, gsub, gmatch, format = string.find, string.sub, string.gsub, string.gmatch, string.format
local strlower, strupper, floor = string.lower, string.upper, math.floor
local tinsert, tconcat = table.insert, table.concat

local SOUND_THROTTLE = 3

local BUILTIN_SOUNDS = {
	RaidWarning       = "Sound: raid warning",
	ReadyCheck        = "Sound: ready check",
	TellMessage       = "Sound: whisper",
	MapPing           = "Sound: map ping",
	LEVELUPSOUND      = "Sound: level up",
	AuctionWindowOpen = "Sound: auction house",
}

local LSM_PREFIX = "lsm:"

local function GetLSM()
	return LibStub("LibSharedMedia-3.0", true)
end

function ChatDigest:GetSoundList()
	local list = {}
	for key, labelKey in pairs(BUILTIN_SOUNDS) do
		list[key] = L[labelKey]
	end
	local lsm = GetLSM()
	if lsm then
		for _, name in ipairs(lsm:List("sound")) do
			if name ~= "None" then
				list[LSM_PREFIX .. name] = name
			end
		end
	end
	return list
end

function ChatDigest:PlayAlertSound(key)
	key = key or self.db.profile.alerts.soundName
	if sub(key, 1, #LSM_PREFIX) == LSM_PREFIX then
		local lsm = GetLSM()
		local path = lsm and lsm:Fetch("sound", sub(key, #LSM_PREFIX + 1), true)
		if path then PlaySoundFile(path) end
	elseif BUILTIN_SOUNDS[key] then
		PlaySound(key)
	end
end

local function KeywordToPattern(keyword)
	local parts = {}
	for token in gmatch(keyword, "%S+") do
		local p = gsub(token, "(.)", function(c)
			if find(c, "%a") then
				return "[" .. strlower(c) .. strupper(c) .. "]"
			elseif find(c, "%p") then
				return "%" .. c
			end
			return c
		end)
		tinsert(parts, p)
	end
	if #parts == 0 then return nil end
	return tconcat(parts, "[%s%p]*")
end

function ChatDigest:CompileAlertKeywords()
	local patterns = {}
	local text = self.db.profile.alerts.keywords or ""
	for keyword in gmatch(text, "[^\r\n,]+") do
		local pattern = KeywordToPattern(strtrim(keyword))
		if pattern then tinsert(patterns, pattern) end
	end
	self.alertPatterns = patterns
end

local function MapPlainText(text, fn)
	local out = {}
	local pos, len = 1, #text
	while pos <= len do
		local s = find(text, "|", pos, true)
		if not s then
			tinsert(out, fn(sub(text, pos)))
			break
		end
		if s > pos then
			tinsert(out, fn(sub(text, pos, s - 1)))
		end
		local code = sub(text, s + 1, s + 1)
		local e
		if code == "H" then
			local _, dataEnd = find(text, "|h", s + 2, true)
			local linkEnd
			if dataEnd then
				local _, closeEnd = find(text, "|h", dataEnd + 1, true)
				linkEnd = closeEnd
			end
			e = linkEnd or len
		elseif code == "T" then
			local _, texEnd = find(text, "|t", s + 2, true)
			e = texEnd or len
		elseif code == "c" then
			e = s + 9
		else
			e = s + 1
		end
		tinsert(out, sub(text, s, e))
		pos = e + 1
	end
	return tconcat(out)
end

local function FindAlert(seg, init, patterns)
	local bestS, bestE
	for _, pattern in ipairs(patterns) do
		local from = init
		while true do
			local s, e = find(seg, pattern, from)
			if not s or (bestS and s > bestS) then break end
			if s == 1 or not find(sub(seg, s - 1, s - 1), "%w") then
				if not bestS or s < bestS or e > bestE then
					bestS, bestE = s, e
				end
				break
			end
			from = s + 1
		end
	end
	return bestS, bestE
end

function ChatDigest:MatchesAlert(text)
	local patterns = self.alertPatterns
	if not patterns or #patterns == 0 or type(text) ~= "string" then return false end
	local found = false
	MapPlainText(text, function(seg)
		if not found and FindAlert(seg, 1, patterns) then found = true end
		return seg
	end)
	return found
end

function ChatDigest:HighlightAlerts(text, hex)
	local patterns = self.alertPatterns
	if not patterns or #patterns == 0 then return text end
	return MapPlainText(text, function(seg)
		local out, pos = {}, 1
		while true do
			local s, e = FindAlert(seg, pos, patterns)
			if not s then break end
			tinsert(out, sub(seg, pos, s - 1))
			tinsert(out, "|cff" .. hex .. sub(seg, s, e) .. "|r")
			pos = e + 1
		end
		tinsert(out, sub(seg, pos))
		return tconcat(out)
	end)
end

local function ToHex(r, g, b)
	return format("%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

function ChatDigest:GetAlertColorHex()
	local opts = self.db.profile.alerts
	if opts.useClassColor then
		local _, class = UnitClass("player")
		local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
		local c = class and colors[class]
		if c then return ToHex(c.r, c.g, c.b) end
	end
	local c = opts.color
	return ToHex(c.r, c.g, c.b)
end

local lastSound = 0

function ChatDigest:TriggerAlert(entry)
	local opts = self.db.profile.alerts
	if opts.noCombat and InCombatLockdown() then return end
	if opts.sound then
		local now = GetTime()
		if now - lastSound >= SOUND_THROTTLE then
			lastSound = now
			self:PlayAlertSound()
		end
	end
end

function ChatDigest:RecheckAlerts()
	for _, e in pairs(self.entries) do
		e.alert = self:MatchesAlert(e.text)
	end
end

function ChatDigest:SetAlertKeywords(text)
	self.db.profile.alerts.keywords = text or ""
	self:CompileAlertKeywords()
	self:RecheckAlerts()
	self:RefreshList()
end
