--!strict
-- How enemies spawn and fight (GDD A9, TDD B8). Enemy stats (HP, Coins,
-- EXP) are generated into Config/Enemies from the tuning sheet; these are
-- the rules around them, which the sheet doesn't cover. Placeholder looks
-- are in Config/EnemyLooks.
--
-- No Roblox types in here, so Lune tests can load it.

local Enemies = require(script.Parent.Enemies)

export type TierRules = {
	-- Seconds a spawn point stays empty after its enemy dies.
	respawnSeconds: number,
	-- Most of one enemy kind alive on an island at once.
	maxAlive: number,
}

local EnemySpawning = {
	-- TDD B8: at most this many enemies alive on one island.
	MAX_ALIVE_PER_ISLAND = 30,

	-- Seconds between spawn checks. Respawns land within one tick of due.
	SPAWN_TICK = 0.5,

	-- GDD A9: a player who dealt at least this share of an enemy's max HP
	-- gets the full kill reward.
	KILL_CREDIT_SHARE = 0.1,

	-- Studs from the player to the enemy's edge that a hit may land from.
	ATTACK_RANGE = 12,
	-- Extra studs the server allows on top, for movement between the
	-- client's swing and the server checking it.
	RANGE_TOLERANCE = 4,
	-- The server accepts a swing this much sooner than 1 / SWING_RATE, so
	-- network jitter doesn't drop honest swings.
	SWING_INTERVAL_TOLERANCE = 0.85,
	-- A target the player locked by tapping stays locked until it dies or
	-- the player is this many studs away.
	LOCK_BREAK_RANGE = 80,

	-- CollectionService tag on every live enemy model, and the attributes
	-- the server sets on it for clients to read (TDD B8: HP lives on the
	-- server and replicates through attributes).
	TAG = "Enemy",
	ATTRIBUTES = table.freeze({
		uid = "EnemyUid",
		id = "EnemyId",
		name = "EnemyName",
		tier = "EnemyTier",
		island = "EnemyIsland",
		hp = "Hp",
		maxHp = "MaxHp",
	}),

	BY_TIER = {
		["Very Easy"] = {
			respawnSeconds = 3,
			maxAlive = 10,
		},
		Easy = {
			respawnSeconds = 4,
			maxAlive = 8,
		},
		Medium = {
			respawnSeconds = 6,
			maxAlive = 6,
		},
		Hard = {
			respawnSeconds = 10,
			maxAlive = 4,
		},
		["Very Hard"] = {
			respawnSeconds = 15,
			maxAlive = 3,
		},
		Boss = {
			respawnSeconds = 30,
			maxAlive = 1,
		},
	} :: { [Enemies.Tier]: TierRules },

	-- Which enemies spawn on each island, by island id. The rest of each
	-- roster is in Config/Enemies for later.
	SPAWNED = {
		NinjaVillage = { "kohai", "elder_kurogane", "karasu_ren" },
	} :: { [string]: { string } },
}

return table.freeze(EnemySpawning)
