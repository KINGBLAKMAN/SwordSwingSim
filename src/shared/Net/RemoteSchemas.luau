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

-- Keys in profile.autos a player may switch on or off.
local AUTO_KEYS = { Clicking.AUTO_KEY }

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
