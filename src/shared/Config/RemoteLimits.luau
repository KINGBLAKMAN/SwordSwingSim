--!strict
-- Per-player rate limits for every client-to-server remote (TDD B6).
-- `calls` per `perSeconds`: { calls = 12, perSeconds = 1 } is 12 per second,
-- { calls = 1, perSeconds = 3 } is one call every 3 seconds.
--
-- A remote that sends to the server must have an entry here, or the server
-- refuses to start (see server/Net/Remotes).

local RateLimiter = require(script.Parent.Parent.Net.RateLimiter)

local RemoteLimits: { [string]: RateLimiter.Limit } = {
	-- Combat and clicking
	Click = { calls = 12, perSeconds = 1 },
	AttackTarget = { calls = 12, perSeconds = 1 },

	-- Eggs
	OpenEgg = { calls = 3, perSeconds = 1 },
	StartAutoOpen = { calls = 2, perSeconds = 1 },
	StopAutoOpen = { calls = 2, perSeconds = 1 },

	-- Pets
	EquipPet = { calls = 5, perSeconds = 1 },
	UnequipPet = { calls = 5, perSeconds = 1 },
	EquipBest = { calls = 5, perSeconds = 1 },
	DeletePets = { calls = 2, perSeconds = 1 },
	LockPet = { calls = 2, perSeconds = 1 },
	MergePets = { calls = 2, perSeconds = 1 },
	CraftPet = { calls = 2, perSeconds = 1 },

	-- Traits
	RerollTrait = { calls = 4, perSeconds = 1 },
	LockTrait = { calls = 4, perSeconds = 1 },

	-- Weapons and potions
	EquipWeapon = { calls = 5, perSeconds = 1 },
	MergeWeapons = { calls = 5, perSeconds = 1 },
	UsePotion = { calls = 5, perSeconds = 1 },

	-- Progression and travel
	Rebirth = { calls = 1, perSeconds = 1 },
	RankUp = { calls = 1, perSeconds = 1 },
	UnlockIsland = { calls = 1, perSeconds = 1 },
	Teleport = { calls = 1, perSeconds = 1 },

	-- Rewards
	ClaimQuest = { calls = 3, perSeconds = 1 },
	ClaimAchievement = { calls = 3, perSeconds = 1 },
	ClaimDaily = { calls = 3, perSeconds = 1 },
	ClaimPlaytime = { calls = 3, perSeconds = 1 },
	ClaimGroup = { calls = 3, perSeconds = 1 },
	RedeemCode = { calls = 1, perSeconds = 3 },

	-- Settings
	SetAuto = { calls = 5, perSeconds = 1 },
	UpdateSetting = { calls = 5, perSeconds = 1 },
}

return table.freeze(RemoteLimits)
