--!strict
-- Egg definitions (TDD B3 EggDef, GDD A6). One egg per island.
--
-- Entry weights are the tuning sheet's base weights (Egg Odds tab) and sum
-- to 100, so each weight reads as a percent before luck. Costs follow
-- EGG_COST_BASE × EGG_COST_GROWTH^(island − 1) from the Inputs tab.
--
-- paidRandom must say whether Robux can reach the roll: true if the cost
-- currency is Robux-buyable, or if a paid luck source can change the odds
-- (TDD B11). A test checks every egg against that rule.

local Rarities = require(script.Parent.Rarities)

export type EggEntry = { pet: string, weight: number }

export type EggDef = {
	id: string,
	island: string,
	cost: number,
	currency: string,
	bonusLuck: number,
	-- On this many opens without a pet of pityMinRarity or better, the next
	-- open only rolls those rarities (GDD A6 "Legendary Pity [x/100]").
	pityThreshold: number,
	pityMinRarity: Rarities.Rarity,
	entries: { EggEntry },
	paidRandom: boolean,
	modelAsset: string,
}

local list: { EggDef } = {
	{
		id = "ninja_village_egg",
		island = "NinjaVillage",
		cost = 25,
		currency = "coins",
		bonusLuck = 0,
		pityThreshold = 100,
		pityMinRarity = "Legendary",
		entries = {
			{ pet = "kohai", weight = 35.12 },
			{ pet = "hana_tetsu", weight = 30.99 },
			{ pet = "elder_kurogane", weight = 24.10 },
			{ pet = "kaeru_jin", weight = 8.37 },
			{ pet = "utsushi", weight = 1.32 },
			{ pet = "karasu_ren", weight = 0.10 },
		},
		-- Paid luck sources can change these odds.
		paidRandom = true,
		modelAsset = "egg.ninja_village.model",
	},
	{
		id = "cursed_city_egg",
		island = "CursedCity",
		cost = 625,
		currency = "coins",
		bonusLuck = 0,
		pityThreshold = 100,
		pityMinRarity = "Legendary",
		entries = {
			{ pet = "haiiro_wisp", weight = 35.12 },
			{ pet = "mokuren", weight = 30.99 },
			{ pet = "kazan", weight = 24.10 },
			{ pet = "nuiko", weight = 8.37 },
			{ pet = "kizuna", weight = 1.32 },
			{ pet = "henko", weight = 0.10 },
		},
		paidRandom = true,
		modelAsset = "egg.cursed_city.model",
	},
}

-- Eggs by id.
local Eggs: { [string]: EggDef } = {}
for _, egg in list do
	Eggs[egg.id] = table.freeze(egg)
end

return table.freeze(Eggs)
