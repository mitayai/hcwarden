local HUD = {}
HCWarden.HUD_module = HUD

local MAX_DEBUFF_ICONS = 6

local POWER_COLOR = {
	[0] = { 0.1, 0.3, 1.0 }, -- mana
	[1] = { 1.0, 0.1, 0.1 }, -- rage
	[2] = { 1.0, 1.0, 0.3 }, -- focus (unused in classic era, harmless if it shows)
	[3] = { 1.0, 1.0, 0.3 }, -- energy
}

local function createBar(parent, r, g, b)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	bar:SetStatusBarColor(r, g, b)
	bar:SetMinMaxValues(0, 1)

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.5)

	local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("CENTER")
	bar.text = text

	return bar
end

local function build()
	local db = HCWardenDB.hud
	local f = CreateFrame("Frame", "HCWardenHUD", UIParent, "BackdropTemplate")
	f:SetSize(200, 96)
	f:SetPoint(db.point, db.x, db.y)
	f:SetMovable(true)
	f:EnableMouse(not db.locked)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		if not HCWardenDB.hud.locked then self:StartMoving() end
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, _, x, y = self:GetPoint()
		HCWardenDB.hud.point = point
		HCWardenDB.hud.x = x
		HCWardenDB.hud.y = y
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

	local healthBar = createBar(f, 0.1, 0.8, 0.1)
	healthBar:SetPoint("TOPLEFT", 6, -6)
	healthBar:SetPoint("RIGHT", -6, 0)
	healthBar:SetHeight(18)
	f.healthBar = healthBar

	local powerBar = createBar(f, 0.1, 0.3, 1.0)
	powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -4)
	powerBar:SetPoint("RIGHT", -6, 0)
	powerBar:SetHeight(12)
	f.powerBar = powerBar

	f.debuffIcons = {}
	for i = 1, MAX_DEBUFF_ICONS do
		local icon = CreateFrame("Frame", nil, f)
		icon:SetSize(20, 20)
		if i == 1 then
			icon:SetPoint("TOPLEFT", powerBar, "BOTTOMLEFT", 0, -6)
		else
			icon:SetPoint("LEFT", f.debuffIcons[i - 1], "RIGHT", 4, 0)
		end
		local tex = icon:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints()
		icon.tex = tex
		local count = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		count:SetPoint("BOTTOMRIGHT", 2, 0)
		icon.count = count
		icon:Hide()
		f.debuffIcons[i] = icon
	end

	f.castBar = HCWarden:CreateCastBar(f, "player", f.debuffIcons[1], -6)

	HCWarden.HUD = f
	return f
end

local function updateHealth()
	local f = HCWarden.HUD
	if not f then return end
	local hp, hpMax = UnitHealth("player"), UnitHealthMax("player")
	if hpMax <= 0 then return end
	f.healthBar:SetMinMaxValues(0, hpMax)
	f.healthBar:SetValue(hp)
	f.healthBar.text:SetText(("%d / %d (%d%%)"):format(hp, hpMax, math.floor((hp / hpMax) * 100)))
end

local function updatePower()
	local f = HCWarden.HUD
	if not f then return end
	local powerType = UnitPowerType("player")
	local power, powerMax = UnitPower("player"), UnitPowerMax("player")
	local color = POWER_COLOR[powerType] or { 0.5, 0.5, 0.5 }
	f.powerBar:SetStatusBarColor(unpack(color))
	if powerMax <= 0 then
		f.powerBar:SetMinMaxValues(0, 1)
		f.powerBar:SetValue(0)
		f.powerBar.text:SetText("")
		return
	end
	f.powerBar:SetMinMaxValues(0, powerMax)
	f.powerBar:SetValue(power)
	f.powerBar.text:SetText(("%d / %d"):format(power, powerMax))
end

local function updateDebuffs()
	local f = HCWarden.HUD
	if not f then return end
	for i = 1, MAX_DEBUFF_ICONS do
		local icon = f.debuffIcons[i]
		local name, texture, count = UnitDebuff("player", i)
		if name then
			icon.tex:SetTexture(texture)
			icon.count:SetText(count and count > 1 and count or "")
			icon:Show()
		else
			icon:Hide()
		end
	end
end

HCWarden:On("PLAYER_LOGIN", function()
	if not HCWardenDB.hud.enabled then return end
	build()
	updateHealth()
	updatePower()
	updateDebuffs()
end)

HCWarden:On("UNIT_HEALTH", function(unit) if unit == "player" then updateHealth() end end)
HCWarden:On("UNIT_MAXHEALTH", function(unit) if unit == "player" then updateHealth() end end)
HCWarden:On("UNIT_POWER_FREQUENT", function(unit) if unit == "player" then updatePower() end end)
HCWarden:On("UNIT_POWER_UPDATE", function(unit) if unit == "player" then updatePower() end end)
HCWarden:On("UNIT_MAXPOWER", function(unit) if unit == "player" then updatePower() end end)
HCWarden:On("UNIT_DISPLAYPOWER", function(unit) if unit == "player" then updatePower() end end)
HCWarden:On("UNIT_AURA", function(unit) if unit == "player" then updateDebuffs() end end)
