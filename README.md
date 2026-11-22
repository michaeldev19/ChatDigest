# ChatDigest Addon

**ChatDigest** is a quality-of-life chat addon for World of Warcraft that tames the spam in capital cities and inns. Instead of watching the same announcements scroll past every few seconds, ChatDigest collects the messages from the channels you choose and shows them in its own window with **only one message per player**. Repeated announcements just update a counter, changed ones are marked as edited, and the list reorders every few seconds so you can actually read it. Spend less time chasing the chat and more time finding your group!

## Features

### One Message per Player

* **Grouping:** Each player appears only once. Repeating the same announcement updates the time and a `xN` counter; writing something different replaces it and marks it as *(edited)*.
* **Smart Comparison:** Messages are compared ignoring case, colors, raid icons, repeated punctuation and extra spaces, so small variations still count as a repeat.
* **Channel Selection:** Capture all your channels or pick specific ones (Trade, LookingForGroup, World...), plus optional Yell and Say.
* **Auto Cleanup:** Entries expire after a configurable number of minutes of inactivity, with a maximum list size. Your own messages and players on your ignore list are skipped.

### Readable Message Window

* **Clean Lines:** `[time] [Channel] [Player] xN: message`, with player names in class colors, raid target icons and working item/achievement links.
* **Category Tabs:** Messages are sorted automatically into **Raid**, **Dungeon**, **Trade**, **Guild** and **Other**, with a counter on each tab. Keywords for each category are fully editable.
* **Search Box:** Filter every tab at once by any words, in the message or the player name.
* **Steady Reading:** The list refreshes every few seconds, pauses while your mouse is over the window, and keeps your scroll position on the same message.

### Keyword Alerts

* **Highlighting:** Define your own keywords (e.g. `ICC 25N`) and matching text is highlighted in a custom color or your character's class color.
* **Flexible Matching:** Spacing is flexible, so `icc 25n` also matches "ICC25N", "ICC-25N" or "ICC 25NLK".
* **Sound Alert:** Optionally play a sound when a new matching message arrives, with the option to stay silent during combat.

### Quick Player Tools

* **Left-click** a name to whisper the player.
* **Right-click** a name for the standard Blizzard player menu (whisper, invite, ignore, report spam...) plus **Copy name**. Addons that extend this menu, such as AddFriend, also work.
* **Player Tooltip (optional):** Hover a name to see race, class, channel, how long they have been announcing and their previous message. **Shift-click** to look up level, guild and zone with `/who`.

### Customization

* Window scale, background opacity, border style (thin, Blizzard or none), font and font size (including LibSharedMedia fonts).
* Time format (24 h or 12 h, with or without seconds).
* Automatically hide the window in combat and/or inside dungeons and raids.
* Key binding to show or hide the window.
* Profile support (AceDB), shared between characters.

## Usage

To start using ChatDigest, follow these simple steps:

1.  Download the addon files.
2.  Place the `ChatDigest` folder directly into your World of Warcraft `Interface/AddOns/` directory.
3.  Restart the WoW client to load the addon.
4.  Type `/chatd show` in-game to open the window.

### Commands

| Command | Description |
| :--- | :--- |
| `/chatd show` | Show the window |
| `/chatd hide` | Hide the window |
| `/chatd toggle` | Show or hide the window |
| `/chatd config` | Open the options panel |
| `/chatd reset` | Reset window position and size |

`/chatdigest` works as an alias of `/chatd`. Options are also available under **Interface → AddOns → ChatDigest** (with the **Alerts**, **Categories** and **Profiles** sub-pages), and through the **Options** button in the window.

## Compatibility

| Attribute | Details |
| :--- | :--- |
| **Addon Version** | 1.0 |
| **Supported WoW Version** | **Wrath of the Lich King (3.3.5a)** |
| **Interface Version** | **30300** |
| **Languages** | English, Spanish (esES / esMX) |

## Credits

Created by: **Shinji** - Author

Built with the [Ace3](https://www.wowace.com/projects/ace3) library framework.

## Contributions

Issues and suggestions are welcome! Feel free to open an issue or submit a pull request at [github.com/michaeldev19/ChatDigest](https://github.com/michaeldev19/ChatDigest).
