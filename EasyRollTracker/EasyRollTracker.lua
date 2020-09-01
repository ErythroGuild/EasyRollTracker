eRollTracker = {}

local LibDB		= LibStub("LibDataBroker-1.1")
local LibDBIcon	= LibStub("LibDBIcon-1.0")
local LibWindow = LibStub("LibWindow-1.1")
-- local AceEvent	= LibStub("AceEvent-3.0"):Embed(EasyRollTracker)
-- local AceGUI	= LibStub("AceGUI-3.0")

-- -- Utility variables & functions.
-- local rolltable = {}

-- local function GetInsertWidget(value, scrollFrame)
-- 	for _, widget in pairs(scrollFrame.children) do
-- 		if rolltable[widget] ~= nil then
-- 			if rolltable[widget] < value then
-- 				return widget
-- 			end
-- 		end
-- 	end
-- 	return nil
-- end

-- this variable should be a valid itemLink
eRollTracker.item = ""
eRollTracker.isOpen = false

local const_version = "v" .. GetAddOnMetadata("EasyRollTracker", "Version")

local const_colortable = {
	Erythro		= "FFCEC9",
	red			= "F53F16",
	gray		= "7A7A7A",
	darkgray	= "414141",
	white		= "EFEFEF",
}

local const_namechars =
	"ÁÀÂÃÄÅ" .. "áàâãäå" ..
	"ÉÈÊË"   .. "éèêë"   ..
	"ÍÌÎÏ"   .. "íìîï"   ..
	"ÓÒÔÕÖØ" .. "óòôõöø" ..
	"ÚÙÛÜ"   .. "úùûü"   ..
	"ÝŸ"     .. "ýÿ"     ..
	"ÆÇÐÑ"   .. "æçðñ"   .. "ß"

local function Colorize(text, color)
	if text == nil then
		return ""
	end
	if color == nil then
		return text
	end
	return "|cFF" .. color .. text .. "|r"
end

local const_classcolor = {
	DEATHKNIGHT	= "C41F3B",
	DEMONHUNTER	= "A330C9",
	DRUID		= "FF7D0A",
	HUNTER		= "A9D271",
	MAGE		= "40C7EB",
	MONK		= "00FF96",
	PALADIN		= "F58CBA",
	PRIEST		= "FFFFFF",
	ROGUE		= "FFF569",
	SHAMAN		= "0070DE",
	WARLOCK		= "8787ED",
	WARRIOR		= "C79C6E",
}
local function ColorizeName(name)
	local classname, _ = UnitClassBase(name)
	local color = const_classcolor[classname]
	return Colorize(name, color)
end

local const_raritycolor = {
	[LE_ITEM_QUALITY_POOR]		= {0.6157, 0.6157, 0.6157},
	[LE_ITEM_QUALITY_COMMON]	= {1.0000, 1.0000, 1.0000},
	[LE_ITEM_QUALITY_UNCOMMON]	= {0.1176, 1.0000, 0.0000},
	[LE_ITEM_QUALITY_RARE]		= {0.0000, 0.4392, 0.8667},
	[LE_ITEM_QUALITY_EPIC]		= {0.6392, 0.2078, 0.9333},
	[LE_ITEM_QUALITY_LEGENDARY]	= {1.0000, 0.5020, 0.0000},
	[LE_ITEM_QUALITY_ARTIFACT]	= {0.9020, 0.8000, 0.5020},
	[LE_ITEM_QUALITY_HEIRLOOM]	= {0.0000, 0.8000, 1.0000}
}
local function ColorizeLayer(frame, rarity)
	frame:SetVertexColor(unpack(const_raritycolor[rarity]))
end

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

local function ToggleVisible()
	if (eRollTrackerFrame:IsShown()) then
		eRollTrackerFrame:Hide()
	else
		eRollTrackerFrame:Show()
	end
end

local function UpdateItemIcon()
	local itemLink = eRollTracker.item
	if (itemLink) then
		local _,_, itemRarity, _,_,_,_,_,_, itemIcon =
			GetItemInfo(itemLink)
		if itemRarity ~= nil then
			ColorizeLayer(eRollTrackerFrame_Item["border"], itemRarity)
		else
			eRollTrackerFrame_Item["border"]:SetVertexColor(0.85, 0.85, 0.85)
		end
		eRollTrackerFrame_Item_Icon["icon"]:SetTexture(itemIcon)
		-- If itemIcon is nil, SetTexture will hide that layer
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

function eRollTracker_GetTitle()
	local str_name = Colorize("Easy", const_colortable["Erythro"]) .. " Roll Tracker"
	local str_version = Colorize(const_version, const_colortable["gray"])
	return str_name .. " " .. str_version
end

