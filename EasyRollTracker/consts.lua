if eRollTracker == nil then eRollTracker = {} end
if eRollTracker.ext == nil then eRollTracker.ext = {} end

local const_version = "v" .. GetAddOnMetadata("EasyRollTracker", "Version")
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

eRollTracker.ext.const_version = const_version
eRollTracker.ext.const_namechars = const_namechars
eRollTracker.ext.const_path_icon_LDB = const_path_icon_LDB
eRollTracker.ext.const_path_icon_unknown = const_path_icon_unknown
