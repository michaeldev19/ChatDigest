-- ChatDigest: consulta /who para el tooltip del nombre
--
-- Nivel, hermandad y zona solo se obtienen con /who. La consulta se envía
-- igual que la de Blizzard, así que el resultado se sigue viendo en el chat;
-- mientras está en curso, ChatDigest lo lee de dos formas:
--   1) WHO_LIST_UPDATE + GetWhoInfo(), si el cliente rellena la lista de Quién
--   2) la línea del chat (CHAT_MSG_SYSTEM), interpretada con los formatos del
--      propio juego (WHO_LIST_FORMAT, WHO_LIST_GUILD_FORMAT), ya traducidos
-- El servidor limita los /who a uno cada pocos segundos: por eso solo se
-- consulta con Mayús+clic y nunca al pasar el ratón.

local ChatDigest = LibStub("AceAddon-3.0"):GetAddon("ChatDigest")

local time, pairs, ipairs, type, tonumber = time, pairs, ipairs, type, tonumber
local find, gsub, gmatch, match, sub = string.find, string.gsub, string.gmatch, string.match, string.sub
local tinsert = table.insert

local WHO_TIMEOUT = 5

ChatDigest.whoCache = {}

local pending

------------------------------------------------------------------------
-- Patrones a partir de los formatos del juego
------------------------------------------------------------------------

-- Convierte un formato de string.format en un patrón de Lua y devuelve
-- también el papel de cada captura, en orden. "%s %s" (raza y clase) se
-- captura junto, porque la raza puede tener espacios ("Elfo de la noche");
-- luego se separa con la lista de clases.
--   %s antes del nivel        -> name (puede aparecer dos veces: enlace y texto)
--   %d                        -> level
--   %s %s                     -> raceClass
--   %s después (con guild)    -> guild y luego zone
--   %s después (sin guild)    -> zone
local function FormatToPattern(fmt, hasGuild)
	if type(fmt) ~= "string" or find(fmt, "%%%d%$") then return nil end -- sin %1$s
	local roles = {}
	local afterRaceClass = 0
	for token in gmatch(gsub(fmt, "%%s %%s", "%%R"), "%%([sdR])") do
		if token == "d" then
			tinsert(roles, "level")
		elseif token == "R" then
			tinsert(roles, "raceClass")
		elseif #roles == 0 or roles[#roles] == "name" then
			tinsert(roles, "name")
		else
			afterRaceClass = afterRaceClass + 1
			tinsert(roles, (hasGuild and afterRaceClass == 1) and "guild" or "zone")
		end
	end

	local p = gsub(fmt, "%%s %%s", "\001")
	p = gsub(p, "([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
	p = gsub(p, "%%s", "(.-)")
	p = gsub(p, "%%d", "(%%d+)")
	p = gsub(p, "\001", "(.+)")
	return { pattern = "^" .. p .. "$", roles = roles }
end

local function ParseWhoLine(msg, parser)
	if not parser then return nil end
	local caps = { match(msg, parser.pattern) }
	if #caps == 0 then return nil end
	local result = { guild = "" }
	for i, role in ipairs(parser.roles) do
		result[role] = caps[i]
	end
	return result
end

local function NumResultsPattern(fmt)
	if type(fmt) ~= "string" then return nil end
	local p = gsub(fmt, "|4[^;]*;", "\002")
	p = gsub(p, "([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
	p = gsub(p, "%%d", "(%%d+)")
	p = gsub(p, "\002", ".-")
	return "^" .. p .. "$"
end

local patterns

local function GetPatterns()
	if not patterns then
		patterns = {
			guild   = FormatToPattern(WHO_LIST_GUILD_FORMAT, true),
			noGuild = FormatToPattern(WHO_LIST_FORMAT, false),
			total   = NumResultsPattern(WHO_NUM_RESULTS),
		}
	end
	return patterns
end

local function SplitRaceClass(text)
	for _, list in pairs({ LOCALIZED_CLASS_NAMES_MALE, LOCALIZED_CLASS_NAMES_FEMALE }) do
		if type(list) == "table" then
			for classFile, className in pairs(list) do
				local suffix = " " .. className
				if sub(text, -#suffix) == suffix then
					return sub(text, 1, -#suffix - 1), className, classFile
				end
			end
		end
	end
	return text, "", nil
end

------------------------------------------------------------------------
-- Consulta
------------------------------------------------------------------------

function ChatDigest:IsWhoPending(name)
	return pending ~= nil and (name == nil or pending.name == name)
end

function ChatDigest:QueryWho(name)
	if pending then return false end
	pending = { name = name }

	self:RegisterEvent("WHO_LIST_UPDATE", "OnWhoListUpdate")
	self:RegisterEvent("CHAT_MSG_SYSTEM", "OnWhoSystemMessage")
	SendWho(WHO_TAG_NAME .. "\"" .. name .. "\"")

	pending.timer = self:ScheduleTimer("OnWhoTimeout", WHO_TIMEOUT)
	return true
end

local function FinishQuery(self, info)
	self:UnregisterEvent("WHO_LIST_UPDATE")
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	if pending.timer then
		self:CancelTimer(pending.timer, true)
	end
	local name = pending.name
	pending = nil

	if info then
		info.time = time()
		self.whoCache[name] = info
		local e = self.entries[name]
		if info.classFile and e and not e.class then
			e.class = info.classFile
		end
	else
		self.whoCache[name] = { notFound = true, time = time() }
	end
	self:OnPlayerInfoUpdated(name)
end

function ChatDigest:OnWhoListUpdate()
	if not pending then return end
	local count = GetNumWhoResults()
	for i = 1, count do
		local name, guild, level, race, class, zone, classFile = GetWhoInfo(i)
		if name == pending.name then
			FinishQuery(self, {
				level = level, guild = guild, race = race, class = class,
				classFile = classFile, zone = zone,
			})
			return
		end
	end
	if count == 0 then
		FinishQuery(self, nil)
	end
end

function ChatDigest:OnWhoSystemMessage(_, msg)
	if not pending or type(msg) ~= "string" then return end
	local p = GetPatterns()

	local line = ParseWhoLine(msg, p.guild) or ParseWhoLine(msg, p.noGuild)
	if line and line.name == pending.name then
		local race, class, classFile = SplitRaceClass(line.raceClass or "")
		FinishQuery(self, {
			level = tonumber(line.level), guild = line.guild, race = race, class = class,
			classFile = classFile, zone = line.zone,
		})
		return
	end

	if p.total and match(msg, p.total) then
		FinishQuery(self, nil)
	end
end

function ChatDigest:OnWhoTimeout()
	if not pending then return end
	pending.timer = nil
	self:UnregisterEvent("WHO_LIST_UPDATE")
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	local name = pending.name
	pending = nil
	self:OnPlayerInfoUpdated(name)
end
