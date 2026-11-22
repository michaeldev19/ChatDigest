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
L["Time format"] = true
L["TIME_FORMAT_DESC"] = "How the time of each message is shown in the window. The examples use the current time."
L["No time"] = "Don't show the time"
L["Font"] = true
L["FONT_DESC"] = "Font of the message list. Fonts registered by other addons through LibSharedMedia also appear here."
L["Chat font (default)"] = true
L["Font size"] = true
L["FONT_SIZE_DESC"] = "Size of the message list text."
L["Player tooltip"] = "Show player info when hovering the name"
L["PLAYER_TOOLTIP_DESC"] = "Shows a tooltip with the player's race and class, channel, how long they have been announcing and their previous message. Shift+click the name to also look up level, guild and zone with /who (the result still appears in the chat)."
L["Hide in combat"] = true
L["HIDE_IN_COMBAT_DESC"] = "Hides the window while you are in combat and shows it again when combat ends (if it was open)."
L["Hide in dungeons and raids"] = true
L["HIDE_IN_INSTANCE_DESC"] = "Hides the window inside dungeons and raids and shows it again when you leave (if it was open)."
L["Border"] = true
L["BORDER_DESC"] = "Style of the window border."
L["Thin (solid)"] = true
L["Blizzard"] = true
L["None"] = true
L["Border size"] = true
L["BORDER_SIZE_DESC"] = "Thickness of the solid border, in pixels."
L["Border color"] = true
L["BORDER_COLOR_DESC"] = "Color of the solid border."
L["Reset position"] = true
L["RESET_DESC"] = "Moves the window back to the center of the screen and restores its default size and scale."

-- Options: channels
L["Channels"] = true
L["All channels"] = true
L["ALL_CHANNELS_DESC"] = "Capture messages from every channel you have joined. Disable it to pick specific channels."
L["Channels to capture"] = true
L["CHANNEL_LIST_DESC"] = "Only messages from the checked channels are captured. Channels are remembered by name, not by number."
L["NO_CHANNELS"] = "You have not joined any channel yet."
L["(not joined)"] = true
L["Other chat types"] = true
L["Yell"] = true
L["YELL_DESC"] = "Capture messages yelled by nearby players."
L["Say"] = true
L["SAY_DESC"] = "Capture messages said by nearby players."

-- Options: messages
L["Messages"] = true
L["Ignore my own messages"] = true
L["IGNORE_SELF_DESC"] = "Do not add your own messages to the list. Players on your ignore list are always skipped."
L["Expire after (minutes)"] = true
L["EXPIRE_DESC"] = "Removes a player from the list when they have not written anything for this many minutes."
L["Maximum entries"] = true
L["MAX_ENTRIES_DESC"] = "Maximum number of players in the list. When it is exceeded, the oldest one is removed."
L["Refresh every (seconds)"] = true
L["REFRESH_DESC"] = "How often the window is redrawn and reordered. A longer interval makes the list easier to read."
L["Pause while hovering"] = true
L["PAUSE_DESC"] = "Stops reordering the list while the mouse is over the window, so it does not move while you read. It updates as soon as the mouse leaves."
L["Paused"] = true
L["Clear list"] = true
L["CLEAR_DESC"] = "Removes every captured message."

-- Options: categories
L["Categories"] = true
L["Raid"] = true
L["Dungeon"] = true
L["Trade"] = true
L["Guild"] = true
L["Other"] = true
L["All"] = true
L["Keywords"] = true
L["KEYWORDS_DESC"] = "One word or phrase per line. Press Accept to save."
L["KEYWORDS_HELP"] = "Each message is sorted into categories by these words. A message can belong to several categories; messages that match none go to |cffcaf7faOther|r.\n\n- Whole words, case-insensitive: |cffcaf7faicc|r matches \"LFM ICC 25\".\n- Phrases are allowed: |cffcaf7fabusco grupo|r.\n- A |cffcaf7fa*|r at the end matches the start of a word: |cffcaf7farecruit*|r matches recruiting, recruits.\n- A |cffcaf7fa!|r at the end makes the word exclusive: if the message contains it, it goes |cffcaf7faonly|r to that category even if it matches others. E.g. |cffcaf7farecruit*!|r in Guild keeps \"recruiting for ICC\" out of Raid."
L["Restore defaults"] = true
L["RESTORE_DESC"] = "Replaces this category's words with the default ones for your game language."

-- Options: alerts
L["Alerts"] = true
L["ALERTS_HELP"] = "When a message contains one of these words, the matching text is highlighted in the window and, if enabled, a sound plays. It only alerts when a player writes a new or changed message, not on every repeat.\n\n- Case-insensitive.\n- Spaces are flexible: |cffcaf7faicc 25n|r matches \"ICC 25N\", \"ICC25N\" and \"ICC-25N\".\n- It also matches at the start of a longer word: |cffcaf7faicc 25n|r highlights \"ICC 25N\" inside \"ICC 25NLK\"."
L["Alert keywords"] = true
L["ALERT_KEYWORDS_DESC"] = "One word or phrase per line (commas also work as separators). Press Accept to save."
L["Notification"] = true
L["No alerts in combat"] = true
L["NO_COMBAT_DESC"] = "Do not play the alert sound while you are in combat. The text is still highlighted."
L["Play a sound"] = true
L["SOUND_DESC"] = "Play a sound when a message matches your keywords (at most once every few seconds)."
L["Sound"] = true
L["SOUND_NAME_DESC"] = "Sound to play. Selecting one plays a preview. Sounds registered by other addons through LibSharedMedia also appear here."
L["Highlight"] = true
L["Use class color"] = true
L["USE_CLASS_COLOR_DESC"] = "Highlight the matching text with your character's class color (e.g. red if you are playing a death knight) instead of the custom color."
L["Highlight color"] = true
L["HIGHLIGHT_COLOR_DESC"] = "Color used to highlight the matching text."
L["Sound: raid warning"] = "Raid warning"
L["Sound: ready check"] = "Ready check"
L["Sound: whisper"] = "Whisper"
L["Sound: map ping"] = "Map ping"
L["Sound: level up"] = "Level up"
L["Sound: auction house"] = "Auction house"

-- Window
L["No messages yet."] = true
L["Options"] = true
L["Copy name"] = true
L["COPY_NAME_TEXT"] = "Press Ctrl+C to copy the name:"

-- Player name tooltip
L["Level %d %s %s"] = true
L["Channel"] = true
L["First seen"] = true
L["Repeats"] = true
L["Previous message:"] = true
L["just now"] = true
L["%d min ago"] = true
L["%d h %d min ago"] = true
L["Querying..."] = true
L["SHIFT_CLICK_WHO"] = "Shift+click: look up level, guild and zone"
L["SHIFT_CLICK_REFRESH"] = "Shift+click: look up again"
L["WHO_NOT_FOUND"] = "Not found with /who (offline or opposite faction)."
L["No messages in this category."] = true
L["No messages match the search."] = true
L["Search..."] = true
L["Clear search"] = true
L["(edited)"] = true

-- Slash commands
L["Available commands:"] = true
L["CMD_SHOW"] = "show the window"
L["CMD_HIDE"] = "hide the window"
L["CMD_TOGGLE"] = "show or hide the window"
L["CMD_CONFIG"] = "open the options panel"
L["CMD_RESET"] = "reset window position and size"
L["Unknown command: %s"] = true
L["Window position reset."] = true
