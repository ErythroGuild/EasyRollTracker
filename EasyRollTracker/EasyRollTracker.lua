if eRollTracker == nil then eRollTracker = {} end
if eRollTracker.ext == nil then eRollTracker.ext = {} end

---------------------
-- Library Imports --
---------------------
local LibDB		= LibStub("LibDataBroker-1.1")
local LibDBIcon	= LibStub("LibDBIcon-1.0")
local LibWindow = LibStub("LibWindow-1.1")

----------------------
-- Member Variables --
----------------------
eRollTracker.wasMainWindowShown = false	-- whether main window should be shown after closing options window
eRollTracker.isAutoClosing = false		-- whether roll will be closed automatically
eRollTracker.item = ""		-- this should be a valid itemLink
eRollTracker.isOpen = false	-- if an item is currently being rolled for
eRollTracker.entries = {}	-- list of current roll (sorted) entries
eRollTracker.specqueue = {}	-- list of players to query specs
eRollTracker.isInspecting = false	-- whether or not an inspect request has been sent already
eRollTracker.pools = {
	heading		= CreateFramePool("Frame", eRollTrackerFrame_Scroll_Layout,"eRollTracker_Template_Heading"),
	entry		= CreateFramePool("Frame", eRollTrackerFrame_Scroll_Layout,"eRollTracker_Template_Entry"),
	separator	= CreateFramePool("Frame", eRollTrackerFrame_Scroll_Layout,"eRollTracker_Template_Separator"),
}	-- reuse frames to prevent excess created frames
eRollTracker.events = {}	-- syntactic sugar for OnEvent handlers

----------------------
-- Imported Aliases --
----------------------
-- Header `#include`s aren't supported.
-- This is the most concise workaround.

-- consts.lua
local const_text_addonname		= eRollTracker.ext.const_text_addonname
local const_version				= eRollTracker.ext.const_version
local const_namechars			= eRollTracker.ext.const_namechars
local const_time_doubleclick	= eRollTracker.ext.const_time_doubleclick
local const_frame_size_ignore	= eRollTracker.ext.const_frame_size_ignore
local const_path_icon_LDB		= eRollTracker.ext.const_path_icon_LDB
local const_path_icon_unknown	= eRollTracker.ext.const_path_icon_unknown

-- color.lua
local const_colortable	= eRollTracker.ext.const_colortable
local const_classcolor	= eRollTracker.ext.const_classcolor

local UncolorizeText = eRollTracker.ext.UncolorizeText

local Colorize		= eRollTracker.ext.Colorize
local ColorizeName	= eRollTracker.ext.ColorizeName
local ColorizeSpec	= eRollTracker.ext.ColorizeSpec
local ColorizeSpecBW = eRollTracker.ext.ColorizeSpecBW
local ColorizeLayerSpec		= eRollTracker.ext.ColorizeLayerSpec
local ColorizeLayerRarity	= eRollTracker.ext.ColorizeLayerRarity

-- components.lua
local ResetHeading		= eRollTracker.ext.ResetHeading
local ResetEntry		= eRollTracker.ext.ResetEntry
local ResetSeparator	= eRollTracker.ext.ResetSeparator

local InitHeading	= eRollTracker.ext.InitHeading
local InitEntry		= eRollTracker.ext.InitEntry
local InitSeparator	= eRollTracker.ext.InitSeparator

-----------------------
-- Utility Functions --
-----------------------
local const_roleicon = {
	TANK	= CreateAtlasMarkup("roleicon-tiny-tank"),
	HEALER	= CreateAtlasMarkup("roleicon-tiny-healer"),
	DAMAGER	= CreateAtlasMarkup("roleicon-tiny-dps"),
	NONE	= CreateAtlasMarkup("roleicon-tiny-none"),
}
local function RoleIconString(name)
	local role = UnitGroupRolesAssigned(name)
	return const_roleicon[role]
end

