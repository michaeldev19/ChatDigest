-- ChatDigest: categorías automáticas por palabras clave (paso 5)
--
-- Cada categoría tiene una lista de palabras editable (una por línea).
-- Coincidencia por palabra completa sobre normText, sin distinguir mayúsculas:
--   "icc"         coincide con "lfm icc 25" pero no con "iccx"
--   "busco grupo" las frases de varias palabras también valen
--   "recluta*"    el * final coincide con el inicio de la palabra (reclutamos...)
--   "recluta*!"   el ! final hace la palabra excluyente: si el mensaje la
--                 contiene, va SOLO a esta categoría aunque coincida con otras
--                 (p. ej. "reclutamos, armamos ICC" -> solo Hermandad).
--                 También vale al principio ("!recluta*"), y con o sin *.
-- No se usa %w ni %f para que funcione con tildes y ñ (UTF-8): la puntuación
-- ASCII se cambia por espacios y se busca " palabra " dentro de " texto ".

local ChatDigest = LibStub("AceAddon-3.0"):GetAddon("ChatDigest")
local L = LibStub("AceLocale-3.0"):GetLocale("ChatDigest")

local ipairs, pairs = ipairs, pairs
local gsub, gmatch, find, sub, strlower = string.gsub, string.gmatch, string.find, string.sub, string.lower
local tinsert, tconcat = table.insert, table.concat

local CATEGORIES = { "raid", "dungeon", "trade", "guild" }
ChatDigest.CATEGORIES = CATEGORIES

local LABEL_KEYS = {
	raid    = "Raid",
	dungeon = "Dungeon",
	trade   = "Trade",
	guild   = "Guild",
	other   = "Other",
}

function ChatDigest:GetCategoryLabel(cat)
	return L[LABEL_KEYS[cat]] or cat
end

local DEFAULT_KEYWORDS = {
	enUS = {
		raid = {
			"raid", "icc*", "toc", "toc10", "toc25", "togc", "totgc", "rs",
			"ruby sanctum", "voa", "archa*", "archavon", "naxx*", "ulduar", "uld",
			"ony", "onyxia", "os", "sartharion", "eoe", "malygos", "maly",
		},
		dungeon = {
			"dungeon*", "heroic*", "hc", "daily", "random", "rdf",
			"hor", "pos", "fos", "poc", "hol", "hos", "cos", "occ", "oculus",
			"nexus", "vh", "dtk", "toc5", "toc 5", "toc5n", "toc 5n"
		},
		trade = {
			"wts", "wtb", "wtt", "sell*", "buy*", "cheap", "price",
			"enchant*", "ench", "jc", "jewelcraft*", "craft*", "tips", "s "
		},
		guild = {
			"guild*", "recruit*!", "gbank", "apply", "progression",
		},
	},
	esES = {
		raid = {
			"banda", "raid", "icc*", "ciudadela", "toc10", "toc 10", "toc10n", "toc 10n",
			"toc10h", "toc 10h", "toc25", "toc 25", "toc25n", "toc 25n", "toc25h", "toc 25h",
			"prueba del cruzado", "sr", "sagrario rubi", "sagrario rubí", "archa*", "archavon",
			"archa10", "archa 10", "archa25", "archa 25", "naxx*", "ulduar", "ony", "onyxia",
			"so", "sartharion", "malygos", "maly",
		},
		dungeon = {
			"mazmorra*", "heroica*", "heroico*", "heroic*", "diaria", "rdf",
			"random", "aleatoria", "busco grupo",
			"foso", "forja", "camaras de reflexion", "cámaras de reflexión",
			"oculus", "nexo", "toc5", "toc 5", "toc5n", "toc 5n", "pdc", "por ojo"
		},
		trade = {
			"vendo", "compro", "wts", "wtb", "wtt", "venta", "precio*", "barato",
			"encantador*", "encantamiento*", "joyero", "joyeria", "joyería", "jc",
			"fabrico", "propina*", "vende", " v ", "alquimista", "alquimia", "sastre",
			"sastrería", "sastreria", "peletero", "peletería", "peleteria",
			"incriptor", "inscripción", "inscripcion", "ingeniero", "ingeniería", "ingenieria"
		},
		guild = {
			"hermandad*", "guild*", "recluta*!", "busca miembros", "buscamos gente",
			"buscamos jugadores", "unete", "únete", "progreso",
		},
	},
}
DEFAULT_KEYWORDS.esMX = DEFAULT_KEYWORDS.esES

local function GetDefaultKeywordText(cat)
	local set = DEFAULT_KEYWORDS[GetLocale()] or DEFAULT_KEYWORDS.enUS
	return tconcat(set[cat], "\n")
end

for _, cat in ipairs(CATEGORIES) do
	ChatDigest.defaults.profile.categories[cat] = { keywords = GetDefaultKeywordText(cat) }
end

local function ToWords(s)
	s = gsub(s, "%p", " ")
	s = gsub(s, "%s+", " ")
	return strtrim(s)
end

function ChatDigest:CompileKeywords()
	local compiled = {}
	for _, cat in ipairs(CATEGORIES) do
		local normal, exclusive = {}, {}
		local text = self.db.profile.categories[cat].keywords or ""
		for line in gmatch(text, "[^\r\n]+") do
			local word = strlower(strtrim(line))
			local isExclusive, prefix = false, false
			if sub(word, 1, 1) == "!" then
				isExclusive = true
				word = sub(word, 2)
			end
			-- Los marcadores finales * y ! pueden ir en cualquier orden
			local last = sub(word, -1)
			while last == "*" or last == "!" do
				if last == "*" then prefix = true else isExclusive = true end
				word = sub(word, 1, -2)
				last = sub(word, -1)
			end
			word = ToWords(word)
			if word ~= "" then
				local needle = prefix and (" " .. word) or (" " .. word .. " ")
				tinsert(isExclusive and exclusive or normal, needle)
			end
		end
		compiled[cat] = { normal = normal, exclusive = exclusive }
	end
	self.compiledKeywords = compiled
end

local function MatchesAny(haystack, needles)
	for _, needle in ipairs(needles) do
		if find(haystack, needle, 1, true) then return true end
	end
	return false
end

function ChatDigest:Categorize(normText)
	if not self.compiledKeywords then self:CompileKeywords() end
	local haystack = " " .. ToWords(normText or "") .. " "
	local compiled = self.compiledKeywords

	local result
	for _, cat in ipairs(CATEGORIES) do
		if MatchesAny(haystack, compiled[cat].exclusive) then
			result = result or {}
			result[cat] = true
		end
	end
	if result then return result end

	for _, cat in ipairs(CATEGORIES) do
		if MatchesAny(haystack, compiled[cat].normal) then
			result = result or {}
			result[cat] = true
		end
	end
	return result or { other = true }
end

function ChatDigest:RecategorizeAll()
	for _, e in pairs(self.entries) do
		e.categories = self:Categorize(e.normText)
	end
end

function ChatDigest:SetCategoryKeywords(cat, text)
	if text == nil then
		text = self.defaults.profile.categories[cat].keywords
	end
	self.db.profile.categories[cat].keywords = text
	self:CompileKeywords()
	self:RecategorizeAll()
	self:RefreshList()
	self:NotifyConfigChanged()
end