function eRollTracker_ShowOptions()
end

function eRollTracker_AcceptCursor()
	local type, itemID, itemLink = GetCursorInfo();
	if type=="item" and itemLink then
		eRollTracker.item = itemLink
		ClearCursor()
		UpdateItemIcon()
		UpdateItemText()
	end
end
function eRollTracker_AcceptText()
	eRollTrackerFrame_EditItem:ClearFocus()
	eRollTracker.item = eRollTrackerFrame_EditItem:GetText()
	UpdateItemIcon()
end
function eRollTracker_SendCursor()
	local type, itemID, itemLink = GetCursorInfo();
	if type=="item" and itemLink then
		eRollTracker.item = itemLink
		ClearCursor()
		UpdateItemIcon()
		UpdateItemText()
	elseif eRollTracker.item ~= "" then
		PickupItem(eRollTracker.item);
		eRollTracker.item = ""
		UpdateItemIcon()
		UpdateItemText()
	end
end

function eRollTracker_OpenRoll()
	eRollTracker.isOpen = true
	local message = "Roll for " .. eRollTracker.item
	SendChatMessage(message, "RAID_WARNING")
	
	-- 	local heading = AceGUI:Create("Label")
	-- 	heading:SetFullWidth(true)
	-- 	local itemID = C_Item.GetItemIconByID(itemtext)
	-- 	heading:SetText(itemtext)
	-- 	heading:SetImage(itemID, 0.15, 0.85, 0.15, 0.85)
	-- 	scrollFrame_main:AddChild(heading)
end

function eRollTracker_CloseRoll()
	eRollTracker.isOpen = false
	local message = "Closed roll for " .. eRollTracker.item
	SendChatMessage(message, "RAID_WARNING")

	-- 	local separator = AceGUI:Create("Heading")
	-- 	separator:SetRelativeWidth(1.0)
	-- 	scrollFrame_main:AddChild(separator)
	-- 	rolltable = {}

	ClearItem()
end

function eRollTracker_ClearAll()
	if eRollTracker.isOpen then
		eRollTracker_CloseRoll()
	else
		ClearItem()
	end

	-- 	scrollFrame_main:ReleaseChildren()
	-- 	rolltable = {}
end

-- local function ParseRollText(text)
-- 	local regex_find_roll =
-- 		"[%a%-" .. match_name_chars .. "]+" ..
-- 		" rolls %d+ %(1%-%d+%)"
-- 	local regex_find_data =
-- 		"([%a%-" .. match_name_chars .. "]+)" ..
-- 		" rolls (%d+) %(1%-(%d+)%)"
-- 	if strfind(text, regex_find_roll) == nil then
-- 		return false
-- 	else
-- 		local _, _, name, roll, max =
-- 			strfind(text, regex_find_data)
-- 		return true, name, roll, max
-- 	end
-- end

-- -- Construct UI.
-- local ui = AceGUI:Create("Window")
-- ui:SetTitle(Colorize("Easy", colortable["Erythro"]) .. " Roll Tracker")
-- ui:SetWidth(320)
-- ui:SetHeight(380)
-- ui:SetLayout("Flow")
-- ui:Hide()

-- local group_item = AceGUI:Create("SimpleGroup")
-- group_item:SetFullWidth(true)
-- group_item:SetLayout("Flow")
-- ui:AddChild(group_item)

-- local editBox_item = AceGUI:Create("EditBox")
-- editBox_item:SetRelativeWidth(0.65)
-- editBox_item:SetLabel("Item: ")
-- group_item:AddChild(editBox_item)

-- local button_clearItem = AceGUI:Create("Button")
-- button_clearItem:SetRelativeWidth(0.35)
-- button_clearItem:SetText("Clear")
-- group_item:AddChild(button_clearItem)

-- local group_actions = AceGUI:Create("SimpleGroup")
-- group_actions:SetFullWidth(true)
-- group_actions:SetLayout("Flow")
-- ui:AddChild(group_actions)

-- local button_announceRoll = AceGUI:Create("Button")
-- button_announceRoll:SetRelativeWidth(0.4)
-- button_announceRoll:SetText("Announce")
-- group_actions:AddChild(button_announceRoll)

-- local button_closeRoll = AceGUI:Create("Button")
-- button_closeRoll:SetRelativeWidth(0.3)
-- button_closeRoll:SetText(Colorize("Close Roll", colortable["red"]))
-- group_actions:AddChild(button_closeRoll)

-- local button_clearAll = AceGUI:Create("Button")
-- button_clearAll:SetRelativeWidth(0.3)
-- button_clearAll:SetText(Colorize("Clear All", colortable["red"]))
-- group_actions:AddChild(button_clearAll)

