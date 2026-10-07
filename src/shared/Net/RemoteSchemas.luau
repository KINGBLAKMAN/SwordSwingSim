--!strict
-- Every remote in the game, defined in one place (TDD B6).
--
-- ToServer remotes carry intent from the client ("I clicked", "open this
-- egg") and list a Check for each argument. The server runs those checks
-- and the rate limit from Config/RemoteLimits before any handler sees the
-- call. Never add an argument that carries an amount, price, damage or
-- outcome: the server works those out itself.
--
-- ToClient remotes carry results from the server. Their arguments come from
-- our own code, so they aren't checked; `args` documents them instead.
--
-- Add a remote here when the system that uses it is built.

local Validate = require(script.Parent.Validate)

export type Direction = "ToServer" | "ToClient"

export type Schema = {
	direction: Direction,
	args: { Validate.Check },
}

local Clicking = require(script.Parent.Parent.Config.Clicking)
local Eggs = require(script.Parent.Parent.Config.Eggs)
local Hatching = require(script.Parent.Parent.Config.Hatching)
local Islands = require(script.Parent.Parent.Config.Islands)
local PetRules = require(script.Parent.Parent.Config.PetRules)
local Quests = require(script.Parent.Parent.Config.Quests)
local Settings = require(script.Parent.Parent.Config.Settings)

-- Keys in profile.autos a player may switch on or off.
local AUTO_KEYS = { Clicking.AUTO_KEY }

-- Pet uids are GUIDs without braces: 36 characters.
local petUid = Validate.string({ maxLength = 36 })

local islandIds = {}
for islandId in Islands do
	table.insert(islandIds, islandId)
end

local questIds = {}
for questId in Quests.BY_ID do
	table.insert(questIds, questId)
end

local eggIds = {}
for eggId in Eggs do
	table.insert(eggIds, eggId)
end

local RemoteSchemas: { [string]: Schema } = {
	-- Client asks to click once. No arguments: the server decides what a
	-- click is worth.
	Click = {
		direction = "ToServer",
		args = {},
	},

	-- Client switches one of its autos (like auto-click) on or off.
	-- args: (key: one of AUTO_KEYS, enabled: boolean)
	SetAuto = {
		direction = "ToServer",
		args = { Validate.oneOf(AUTO_KEYS), Validate.boolean() },
	},

	-- Client asks to swing at an enemy. The server checks the enemy is
	-- alive, on the player's island and in reach, and works out the damage.
	-- args: (enemyUid: string)
	AttackTarget = {
		direction = "ToServer",
		args = { Validate.string({ maxLength = 16 }) },
	},

	-- Server tells the attacker a hit landed, for the damage number.
	-- args: (enemyUid: string, damage: number, isCrit: boolean)
	DamageFx = {
		direction = "ToClient",
		args = {},
	},

	-- Server tells a player what a kill dropped for them, for the toast and
	-- the rare-drop banner.
	-- args: (enemyId: string, drops: { DropTables.Drop })
	DropFx = {
		direction = "ToClient",
		args = {},
	},

	-- Client asks to open an egg `count` times (1 if left out). The server
	-- checks island, distance, policy, storage and cost, and rolls.
	-- args: (eggId: string, count: number?)
	OpenEgg = {
		direction = "ToServer",
		args = {
			Validate.oneOf(eggIds),
			Validate.optional(
				Validate.number({ min = 1, max = Hatching.MAX_OPEN_COUNT, integer = true })
			),
		},
	},

	-- Server tells the player what their eggs hatched.
	-- args: (eggId: string, hatched: { EggService.HatchedPet })
	HatchResult = {
		direction = "ToClient",
		args = {},
	},

	-- Client asks to equip or unequip one of its pets.
	-- args: (uid: string)
	EquipPet = {
		direction = "ToServer",
		args = { petUid },
	},
	UnequipPet = {
		direction = "ToServer",
		args = { petUid },
	},

	-- Client asks to fill its equip slots with its strongest pets.
	EquipBest = {
		direction = "ToServer",
		args = {},
	},

	-- Client asks to delete some of its pets. The server refuses the whole
	-- batch if any is locked, equipped or not theirs.
	-- args: (uids: { string })
	DeletePets = {
		direction = "ToServer",
		args = { Validate.arrayOf(petUid, PetRules.MAX_DELETE_BATCH) },
	},

	-- Client locks or unlocks one of its pets.
	-- args: (uid: string, locked: boolean)
	LockPet = {
		direction = "ToServer",
		args = { petUid, Validate.boolean() },
	},

	-- Client changes one of its on/off settings (Config/Settings).
	-- args: (key: string, value: boolean)
	-- Client asks for a completed quest's reward. The server checks the
	-- quest is active and complete.
	ClaimQuest = {
		direction = "ToServer",
		args = { Validate.oneOf(questIds) },
	},

	-- Client asks to unlock an island (pay its cost) or travel to one it
	-- has unlocked. The server checks the requirement and the Coins.
	UnlockIsland = {
		direction = "ToServer",
		args = { Validate.oneOf(islandIds) },
	},
	Teleport = {
		direction = "ToServer",
		args = { Validate.oneOf(islandIds) },
	},

	UpdateSetting = {
		direction = "ToServer",
		args = { Validate.oneOf(Settings.keys()), Validate.boolean() },
	},

	-- Server sends changes to the player's own profile, batched a few times
	-- a second (TDD B6). The first one after joining is the whole profile.
	-- args: (changes: { ProfileDelta.Change })
	ProfileDelta = {
		direction = "ToClient",
		args = {},
	},

	-- Server shows the player a short message.
	-- args: (message: string)
	Notify = {
		direction = "ToClient",
		args = {},
	},
}

return table.freeze(RemoteSchemas)
