local MAX_DEBUFF_ICONS = 6

local CLASS_LABEL = {
	worldboss = "|cffff0000Boss|r",
	rareelite = "|cffff8800Rare Elite|r",
	elite = "|cffffff00Elite|r",
	rare = "|cff00ccffRare|r",
	normal = "",
	trivial = "",
	minus = "",
}

local POWER_COLOR = {
	[0] = { 0.1, 0.3, 1.0 }, -- mana
	[1] = { 1.0, 0.1, 0.1 }, -- rage
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
	local db = HCWardenDB.targetHud
	local f = CreateFrame("Frame", "HCWardenTargetHUD", UIParent, "BackdropTemplate")
	f:SetSize(200, 104)
	f:SetPoint(db.point, db.x, db.y)
	f:SetMovable(true)
	f:EnableMouse(not db.locked)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		if not HCWardenDB.targetHud.locked then self:StartMoving() end
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, _, x, y = self:GetPoint()
		HCWardenDB.targetHud.point = point
		HCWardenDB.targetHud.x = x
		HCWardenDB.targetHud.y = y
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

	local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	nameText:SetPoint("TOPLEFT", 6, -6)
	nameText:SetPoint("RIGHT", -6, 0)
	nameText:SetJustifyH("LEFT")
	f.nameText = nameText

	local healthBar = createBar(f, 0.8, 0.1, 0.1)
	healthBar:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
	healthBar:SetPoint("RIGHT", -6, 0)
	healthBar:SetHeight(18)
	f.healthBar = healthBar

	local powerBar = createBar(f, 0.1, 0.3, 1.0)
	powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -4)
	powerBar:SetPoint("RIGHT", -6, 0)
	powerBar:SetHeight(10)
	f.powerBar = powerBar

	f.debuffIcons = {}
	for i = 1, MAX_DEBUFF_ICONS do
		local icon = CreateFrame("Frame", nil, f)
		icon:SetSize(18, 18)
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

	f.castBar = HCWarden:CreateCastBar(f, "target", f.debuffIcons[1], -6)

	f:Hide()
	HCWarden.TargetHUD = f
	return f
end

local function updateAll()
	local f = HCWarden.TargetHUD
	if not f then return end

	if not UnitExists("target") then
		f:Hide()
		return
	end
	f:Show()

	local name = UnitName("target") or "Unknown"
	local level = UnitLevel("target")
	local levelText = (level and level > 0) and level or "??"
	local classification = UnitClassification("target")
	local label = CLASS_LABEL[classification] or ""
	local color = UnitCanAttack("player", "target") and "|cffff5555" or "|cff55ff55"
	f.nameText:SetText(("%s%s|r [%s] %s"):format(color, name, levelText, label))

	local hp, hpMax = UnitHealth("target"), UnitHealthMax("target")
	if hpMax > 0 then
		f.healthBar:SetMinMaxValues(0, hpMax)
		f.healthBar:SetValue(hp)
		f.healthBar.text:SetText(("%d / %d (%d%%)"):format(hp, hpMax, math.floor((hp / hpMax) * 100)))
	end

	local powerType = UnitPowerType("target")
	local power, powerMax = UnitPower("target"), UnitPowerMax("target")
	if powerMax > 0 then
		local pcolor = POWER_COLOR[powerType] or { 0.5, 0.5, 0.5 }
		f.powerBar:SetStatusBarColor(unpack(pcolor))
		f.powerBar:SetMinMaxValues(0, powerMax)
		f.powerBar:SetValue(power)
		f.powerBar.text:SetText(("%d / %d"):format(power, powerMax))
		f.powerBar:Show()
	else
		f.powerBar:Hide()
	end

	for i = 1, MAX_DEBUFF_ICONS do
		local icon = f.debuffIcons[i]
		local dname, texture, count = UnitDebuff("target", i)
		if dname then
			icon.tex:SetTexture(texture)
			icon.count:SetText(count and count > 1 and count or "")
			icon:Show()
		else
			icon:Hide()
		end
	end
end

HCWarden:On("PLAYER_LOGIN", function()
	if not HCWardenDB.targetHud.enabled then return end
	build()
	updateAll()
end)

HCWarden:On("PLAYER_TARGET_CHANGED", updateAll)
HCWarden:On("UNIT_HEALTH", function(unit) if unit == "target" then updateAll() end end)
HCWarden:On("UNIT_MAXHEALTH", function(unit) if unit == "target" then updateAll() end end)
HCWarden:On("UNIT_POWER_FREQUENT", function(unit) if unit == "target" then updateAll() end end)
HCWarden:On("UNIT_POWER_UPDATE", function(unit) if unit == "target" then updateAll() end end)
HCWarden:On("UNIT_MAXPOWER", function(unit) if unit == "target" then updateAll() end end)
HCWarden:On("UNIT_AURA", function(unit) if unit == "target" then updateAll() end end)
HCWarden:On("UNIT_LEVEL", function(unit) if unit == "target" then updateAll() end end)
HCWarden:On("UNIT_CLASSIFICATION_CHANGED", function(unit) if unit == "target" then updateAll() end end)
