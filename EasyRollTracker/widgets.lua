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
