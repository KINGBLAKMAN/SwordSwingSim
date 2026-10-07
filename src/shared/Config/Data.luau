--!strict
-- Player data settings (TDD B3–B4). DataService and the profile template
-- read these.

local Data = {
	-- DataStore that holds every player's profile. Dev, Test and Prod are
	-- separate universes (TDD B14), so each one already gets its own store.
	STORE_NAME = "PlayerData",

	-- A profile's DataStore key is KEY_PREFIX followed by the player's UserId.
	KEY_PREFIX = "Player_",

	-- Seconds to keep retrying a profile load before kicking the player with
	-- a rejoin message. Keep it above ~60 so a stuck session lock from a
	-- crashed server can still be taken over (ProfileStore does that at 40 s).
	LOAD_TIMEOUT = 120,

	-- Seconds between sends of queued profile changes to each client. TDD B6
	-- batches server-to-client updates at 5–10 Hz.
	DELTA_SEND_INTERVAL = 0.1,

	-- Starting values for a brand-new player.
	STARTING_LEVEL = 1,
	STARTING_RANK = 1,
	-- GDD A7: the pet inventory holds 100 before storage upgrades.
	PET_STORAGE_CAP = 100,
	-- GDD A12a island 1. Island ids move to Config/Islands when that exists.
	STARTING_ISLAND = "NinjaVillage",

	-- Studio only: set to true to make every profile load fail, so you can
	-- see the kick path from checklist C7. Live servers ignore it.
	SIMULATE_LOAD_FAILURE_IN_STUDIO = false,
}

return table.freeze(Data)
