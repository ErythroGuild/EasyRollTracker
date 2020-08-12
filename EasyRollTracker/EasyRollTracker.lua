EasyRollTracker = {}

local AceEvent = LibStub("AceEvent-3.0"):Embed(EasyRollTracker)
local AceGUI = LibStub("AceGUI-3.0")
-- local LibDBIcon = LibStub("LibDBIcon-1.0")
-- local LibWindow = LibStub("LibWindow-1.1")

-- Utility variables & functions.
local rolltable = {}

local function GetInsertWidget(value, scrollFrame)
	for _, widget in pairs(scrollFrame.children) do
		if rolltable[widget] ~= nil then
			if rolltable[widget] < value then
				return widget
			end
		end
	end
	return nil
end

local colortable = {
	Erythro		= "FFCEC9",
	red			= "F53F16",
	gray		= "7A7A7A",
	darkgray	= "414141",
}

local function Colorize(text, color)
	return "|cFF" .. color .. text .. "|r"
end

local classcolor = {
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
	local _, classname, _ = UnitClass(name)
	local color = classcolor[classname]
	return Colorize(name, color)
end

local roleicon = {
	TANK	= CreateAtlasMarkup("roleicon-tiny-tank"),
	HEALER	= CreateAtlasMarkup("roleicon-tiny-healer"),
	DAMAGER	= CreateAtlasMarkup("roleicon-tiny-dps"),
	NONE	= CreateAtlasMarkup("roleicon-tiny-none"),
}
local function RoleIconString(name)
	local role = UnitGroupRolesAssigned(name)
	return roleicon[role]
end

local function ParseRollText(text)
	if strfind(text, "[%a%-]+ rolls %d+ %(1%-%d+%)") == nil then
		return false
	else
		local _, _, name, roll, max =
			strfind(text, "([%a%-]+) rolls (%d+) %(1%-(%d+)%)")
		return true, name, roll, max
	end
end

-- Construct UI.
local ui = AceGUI:Create("Window")
ui:SetTitle(Colorize("Easy", colortable["Erythro"]) .. " Roll Tracker")
ui:SetWidth(320)
ui:SetHeight(380)
ui:SetLayout("Flow")
ui:Hide()

local group_item = AceGUI:Create("SimpleGroup")
group_item:SetFullWidth(true)
group_item:SetLayout("Flow")
ui:AddChild(group_item)

local editBox_item = AceGUI:Create("EditBox")
editBox_item:SetRelativeWidth(0.65)
editBox_item:SetLabel("Item: ")
group_item:AddChild(editBox_item)

local button_clearItem = AceGUI:Create("Button")
button_clearItem:SetRelativeWidth(0.35)
button_clearItem:SetText("Clear")
group_item:AddChild(button_clearItem)

local group_actions = AceGUI:Create("SimpleGroup")
group_actions:SetFullWidth(true)
group_actions:SetLayout("Flow")
ui:AddChild(group_actions)

local button_announceRoll = AceGUI:Create("Button")
button_announceRoll:SetRelativeWidth(0.4)
button_announceRoll:SetText("Announce")
group_actions:AddChild(button_announceRoll)

local button_closeRoll = AceGUI:Create("Button")
button_closeRoll:SetRelativeWidth(0.3)
button_closeRoll:SetText(Colorize("Close Roll", colortable["red"]))
group_actions:AddChild(button_closeRoll)

local button_clearAll = AceGUI:Create("Button")
button_clearAll:SetRelativeWidth(0.3)
button_clearAll:SetText(Colorize("Clear All", colortable["red"]))
group_actions:AddChild(button_clearAll)

local group_scroll = AceGUI:Create("SimpleGroup")
group_scroll:SetFullWidth(true)
group_scroll:SetFullHeight(true)
group_scroll:SetLayout("Fill")
ui:AddChild(group_scroll)

local scrollFrame_main = AceGUI:Create("ScrollFrame")
scrollFrame_main:SetLayout("List")
group_scroll:AddChild(scrollFrame_main)

-- Define event listeners.
function newEntry(player, roll, max)
	local entry = AceGUI:Create("SimpleGroup")
	entry:SetFullWidth(true)
	entry:SetLayout("Flow")
	local name = AceGUI:Create("Label")
	name:SetText(RoleIconString(player) .. " " .. ColorizeName(player))
	name:SetRelativeWidth(0.65)
	entry:AddChild(name)
	local value = AceGUI:Create("Label")
	value:SetText(roll)
	value:SetRelativeWidth(0.15)
	entry:AddChild(value)
	local maxvalue = AceGUI:Create("Label")
	local maxnum = tonumber(max)
	if maxnum == 100 then
		maxvalue:SetText(Colorize(max, colortable["gray"]))
	elseif maxnum > 100 then
		maxvalue:SetText(Colorize(max, colortable["red"]))
		value:SetText(Colorize(roll, colortable["red"]))
	elseif maxnum < 100 then
		maxvalue:SetText(Colorize(max, colortable["darkgray"]))
	else
		maxvalue:SetText(max)
	end
	maxvalue:SetRelativeWidth(0.15)
	entry:AddChild(maxvalue)
	rolltable[entry] = tonumber(roll)
	return entry
end

function EasyRollTracker:RollHandler(self, event, text)
	local isRoll, name, roll, max = ParseRollText(text)
	if isRoll then
		local entry = newEntry(name, roll, max)
		local widget = GetInsertWidget(tonumber(roll), scrollFrame_main)
		if widget ~= nil then
			scrollFrame_main:AddChild(entry, widget)
		else
			scrollFrame_main:AddChild(entry)
		end
	end
end
EasyRollTracker:RegisterEvent("CHAT_MSG_SYSTEM", "RollHandler", text)

-- Define callbacks.
function ClearEditBox()
	editBox_item:SetText()
end
button_clearItem:SetCallback("OnClick", ClearEditBox)

function AnnounceRoll()
	local itemtext = editBox_item:GetText()
	local message = "Roll for " .. itemtext
	SendChatMessage(message, "RAID_WARNING")
	local heading = AceGUI:Create("Label")
	heading:SetFullWidth(true)
	local itemID = C_Item.GetItemIconByID(itemtext)
	heading:SetText(itemtext)
	heading:SetImage(itemID, 0.15, 0.85, 0.15, 0.85)
	scrollFrame_main:AddChild(heading)
end
button_announceRoll:SetCallback("OnClick", AnnounceRoll)

function CloseRoll()
	local itemtext = editBox_item:GetText()
	local message = "Closed roll for " .. itemtext
	SendChatMessage(message, "RAID_WARNING")
	local separator = AceGUI:Create("Heading")
	separator:SetRelativeWidth(1.0)
	scrollFrame_main:AddChild(separator)
	rolltable = {}
	ClearEditBox()
end
button_closeRoll:SetCallback("OnClick", CloseRoll)

function ClearAll()
	scrollFrame_main:ReleaseChildren()
	rolltable = {}
	ClearEditBox()
end
button_clearAll:SetCallback("OnClick", ClearAll)

-- Set slash commands.
SLASH_EASYROLLTRACKER1, SLASH_EASYROLLTRACKER2 = "/rolltrack", "/rt"
function SlashCmdList.EASYROLLTRACKER(msg, editBox)
	ui:Show()
end

-- -- Save/Load position.
-- LibWindow.RegisterConfig(ui, EasyRollTrackerDB)
-- LibWindow.RestorePosition(ui)
