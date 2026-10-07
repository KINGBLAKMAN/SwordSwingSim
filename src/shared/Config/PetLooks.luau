--!strict
-- How pets follow their owner (TDD B8). Pets are client-only placeholder
-- balls in their rarity color until the real models come from Blender
-- (E-part). Distances are in studs.

local PetLooks = {
	-- Ball size by rarity: rarer pets are a little bigger.
	SIZE = {
		Common = 1.6,
		Uncommon = 1.8,
		Rare = 2,
		Epic = 2.2,
		Legendary = 2.5,
		Mythical = 2.8,
		Secret = 3.2,
	} :: { [string]: number },

	-- Where the row of pets sits, from the owner's root part.
	BEHIND = 5,
	HEIGHT = 0.5,
	SPACING = 3,

	-- How fast pets catch up to their spot; higher is snappier.
	FOLLOW_SPEED = 8,
	-- A pet further than this from its spot jumps there (after a teleport).
	SNAP_DISTANCE = 60,

	-- Gentle up-and-down float.
	BOB_HEIGHT = 0.4,
	BOB_SPEED = 3,

	-- Pets further than this from the camera aren't drawn (TDD B8: ~150).
	CULL_DISTANCE = 150,
}

return table.freeze(PetLooks)
