-- ChatDigest: núcleo del addon (inicialización, base de datos y comandos)

local ChatDigest = LibStub("AceAddon-3.0"):NewAddon("ChatDigest",
	"AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ChatDigest")

ChatDigest.version = GetAddOnMetadata("ChatDigest", "Version") or "dev"

BINDING_HEADER_CHATDIGEST = "ChatDigest"
BINDING_NAME_CHATDIGEST_TOGGLE = L["Show/hide window"]

ChatDigest.defaults = {
	profile = {
		window = {
			shown    = false,
			locked   = false,
			scale    = 1.0,
			alpha    = 0.85,
			width    = 480,
			height   = 300,
			point    = "CENTER",
			relPoint = "CENTER",
			x        = 0,
			y        = 0,
			filter   = "all", -- pestaña elegida: all, raid, dungeon, trade, guild, other
			timeFormat = "%H:%M:%S", -- formato de date() para la hora; "" = sin hora
			font       = "",         -- nombre de la fuente; "" = la del chat
			fontSize   = 14,         -- tamaño del texto de la lista
			playerTooltip = false,   -- tooltip con información al pasar por el nombre
			hideInCombat   = true,   -- ocultar la ventana durante el combate
			hideInInstance = false,  -- ocultar la ventana en mazmorras y bandas
			borderStyle = "solid",   -- solid (liso), blizzard o none
			borderSize  = 1,         -- grosor en píxeles del borde liso
			borderColor = { r = 0, g = 0, b = 0 }, -- color del borde liso (negro)
		},
		-- Palabras clave de cada categoría
		-- raid/dungeon/trade/guild con las palabras por defecto según GetLocale().
		categories = {},
		-- Qué mensajes se capturan
		capture = {
			allChannels = true,  -- capturar todos los canales numerados
			channels    = {},    -- [nombre base en minúsculas] = true (si allChannels = false)
			yell        = true,  -- Gritar
			say         = false, -- Decir
			ignoreSelf  = true,  -- ignorar mis propios mensajes
		},
		-- Agrupación y refresco de la lista
		messages = {
			expireMinutes   = 5,   -- borrar entradas sin actividad tras N minutos
			maxEntries      = 200, -- máximo de jugadores en la lista
			refreshInterval = 10,  -- segundos entre cada refresco de la ventana
			pauseOnHover    = true, -- no refrescar mientras el ratón está sobre la ventana
		},
		-- Alertas por palabras clave
		alerts = {
			keywords      = "",            -- una palabra o frase por línea
			noCombat      = true,          -- no avisar durante el combate
			sound         = false,         -- avisar con sonido
			soundName     = "RaidWarning", -- sonido elegido (ver Alerts.lua)
			useClassColor = false,         -- resaltar con el color de clase del autor
			color         = { r = 0.2, g = 1, b = 0.4 }, -- color propio (verde)
		},
	},
}

function ChatDigest:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ChatDigest_DB", self.defaults, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self:SetupOptions()

	self:RegisterChatCommand("chatd", "SlashCommand")
	self:RegisterChatCommand("chatdigest", "SlashCommand")
end

function ChatDigest:OnEnable()
	self:CompileKeywords()
	self:CompileAlertKeywords()
	self:CreateMainFrame()
	self:EnableCapture()
	self:StartRefreshTimer()
	self:EnableAutoHide()
	if self.db.profile.window.shown then
		self:ShowWindow()
	end
	self:UpdateAutoHide()
end

function ChatDigest:OnPlayerEnteringWorld()
	self:UpdateChannelList()
	self:UpdateAutoHide()
end

function ChatDigest:RefreshConfig()
	self:CompileKeywords()
	self:RecategorizeAll()
	self:CompileAlertKeywords()
	self:RecheckAlerts()
	self:ApplyWindowSettings()
	self:ApplyMessageSettings()
	if self.db.profile.window.shown then
		self:ShowWindow()
	else
		self:HideWindow()
	end
	self:UpdateAutoHide()
end

------------------------------------------------------------------------
-- Comandos: /chatd o /chatdigest
------------------------------------------------------------------------

function ChatDigest:PrintHelp()
	self:Print(L["Available commands:"])
	print("  |cffcaf7fa/chatd show|r - " .. L["CMD_SHOW"])
	print("  |cffcaf7fa/chatd hide|r - " .. L["CMD_HIDE"])
	print("  |cffcaf7fa/chatd toggle|r - " .. L["CMD_TOGGLE"])
	print("  |cffcaf7fa/chatd config|r - " .. L["CMD_CONFIG"])
	print("  |cffcaf7fa/chatd reset|r - " .. L["CMD_RESET"])
end

function ChatDigest:SlashCommand(input)
	local cmd = self:GetArgs(input, 1)
	cmd = cmd and cmd:lower() or ""

	if cmd == "show" then
		self:ShowWindow()
	elseif cmd == "hide" then
		self:HideWindow()
	elseif cmd == "toggle" then
		self:ToggleWindow()
	elseif cmd == "config" or cmd == "options" then
		self:OpenConfig()
	elseif cmd == "reset" then
		self:ResetWindow()
		self:Print(L["Window position reset."])
	elseif cmd == "" or cmd == "help" then
		self:PrintHelp()
	else
		self:Print(string.format(L["Unknown command: %s"], cmd))
		self:PrintHelp()
	end
end
