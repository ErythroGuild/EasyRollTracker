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

-- Official class colors, but in the range [0.0, 1.0].
-- Table entries are formatted as {r, g, b, a}.
local const_classcolordec = {
	[0]			= {0.00, 0.00, 0.00, 0.00},
	DEATHKNIGHT	= {0.77, 0.12, 0.23, 1.00},
	DEMONHUNTER	= {0.64, 0.19, 0.79, 1.00},
	DRUID		= {1.00, 0.49, 0.04, 1.00},
	HUNTER		= {0.67, 0.83, 0.45, 1.00},
	MAGE		= {0.25, 0.78, 0.92, 1.00},
	MONK		= {0.00, 1.00, 0.59, 1.00},
	PALADIN		= {0.96, 0.55, 0.73, 1.00},
	PRIEST		= {1.00, 1.00, 1.00, 1.00},
	ROGUE		= {1.00, 0.96, 0.41, 1.00},
	SHAMAN		= {0.00, 0.44, 0.87, 1.00},
	WARLOCK		= {0.53, 0.53, 0.93, 1.00},
	WARRIOR		= {0.78, 0.61, 0.43, 1.00},
}

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
-- Colorize a spec by class color.
local function ColorizeSpec(spec, specID)
	local class = const_specclass[specID]
	local color = const_classcolor[class]
	return Colorize(spec, color)
end
eRollTracker.ext.ColorizeSpec = ColorizeSpec

-- Black: Death Knight, Demon Hunter, Shaman
-- White: everything else
local const_specbw = {
	[1455] = "FFFFFF", [ 250] = "FFFFFF", [ 251] = "FFFFFF", [ 252] = "FFFFFF",
	[1456] = "FFFFFF", [ 577] = "FFFFFF", [ 581] = "FFFFFF",
	[1447] = "000000", [ 102] = "000000", [ 103] = "000000", [ 104] = "000000", [ 105] = "000000",
	[1448] = "000000", [ 253] = "000000", [ 254] = "000000", [ 255] = "000000",
	[1449] = "000000", [  62] = "000000", [  63] = "000000", [  64] = "000000",
	[1450] = "000000", [ 268] = "000000", [ 270] = "000000", [ 269] = "000000",
	[1451] = "000000", [  65] = "000000", [  66] = "000000", [  70] = "000000",
	[1452] = "000000", [ 256] = "000000", [ 257] = "000000", [ 258] = "000000",
	[1453] = "000000", [ 259] = "000000", [ 260] = "000000", [ 261] = "000000",
	[1444] = "FFFFFF", [ 262] = "FFFFFF", [ 263] = "FFFFFF", [ 264] = "FFFFFF",
	[1454] = "000000", [ 265] = "000000", [ 266] = "000000", [ 267] = "000000",
	[1446] = "000000", [  71] = "000000", [  72] = "000000", [  73] = "000000",
}
-- A contrasting text color with the class color itself.
local function ColorizeSpecBW(spec, specID)
	local color = const_specbw[specID]
	return Colorize(spec, color)
end
eRollTracker.ext.ColorizeSpecBW = ColorizeSpecBW

-- Colorize a <LayeredRegion> by class color.
local function ColorizeLayerSpec(frame, specID)
	local class = const_specclass[specID]
	frame:SetVertexColor(unpack(const_classcolordec[class]))
end
eRollTracker.ext.ColorizeLayerSpec = ColorizeLayerSpec

-- Colorize a <LayeredRegion> by rarity level.
local function ColorizeLayerRarity(frame, rarity)
	local r, g, b, _ = GetItemQualityColor(rarity)
	frame:SetVertexColor(r, g, b)
end
eRollTracker.ext.ColorizeLayerRarity = ColorizeLayerRarity
