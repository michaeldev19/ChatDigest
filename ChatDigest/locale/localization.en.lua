local L = LibStub("AceLocale-3.0"):NewLocale("ChatDigest", "enUS", true)
if not L then return end

-- Options panel
L["General"] = true
L["Profiles"] = true
L["Window"] = true
L["DESCRIPTION"] = "Groups repeated chat messages and shows only the latest message from each player."
L["Show/hide window"] = true
L["Lock window"] = true
L["LOCK_DESC"] = "Prevents moving and resizing the window."
L["Scale"] = true
L["SCALE_DESC"] = "Size of the whole window."
L["Background opacity"] = true
L["ALPHA_DESC"] = "Opacity of the window background. Text is not affected."
L["Reset position"] = true
L["RESET_DESC"] = "Moves the window back to the center of the screen and restores its default size and scale."

-- Window
L["No messages yet."] = true

-- Slash commands
L["Available commands:"] = true
L["CMD_SHOW"] = "show the window"
L["CMD_HIDE"] = "hide the window"
L["CMD_TOGGLE"] = "show or hide the window"
L["CMD_CONFIG"] = "open the options panel"
L["CMD_RESET"] = "reset window position and size"
L["Unknown command: %s"] = true
L["Window position reset."] = true
