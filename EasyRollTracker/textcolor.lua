if eRollTracker == nil then eRollTracker = {} end
if eRollTracker.ext == nil then eRollTracker.ext = {} end

-- Remove leading "|cFFxxxxxx" and trailing "|r" if it exists.
-- Otherwise returns original text.
-- Note: ONLY works on fully-surrounded text.
local function UncolorizeText(colortext)
	local regex_find_text = "|cFF%x%x%x%x%x%x(.*)|r"
	local _,_, capture = string.find(colortext, regex_find_text)
	if capture == nil then
		return colortext
	else
		return capture
	end
end
eRollTracker.ext.UncolorizeText = UncolorizeText

-- List of common colors; accessible by name.
local const_colortable = {
	Erythro		= "FFCEC9",
	red			= "F53F16",
	gray		= "7A7A7A",
	darkgray	= "414141",
	white		= "EFEFEF",
}
eRollTracker.ext.const_colortable = const_colortable

-- Surround text in "|cFFxxxxxx" and "|r".
-- Note: does NOT work if text contains color escapes already.
-- This function does NOT perform any validation.
local function Colorize(text, color)
	if text == nil then
		return ""
	end
	if color == nil then
		return text
	end
	return "|cFF" .. color .. text .. "|r"
end
eRollTracker.ext.Colorize = Colorize

-- List of official class colors.
-- Indexed by Blizz's internal constants for readability.
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
eRollTracker.ext.const_classcolor = const_classcolor

-- Colorize a name by class color.
local function ColorizeName(name)
	local classname, _ = UnitClassBase(name)
	local color = const_classcolor[classname]
	return Colorize(name, color)
end
eRollTracker.ext.ColorizeName = ColorizeName

-- List of Blizz's internal class constants, by specID.
local const_specclass = {
	[1455] = "DEATHKNIGHT", [ 250] = "DEATHKNIGHT", [ 251] = "DEATHKNIGHT", [ 252] = "DEATHKNIGHT",
	[1456] = "DEMONHUNTER", [ 577] = "DEMONHUNTER", [ 581] = "DEMONHUNTER",
	[1447] = "DRUID"      , [ 102] = "DRUID"      , [ 103] = "DRUID"      , [ 104] = "DRUID"      , [ 105] = "DRUID"      ,
	[1448] = "HUNTER"     , [ 253] = "HUNTER"     , [ 254] = "HUNTER"     , [ 255] = "HUNTER"     ,
	[1449] = "MAGE"       , [  62] = "MAGE"       , [  63] = "MAGE"       , [  64] = "MAGE"       ,
	[1450] = "MONK"       , [ 268] = "MONK"       , [ 270] = "MONK"       , [ 269] = "MONK"       ,
	[1451] = "PALADIN"    , [  65] = "PALADIN"    , [  66] = "PALADIN"    , [  70] = "PALADIN"    ,
	[1452] = "PRIEST"     , [ 256] = "PRIEST"     , [ 257] = "PRIEST"     , [ 258] = "PRIEST"     ,
	[1453] = "ROGUE"      , [ 259] = "ROGUE"      , [ 260] = "ROGUE"      , [ 261] = "ROGUE"      ,
	[1444] = "SHAMAN"     , [ 262] = "SHAMAN"     , [ 263] = "SHAMAN"     , [ 264] = "SHAMAN"     ,
	[1454] = "WARLOCK"    , [ 265] = "WARLOCK"    , [ 266] = "WARLOCK"    , [ 267] = "WARLOCK"    ,
	[1446] = "WARRIOR"    , [  71] = "WARRIOR"    , [  72] = "WARRIOR"    , [  73] = "WARRIOR"    ,
}
eRollTracker.ext.const_specclass = const_specclass

-- Colorize a spec by class color.
local function ColorizeSpec(spec, specID)
	local class = const_specclass[specID]
	local color = const_classcolor[class]
	return Colorize(spec, color)
end
eRollTracker.ext.ColorizeSpec = ColorizeSpec

-- List of official rarity colors.
-- Indexed by Blizz's internal constants for readability.
-- NOTE: these are converted from hex values, and contain
-- a small amount of precision loss.
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
eRollTracker.ext.const_raritycolor = const_raritycolor

-- Colorize a <LayeredRegion> by rarity level.
local function ColorizeLayer(frame, rarity)
	frame:SetVertexColor(unpack(const_raritycolor[rarity]))
end
eRollTracker.ext.ColorizeLayer = ColorizeLayer
