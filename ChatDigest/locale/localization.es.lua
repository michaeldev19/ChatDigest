local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:NewLocale("ChatDigest", "esES") or AceLocale:NewLocale("ChatDigest", "esMX")
if not L then return end

-- Panel de opciones
L["General"] = "General"
L["Profiles"] = "Perfiles"
L["Window"] = "Ventana"
L["DESCRIPTION"] = "Agrupa los mensajes repetidos del chat y muestra solo el último mensaje de cada jugador."
L["Show/hide window"] = "Mostrar/ocultar ventana"
L["Lock window"] = "Bloquear ventana"
L["LOCK_DESC"] = "Impide mover y cambiar el tamaño de la ventana."
L["Scale"] = "Escala"
L["SCALE_DESC"] = "Tamaño de toda la ventana."
L["Background opacity"] = "Opacidad del fondo"
L["ALPHA_DESC"] = "Opacidad del fondo de la ventana. No afecta al texto."
L["Reset position"] = "Restablecer posición"
L["RESET_DESC"] = "Devuelve la ventana al centro de la pantalla y restaura su tamaño y escala por defecto."

-- Ventana
L["No messages yet."] = "Aún no hay mensajes."

-- Comandos
L["Available commands:"] = "Comandos disponibles:"
L["CMD_SHOW"] = "muestra la ventana"
L["CMD_HIDE"] = "oculta la ventana"
L["CMD_TOGGLE"] = "muestra u oculta la ventana"
L["CMD_CONFIG"] = "abre el panel de opciones"
L["CMD_RESET"] = "restablece la posición y el tamaño de la ventana"
L["Unknown command: %s"] = "Comando desconocido: %s"
L["Window position reset."] = "Posición de la ventana restablecida."
