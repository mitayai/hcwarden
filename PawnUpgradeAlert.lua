-- Alerts when a newly acquired bag item is an upgrade, using Pawn's own scoring (Pawn must be installed/enabled).
-- Pawn already draws a green arrow on bag icons for upgrades (PawnCommon.ShowBagUpgradeAdvisor) -- this just
-- adds a loud one-time alert so you don't have to notice the small icon while leveling.

-- BigWigs' standard boss-kill victory fanfare (bundled with BigWigs, ~4.6s) instead of the
-- default raid-warning klaxon -- this is good news, not danger. Chosen over the other
-- options below by actually inspecting each file's waveform/spectrogram (no in-game audio
-- playback available here): this one has a sharp multi-hit horn-stab rhythm rather than a
-- slow swell, and broadband energy up into ~20kHz consistent with real crowd noise under
-- the horns, not just a clean synth tone.
-- Other options bundled by other installed addons, if this one still isn't right:
--   BigWigs\Media\Sounds\VictoryClassic.ogg - smoother orchestral swell, less punchy
--   BigWigs\Media\Sounds\VictoryLong.ogg    - longer/more elaborate version of this one
--   DBM-Core\sounds\Victory\bbvictory.ogg   - cleaner/shorter synth fanfare, no crowd noise
--   WeakAuras\Media\Sounds\TadaFanfare.ogg  - very short, punchy two-note "ta-da!"
local UPGRADE_SOUND = "Interface\\AddOns\\BigWigs\\Media\\Sounds\\Victory.ogg"

local lastSeenItemID = {} -- ["bag:slot"] = itemID
local alertedItemIDs = {} -- [itemID] = true, so we only alert once per item type per session
local pendingRetries = {}
local initialized = false

local function getContainerItemID(bag, slot)
	if C_Container and C_Container.GetContainerItemID then
		return C_Container.GetContainerItemID(bag, slot)
	end
	return GetContainerItemID(bag, slot)
end

local function getContainerItemLink(bag, slot)
	if C_Container and C_Container.GetContainerItemLink then
		return C_Container.GetContainerItemLink(bag, slot)
	end
	return GetContainerItemLink(bag, slot)
end

local function getContainerNumSlots(bag)
	if C_Container and C_Container.GetContainerNumSlots then
		return C_Container.GetContainerNumSlots(bag)
	end
	return GetContainerNumSlots(bag)
end

local function checkLinkForUpgrade(itemID, link, attemptsLeft)
	if not PawnShouldItemLinkHaveUpgradeArrow then return end
	local isUpgrade = PawnShouldItemLinkHaveUpgradeArrow(link, true)
	if isUpgrade == nil then
		-- Pawn hasn't got item data cached yet; try again shortly.
		if attemptsLeft > 0 then
			C_Timer.After(0.3, function() checkLinkForUpgrade(itemID, link, attemptsLeft - 1) end)
		end
		return
	end
	if isUpgrade and not alertedItemIDs[itemID] then
		alertedItemIDs[itemID] = true
		local name = GetItemInfo(link) or link
		HCWarden:Announce(("Upgrade picked up: %s"):format(name), HCWardenDB.alerts.playSound,
			UPGRADE_SOUND)
	end
end

local function scanBags(alertOnNew)
	for bag = 0, (NUM_BAG_SLOTS or 4) do
		local slots = getContainerNumSlots(bag) or 0
		for slot = 1, slots do
			local key = bag .. ":" .. slot
			local itemID = getContainerItemID(bag, slot)
			if lastSeenItemID[key] ~= itemID then
				lastSeenItemID[key] = itemID
				if alertOnNew and itemID and not alertedItemIDs[itemID] then
					local link = getContainerItemLink(bag, slot)
					if link then
						checkLinkForUpgrade(itemID, link, 5)
					end
				end
			end
		end
	end
end

HCWarden:On("PLAYER_LOGIN", function()
	if not PawnShouldItemLinkHaveUpgradeArrow then
		print("|cffff8800[HCWarden]|r Pawn not found -- upgrade-pickup alerts disabled. Install/enable Pawn to use this.")
		return
	end
	-- Snapshot current bags without alerting, so we don't fire on everything you already own at login.
	scanBags(false)
	initialized = true
end)

HCWarden:On("BAG_UPDATE_DELAYED", function()
	if not initialized then return end
	scanBags(true)
end)
