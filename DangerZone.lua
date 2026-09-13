local DangerZone = {}
HCWarden.DangerZone = DangerZone

local CLASS_LABEL = {
	worldboss = "|cffff0000BOSS|r",
	rareelite = "|cffff8800RARE ELITE|r",
	elite = "|cffffff00ELITE|r",
	rare = "|cff00ccffRARE|r",
}

local tracked = {} -- [nameplateUnit] = { name = , class = }

local function isThreat(unit)
	if not UnitExists(unit) or UnitIsDead(unit) then return false end
	if not UnitCanAttack("player", unit) then return false end
	local classification = UnitClassification(unit)
	return CLASS_LABEL[classification] ~= nil, classification
end

local function refreshFrame()
	local frame = DangerZone.frame
	if not frame then return end

	local lines = {}
	for _, info in pairs(tracked) do
		table.insert(lines, ("%s %s"):format(CLASS_LABEL[info.class], info.name))
	end

	if #lines == 0 then
		frame.text:SetText("No nearby threats")
		frame.text:SetTextColor(0.6, 0.6, 0.6)
	else
		table.sort(lines)
		frame.text:SetText(table.concat(lines, "\n"))
		frame.text:SetTextColor(1, 1, 1)
	end
end

function DangerZone:CreateFrame()
	local f = CreateFrame("Frame", "HCWardenDangerFrame", UIParent, "BackdropTemplate")
	f:SetSize(220, 80)
	f:SetPoint("TOPRIGHT", -20, -200)
	if f.SetBackdrop then
		f:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 12,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		f:SetBackdropColor(0, 0, 0, 0.5)
	end

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	title:SetPoint("TOPLEFT", 8, -6)
	title:SetText("HCWarden: Nearby Threats")

	local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("TOPLEFT", 8, -22)
	text:SetPoint("RIGHT", -8, 0)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")
	f.text = text

	self.frame = f
	refreshFrame()
end

HCWarden:On("PLAYER_LOGIN", function()
	if HCWardenDB.dangerZone.enabled then
		DangerZone:CreateFrame()
	end
end)

HCWarden:On("NAME_PLATE_UNIT_ADDED", function(unit)
	if not HCWardenDB.dangerZone.enabled then return end
	local threat, classification = isThreat(unit)
	if threat then
		local name = UnitName(unit)
		tracked[unit] = { name = name, class = classification }
		refreshFrame()
		if classification == "worldboss" or classification == "rareelite" or classification == "rare" then
			HCWarden.Alerts and print(("|cffff8800[HCWarden]|r Nearby: %s (%s)"):format(name, classification))
		end
	end
end)

HCWarden:On("NAME_PLATE_UNIT_REMOVED", function(unit)
	if tracked[unit] then
		tracked[unit] = nil
		refreshFrame()
	end
end)
