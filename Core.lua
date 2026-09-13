HCWarden = CreateFrame("Frame", "HCWardenFrame")

local defaults = {
	alerts = {
		healthWarnThresholds = { 50, 30, 15 },
		bigHitPercent = 15,
		bigHitWindow = 1.5,
		flashScreen = true,
		playSound = true,
	},
	dangerZone = {
		enabled = true,
		radius = 40,
	},
	hud = {
		enabled = true,
		locked = false,
		point = "CENTER",
		x = 0,
		y = 200,
	},
	targetHud = {
		enabled = true,
		locked = false,
		point = "CENTER",
		x = 220,
		y = 200,
	},
	totemBar = {
		enabled = true,
		locked = false,
		point = "CENTER",
		x = 0,
		y = 260,
	},
	weaponBar = {
		enabled = true,
		locked = false,
		point = "CENTER",
		x = -220,
		y = 200,
	},
}

local function copyDefaults(src, dst)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then
				dst[k] = {}
			end
			copyDefaults(v, dst[k])
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
end

HCWarden:RegisterEvent("ADDON_LOADED")
HCWarden:RegisterEvent("PLAYER_LOGIN")

HCWarden:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local name = ...
		if name == "HCWarden" then
			HCWardenDB = HCWardenDB or {}
			copyDefaults(defaults, HCWardenDB)
			self.db = HCWardenDB
		end
	elseif event == "PLAYER_LOGIN" then
		print("|cff3399ffHCWarden|r loaded. Type |cffffff00/hcw|r for options.")
		if self.OnPlayerLogin then
			self:OnPlayerLogin()
		end
	end

	if self.handlers and self.handlers[event] then
		for _, fn in ipairs(self.handlers[event]) do
			fn(...)
		end
	end
end)

HCWarden.handlers = {}

function HCWarden:On(event, fn)
	self.handlers[event] = self.handlers[event] or {}
	table.insert(self.handlers[event], fn)
	self:RegisterEvent(event)
end

-- soundFile is optional: a raw sound file path to play instead of the default raid-warning
-- klaxon, for announcements that are good news rather than a danger warning. Falls back to
-- the klaxon if the file can't be played for any reason (e.g. its addon got uninstalled).
function HCWarden:Announce(text, playSound, soundFile)
	if RaidNotice_AddMessage and RaidWarningFrame then
		RaidNotice_AddMessage(RaidWarningFrame, text, ChatTypeInfo["RAID_WARNING"])
	end
	print(("|cffff3333[HCWarden]|r %s"):format(text))
	if playSound then
		local played = false
		if soundFile then
			local ok, willPlay = pcall(PlaySoundFile, soundFile, "Master")
			played = ok and willPlay
		end
		if not played then
			pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master")
		end
	end
end

SLASH_HCWARDEN1 = "/hcw"
SlashCmdList["HCWARDEN"] = function(msg)
	msg = (msg or ""):lower():trim()
	if msg == "lock" then
		HCWardenDB.hud.locked = true
		HCWardenDB.targetHud.locked = true
		HCWardenDB.totemBar.locked = true
		HCWardenDB.weaponBar.locked = true
		print("HCWarden: HUD locked.")
	elseif msg == "unlock" then
		HCWardenDB.hud.locked = false
		HCWardenDB.targetHud.locked = false
		HCWardenDB.totemBar.locked = false
		HCWardenDB.weaponBar.locked = false
		print("HCWarden: HUD unlocked, drag it where you want.")
	elseif msg == "reset" then
		HCWardenDB.hud.point = defaults.hud.point
		HCWardenDB.hud.x = defaults.hud.x
		HCWardenDB.hud.y = defaults.hud.y
		if HCWarden.HUD then
			HCWarden.HUD:ClearAllPoints()
			HCWarden.HUD:SetPoint(HCWardenDB.hud.point, HCWardenDB.hud.x, HCWardenDB.hud.y)
		end
		HCWardenDB.targetHud.point = defaults.targetHud.point
		HCWardenDB.targetHud.x = defaults.targetHud.x
		HCWardenDB.targetHud.y = defaults.targetHud.y
		if HCWarden.TargetHUD then
			HCWarden.TargetHUD:ClearAllPoints()
			HCWarden.TargetHUD:SetPoint(HCWardenDB.targetHud.point, HCWardenDB.targetHud.x, HCWardenDB.targetHud.y)
		end
		HCWardenDB.totemBar.point = defaults.totemBar.point
		HCWardenDB.totemBar.x = defaults.totemBar.x
		HCWardenDB.totemBar.y = defaults.totemBar.y
		if HCWarden.TotemBar then
			HCWarden.TotemBar:ClearAllPoints()
			HCWarden.TotemBar:SetPoint(HCWardenDB.totemBar.point, HCWardenDB.totemBar.x, HCWardenDB.totemBar.y)
		end
		HCWardenDB.weaponBar.point = defaults.weaponBar.point
		HCWardenDB.weaponBar.x = defaults.weaponBar.x
		HCWardenDB.weaponBar.y = defaults.weaponBar.y
		if HCWarden.WeaponBar then
			HCWarden.WeaponBar:ClearAllPoints()
			HCWarden.WeaponBar:SetPoint(HCWardenDB.weaponBar.point, HCWardenDB.weaponBar.x, HCWardenDB.weaponBar.y)
		end
		print("HCWarden: HUD position reset.")
	else
		print("|cff3399ffHCWarden|r commands:")
		print("  /hcw lock - lock the HUD (player + target) in place")
		print("  /hcw unlock - unlock the HUDs so you can drag them")
		print("  /hcw reset - reset HUD positions")
	end
end
