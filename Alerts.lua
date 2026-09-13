local Alerts = {}
HCWarden.Alerts = Alerts

local DANGEROUS_DEBUFF_TYPES = {
	Poison = true,
	Disease = true,
	Curse = true,
}

local warnedThreshold = nil -- lowest threshold already warned about since last full-ish heal
local recentHits = {} -- { {time=, amount=}, ... } amounts are positive damage taken
local lastHealth, lastHealthMax
local activeDebuffWarnings = {} -- [name] = true, so we only announce once per application

local function cfg()
	return HCWardenDB.alerts
end

local function bigAlert(text)
	HCWarden:Announce(text, cfg().playSound)
end

local function checkHealthThresholds(pct)
	local thresholds = cfg().healthWarnThresholds
	-- find the lowest threshold at or above current pct that we haven't warned for yet
	local crossed = nil
	for _, t in ipairs(thresholds) do
		if pct <= t then
			if warnedThreshold == nil or t < warnedThreshold then
				crossed = t
			end
		end
	end
	if crossed then
		warnedThreshold = crossed
		bigAlert(("HP %d%% -- %d%% THRESHOLD"):format(math.floor(pct), crossed))
	end
	if pct >= 90 then
		warnedThreshold = nil -- reset once safely topped back up
	end
end

local function checkBigHit(amount, maxHealth)
	local now = GetTime()
	table.insert(recentHits, { time = now, amount = amount })
	local window = cfg().bigHitWindow
	local total = 0
	for i = #recentHits, 1, -1 do
		if now - recentHits[i].time > window then
			table.remove(recentHits, i)
		else
			total = total + recentHits[i].amount
		end
	end
	local pctOfMax = (total / maxHealth) * 100
	if pctOfMax >= cfg().bigHitPercent then
		bigAlert(("BIG HIT! -%d%% in %.1fs"):format(math.floor(pctOfMax), window))
		recentHits = {}
	end
end

HCWarden:On("UNIT_HEALTH", function(unit)
	if unit ~= "player" then return end
	local hp = UnitHealth("player")
	local hpMax = UnitHealthMax("player")
	if hpMax <= 0 then return end
	local pct = (hp / hpMax) * 100

	if lastHealth and hp < lastHealth then
		checkBigHit(lastHealth - hp, hpMax)
	end
	lastHealth, lastHealthMax = hp, hpMax

	checkHealthThresholds(pct)
end)

HCWarden:On("UNIT_AURA", function(unit)
	if unit ~= "player" then return end
	local seenThisScan = {}
	local i = 1
	while true do
		local name, _, _, debuffType = UnitDebuff("player", i)
		if not name then break end
		seenThisScan[name] = true
		if DANGEROUS_DEBUFF_TYPES[debuffType] and not activeDebuffWarnings[name] then
			activeDebuffWarnings[name] = true
			bigAlert(("Dangerous debuff: %s (%s)"):format(name, debuffType))
		end
		i = i + 1
	end
	-- clear out debuffs that fell off so they can re-warn if reapplied
	for name in pairs(activeDebuffWarnings) do
		if not seenThisScan[name] then
			activeDebuffWarnings[name] = nil
		end
	end
end)

-- Drowning: Classic still uses the mirror timer system for breath.
HCWarden:On("MIRROR_TIMER_UPDATE", function(timerType, value, maxValue)
	if timerType ~= "BREATH" then return end
	if maxValue <= 0 then return end
	local pct = (value / maxValue) * 100
	if pct <= 20 and not Alerts._warnedBreath then
		Alerts._warnedBreath = true
		bigAlert("LOW BREATH -- GET OUT OF THE WATER")
	elseif pct > 50 then
		Alerts._warnedBreath = false
	end
end)
