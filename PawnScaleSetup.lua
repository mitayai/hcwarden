-- Automatically creates a blended Pawn scale for early-level Elemental Shaman leveling.
--
-- Bug this fixes: Pawn's stock Elemental scale ("Classic":SHAMAN1) weighs melee weapon DPS
-- and Attack Power at 0, because a real Elemental Shaman's damage comes from spells, not
-- auto-attacks. But at low level your mana pool is tiny, so you melee constantly between
-- casts -- and a straight DPS upgrade (e.g. a quest-reward weapon) was never showing an
-- upgrade arrow or triggering HCWarden's pickup alert, because Pawn's comparison genuinely
-- scored both weapons as equal under that scale.
--
-- The fix: clone the Elemental scale, give the clone a moderate MeleeDps/Ap weight (about
-- half of Pawn's own Enhancement scale), and show only the clone. This only ever needs to
-- run once -- PawnCommon (and its Scales table) is account-wide SavedVariables, and
-- PawnDoesScaleExist guards against recreating it on every login.

local SOURCE_SCALE = "\"Classic\":SHAMAN1" -- Pawn's built-in Elemental Shaman scale
local NEW_SCALE = "ElementalLeveling"

local function trySetup(attemptsLeft)
	if not (PawnIsInitialized and PawnDoesScaleExist and PawnDuplicateScale) then
		-- Pawn may not have finished PawnInitialize() yet if it loads after HCWarden.
		if attemptsLeft > 0 then
			C_Timer.After(0.5, function() trySetup(attemptsLeft - 1) end)
		end
		return
	end

	if PawnDoesScaleExist(NEW_SCALE) then return end -- already set up
	if not PawnDoesScaleExist(SOURCE_SCALE) then return end -- not an Elemental Shaman, or Pawn scale data missing

	if not PawnDuplicateScale(SOURCE_SCALE, NEW_SCALE) then return end
	PawnCommon.Scales[NEW_SCALE].LocalizedName = "Elemental (Leveling)"
	PawnSetStatValue(NEW_SCALE, "MeleeDps", 1.5)
	PawnSetStatValue(NEW_SCALE, "Ap", 0.25)
	PawnSetScaleVisible(SOURCE_SCALE, false)
	PawnSetScaleVisible(NEW_SCALE, true)

	HCWarden:Announce("Pawn: added 'Elemental (Leveling)' scale so weapon DPS upgrades show up while you're still meleeing to save mana.", HCWardenDB.alerts.playSound)
end

HCWarden:On("PLAYER_LOGIN", function()
	trySetup(10)
end)
