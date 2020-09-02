local LibDB		= LibStub("LibDataBroker-1.1")
local LibDBIcon	= LibStub("LibDBIcon-1.0")
local LibWindow = LibStub("LibWindow-1.1")
-- local AceEvent	= LibStub("AceEvent-3.0"):Embed(EasyRollTracker)
-- local AceGUI	= LibStub("AceGUI-3.0")

-- -- Utility variables & functions.

eRollTracker = {}

-- this variable should be a valid itemLink
eRollTracker.item = ""
eRollTracker.isOpen = false
eRollTracker.entries = {}

eRollTracker.pools = { heading = nil, entry = nil, separator = nil }
-- Pools need to have a custom creationfunc (can't use FramePool directly)
-- in order to set anchors properly.
-- Anchors cannot be set in template itself, since the template doesn't
-- know about the rest of the UI yet.
eRollTracker.pools.heading = CreateFramePool("Frame", eRollTrackerFrame_Scroll_Layout,"eRollTracker_Template_Heading")
eRollTracker.pools.entry = CreateFramePool("Frame", eRollTrackerFrame_Scroll_Layout,"eRollTracker_Template_Entry")
eRollTracker.pools.separator = CreateFramePool("Frame", eRollTrackerFrame_Scroll_Layout,"eRollTracker_Template_Separator")

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

local function UncolorizeText(colortext)
	local regex_find_text = "|cFF%x%x%x%x%x%x(.*)|r"
	local _,_, capture = string.find(colortext, regex_find_text)
	if capture == nil then
		return colortext
	else
		return capture
	end
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

local function GetSpec(player)
	return ""
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

local function GetInsertIndex(roll)
	for i, widget in ipairs(eRollTracker.entries) do
		if widget.roll then
			local roll_compare =
				tonumber(UncolorizeText(widget.roll:GetText()))
			if roll_compare < roll then
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

local function ResetEntry(frame)
	if (frame.item) then
		frame.item = nil
	end
	if (frame.icon) then
		frame.icon:SetTexture(nil)
	end
	frame:ClearAllPoints()
	frame:Hide()
end
local function InitHeading(frame)
	frame:SetParent(eRollTrackerFrame_Scroll_Layout)
	frame.item = eRollTracker.item
	if (frame.item) then
		local _,_, itemRarity, _,_,_,_,_,_, itemIcon =
			GetItemInfo(frame.item)
		if itemRarity ~= nil then
			ColorizeLayer(frame.border, itemRarity)
		else
			frame.border:SetVertexColor(0.85, 0.85, 0.85)
		end
		frame.icon:SetTexture(itemIcon)
		-- If itemIcon is nil, SetTexture will hide that layer
	end
end
local function InitEntry(frame)
	frame:SetParent(eRollTrackerFrame_Scroll_Layout)
	frame:SetPoint("LEFT", eRollTrackerFrame_Scroll, "LEFT", 4, 0)
	frame:SetPoint("RIGHT", eRollTrackerFrame_Scroll, "RIGHT", -20, 0)
	frame.role:SetPoint("LEFT", frame, "LEFT", 4, 0)
	frame.max:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
	frame.spec:SetPoint("LEFT", frame.role, "RIGHT")
	frame.roll:SetPoint("RIGHT", frame.max, "LEFT")
	frame.name:SetPoint("LEFT", frame.spec, "RIGHT")
	frame.name:SetPoint("RIGHT", frame.roll, "LEFT")
end
local function InitSeparator(frame)
	frame:SetParent(eRollTrackerFrame_Scroll_Layout)
	frame:SetPoint("LEFT", eRollTrackerFrame_Scroll, "LEFT", 4, 0)
	frame:SetPoint("RIGHT", eRollTrackerFrame_Scroll, "RIGHT", -20, 0)
end

local function SetupEntry(entry, player, roll, max)
	entry.role:SetText(RoleIconString(player))
	entry.spec:SetText(GetSpec(player))
	entry.name:SetText(ColorizeName(player))
	entry.roll:SetText(roll)
	local maxnum = tonumber(max)
	if maxnum == 100 then
		entry.max:SetText(Colorize(max, const_colortable["gray"]))
	elseif maxnum > 100 then
		entry.max:SetText(Colorize(max, const_colortable["red"]))
		entry.roll:SetText(Colorize(roll, const_colortable["red"]))
	elseif maxnum < 100 then
		entry.max:SetText(Colorize(max, const_colortable["darkgray"]))
	else
		entry.max:SetText(max)
	end
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
		eRollTracker_ShowTooltip()
	end
end
function eRollTracker_AcceptText()
	eRollTrackerFrame_EditItem:ClearFocus()
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
	elseif eRollTracker.item ~= "" then
		PickupItem(eRollTracker.item);
		eRollTracker.item = ""
		UpdateItemIcon()
		UpdateItemText()
		eRollTracker_HideTooltip()
	end
end

function eRollTracker_ShowTooltip()
	if eRollTracker.item ~= "" then
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(_G["eRollTrackerFrame_Item"], "ANCHOR_NONE")
		GameTooltip:SetPoint("TOPLEFT", eRollTrackerFrame_Item, "BOTTOMLEFT", 0, -4)
		GameTooltip:SetHyperlink(eRollTracker.item)
		GameTooltip:Show()
	end
end
function eRollTracker_HideTooltip()
	GameTooltip:Hide()
	GameTooltip:ClearLines()
end

function eRollTracker_OpenRoll()
	eRollTracker.isOpen = true
	local message = "Roll for " .. eRollTracker.item
	SendChatMessage(message, "RAID_WARNING")

	local heading = eRollTracker.pools.heading:Acquire()
	ResetEntry(heading)
	InitHeading(heading)
	heading:Show()
	ScrollAppend(heading)
	eRollTracker.entries = { heading }
end

function eRollTracker_CloseRoll()
	eRollTracker.isOpen = false
	local message = "Closed roll for " .. eRollTracker.item
	SendChatMessage(message, "RAID_WARNING")

	local separator = eRollTracker.pools.separator:Acquire()
	ResetEntry(separator)
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

function eRollTrackerFrame_Scroll_OnScrollRangeChanged(self, xrange, yrange)
	local name = self:GetName();
	local scrollbar = self.ScrollBar or _G[name.."ScrollBar"];
	local thumbTexture = scrollbar.ThumbTexture or _G[scrollbar:GetName().."ThumbTexture"];

	local range_window = self:GetHeight()
	local range_max = self:GetScrollChild():GetHeight()
	local height_bar = scrollbar:GetHeight()
	local height_thumb = height_bar * (range_window / range_max)
	height_thumb = math.min(height_thumb, height_bar)
	height_thumb = math.max(height_thumb, 18)
	
	thumbTexture:SetHeight(height_thumb)

	ScrollFrame_OnScrollRangeChanged(self, xrange, yrange)
end

function eRollTrackerFrame_OnEvent(self, event, ...)
	if event == "CHAT_MSG_SYSTEM" then
		local text = ...
		local isRoll, name, roll, max = ParseRollText(text)
		if isRoll then
			local entry = eRollTracker.pools.entry:Acquire()
			ResetEntry(entry)
			InitEntry(entry)
			SetupEntry(entry, name, roll, max)
			entry:Show()
			local index = GetInsertIndex(tonumber(roll))
			ScrollInsert(entry, index)
		end
	end
end

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