-- local group_scroll = AceGUI:Create("SimpleGroup")
-- group_scroll:SetFullWidth(true)
-- group_scroll:SetFullHeight(true)
-- group_scroll:SetLayout("Fill")
-- ui:AddChild(group_scroll)

-- local scrollFrame_main = AceGUI:Create("ScrollFrame")
-- scrollFrame_main:SetLayout("List")
-- group_scroll:AddChild(scrollFrame_main)

-- -- Define event listeners.
-- function newEntry(player, roll, max)
-- 	local entry = AceGUI:Create("SimpleGroup")
-- 	entry:SetFullWidth(true)
-- 	entry:SetLayout("Flow")
-- 	local name = AceGUI:Create("Label")
-- 	name:SetText(RoleIconString(player) .. " " .. ColorizeName(player))
-- 	name:SetRelativeWidth(0.65)
-- 	entry:AddChild(name)
-- 	local value = AceGUI:Create("Label")
-- 	value:SetText(roll)
-- 	value:SetRelativeWidth(0.15)
-- 	entry:AddChild(value)
-- 	local maxvalue = AceGUI:Create("Label")
-- 	local maxnum = tonumber(max)
-- 	if maxnum == 100 then
-- 		maxvalue:SetText(Colorize(max, colortable["gray"]))
-- 	elseif maxnum > 100 then
-- 		maxvalue:SetText(Colorize(max, colortable["red"]))
-- 		value:SetText(Colorize(roll, colortable["red"]))
-- 	elseif maxnum < 100 then
-- 		maxvalue:SetText(Colorize(max, colortable["darkgray"]))
-- 	else
-- 		maxvalue:SetText(max)
-- 	end
-- 	maxvalue:SetRelativeWidth(0.15)
-- 	entry:AddChild(maxvalue)
-- 	rolltable[entry] = tonumber(roll)
-- 	return entry
-- end

-- function EasyRollTracker:RollHandler(self, event, text)
-- 	local isRoll, name, roll, max = ParseRollText(text)
-- 	if isRoll then
-- 		local entry = newEntry(name, roll, max)
-- 		local widget = GetInsertWidget(tonumber(roll), scrollFrame_main)
-- 		if widget ~= nil then
-- 			scrollFrame_main:AddChild(entry, widget)
-- 		else
-- 			scrollFrame_main:AddChild(entry)
-- 		end
-- 	end
-- end
-- EasyRollTracker:RegisterEvent("CHAT_MSG_SYSTEM", "RollHandler", text)

-- -- Define callbacks.
-- function ClearEditBox()
-- 	editBox_item:SetText()
-- end
-- button_clearItem:SetCallback("OnClick", ClearEditBox)

-- Set slash commands.
SLASH_EASYROLLTRACKER1, SLASH_EASYROLLTRACKER2, SLASH_EASYROLLTRACKER3 =
	"/rolltracker", "/rolltrack", "/rt"
function SlashCmdList.EASYROLLTRACKER(msg, editBox)
	ToggleVisible()
end

-- Minimap icon.
local const_name_LDB_icon = "Easy Roll Tracker Icon"
local const_path_LDB_icon = "Interface\\AddOns\\EasyRollTracker\\rc\\EasyRollTracker - minimap.tga"

local LDB_icon = LibDB:NewDataObject(const_name_LDB_icon, {
	type = "launcher",
	icon = const_path_LDB_icon,
	tocname = "EasyRollTracker",
	label = "Easy Roll Tracker",
	OnClick = function(clickedFrame, button)
		if button == "LeftButton" then
			ToggleVisible()
		elseif button == "RightButton" then
			eRollTracker_ShowOptions()
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:ClearLines()
		local str_name = Colorize("Easy", const_colortable["Erythro"]) .. " Roll Tracker"
		local str_version = Colorize(const_version, const_colortable["gray"])
		tooltip:AddDoubleLine(str_name, str_version)
		local str_left = Colorize(" toggle showing the addon window.", const_colortable["white"])
		local str_right = Colorize(" open the configuration window.", const_colortable["white"])
		tooltip:AddLine("Left-Click:" .. str_left)
		tooltip:AddLine("Right-Click:" .. str_right)
	end
})
local EasyRollTrackerDB = { minimap_icon = { hide = false } }
LibDBIcon:Register(const_name_LDB_icon, LDB_icon, EasyRollTrackerDB.minimap_icon)

-- Save/Load position.
-- TODO: RestorePosition() requires waiting for ADDON_LOADED event
-- LibWindow.RegisterConfig(eRollTrackerFrame, EasyRollTrackerDB.window)
-- LibWindow.MakeDraggable(eRollTrackerFrame)
-- LibWindow.RestorePosition(eRollTrackerFrame)
