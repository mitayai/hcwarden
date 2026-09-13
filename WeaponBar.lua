-- Weapon imbue (Windfury/Flametongue/Rockbiter/Frostbrand) tracker, like TotemTimers' weapon bar.
-- Uses GetWeaponEnchantInfo(), the same API TotemTimers itself uses for this.

local ROW_HEIGHT = 22
local SLOTS = { { hand = "main", invSlot = 16, label = "Main Hand" }, { hand = "off", invSlot = 17, label = "Off Hand" } }

local lastRemaining = {}
local lastEnchantID = {}
local maxDuration = {}

local function createRow(parent, index, label)
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
	bar:SetStatusBarColor(0.9, 0.7, 0.1)
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
	text:SetText(label)
	row.text = text

	local timeText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	timeText:SetPoint("RIGHT", -4, 0)
	row.timeText = timeText

	row:Hide()
	return row
end

local function build()
	local db = HCWardenDB.weaponBar
	local f = CreateFrame("Frame", "HCWardenWeaponBar", UIParent, "BackdropTemplate")
	f:SetSize(180, ROW_HEIGHT * #SLOTS + 6)
	f:SetPoint(db.point, db.x, db.y)
	f:SetMovable(true)
	f:EnableMouse(not db.locked)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		if not HCWardenDB.weaponBar.locked then self:StartMoving() end
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, _, x, y = self:GetPoint()
		HCWardenDB.weaponBar.point = point
		HCWardenDB.weaponBar.x = x
		HCWardenDB.weaponBar.y = y
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
	for i, slotInfo in ipairs(SLOTS) do
		f.rows[i] = createRow(f, i, slotInfo.label)
	end

	local elapsed = 0
	f:SetScript("OnUpdate", function(self, delta)
		elapsed = elapsed + delta
		if elapsed < 0.1 then return end
		elapsed = 0

		local hasMain, mainExpMs, mainCharges, mainID, hasOff, offExpMs, offCharges, offID = GetWeaponEnchantInfo()
		local data = {
			{ has = hasMain, expMs = mainExpMs, charges = mainCharges, id = mainID },
			{ has = hasOff, expMs = offExpMs, charges = offCharges, id = offID },
		}

		local anyActive = false
		for i, slotInfo in ipairs(SLOTS) do
			local row = self.rows[i]
			local d = data[i]
			local remaining = (d.has and d.expMs) and d.expMs / 1000 or 0

			if d.has and remaining > 0 then
				anyActive = true
				-- A fresh application shows up as the remaining time going up (or the enchant changing).
				if lastEnchantID[i] ~= d.id or remaining > (lastRemaining[i] or 0) then
					maxDuration[i] = remaining
				end
				lastEnchantID[i] = d.id
				lastRemaining[i] = remaining

				row.icon:SetTexture(GetInventoryItemTexture("player", slotInfo.invSlot))
				row.bar:SetMinMaxValues(0, maxDuration[i] or remaining)
				row.bar:SetValue(remaining)
				local chargeText = (d.charges and d.charges > 0) and (" x" .. d.charges) or ""
				row.timeText:SetText(("%.0fs%s"):format(remaining, chargeText))
				row:Show()
			else
				lastEnchantID[i] = nil
				lastRemaining[i] = 0
				maxDuration[i] = nil
				row:Hide()
			end
		end
		self:SetShown(anyActive)
	end)

	-- Note: don't Hide() here -- OnUpdate never fires on a hidden frame.
	HCWarden.WeaponBar = f
	return f
end

HCWarden:On("PLAYER_LOGIN", function()
	if not HCWardenDB.weaponBar.enabled then return end
	build()
end)
