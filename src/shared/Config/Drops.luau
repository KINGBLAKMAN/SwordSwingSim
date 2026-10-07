--!strict
-- What enemies drop (GDD A9). Util/DropTables builds each enemy's table
-- from these rules, and both the server roll and the enemy info panel use
-- that table, so the odds shown are the odds rolled.
--
-- Every enemy:
--   * Rolled: its own pet, its island's tokens by tier, plus any EXTRA.
--   * Granted: its Coins (Config/Enemies) on every kill.
-- Each rolled entry rolls on its own, so one kill can drop several.

export type TokenRule = { chance: number, min: number, max: number }
-- kind is "pet", "token" or "weapon"; item is an id in that kind's config.
export type ExtraDrop = { kind: string, item: string, chance: number, min: number, max: number }

local Drops = {
	-- Chance an enemy drops its own pet; bosses drop theirs a bit more.
	PET_CHANCE = 0.125,
	BOSS_PET_CHANCE = 0.15,

	-- Chance and amount of each island token by tier: higher tiers drop
	-- more often and more at once (GDD A9: 10–75%).
	TOKEN_BY_TIER = {
		["Very Easy"] = { chance = 0.1, min = 1, max = 1 },
		Easy = { chance = 0.15, min = 1, max = 1 },
		Medium = { chance = 0.25, min = 1, max = 2 },
		Hard = { chance = 0.4, min = 1, max = 2 },
		["Very Hard"] = { chance = 0.55, min = 1, max = 3 },
		Boss = { chance = 0.75, min = 2, max = 4 },
	} :: { [string]: TokenRule },

	-- Tokens each island's enemies drop (Config/Tokens).
	ISLAND_TOKENS = {
		NinjaVillage = { "scroll_token", "mask_token" },
		CursedCity = { "talisman_token", "curse_shard" },
	} :: { [string]: { string } },

	-- Extra rolled drops for particular enemies, by enemy id.
	EXTRA = {
		-- GDD A8: the 1% rare sword.
		karasu_ren = {
			{ kind = "weapon", item = "crowfeather_tachi", chance = 0.01, min = 1, max = 1 },
		},
	} :: {
		[string]: { { kind: string, item: string, chance: number, min: number, max: number } },
	},

	-- Player attribute with the player's drop boost (StatService), so the
	-- enemy info panel can show the boosted odds. Display only: the server
	-- rolls with its own value.
	DROP_BOOST_ATTRIBUTE = "DropBoost",

	-- Drops at or under this chance count as rare: the server logs them and
	-- the client shows a banner.
	RARE_CHANCE = 0.01,
}

return table.freeze(Drops)
