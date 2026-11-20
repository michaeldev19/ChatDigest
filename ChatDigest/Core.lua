-- ChatDigest: núcleo del addon (inicialización, base de datos y comandos)

local ChatDigest = LibStub("AceAddon-3.0"):NewAddon("ChatDigest",
	"AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ChatDigest")

ChatDigest.version = GetAddOnMetadata("ChatDigest", "Version") or "dev"

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
	self:CreateMainFrame()
	if self.db.profile.window.shown then
		self:ShowWindow()
	end
end

-- Se llama al cambiar, copiar o reiniciar un perfil
function ChatDigest:RefreshConfig()
	self:ApplyWindowSettings()
	if self.db.profile.window.shown then
		self:ShowWindow()
	else
		self:HideWindow()
	end
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
