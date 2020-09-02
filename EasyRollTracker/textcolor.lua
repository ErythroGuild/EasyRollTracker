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

-- List of common colors; accessible by name.
local const_colortable = {
	Erythro		= "FFCEC9",
	red			= "F53F16",
	gray		= "7A7A7A",
	darkgray	= "414141",
	white		= "EFEFEF",
}

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

-- Colorize a name by class color.
local function ColorizeName(name)
	local classname, _ = UnitClassBase(name)
	local color = const_classcolor[classname]
	return Colorize(name, color)
end

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

-- Colorize a <LayeredRegion> by rarity level.
local function ColorizeLayer(frame, rarity)
	frame:SetVertexColor(unpack(const_raritycolor[rarity]))
end
