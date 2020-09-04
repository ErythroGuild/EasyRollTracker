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
eRollTracker.item = ""		-- this should be a valid itemLink
eRollTracker.isOpen = false	-- if an item is currently being rolled for
eRollTracker.entries = {}	-- list of current roll (sorted) entries
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
local const_text_addonname	= eRollTracker.ext.const_text_addonname
local const_version			= eRollTracker.ext.const_version
local const_namechars		= eRollTracker.ext.const_namechars
local const_path_icon_LDB = eRollTracker.ext.const_path_icon_LDB
local const_path_icon_unknown = eRollTracker.ext.const_path_icon_unknown

-- textcolor.lua
local const_colortable	= eRollTracker.ext.const_colortable
local const_classcolor	= eRollTracker.ext.const_classcolor
local const_raritycolor	= eRollTracker.ext.const_raritycolor

local UncolorizeText = eRollTracker.ext.UncolorizeText

local Colorize		= eRollTracker.ext.Colorize
local ColorizeName	= eRollTracker.ext.ColorizeName
local ColorizeLayer	= eRollTracker.ext.ColorizeLayer

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

local function GetSpec(player)
	return ""
end

local function ResetAddonData(isAcceptCallback)
	if isAcceptCallback == nil then
		StaticPopup_Show("EASYROLLTRACKER_RESET")
		return
	elseif isAcceptCallback == true then
		eRollTracker_ClearAll()
	
		EasyRollTrackerDB = {
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
	print(ColorCommand("  /rt help:")	.. " opens the help window")
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
			ColorizeLayer(eRollTrackerFrame_Item.border, itemRarity)
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
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("ADDON_LOADED")
end

-- Use LibWindow to save the position in a resolution-independent way.
function eRollTracker_StopPositioning()
	eRollTrackerFrame:StopMovingOrSizing()
	LibWindow.SavePosition(eRollTrackerFrame)
end

-- Open the Interface settings menu to the panel for this AddOn.
function eRollTracker_ShowOptions()
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
	eRollTracker.item = eRollTrackerFrame_EditItem:GetText()
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
	SendChatMessage(message, "RAID_WARNING")

	local heading = eRollTracker.pools.heading:Acquire()
	ResetHeading(heading)
	InitHeading(heading, eRollTracker.item)
	heading:Show()
	ScrollAppend(heading)
	eRollTracker.entries = { heading }
end

function eRollTracker_CloseRoll()
	eRollTracker.isOpen = false
	
	local itemstring = eRollTracker.item
	local _, itemLink = GetItemInfo(eRollTracker.item)
	if itemLink ~= nil then
		itemstring = itemLink
	end
	local message = "Closed roll for " .. itemstring
	SendChatMessage(message, "RAID_WARNING")

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

-- Event: CHAT_MSG_SYSTEM
-- If found, insert a new roll entry into the list.
function eRollTracker.events:CHAT_MSG_SYSTEM(...)
	local text = ...
	local isRoll, player, roll, max = ParseRollText(text)
	if isRoll then
		local entry = eRollTracker.pools.entry:Acquire()
		ResetEntry(entry)

		local role = RoleIconString(player)
		local spec = GetSpec(player)
		local name = ColorizeName(player)
		local maxnum = tonumber(max)
		if maxnum == 100 then
			max = Colorize(max, const_colortable["gray"])
		elseif maxnum > 100 then
			max = Colorize(max, const_colortable["red"])
			roll = Colorize(roll, const_colortable["red"])
		elseif maxnum < 100 then
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
		PrintHelpText()
	if cmd == "help" or cmd == "h" or cmd == "?" then
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
	" Roll Tracker data.".. "\n" ..
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
