-- ChatDigest: panel de opciones en Interfaz > Accesorios (Ace3)

local ChatDigest = LibStub("AceAddon-3.0"):GetAddon("ChatDigest")
local L = LibStub("AceLocale-3.0"):GetLocale("ChatDigest")

local AceConfig         = LibStub("AceConfig-3.0")
local AceConfigDialog   = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions      = LibStub("AceDBOptions-3.0")

-- Lectura/escritura de los valores de la ventana
local function windowGet(info)
	return ChatDigest.db.profile.window[info[#info]]
end

local function windowSet(info, value)
	ChatDigest.db.profile.window[info[#info]] = value
	ChatDigest:ApplyWindowSettings()
end

local function GetGeneralOptions()
	return {
		type = "group",
		name = "ChatDigest",
		args = {
			version = {
				type = "description",
				name = "|cffcaf7faVersion " .. ChatDigest.version .. "|r",
				order = 1,
			},
			description = {
				type = "description",
				name = L["DESCRIPTION"] .. "\n",
				order = 2,
			},
			toggleWindow = {
				type = "execute",
				name = L["Show/hide window"],
				order = 3,
				func = function() ChatDigest:ToggleWindow() end,
			},

			windowHeader = {
				type = "header",
				name = L["Window"],
				order = 10,
			},
			locked = {
				type = "toggle",
				name = L["Lock window"],
				desc = L["LOCK_DESC"],
				width = "full",
				order = 11,
				get = windowGet,
				set = windowSet,
			},
			scale = {
				type = "range",
				name = L["Scale"],
				desc = L["SCALE_DESC"],
				min = 0.5, max = 2.0, step = 0.05,
				isPercent = true,
				order = 12,
				get = windowGet,
				set = windowSet,
			},
			alpha = {
				type = "range",
				name = L["Background opacity"],
				desc = L["ALPHA_DESC"],
				min = 0, max = 1, step = 0.05,
				isPercent = true,
				order = 13,
				get = windowGet,
				set = windowSet,
			},
			reset = {
				type = "execute",
				name = L["Reset position"],
				desc = L["RESET_DESC"],
				order = 14,
				func = function() ChatDigest:ResetWindow() end,
			},
		},
	}
end

function ChatDigest:SetupOptions()
	AceConfig:RegisterOptionsTable("ChatDigest", GetGeneralOptions)
	self.optionsFrame = AceConfigDialog:AddToBlizOptions("ChatDigest", "ChatDigest")

	local profiles = AceDBOptions:GetOptionsTable(self.db)
	AceConfig:RegisterOptionsTable("ChatDigest_Profiles", profiles)
	self.profilesFrame = AceConfigDialog:AddToBlizOptions("ChatDigest_Profiles", L["Profiles"], "ChatDigest")
end

-- Refresca el panel si está abierto (por ejemplo, tras /chatd reset)
function ChatDigest:NotifyConfigChanged()
	AceConfigRegistry:NotifyChange("ChatDigest")
end

function ChatDigest:OpenConfig()
	-- En 3.3.5 la primera llamada a veces no selecciona la categoría
	-- correcta; llamarla dos veces es la solución habitual.
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end