local function ParseRollText(text)
	local regex_find_roll =
		"[%a%-" .. const_namechars .. "]+" ..
		" rolls %d+ %(1%-%d+%)"
	local regex_find_data =
		"([%a%-" .. const_namechars .. "]+)" ..
		" rolls (%d+) %(1%-(%d+)%)"
	if string.find(text, regex_find_roll) == nil then
		return false
	else
		local _,_, name, roll, max =
			string.find(text, regex_find_data)
		return true, name, roll, max
	end
end

local const_spectable = {
	[1455] = "new",	-- Death Knight
	[ 250] = "BDK", [ 251] = "FRS", [ 252] = "UNH",
	[1456] = "new",	-- Demon Hunter
	[ 577] = "HAV", [ 581] = "VDH",
	[1447] = "new",	-- Druid
	[ 102] = "OWL", [ 103] = "CAT", [ 104] = "BR" , [ 105] = "RST",
	[1448] = "new",	-- Hunter
	[ 253] = "BM" , [ 254] = "MM" , [ 255] = "SV" ,
	[1449] = "new",	-- Mage
	[  62] = "ARC", [  63] = "HOT", [  64] = "FRS",
	[1450] = "new",	-- Monk
	[ 268] = "BRM", [ 270] = "MW" , [ 269] = "WW" ,
	[1451] = "new",	-- Paladin
	[  65] = "HLY", [  66] = "PT" , [  70] = "RET",
	[1452] = "new",	-- Priest
	[ 256] = "DSC", [ 257] = "HLY", [ 258] = "SHA",
	[1453] = "new",	-- Rogue
	[ 259] = "SIN", [ 260] = "OUT", [ 261] = "SUB",
	[1444] = "new",	-- Shaman
	[ 262] = "ELE", [ 263] = "ENH", [ 264] = "RST",
	[1454] = "new",	-- Warlock
	[ 265] = "AFF", [ 266] = "DMN", [ 267] = "DST",
	[1446] = "new",	-- Warrior
	[  71] = "ARM", [  72] = "FY" , [  73] = "PT" ,
}
local function GetSpec(player, entry)
	local GUID = UnitGUID(player)
	if eRollTracker.specqueue[GUID] == nil then
		eRollTracker.specqueue[GUID] = {
			["name"] = player,
			["entry"] = { entry },
		}
	else
		table.insert(eRollTracker.specqueue[GUID].entry, entry)
	end
	if eRollTracker.isInspecting == false then
		NotifyInspect(player)
		eRollTracker.isInspecting = true
		local function reinspect()
			if eRollTracker.isInspecting then
				NotifyInspect(player)
				C_Timer.After(2.000, reinspect)
			end
		end
		C_Timer.After(2.000, reinspect)
	end
	return ""
end

local function getItemLink(itemtext)
	local regex_find_itemlink = "(|c[fF][fF]%x%x%x%x%x%x|Hitem:[:%d]-|h.-|h|r)"
	local _,_, itemlink = string.find(itemtext, regex_find_itemlink)
	if itemlink == nil then
		return ""
	else
		return itemlink
	end
end

local function ResetAddonData(isAcceptCallback)
	if isAcceptCallback == nil then
		StaticPopup_Show("EASYROLLTRACKER_RESET")
		return
	elseif isAcceptCallback == true then
		eRollTracker_ClearAll()
	
		EasyRollTrackerDB = {
			options = {
				maxRollThreshold = 100,
				onlyAllowValidItems = true,
				autoCloseRoll = false,
				autoCloseDelay = 150,
				exportOnClear = false,
			},
			unmaximize = { width = 250, height = 320 },
			libwindow = {},
			ldbicon = { hide = false },
		}
	
		eRollTrackerFrame:ClearAllPoints()
		eRollTrackerFrame:SetPoint("CENTER")
		eRollTrackerFrame:SetSize(250, 320)
	
		LibWindow.RegisterConfig(eRollTrackerFrame, EasyRollTrackerDB.libwindow)
		LibWindow.SavePosition(eRollTrackerFrame)
	
		eRollTrackerFrame:Hide()
	end
