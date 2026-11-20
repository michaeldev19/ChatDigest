-- ChatDigest: ventana principal (por ahora vacía)

local ChatDigest = LibStub("AceAddon-3.0"):GetAddon("ChatDigest")
local L = LibStub("AceLocale-3.0"):GetLocale("ChatDigest")

local FRAME_NAME = "ChatDigestMainFrame"
local MIN_WIDTH, MIN_HEIGHT = 320, 160
local MAX_WIDTH, MAX_HEIGHT = 1200, 900

local BACKDROP = {
	bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

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
	f:SetBackdrop(BACKDROP)
	f:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

	-- Arrastrar para mover
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

	-- Título
	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 12, -10)
	title:SetText("ChatDigest")
	f.title = title

	-- Botón de cerrar
	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 2)
	close:SetScript("OnClick", function() addon:HideWindow() end)
	f.closeButton = close

	-- Línea separadora bajo el título
	local sep = f:CreateTexture(nil, "ARTWORK")
	sep:SetTexture(1, 1, 1, 0.15)
	sep:SetHeight(1)
	sep:SetPoint("TOPLEFT", 8, -28)
	sep:SetPoint("TOPRIGHT", -8, -28)

	-- Zona de contenido (aquí irá la lista de mensajes)
	local content = CreateFrame("Frame", nil, f)
	content:SetPoint("TOPLEFT", 8, -32)
	content:SetPoint("BOTTOMRIGHT", -8, 8)
	f.content = content

	local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	empty:SetPoint("CENTER")
	empty:SetText(L["No messages yet."])
	f.emptyText = empty

	-- Agarre para cambiar el tamaño
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

	-- Recordar si la ventana queda abierta. IsShown() distingue un Hide()
	-- real (cerrar, Esc) de ocultar toda la interfaz con Alt+Z.
	f:SetScript("OnHide", function(frame)
		frame:StopMovingOrSizing()
		if not frame:IsShown() then
			addon.db.profile.window.shown = false
		end
	end)

	-- Cerrar con Esc
	tinsert(UISpecialFrames, FRAME_NAME)

	self.frame = f
	self:ApplyWindowSettings()
	return f
end

-- Aplica escala, tamaño, posición, opacidad y bloqueo desde el perfil
function ChatDigest:ApplyWindowSettings()
	local f = self.frame
	if not f then return end
	local w = self.db.profile.window

	f:SetScale(w.scale)
	f:SetWidth(w.width)
	f:SetHeight(w.height)
	f:ClearAllPoints()
	f:SetPoint(w.point, UIParent, w.relPoint, w.x, w.y)
	f:SetBackdropColor(0, 0, 0, w.alpha)

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
