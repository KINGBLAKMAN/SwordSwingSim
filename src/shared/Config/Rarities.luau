--!strict
-- Rarity tiers, lowest first, and how strongly luck boosts each one
-- (GDD A6). Luck only lifts the rare tiers: an adjusted weight is
-- weight × (1 + luck × LUCK_SENSITIVITY[rarity]), then weights renormalize.

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythical" | "Secret"

local Rarities = {
	ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Secret" } :: { Rarity },

	-- From the tuning sheet, Egg Odds tab, "Luck sensitivity" column.
	LUCK_SENSITIVITY = {
		Common = 0,
		Uncommon = 0,
		Rare = 0.25,
		Epic = 0.5,
		Legendary = 1,
		Mythical = 1.5,
		Secret = 2,
	} :: { [Rarity]: number },
}

return table.freeze(Rarities)
