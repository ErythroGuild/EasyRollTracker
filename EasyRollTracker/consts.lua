if eRollTracker == nil then eRollTracker = {} end
if eRollTracker.ext == nil then eRollTracker.ext = {} end

----------------------
-- Imported Aliases --
----------------------
-- Header `#include`s aren't supported.
-- This is the most concise workaround.

-- color.lua
local const_colortable = eRollTracker.ext.const_colortable
local Colorize = eRollTracker.ext.Colorize

---------------
-- Constants --
---------------
local const_text_addonname =
	Colorize("Easy", const_colortable["Erythro"]) .. " Roll Tracker"
local const_version = "v" .. GetAddOnMetadata("EasyRollTracker", "Version")
local const_time_doubleclick = 0.500	-- Windows' default value
local const_frame_size_ignore = 2.0		-- threshold for counting frame sizes as equal
local const_namechars =
	"ÁÀÂÃÄÅ" .. "áàâãäå" ..
	"ÉÈÊË"   .. "éèêë"   ..
	"ÍÌÎÏ"   .. "íìîï"   ..
	"ÓÒÔÕÖØ" .. "óòôõöø" ..
	"ÚÙÛÜ"   .. "úùûü"   ..
	"ÝŸ"     .. "ýÿ"     ..
	"ÆÇÐÑ"   .. "æçðñ"   .. "ß"
local const_path_icon_LDB =
	"Interface\\AddOns\\EasyRollTracker\\rc\\EasyRollTracker - minimap.tga"
local const_path_icon_unknown =
	"Interface\\AddOns\\EasyRollTracker\\rc\\icon-unknown.tga"

eRollTracker.ext.const_text_addonname = const_text_addonname
eRollTracker.ext.const_version = const_version
eRollTracker.ext.const_time_doubleclick = const_time_doubleclick
eRollTracker.ext.const_frame_size_ignore = const_frame_size_ignore
eRollTracker.ext.const_namechars = const_namechars
eRollTracker.ext.const_path_icon_LDB = const_path_icon_LDB
eRollTracker.ext.const_path_icon_unknown = const_path_icon_unknown
