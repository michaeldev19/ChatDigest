-- ChatDigest: panel de opciones en Interfaz > Accesorios (Ace3)
--
--   ChatDigest       página principal: Ventana, Canales y Mensajes (paneles)
--     Alertas        palabras clave, sonido y color de resalte
--     Categorías     palabras de cada categoría
--     Perfiles       AceDBOptions

local ChatDigest = LibStub("AceAddon-3.0"):GetAddon("ChatDigest")
local L = LibStub("AceLocale-3.0"):GetLocale("ChatDigest")

local AceConfig         = LibStub("AceConfig-3.0")
local AceConfigDialog   = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions      = LibStub("AceDBOptions-3.0")

local APP_MAIN       = "ChatDigest"
local APP_ALERTS     = "ChatDigest_Alerts"
local APP_CATEGORIES = "ChatDigest_Categories"
local APP_PROFILES   = "ChatDigest_Profiles"

local function windowGet(info)
	return ChatDigest.db.profile.window[info[#info]]
end

local function windowSet(info, value)
	ChatDigest.db.profile.window[info[#info]] = value
	ChatDigest:ApplyWindowSettings()
end

local function fontSet(info, value)
	ChatDigest.db.profile.window[info[#info]] = value
	ChatDigest:ApplyWindowSettings()
	ChatDigest:RefreshList()
end

local function autoHideSet(info, value)
	ChatDigest.db.profile.window[info[#info]] = value
	ChatDigest:UpdateAutoHide()
end

local function captureGet(info)
	return ChatDigest.db.profile.capture[info[#info]]
end

local function captureSet(info, value)
	ChatDigest.db.profile.capture[info[#info]] = value
end

local function messagesGet(info)
	return ChatDigest.db.profile.messages[info[#info]]
end

local function messagesSet(info, value)
	ChatDigest.db.profile.messages[info[#info]] = value
	ChatDigest:ApplyMessageSettings()
end

local function alertsGet(info)
	return ChatDigest.db.profile.alerts[info[#info]]
end

local function alertsSet(info, value)
	ChatDigest.db.profile.alerts[info[#info]] = value
	ChatDigest:RefreshList()
end

local TIME_FORMATS = {
	"%H:%M:%S",    -- 14:05:09
	"%H:%M",       -- 14:05
	"%I:%M:%S %p", -- 02:05:09 PM
	"%I:%M %p",    -- 02:05 PM
	"",            -- sin hora
}

local function TimeFormatValues()
	local values = {}
	for _, fmt in ipairs(TIME_FORMATS) do
		if fmt == "" then
			values[fmt] = L["No time"]
		else
			values[fmt] = date(fmt)
		end
	end
	return values
end

local function ChannelValues()
	local values = {}
	for key, name in pairs(ChatDigest.joinedChannels) do
		values[key] = name
	end
	for key, on in pairs(ChatDigest.db.profile.capture.channels) do
		if on and not values[key] then
			values[key] = key .. " |cff808080" .. L["(not joined)"] .. "|r"
		end
	end
	return values
end

local function NoChannelsJoined()
	return next(ChannelValues()) == nil
end

local function GetMainOptions()
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

			-- Panel: Ventana
			window = {
				type = "group",
				inline = true,
				name = L["Window"],
				order = 10,
				args = {
					locked = {
						type = "toggle",
						name = L["Lock window"],
						desc = L["LOCK_DESC"],
						width = "full",
						order = 1,
						get = windowGet,
						set = windowSet,
					},
					scale = {
						type = "range",
						name = L["Scale"],
						desc = L["SCALE_DESC"],
						min = 0.5, max = 2.0, step = 0.05,
						isPercent = true,
						order = 2,
						get = windowGet,
						set = windowSet,
					},
					alpha = {
						type = "range",
						name = L["Background opacity"],
						desc = L["ALPHA_DESC"],
						min = 0, max = 1, step = 0.05,
						isPercent = true,
						order = 3,
						get = windowGet,
						set = windowSet,
					},
					timeFormat = {
						type = "select",
						name = L["Time format"],
						desc = L["TIME_FORMAT_DESC"],
						order = 4,
						values = TimeFormatValues,
						get = windowGet,
						set = function(_, value)
							ChatDigest.db.profile.window.timeFormat = value
							ChatDigest:RefreshList()
						end,
					},
					font = {
						type = "select",
						name = L["Font"],
						desc = L["FONT_DESC"],
						order = 5,
						values = function() return ChatDigest:GetFontList() end,
						get = windowGet,
						set = fontSet,
					},
					fontSize = {
						type = "range",
						name = L["Font size"],
						desc = L["FONT_SIZE_DESC"],
						min = 8, max = 24, step = 1,
						order = 6,
						get = windowGet,
						set = fontSet,
					},
					playerTooltip = {
						type = "toggle",
						name = L["Player tooltip"],
						desc = L["PLAYER_TOOLTIP_DESC"],
						width = "full",
						order = 6.5,
						get = windowGet,
						set = windowSet,
					},
					hideInCombat = {
						type = "toggle",
						name = L["Hide in combat"],
						desc = L["HIDE_IN_COMBAT_DESC"],
						order = 6.6,
						get = windowGet,
						set = autoHideSet,
					},
					hideInInstance = {
						type = "toggle",
						name = L["Hide in dungeons and raids"],
						desc = L["HIDE_IN_INSTANCE_DESC"],
						order = 6.7,
						get = windowGet,
						set = autoHideSet,
					},
					borderStyle = {
						type = "select",
						name = L["Border"],
						desc = L["BORDER_DESC"],
						order = 7,
						values = {
							solid    = L["Thin (solid)"],
							blizzard = L["Blizzard"],
							none     = L["None"],
						},
						get = windowGet,
						set = windowSet,
					},
					borderSize = {
						type = "range",
						name = L["Border size"],
						desc = L["BORDER_SIZE_DESC"],
						min = 1, max = 8, step = 1,
						order = 8,
						disabled = function() return ChatDigest.db.profile.window.borderStyle ~= "solid" end,
						get = windowGet,
						set = windowSet,
					},
					borderColor = {
						type = "color",
						name = L["Border color"],
						desc = L["BORDER_COLOR_DESC"],
						order = 9,
						disabled = function() return ChatDigest.db.profile.window.borderStyle ~= "solid" end,
						get = function()
							local c = ChatDigest.db.profile.window.borderColor
							return c.r, c.g, c.b
						end,
						set = function(_, r, g, b)
							local c = ChatDigest.db.profile.window.borderColor
							c.r, c.g, c.b = r, g, b
							ChatDigest:ApplyWindowSettings()
						end,
					},
					reset = {
						type = "execute",
						name = L["Reset position"],
						desc = L["RESET_DESC"],
						order = 10,
						func = function() ChatDigest:ResetWindow() end,
					},
				},
			},

			-- Panel: Canales
			channels = {
				type = "group",
				inline = true,
				name = L["Channels"],
				order = 20,
				args = {
					allChannels = {
						type = "toggle",
						name = L["All channels"],
						desc = L["ALL_CHANNELS_DESC"],
						width = "full",
						order = 1,
						get = captureGet,
						set = captureSet,
					},
					channelList = {
						type = "multiselect",
						name = L["Channels to capture"],
						desc = L["CHANNEL_LIST_DESC"],
						order = 2,
						hidden = function() return ChatDigest.db.profile.capture.allChannels end,
						values = ChannelValues,
						get = function(_, key)
							return ChatDigest.db.profile.capture.channels[key]
						end,
						set = function(_, key, value)
							ChatDigest.db.profile.capture.channels[key] = value or nil
						end,
					},
					noChannels = {
						type = "description",
						name = "|cff808080" .. L["NO_CHANNELS"] .. "|r",
						order = 3,
						hidden = function()
							return ChatDigest.db.profile.capture.allChannels or not NoChannelsJoined()
						end,
					},
					otherHeader = {
						type = "header",
						name = L["Other chat types"],
						order = 10,
					},
					yell = {
						type = "toggle",
						name = L["Yell"],
						desc = L["YELL_DESC"],
						order = 11,
						get = captureGet,
						set = captureSet,
					},
					say = {
						type = "toggle",
						name = L["Say"],
						desc = L["SAY_DESC"],
						order = 12,
						get = captureGet,
						set = captureSet,
					},
				},
			},

			-- Panel: Mensajes
			messages = {
				type = "group",
				inline = true,
				name = L["Messages"],
				order = 30,
				args = {
					ignoreSelf = {
						type = "toggle",
						name = L["Ignore my own messages"],
						desc = L["IGNORE_SELF_DESC"],
						width = "full",
						order = 1,
						get = captureGet,
						set = captureSet,
					},
					expireMinutes = {
						type = "range",
						name = L["Expire after (minutes)"],
						desc = L["EXPIRE_DESC"],
						min = 1, max = 60, step = 1,
						order = 2,
						get = messagesGet,
						set = messagesSet,
					},
					maxEntries = {
						type = "range",
						name = L["Maximum entries"],
						desc = L["MAX_ENTRIES_DESC"],
						min = 20, max = 1000, step = 10,
						order = 3,
						get = messagesGet,
						set = messagesSet,
					},
					refreshInterval = {
						type = "range",
						name = L["Refresh every (seconds)"],
						desc = L["REFRESH_DESC"],
						min = 1, max = 60, step = 1,
						order = 4,
						get = messagesGet,
						set = messagesSet,
					},
					pauseOnHover = {
						type = "toggle",
						name = L["Pause while hovering"],
						desc = L["PAUSE_DESC"],
						width = "full",
						order = 5,
						get = messagesGet,
						set = messagesSet,
					},
					clear = {
						type = "execute",
						name = L["Clear list"],
						desc = L["CLEAR_DESC"],
						order = 6,
						func = function() ChatDigest:ClearMessages() end,
					},
				},
			},
		},
	}
end

------------------------------------------------------------------------
-- Submenú: Alertas
------------------------------------------------------------------------

local function GetAlertOptions()
	local function soundDisabled()
		return not ChatDigest.db.profile.alerts.sound
	end
	local function colorDisabled()
		return ChatDigest.db.profile.alerts.useClassColor
	end

	return {
		type = "group",
		name = L["Alerts"],
		args = {
			help = {
				type = "description",
				name = L["ALERTS_HELP"] .. "\n",
				order = 1,
			},
			keywords = {
				type = "input",
				name = L["Alert keywords"],
				desc = L["ALERT_KEYWORDS_DESC"],
				multiline = 6,
				width = "full",
				order = 2,
				get = alertsGet,
				set = function(_, value) ChatDigest:SetAlertKeywords(value) end,
			},

			notifyHeader = {
				type = "header",
				name = L["Notification"],
				order = 10,
			},
			noCombat = {
				type = "toggle",
				name = L["No alerts in combat"],
				desc = L["NO_COMBAT_DESC"],
				width = "full",
				order = 11,
				get = alertsGet,
				set = alertsSet,
			},
			sound = {
				type = "toggle",
				name = L["Play a sound"],
				desc = L["SOUND_DESC"],
				order = 12,
				get = alertsGet,
				set = alertsSet,
			},
			soundName = {
				type = "select",
				name = L["Sound"],
				desc = L["SOUND_NAME_DESC"],
				order = 13,
				disabled = soundDisabled,
				values = function() return ChatDigest:GetSoundList() end,
				get = alertsGet,
				set = function(_, value)
					ChatDigest.db.profile.alerts.soundName = value
					ChatDigest:PlayAlertSound(value) -- vista previa
				end,
			},

			colorHeader = {
				type = "header",
				name = L["Highlight"],
				order = 20,
			},
			useClassColor = {
				type = "toggle",
				name = L["Use class color"],
				desc = L["USE_CLASS_COLOR_DESC"],
				order = 21,
				get = alertsGet,
				set = alertsSet,
			},
			color = {
				type = "color",
				name = L["Highlight color"],
				desc = L["HIGHLIGHT_COLOR_DESC"],
				order = 22,
				disabled = colorDisabled,
				get = function()
					local c = ChatDigest.db.profile.alerts.color
					return c.r, c.g, c.b
				end,
				set = function(_, r, g, b)
					local c = ChatDigest.db.profile.alerts.color
					c.r, c.g, c.b = r, g, b
					ChatDigest:RefreshList()
				end,
			},
		},
	}
end

------------------------------------------------------------------------
-- Submenú: Categorías
------------------------------------------------------------------------

local function GetCategoryOptions()
	local args = {
		help = {
			type = "description",
			name = L["KEYWORDS_HELP"] .. "\n",
			order = 1,
		},
	}
	for i, cat in ipairs(ChatDigest.CATEGORIES) do
		args[cat] = {
			type = "group",
			inline = true,
			name = ChatDigest:GetCategoryLabel(cat),
			order = 10 + i,
			args = {
				keywords = {
					type = "input",
					name = L["Keywords"],
					desc = L["KEYWORDS_DESC"],
					multiline = 6,
					width = "full",
					order = 1,
					get = function()
						return ChatDigest.db.profile.categories[cat].keywords
					end,
					set = function(_, value)
						ChatDigest:SetCategoryKeywords(cat, value)
					end,
				},
				restore = {
					type = "execute",
					name = L["Restore defaults"],
					desc = L["RESTORE_DESC"],
					order = 2,
					func = function()
						ChatDigest:SetCategoryKeywords(cat, nil)
					end,
				},
			},
		}
	end
	return {
		type = "group",
		name = L["Categories"],
		args = args,
	}
end

------------------------------------------------------------------------
-- Registro
------------------------------------------------------------------------

local function OrderSubcategories(parentFrame, children)
	local list = INTERFACEOPTIONS_ADDONCATEGORIES
	if type(list) ~= "table" then return end
	for i = #list, 1, -1 do
		for _, child in ipairs(children) do
			if list[i] == child then
				tremove(list, i)
				break
			end
		end
	end
	for i = 1, #list do
		if list[i] == parentFrame then
			for j, child in ipairs(children) do
				tinsert(list, i + j, child)
			end
			break
		end
	end
	if InterfaceAddOnsList_Update then
		InterfaceAddOnsList_Update()
	end
end

function ChatDigest:SetupOptions()
	AceConfig:RegisterOptionsTable(APP_MAIN, GetMainOptions)
	AceConfig:RegisterOptionsTable(APP_ALERTS, GetAlertOptions)
	AceConfig:RegisterOptionsTable(APP_CATEGORIES, GetCategoryOptions)
	AceConfig:RegisterOptionsTable(APP_PROFILES, AceDBOptions:GetOptionsTable(self.db))

	self.optionsFrame    = AceConfigDialog:AddToBlizOptions(APP_MAIN, "ChatDigest")
	self.alertsFrame     = AceConfigDialog:AddToBlizOptions(APP_ALERTS, L["Alerts"], "ChatDigest")
	self.categoriesFrame = AceConfigDialog:AddToBlizOptions(APP_CATEGORIES, L["Categories"], "ChatDigest")
	self.profilesFrame   = AceConfigDialog:AddToBlizOptions(APP_PROFILES, L["Profiles"], "ChatDigest")

	OrderSubcategories(self.optionsFrame, { self.alertsFrame, self.categoriesFrame, self.profilesFrame })
end

function ChatDigest:NotifyConfigChanged()
	AceConfigRegistry:NotifyChange(APP_MAIN)
	AceConfigRegistry:NotifyChange(APP_ALERTS)
	AceConfigRegistry:NotifyChange(APP_CATEGORIES)
end

function ChatDigest:OpenConfig()
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end
