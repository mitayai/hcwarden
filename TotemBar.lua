-- A compact totem timer bar (like TotemTimers): one row per totem slot, showing icon,
-- name, and a shrinking bar/countdown so you know when to refresh it.

local MAX_TOTEM_SLOTS = MAX_TOTEMS or 4
local ROW_HEIGHT = 22
local UPDATE_INTERVAL = 0.1

local function createRow(parent, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(ROW_HEIGHT - 2)
	row:SetPoint("TOPLEFT", 4, -4 - (index - 1) * ROW_HEIGHT)
	row:SetPoint("RIGHT", -4, 0)

	local icon = row:CreateTexture(nil, "ARTWORK")
	icon:SetSize(ROW_HEIGHT - 4, ROW_HEIGHT - 4)
	icon:SetPoint("LEFT", 0, 0)
	row.icon = icon

	local bar = CreateFrame("StatusBar", nil, row)
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	bar:SetStatusBarColor(0.3, 0.6, 1.0)
	bar:SetPoint("LEFT", icon, "RIGHT", 4, 0)
	bar:SetPoint("RIGHT", 0, 0)
	bar:SetHeight(ROW_HEIGHT - 4)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	row.bar = bar

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.5)

	local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("LEFT", 4, 0)
	text:SetJustifyH("LEFT")
	row.text = text

	local timeText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	timeText:SetPoint("RIGHT", -4, 0)
	row.timeText = timeText

	row:Hide()
	return row
end

local function build()
	local db = HCWardenDB.totemBar
	local f = CreateFrame("Frame", "HCWardenTotemBar", UIParent, "BackdropTemplate")
	f:SetSize(180, ROW_HEIGHT * MAX_TOTEM_SLOTS + 6)
	f:SetPoint(db.point, db.x, db.y)
	f:SetMovable(true)
	f:EnableMouse(not db.locked)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		if not HCWardenDB.totemBar.locked then self:StartMoving() end
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, _, x, y = self:GetPoint()
		HCWardenDB.totemBar.point = point
		HCWardenDB.totemBar.x = x
		HCWardenDB.totemBar.y = y
	end)

	if f.SetBackdrop then
		f:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 10,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		f:SetBackdropColor(0, 0, 0, 0.4)
	end

	f.rows = {}
	for i = 1, MAX_TOTEM_SLOTS do
		f.rows[i] = createRow(f, i)
	end

	local elapsed = 0
	f:SetScript("OnUpdate", function(self, delta)
		elapsed = elapsed + delta
		if elapsed < UPDATE_INTERVAL then return end
		elapsed = 0

		local anyActive = false
		for slot = 1, MAX_TOTEM_SLOTS do
			local row = self.rows[slot]
			local haveTotem, name, startTime, duration = GetTotemInfo(slot)
			if haveTotem and name and name ~= "" and duration and duration > 0 then
				anyActive = true
				local remaining = (startTime + duration) - GetTime()
				if remaining < 0 then remaining = 0 end
				row.bar:SetMinMaxValues(0, duration)
				row.bar:SetValue(remaining)
				row.timeText:SetText(("%.0fs"):format(remaining))
				row:Show()
			else
				row:Hide()
			end
		end
		self:SetShown(anyActive)
	end)

	-- Note: don't Hide() here -- OnUpdate never fires on a hidden frame, and OnUpdate
	-- is what hides/shows this frame based on whether any totem is active.
	HCWarden.TotemBar = f
	return f
end

local function refreshSlot(slot)
	local f = HCWarden.TotemBar
	if not f or not f.rows[slot] then return end
	local row = f.rows[slot]
	local haveTotem, name, startTime, duration, icon = GetTotemInfo(slot)
	if haveTotem and name and name ~= "" then
		row.icon:SetTexture(icon)
		row.text:SetText(name)
	end
end

HCWarden:On("PLAYER_LOGIN", function()
	if not HCWardenDB.totemBar.enabled then return end
	build()
	for slot = 1, MAX_TOTEM_SLOTS do
		refreshSlot(slot)
	end
end)

HCWarden:On("PLAYER_TOTEM_UPDATE", function(slot)
	refreshSlot(slot)
end)
