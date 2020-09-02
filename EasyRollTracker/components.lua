if eRollTracker == nil then eRollTracker = {} end
if eRollTracker.ext == nil then eRollTracker.ext = {} end

-- This needs to be handled separately because FramePoolMixin provides
-- very little control over refresh/init/destroy of its children.

-- Most anchors are set here, and not in the template itself.
-- The template doesn't know about the rest of the UI before
-- being created.

----------------------
-- Imported Aliases --
----------------------
-- Header `#include`s aren't supported.
-- This is the most concise workaround.

-- textcolor.lua
local ColorizeLayer	= eRollTracker.ext.ColorizeLayer

---------------------
-- Reset Functions --
---------------------
-- Functions to reset Frame templates to a cleared state.

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
eRollTracker.ext.ResetEntry = ResetEntry

--------------------
-- Init Functions --
--------------------
-- Functions to init a newly created/acquired Frame template.

local function InitHeading(frame, item)
	frame:SetParent(eRollTrackerFrame_Scroll_Layout)
	frame.item = item
	if item then
		local _,_, itemRarity, _,_,_,_,_,_, itemIcon =
			GetItemInfo(item)
		if itemRarity ~= nil then
			ColorizeLayer(frame.border, itemRarity)
		else
			frame.border:SetVertexColor(0.85, 0.85, 0.85)
		end
		frame.icon:SetTexture(itemIcon)
		-- If itemIcon is nil, SetTexture will hide that layer
	end
end
eRollTracker.ext.InitHeading = InitHeading

local function InitEntry(frame, role, spec, name, roll, max)
	frame:SetParent(eRollTrackerFrame_Scroll_Layout)
	frame:SetPoint("LEFT", eRollTrackerFrame_Scroll, "LEFT", 4, 0)
	frame:SetPoint("RIGHT", eRollTrackerFrame_Scroll, "RIGHT", -20, 0)
	frame.role:SetPoint("LEFT", frame, "LEFT", 4, 0)
	frame.max:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
	frame.spec:SetPoint("LEFT", frame.role, "RIGHT")
	frame.roll:SetPoint("RIGHT", frame.max, "LEFT")
	frame.name:SetPoint("LEFT", frame.spec, "RIGHT")
	frame.name:SetPoint("RIGHT", frame.roll, "LEFT")
	
	frame.role:SetText(role)
	frame.spec:SetText(spec)
	frame.name:SetText(name)
	frame.roll:SetText(roll)
	frame.max:SetText(max)
end
eRollTracker.ext.InitEntry = InitEntry

local function InitSeparator(frame)
	frame:SetParent(eRollTrackerFrame_Scroll_Layout)
	frame:SetPoint("LEFT", eRollTrackerFrame_Scroll, "LEFT", 4, 0)
	frame:SetPoint("RIGHT", eRollTrackerFrame_Scroll, "RIGHT", -20, 0)
end
eRollTracker.ext.InitSeparator = InitSeparator