# Easy Roll Tracker

A lightweight addon to list `/roll` results in a raid,
with many convenience features. Open the tracking window
with `/rt` or `/rolltrack`.

**Feedback, suggestions, and criticism are welcome!**
Open a [new GitHub issue][5] for the fastest response,
but comments in other places will get to me eventually.

### Limitations
- Can only handle one roll at a time
- Cannot show order of duplicate rolls; I recommend
making a rule to only count lowest roll in this case
(or go back to chat logs and check)
- Specs are fetched one-at-a-time, and subject to server
limits (need to send inspect request and be in range)

### Major features

- Listing and sorting all `/roll` results in group
- Tracking the number rolled out of
- Announcing loot rolls to group as `/rw`

### Commands

*These can be opened with any of the addon aliases:*
*`/rt`, `/rolltrack`, or `/erolltracker`.*

- `/rt`: toggles main window
- `/rt help`, `h`, `?`: prints a list of available commands
- `/rt config`, `opt`, `options`: opens the addon settings
- `/rt close`: closes the current roll
- `/rt clear`: clears the main window
- `/rt reset`: reset all addon data

### Minor features

- Slash command (`/rt`) interface
- Minimap button for quick access
- Displaying spec and role icon
- Formatting names with class color
- Highlighting out-of-bounds rolls
- Drag-and-drop or shift-click items
- Items can be dragged onto editbox
- Parses valid plaintext to itemlinks
- Tooltip preview of items
- Resizable window
- Maximize by double-clicking titlebar / resize handle

*The project can be found on CurseForge [here][1].*

*Download the latest release from GitHub [here][2].*

*Screenshots (including historical versions) hosted*
*on Imgur [here][3].*

*Latest CurseForge screenshots are [here][4].*

[1]: https://www.curseforge.com/wow/addons/easy-roll-tracker
[2]: https://github.com/ErythroGuild/EasyRollTracker/releases/latest
[3]: https://imgur.com/a/AZu9CpG
[4]: https://www.curseforge.com/wow/addons/easy-roll-tracker/screenshots
[5]: https://github.com/ErythroGuild/EasyRollTracker/issues/new
