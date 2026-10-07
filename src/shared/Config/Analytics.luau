--!strict
-- Analytics events (TDD B12). The onboarding funnel follows the first
-- session of GDD C2: each step is logged once per player, the first time
-- they reach it, so the Creator Dashboard shows where new players stop.
-- Step numbers are positions in this list: add new steps at the end, or
-- the dashboard's history mixes up.

local Analytics = {
	ONBOARDING_STEPS = {
		"Joined",
		"FirstClick",
		"FirstKill",
		"FirstEgg",
		"FirstEquip",
		"FirstQuestClaimed",
		"Island2Unlocked",
	},
}

return table.freeze(Analytics)
