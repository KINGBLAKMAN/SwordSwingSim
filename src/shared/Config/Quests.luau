--!strict
-- Island quest chains (GDD A13). Each island has a short chain: one quest
-- is active at a time, and claiming its reward starts the next. The tuning
-- sheet has no quest tab yet, so the chain lives here; move it into the
-- sheet when the daily and weekly pools arrive.
--
-- Goals count only while their quest is active, so kills before the quest
-- started don't count.

export type GoalKind = "kill" | "open"

export type QuestDef = {
	id: string,
	island: string,
	-- "kill": defeat `count` of enemy `target` (shared kill credit counts).
	-- "open": open `count` of egg `target`.
	kind: GoalKind,
	target: string,
	count: number,
	-- Coins granted on claim. Coin boosts (like x2 Coins) apply.
	rewardCoins: number,
}

local list: { QuestDef } = {
	-- Island 1: teaches the loop: fight, open the egg, take on the boss.
	{
		id = "nv_kohai",
		island = "NinjaVillage",
		kind = "kill",
		target = "kohai",
		count = 25,
		rewardCoins = 50,
	},
	{
		id = "nv_open_eggs",
		island = "NinjaVillage",
		kind = "open",
		target = "ninja_village_egg",
		count = 3,
		rewardCoins = 75,
	},
	{
		id = "nv_karasu_ren",
		island = "NinjaVillage",
		kind = "kill",
		target = "karasu_ren",
		count = 1,
		rewardCoins = 250,
	},
}

local Quests = {
	BY_ID = {} :: { [string]: QuestDef },
	-- Quest ids in order, by island.
	CHAINS = {} :: { [string]: { string } },
}

for _, quest in list do
	Quests.BY_ID[quest.id] = quest
	local chain = Quests.CHAINS[quest.island] or {}
	table.insert(chain, quest.id)
	Quests.CHAINS[quest.island] = chain
end

return table.freeze(Quests)
