if eRollTracker == nil then eRollTracker = {} end
if eRollTracker.ext == nil then eRollTracker.ext = {} end

function eRollTrackerFrame_Options_OnShow(self)
	self:ClearAllPoints()
	self:SetPoint("CENTER", eRollTrackerFrame)
end

function eRollTrackerFrame_Options_SetDefaults(self, button, down)
	local window = self:GetParent()
	window.showMinimapButton:SetChecked(true)
	window.maxRollThreshold.editbox:SetNumber(100)
	window.onlyAllowValidItems:SetChecked(true)
	window.autoCloseRoll:SetChecked(false)
	window.autoCloseDelay:SetAlpha(0.4)
	window.autoCloseDelay.editbox:SetNumber(150)
	window.exportOnClear:SetChecked(false)
end
