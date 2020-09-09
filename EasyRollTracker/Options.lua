if eRollTracker == nil then eRollTracker = {} end
if eRollTracker.ext == nil then eRollTracker.ext = {} end

local LibDBIcon	= LibStub("LibDBIcon-1.0")

function eRollTrackerFrame_Options_OnShow(self)
	self:ClearAllPoints()
	self:SetPoint("CENTER", eRollTrackerFrame)

	local DB = EasyRollTrackerDB
	self.showMinimapButton:SetChecked(not DB.ldbicon.hide)
	self.maxRollThreshold.editbox:SetNumber(DB.options.maxRollThreshold)
	self.onlyAllowValidItems:SetChecked(DB.options.onlyAllowValidItems)
	self.autoCloseRoll:SetChecked(DB.options.autoCloseRoll)
	if DB.options.autoCloseRoll then
		self.autoCloseDelay:SetAlpha(1.0)
	else
		self.autoCloseDelay:SetAlpha(0.4)
	end
	self.autoCloseDelay.editbox:SetNumber(DB.options.autoCloseDelay)
	self.exportOnClear:SetChecked(DB.options.exportOnClear)
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

function eRollTrackerFrame_Options_OnAccept(self, button, down)
	local window = self:GetParent()

	EasyRollTrackerDB.ldbicon.hide = not window.showMinimapButton:GetChecked()
	EasyRollTrackerDB.options.maxRollThreshold = window.maxRollThreshold.editbox:GetNumber()
	EasyRollTrackerDB.options.onlyAllowValidItems = window.onlyAllowValidItems:GetChecked()
	EasyRollTrackerDB.options.autoCloseRoll = window.autoCloseRoll:GetChecked()
	EasyRollTrackerDB.options.autoCloseDelay = window.autoCloseDelay.editbox:GetNumber()
	EasyRollTrackerDB.options.exportOnClear = window.exportOnClear:GetChecked()

	if EasyRollTrackerDB.ldbicon.hide then
		LibDBIcon:Hide("Easy Roll Tracker Icon")
	else
		LibDBIcon:Show("Easy Roll Tracker Icon")
	end

	window:Hide()
end