end

local function PrintHelpText()
	local function ColorCommand(cmd)
		return Colorize(cmd, const_colortable["Erythro"])
	end

	print(
		const_text_addonname ..
		" (" .. const_version .. ")" ..
		" commands:"
	)

	print(ColorCommand("  /rt:") .. " toggles the main window")
	print(ColorCommand("  /rt help:")	.. " lists available commands")
	print(ColorCommand("  /rt config:")	.. " opens the addon settings")
	print(ColorCommand("  /rt close:")	.. " closes the current roll")
	print(ColorCommand("  /rt clear:")	.. " clears the main window")
	print(ColorCommand("  /rt reset:")	.. " reset all data/settings")
end

local function SetItem(itemstring)
	-- Validate item here (if enabled).
	-- local itemID, itemLink = GetItemInfo(itemstring)
	-- local is_itemLink = (itemID ~= nil)
	-- if is_itemLink then
	-- 	eRollTracker.item = itemLink
	-- else
	-- 	eRollTracker.item = itemstring
	-- end
end

local function ToggleVisible()
	if (eRollTrackerFrame:IsShown()) then
		eRollTrackerFrame:Hide()
	else
		eRollTrackerFrame:Show()
		LibWindow.RestorePosition(eRollTrackerFrame)
	end
end

-- View display update functions for the current roll item.
local function UpdateItemIcon()
	local itemLink = eRollTracker.item
	if itemLink then
		local _,_, itemRarity, _,_,_,_,_,_, itemIcon =
			GetItemInfo(itemLink)
		if itemRarity ~= nil then
			ColorizeLayerRarity(eRollTrackerFrame_Item.border, itemRarity)
		else
			eRollTrackerFrame_Item.border:SetVertexColor(0.85, 0.85, 0.85)
		end

		if itemLink == "" then
			eRollTrackerFrame_Item_Icon.icon:SetTexture(nil)	-- hides texture
		elseif itemIcon == nil then
			eRollTrackerFrame_Item_Icon.icon:SetTexture(const_path_icon_unknown)
		else
			eRollTrackerFrame_Item_Icon.icon:SetTexture(itemIcon)
		end
	end
end
local function UpdateItemText()
	eRollTrackerFrame_EditItem:SetText(eRollTracker.item)
end
local function ClearItem()
	eRollTracker.item = ""
	UpdateItemIcon()
	UpdateItemText()
end

local function GetInsertIndex(roll)
	for i, widget in ipairs(eRollTracker.entries) do
		if widget.roll then
			local roll_compare =
				tonumber(UncolorizeText(widget.roll:GetText()))
			local roll_new =
				tonumber(UncolorizeText(roll))
			if roll_compare < roll_new then
				return i
			end
		end
	end
	return #(eRollTracker.entries) + 1
end

-- Inserts frame as the new frame at index.
-- The current frame at index is pushed down by 1.
local function ScrollInsert(frame, index)
	local frame_prev = nil
	if index == 1 then
		frame_prev = eRollTrackerFrame_Scroll_Layout_PadTop
	else
		frame_prev = eRollTracker.entries[index-1]
	end
	frame:SetPoint("TOP", frame_prev, "BOTTOM")

	local frame_next = nil
	if index == #(eRollTracker.entries)+1 then
		frame_next = eRollTrackerFrame_Scroll_Layout_PadBottom
	else
		frame_next = eRollTracker.entries[index]
	end
	frame_next:SetPoint("TOP", frame, "BOTTOM")

	table.insert(eRollTracker.entries, index, frame)
	
	eRollTrackerFrame_Scroll_Layout:AddLayoutChildren(frame)
	eRollTrackerFrame_Scroll_Layout:Layout()
