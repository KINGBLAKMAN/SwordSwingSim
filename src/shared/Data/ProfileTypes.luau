--!strict
-- The shape of a player's saved data (TDD B3). The server owns it; each
-- client gets a read-only copy through ProfileDelta.
--
-- Changing the shape:
--   * New field on a fixed table (currencies, stats, flags...): add it here
--     and in DataService/ProfileTemplate. Reconcile copies the template's
--     value into older saves, so no migration is needed.
--   * New field inside per-item records (PetInstance, WeaponInstance,
--     quest or boost entries): the template has no items for Reconcile to
--     copy from, so also add a migration step that sets it on every item.
--   * Renamed, moved or retyped field: also add a step to
--     DataService/Migrations.
--
-- ProfileStore saves plain data only: no arrays with gaps, no tables that
-- mix array and dictionary keys, no Instances, userdata or functions.
-- Dictionaries keyed by a number (like battlepass tiers) use string keys.

local BigNum = require(script.Parent.Parent.Util.BigNum)

type BigNum = BigNum.BigNum

export type Variant = "Normal" | "Shiny" | "Divine"

export type PetInstance = {
	uid: string,
	id: string,
	variant: Variant,
	level: number,
	xp: number,
	-- One entry per trait slot. "" marks an empty slot, because an array
	-- with gaps can't be saved.
	traits: { string },
	traitLocks: { boolean },
	locked: boolean,
	obtainedAt: number,
	source: string,
}

-- B3 names this type without listing its fields; these follow GDD A8
-- (merge into Shiny or Divine, level up with Coins, lockable).
export type WeaponInstance = {
	uid: string,
	id: string,
	variant: Variant,
	level: number,
	locked: boolean,
	obtainedAt: number,
	source: string,
}

export type Profile = {
	-- Version of this shape the data was saved with (see DataService/Migrations).
	schemaVersion: number,

	currencies: {
		energy: BigNum,
		coins: BigNum,
		embers: BigNum,
		gems: number,
		-- Island tokens by token id, e.g. Scroll Token (GDD A12a).
		tokens: { [string]: number },
	},

	stats: {
		level: number,
		exp: BigNum,
		rank: number,
		rebirths: number,
		totalClicks: number,
		totalKills: number,
		eggsOpened: number,
		playtime: number,
	},

	-- Pets by uid, and the uids of equipped pets.
	pets: { [string]: PetInstance },
	equippedPets: { string },
	petStorageCap: number,

	-- Weapons by uid, and the uid of the equipped weapon.
	weapons: { [string]: WeaponInstance },
	equippedWeapon: string?,

	-- Collection log: pets[petId][variant] and weapons[weaponId] are true once owned.
	index: {
		pets: { [string]: { [string]: boolean } },
		weapons: { [string]: boolean },
	},

	-- Opens since the last pity-tier pet, by egg id.
	pity: { [string]: number },
	islandsUnlocked: { [string]: boolean },
	currentIsland: string,

	boosts: {
		active: { [string]: { tier: number, endsAt: number } },
		inventory: { [string]: number },
	},

	quests: { [string]: { progress: number, claimed: boolean, assignedAt: number } },
	achievements: { [string]: number },
	daily: { streak: number, lastClaimDay: number },

	battlepass: {
		season: number,
		xp: number,
		premium: boolean,
		-- Claimed tiers, keyed by the tier number as a string (B3 uses
		-- number keys, which would leave gaps ProfileStore can't save).
		claimed: { [string]: boolean },
	},

	redeemedCodes: { [string]: boolean },

	purchases: {
		-- os.time() of each granted purchase, by PurchaseId. Trim to the
		-- last ~100 (TDD B3).
		receipts: { [string]: number },
		lifetimeRobux: number,
	},

	settings: { [string]: any },
	autos: { [string]: boolean | number },
	flags: { groupRewardClaimed: boolean, tutorialStep: number },

	-- os.time() when the player last left, for offline rewards (GDD A10).
	lastOnline: number,
}

return {}
