function eRollTrackerFrame_EditBox_OnLoad(self)
	hooksecurefunc("ChatEdit_InsertLink", function(link)
		if self and self:IsVisible() and self:HasFocus() then
			self:Insert(link);
			return true;
		end
	end);
end

function eRollTrackerFrame_EditBox_OnTextChanged(self)
	if self:GetText() == "" then
		self.buttonClear:Hide();
	else
		self.buttonClear:Show();
	end
end

function eRollTrackerFrame_EditBox_ButtonClear_OnClick(self, button, down)
	self:GetParent():SetFocus();
	self:GetParent():SetText("");
	self:GetParent():ClearFocus();
	-- simulates a click on the editbox to trigger events
	self:GetParent():SetFocus();
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
