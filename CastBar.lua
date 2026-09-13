-- Shared cast bar widget, used by both the player HUD and the target HUD.

function HCWarden:CreateCastBar(parent, unit, anchorFrame, offsetY)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	bar:SetStatusBarColor(1, 0.7, 0)
	bar:SetHeight(16)
	bar:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, offsetY or -6)
	bar:SetPoint("RIGHT", parent, "RIGHT", -6, 0)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.5)

	local icon = bar:CreateTexture(nil, "ARTWORK")
	icon:SetSize(14, 14)
	icon:SetPoint("LEFT", bar, "LEFT", 2, 0)
	bar.icon = icon

	local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
	text:SetPoint("RIGHT", -4, 0)
	text:SetJustifyH("LEFT")
	bar.text = text

	-- Note: don't Hide() here -- OnUpdate never fires on a hidden frame, and OnUpdate
	-- is what hides/shows this bar based on whether the unit is casting.

	local elapsed = 0
	bar:SetScript("OnUpdate", function(self, delta)
		elapsed = elapsed + delta
		if elapsed < 0.05 then return end
		elapsed = 0

		local name, _, texture, startTime, endTime, _, notInterruptible = UnitCastingInfo(unit)
		local channeling = false
		if not name then
			name, _, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
			channeling = true
		end

		if not name then
			self:Hide()
			return
		end

		local duration = (endTime - startTime) / 1000
		if duration <= 0 then duration = 1 end
		self:SetMinMaxValues(0, duration)
		if channeling then
			self:SetValue((endTime / 1000) - GetTime())
		else
			self:SetValue(GetTime() - (startTime / 1000))
		end

		self.icon:SetTexture(texture)
		self.text:SetText(name)
		if notInterruptible then
			self:SetStatusBarColor(0.6, 0.2, 0.2)
		else
			self:SetStatusBarColor(1, 0.7, 0)
		end
		self:Show()
	end)

	return bar
end
