--!strict
-- A brand-new player's profile (TDD B3–B4). ProfileStore copies it for new
-- players, and Reconcile copies any field missing from an older save out of
-- it (on fixed tables only; see ProfileTypes). The Profile type annotation
-- makes the type checker flag a field that's missing here.
--
-- Don't change this table at runtime: every new profile is copied from it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BigNum = require(ReplicatedStorage.Shared.Util.BigNum)
local DataConfig = require(ReplicatedStorage.Shared.Config.Data)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local Migrations = require(script.Parent.Migrations)

local template: ProfileTypes.Profile = {
	schemaVersion = Migrations.LATEST_VERSION,

	currencies = {
		energy = BigNum.zero(),
		coins = BigNum.zero(),
		embers = BigNum.zero(),
		gems = 0,
		tokens = {},
	},

	stats = {
		level = DataConfig.STARTING_LEVEL,
		exp = BigNum.zero(),
		rank = DataConfig.STARTING_RANK,
		rebirths = 0,
		totalClicks = 0,
		totalKills = 0,
		eggsOpened = 0,
		playtime = 0,
	},

	pets = {},
	equippedPets = {},
	petStorageCap = DataConfig.PET_STORAGE_CAP,

	weapons = {},
	equippedWeapon = nil,

	index = { pets = {}, weapons = {} },

	pity = {},
	islandsUnlocked = { [DataConfig.STARTING_ISLAND] = true },
	currentIsland = DataConfig.STARTING_ISLAND,

	boosts = { active = {}, inventory = {} },

	quests = {},
	achievements = {},
	daily = { streak = 0, lastClaimDay = 0 },

	battlepass = { season = 0, xp = 0, premium = false, claimed = {} },

	redeemedCodes = {},

	purchases = { receipts = {}, lifetimeRobux = 0 },

	settings = {},
	autos = {},
	flags = {
		groupRewardClaimed = false,
		tutorialStep = 0,
		startingEnergyGranted = false,
		onboardingLogged = {},
	},

	lastOnline = 0,
}

return template