end
local function ScrollAppend(frame)
	ScrollInsert(frame, #(eRollTracker.entries)+1)
	local max_scroll = eRollTrackerFrame_Scroll:GetVerticalScrollRange()
	eRollTrackerFrame_Scroll:SetVerticalScroll(max_scroll)
end

----------------------
-- Global Functions --
----------------------
-- These are easily accessible from XML.

-- A prettified title string, including the AddOn version string.
function eRollTracker_OnLoad(self)
	local str_version = Colorize(const_version, const_colortable["gray"])
	str_title = const_text_addonname .. " " .. str_version
	self.title:SetText(str_title)
	self.clickprev = GetTime();
	
	self:RegisterForDrag("LeftButton")
	table.insert(UISpecialFrames, "eRollTrackerFrame")

	local addon_registered = C_ChatInfo.RegisterAddonMessagePrefix("eRollTrack")
	if addon_registered == false then
		StaticPopup_Show("EASYROLLTRACKER_CHATPREFIXFULL")
	else
		self:RegisterEvent("CHAT_MSG_ADDON")
	end

	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("INSPECT_READY")
end

-- Toggle maximizing the window. Saves previous size to SavedVariables.
function eRollTracker_ToggleMaximize()
	local width, height = eRollTrackerFrame:GetSize()
	local width_max, height_max = eRollTrackerFrame:GetMaxResize()

	local function IsEqual(x, y)
		return math.abs(x - y) < const_frame_size_ignore
	end

	if IsEqual(width, width_max) and IsEqual(height, height_max) then
		local width, height = 250, 320
		if EasyRollTrackerDB.unmaximize ~= nil then
			width = EasyRollTrackerDB.unmaximize["width"]
			height = EasyRollTrackerDB.unmaximize["height"]
		end
		eRollTrackerFrame:SetSize(width, height)
	else
		EasyRollTrackerDB.unmaximize = {
			["width"] = width,
			["height"] = height
		}
		eRollTrackerFrame:SetSize(width_max, height_max)
	end
end

-- Detect double clicks on window titlebar.
function eRollTracker_OnMouseDown(self, button)
	if eRollTrackerFrame_TitleHitbox:IsMouseOver() then
		local click = GetTime()
		-- 500ms is Windows' default interval
		if click - self.clickprev < const_time_doubleclick then
			eRollTracker_ToggleMaximize()
			-- clear double click buffer by setting threshold back in time
			self.clickprev = GetTime() - const_time_doubleclick
		else
			self.clickprev = GetTime()
		end
	end
end

-- Use LibWindow to save the position in a resolution-independent way.
function eRollTracker_StopPositioning()
	eRollTrackerFrame:StopMovingOrSizing()
	LibWindow.SavePosition(eRollTrackerFrame)
end

-- Open the Interface settings menu to the panel for this AddOn.
function eRollTracker_ShowOptions()
	eRollTracker.wasMainWindowShown = eRollTrackerFrame:IsShown()
	eRollTrackerFrame:Hide()
	eRollTrackerFrame_Options:HookScript("OnHide", function()
		if eRollTracker.wasMainWindowShown then
			eRollTrackerFrame:Show()
		end
	end)
	eRollTrackerFrame:HookScript("OnShow", function()
		if eRollTrackerFrame_Options:IsShown() then
			eRollTracker.wasMainWindowShown = true
			eRollTrackerFrame:Hide()
		end
	end)

	if eRollTrackerFrame_Options:IsShown() == false then
		eRollTrackerFrame_Options:Show()
	end
end

-- Show the export logs window (fully populated).
function eRollTracker_ExportLogs()
	if eRollTrackerFrame_ExportLogs:IsShown() then
		eRollTrackerFrame_ExportLogs:Hide()
	end
	
	local log = "Exported on: " .. date("%F %T") .. "|n|n"
	local entries = { eRollTrackerFrame_Scroll_Layout:GetChildren() }
	for _, entry in pairs(entries) do
		if entry.entryType ~= nil then
			if entry.entryType == "HEADING" then
				log = log .. entry.item .. "|n"
			elseif entry.entryType == "SEPARATOR" then
				log = log .. "--------" .. "|n|n"
			elseif entry.entryType == "ENTRY" then
				local name = entry.name:GetText()
				local roll = entry.roll:GetText()
				local max  = entry.max:GetText()
				log = log .. "> " .. name .. ": " .. roll .. "/" .. max .. "|n"
			end
		end
	end

	eRollTrackerFrame_ExportLogs_Scroll_Logs.text = log
	eRollTrackerFrame_ExportLogs:Show()
	if eRollTrackerFrame:IsShown() == false then
		eRollTrackerFrame:Show()
	end
end

-- Use the item data on the cursor to update internal variables.
function eRollTracker_AcceptCursor()
	local type, itemID, itemLink = GetCursorInfo();
	if type=="item" and itemLink then
		eRollTracker.item = itemLink
		ClearCursor()
		UpdateItemIcon()
		UpdateItemText()
		if MouseIsOver(eRollTrackerFrame_Item) then
			eRollTracker_ShowTooltip()
		end
	end
end
function eRollTracker_AcceptText()
	local itemtext = eRollTrackerFrame_EditItem:GetText()
	if EasyRollTrackerDB.options.onlyAllowValidItems then
		itemtext = getItemLink(itemtext)
		eRollTrackerFrame_EditItem:SetText(itemtext)
	end
	eRollTracker.item = itemtext
	UpdateItemIcon()
end
function eRollTracker_SendCursor()
	local type, itemID, itemLink = GetCursorInfo()
	if type=="item" and itemLink then
		eRollTracker.item = itemLink
		ClearCursor()
		UpdateItemIcon()
		UpdateItemText()
		eRollTracker_ShowTooltip()
	else
		local _, itemLinkSelf = GetItemInfo(eRollTracker.item)
		if itemLinkSelf ~= nil then
			PickupItem(eRollTracker.item);
			eRollTracker.item = ""
			UpdateItemIcon()
			UpdateItemText()
			eRollTracker_HideTooltip()
		end
	end
	-- some code repetition is necessary here;
	-- otherwise we end up in a loop of calling Accept/Send.
end

-- Tooltip display handling for the main Item.
function eRollTracker_ShowTooltip()
	local _, itemLink = GetItemInfo(eRollTracker.item)
	if itemLink ~= nil then
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(eRollTrackerFrame_Item, "ANCHOR_NONE")
		GameTooltip:SetPoint("TOPLEFT", eRollTrackerFrame_Item, "BOTTOMLEFT", 0, -4)
		GameTooltip:SetHyperlink(itemLink)
		GameTooltip:Show()
	end
end
function eRollTracker_HideTooltip()
	GameTooltip:Hide()
	GameTooltip:ClearLines()
	GameTooltip:ClearAllPoints()
end

----------------------------
-- Global State Functions --
----------------------------
-- These functions also handle state transitions for the addon,
-- setting properties based on whether a roll is currently open.

function eRollTracker_OpenRoll()
	eRollTracker.isOpen = true

	local itemstring = eRollTracker.item
	local _, itemLink = GetItemInfo(eRollTracker.item)
	if itemLink ~= nil then
		itemstring = itemLink
	end
	local message = "Roll for " .. itemstring
	local channel = ""
	if IsInRaid() then
		channel = "RAID_WARNING"
	elseif IsInGroup() then
		channel = "PARTY"
	else
		channel = "SAY"
	end
	SendChatMessage(message, channel)
	
	ChatThrottleLib:SendAddonMessage("ALERT", "eRollTrack", "<v1>H:" .. eRollTracker.item, "RAID")

	local heading = eRollTracker.pools.heading:Acquire()
	ResetHeading(heading)
	InitHeading(heading, eRollTracker.item)
	heading:Show()
	ScrollAppend(heading)
	eRollTracker.entries = { heading }

	if EasyRollTrackerDB.options.autoCloseRoll then
		eRollTracker.isAutoClosing = true
		C_Timer.After(EasyRollTrackerDB.options.autoCloseDelay, function()
			if eRollTracker.isAutoClosing then
				eRollTracker_CloseRoll()
			end
		end)
	end
end

function eRollTracker_CloseRoll()
	eRollTracker.isOpen = false
	eRollTracker.isAutoClosing = false;
	
	local itemstring = eRollTracker.item
	local _, itemLink = GetItemInfo(eRollTracker.item)
	if itemLink ~= nil then
		itemstring = itemLink
	end
	local message = "Closed roll for " .. itemstring
	local channel = ""
	if IsInRaid() then
		channel = "RAID_WARNING"
	elseif IsInGroup() then
		channel = "PARTY"
	else
		channel = "SAY"
	end
	SendChatMessage(message, channel)

	ChatThrottleLib:SendAddonMessage("ALERT", "eRollTrack", "<v1>S:", "RAID")

	local separator = eRollTracker.pools.separator:Acquire()
	ResetSeparator(separator)
	InitSeparator(separator)
	separator:Show()
	ScrollAppend(separator)
	eRollTracker.entries = { separator }

	ClearItem()
end

function eRollTracker_ClearAll()
	if eRollTracker.isOpen then
		eRollTracker_CloseRoll()
	else
		ClearItem()
	end

	if EasyRollTrackerDB.options.exportOnClear then
		eRollTracker_ExportLogs()
	end

	eRollTrackerFrame_Scroll_Layout_PadBottom:SetPoint("TOP", eRollTrackerFrame_Scroll_Layout_PadTop, "BOTTOM")

	eRollTracker.pools.heading:ReleaseAll()
	eRollTracker.pools.entry:ReleaseAll()
	eRollTracker.pools.separator:ReleaseAll()

	for _, widget in eRollTracker.pools.heading:EnumerateInactive() do
		widget:SetParent(nil)
	end
	for _, widget in eRollTracker.pools.entry:EnumerateInactive() do
		widget:SetParent(nil)
	end
	for _, widget in eRollTracker.pools.separator:EnumerateInactive() do
		widget:SetParent(nil)
	end

	eRollTracker.entries = {}
	eRollTrackerFrame_Scroll_Layout:Layout()
end

--------------------
-- Event Handlers --
--------------------

-- Dispatcher for arbitrary event types.
function eRollTrackerFrame_OnEvent(self, event, ...)
	eRollTracker.events[event](self, ...)
end

-- Event: RAID_/GROUP_ROSTER_UPDATE
-- Updates the button status
-- (whether or not a client can broadcast roll alerts).
function eRollTracker.events:RAID_ROSTER_UPDATE()
	-- print("raid roster update")
end
function eRollTracker.events:GROUP_ROSTER_UPDATE()
	-- print("group roster update")
end

-- Event: CHAT_MSG_ADDON
function eRollTracker.events:CHAT_MSG_ADDON(...)
	local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...
	local self_name, self_realm = UnitFullName("player")
	local self_str = self_name .. "-" .. self_realm
	local isSelf = (sender == self_str)
	local isAssist = false
	if UnitIsSameServer(sender) then
		local regex_find_name = "([^%-]+)%-.+"
		local _,_, name = string.find(sender, regex_find_name)
		sender = name
	end
	if IsInRaid() then
		isAssist = (UnitIsGroupAssistant(sender) or UnitIsGroupLeader(sender))
	elseif IsInGroup() then
		isAssist = UnitIsGroupLeader(sender)
	else
		isAssist = true
	end
	if (prefix == "eRollTrack") and (not isSelf) and isAssist then
		local regex_find_comm = "^<v(%d+)>([HS]):(.*)"
		local _,_, version, type, data =
			string.find(text, regex_find_comm)
		if version == "1" then
			if type == "S" then
				eRollTracker.isOpen = false

				local separator = eRollTracker.pools.separator:Acquire()
				ResetSeparator(separator)
				InitSeparator(separator)
				separator:Show()
				ScrollAppend(separator)
				eRollTracker.entries = { separator }
			
				ClearItem()
			elseif type == "H" then
				eRollTracker.isOpen = true
				eRollTracker.item = data

				local heading = eRollTracker.pools.heading:Acquire()
				ResetHeading(heading)
				InitHeading(heading, eRollTracker.item)
				heading:Show()
				ScrollAppend(heading)
				eRollTracker.entries = { heading }
			end
		end
	end
end

-- Event: INSPECT_READY
-- Updates any spec info that still needs to be filled in.
function eRollTracker.events:INSPECT_READY(...)
	local inspecteeGUID = ...
	local frame_inspectee = eRollTracker.specqueue[inspecteeGUID]
	if frame_inspectee ~= nil then
		local spec = ""
		local player = eRollTracker.specqueue[inspecteeGUID].name
		local specID = GetInspectSpecialization(player)
		spec = const_spectable[specID]
		spec = ColorizeSpecBW(spec, specID)

		for _, entry in pairs(eRollTracker.specqueue[inspecteeGUID].entry) do
			entry.spec:SetText(spec)
			ColorizeLayerSpec(entry.specBackground, specID)
		end
		
		eRollTracker.specqueue[inspecteeGUID] = nil
		ClearInspectPlayer()
		if #(eRollTracker.specqueue) > 0 then
			for k,v in pairs(eRollTracker.specqueue) do
				NotifyInspect(v.name)
				eRollTracker.isInspecting = true
				local function reinspect()
					if eRollTracker.isInspecting then
						NotifyInspect(player)
						C_Timer.After(2.000, reinspect)
					end
				end
				C_Timer.After(2.000, reinspect)
				break
			end
		else
			eRollTracker.isInspecting = false
		end
	end
end

-- Event: CHAT_MSG_SYSTEM
-- If found, insert a new roll entry into the list.
function eRollTracker.events:CHAT_MSG_SYSTEM(...)
	local text = ...
	local isRoll, player, roll, max = ParseRollText(text)
	if isRoll then
		local entry = eRollTracker.pools.entry:Acquire()
		ResetEntry(entry)

		local role = RoleIconString(player)
		local spec = GetSpec(player, entry)
		local name = ColorizeName(player)
		local maxnum = tonumber(max)
		local threshold = EasyRollTrackerDB.options.maxRollThreshold
		if maxnum == threshold then
			max = Colorize(max, const_colortable["gray"])
		elseif maxnum > threshold then
			max = Colorize(max, const_colortable["red"])
			roll = Colorize(roll, const_colortable["red"])
		elseif maxnum < threshold then
			max = Colorize(max, const_colortable["darkgray"])
		end

		InitEntry(entry, role, spec, name, roll, max)
		entry:Show()
		local index = GetInsertIndex(tonumber(UncolorizeText(roll)))
		ScrollInsert(entry, index)
	end
end

-- Event: ADDON_LOADED
-- Handle anything dependent on loading SavedVariables.
function eRollTracker.events:ADDON_LOADED(...)
	local addonName = ...
	if addonName == "EasyRollTracker" then
		if EasyRollTrackerDB == nil then
			EasyRollTrackerDB = {}
		end

		-- Default options
		if EasyRollTrackerDB.options == nil then
			EasyRollTrackerDB.options = {}
		end
		if EasyRollTrackerDB.options.maxRollThreshold == nil then
			EasyRollTrackerDB.options.maxRollThreshold = 100
		end
		if EasyRollTrackerDB.options.onlyAllowValidItems == nil then
			EasyRollTrackerDB.options.onlyAllowValidItems = true
		end
		if EasyRollTrackerDB.options.autoCloseRoll == nil then
			EasyRollTrackerDB.options.autoCloseRoll = false
		end
		if EasyRollTrackerDB.options.autoCloseDelay == nil then
			EasyRollTrackerDB.options.autoCloseDelay = 150
		end
		if EasyRollTrackerDB.options.exportOnClear == nil then
			EasyRollTrackerDB.options.exportOnClear = false
		end

		-- LibWindow: resolution-independent positioning
		-- Registration needs to happen after addon loads,
		-- otherwise XML frames aren't defined yet.
		if EasyRollTrackerDB.libwindow == nil then
			EasyRollTrackerDB.libwindow = {}
		end
		LibWindow.RegisterConfig(eRollTrackerFrame, EasyRollTrackerDB.libwindow)
		LibWindow.RestorePosition(eRollTrackerFrame)

		-- LDBIcon: minimap button
		local name_LDB_icon = "Easy Roll Tracker Icon"

		local function MinimapTooltip(tooltip)
			tooltip:ClearLines()
			local version = Colorize(const_version, const_colortable["gray"])
			tooltip:AddDoubleLine(const_text_addonname, version)
			local l_click = Colorize(" toggle showing the addon window.", const_colortable["white"])
			local r_click = Colorize(" open the configuration window.", const_colortable["white"])
			tooltip:AddLine("Left-Click:" .. l_click)
			tooltip:AddLine("Right-Click:" .. r_click)
		end

		-- First create a Data Broker to bind the minimap button to.
		local LDB_icon = LibDB:NewDataObject(name_LDB_icon, {
			type = "launcher",
			icon = const_path_icon_LDB,
			tocname = "EasyRollTracker",
			label = "Easy Roll Tracker",
			OnTooltipShow = MinimapTooltip,
			OnClick = function(frame, button)
				if button == "LeftButton" then
					ToggleVisible()
				elseif button == "RightButton" then
					eRollTracker_ShowOptions()
				end
			end
		})

		if EasyRollTrackerDB.ldbicon == nil then
			-- default value: *do* show minimap
			EasyRollTrackerDB.ldbicon = { hide = false }
		end
		LibDBIcon:Register(name_LDB_icon, LDB_icon, EasyRollTrackerDB.ldbicon)
	end
end

--------------------
-- Slash Commands --
--------------------
SLASH_EASYROLLTRACKER1, SLASH_EASYROLLTRACKER2, SLASH_EASYROLLTRACKER3 =
	"/erolltracker", "/rolltrack", "/rt"
function SlashCmdList.EASYROLLTRACKER(msg, editBox)
	local cmd = string.lower(msg)
	if cmd == "help" or cmd == "h" or cmd == "?" then
		PrintHelpText()
	elseif cmd == "config" or cmd == "opt" or cmd == "options" then
		eRollTracker_ShowOptions()
	elseif cmd == "close" then
		eRollTrackerFrame_ButtonsRoll_CloseRoll:Click()
	elseif cmd == "clear" then
		eRollTrackerFrame_ButtonClear:Click()
	elseif cmd == "reset" then
		ResetAddonData()
	else
		ToggleVisible()
	end
end

-------------------
-- Popup Dialogs --
-------------------
local const_text_confirmReset =
	"This will reset all " ..
	Colorize("Easy", const_colortable["Erythro"]) ..
	" Roll Tracker data.".. "|n" ..
	"Are you sure?"
StaticPopupDialogs["EASYROLLTRACKER_RESET"] = {
	showAlert = true,
	text = const_text_confirmReset,
	button1 = "Yes",
	button2 = "Cancel",
	OnAccept = function()
		ResetAddonData(true)
	end,
	whileDead = true,
	hideOnEscape = true,
	timeout = 300,
}

local const_text_chatPrefixFull =
	"All chat prefix slots have been registered." .. "|n" ..
	Colorize("Easy", const_colortable["Erythro"]) ..
	" Roll Tracker can no longer sync your display" .. "|n" ..
	"with the rest of the raid."
StaticPopupDialogs["EASYROLLTRACKER_CHATPREFIXFULL"] = {
	showAlert = true,
	text = const_text_chatPrefixFull,
	button1 = "Okay",
	whileDead = true,
	hideOnEscape = true,
	timeout = 300,
}