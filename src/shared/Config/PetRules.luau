--!strict
-- Pet inventory rules (GDD A7). Each pet's Energy bonus is generated into
-- Config/Pets from the tuning sheet; these are the rules around owning and
-- equipping them.

local PetRules = {
	-- Equip slots before ranks and passes add more (GDD A7).
	BASE_EQUIP_SLOTS = 3,

	-- Most pets one DeletePets request may name.
	MAX_DELETE_BATCH = 100,

	-- Player attributes the server keeps up to date for every client:
	-- the pet ids a player has equipped (comma separated, for drawing
	-- other players' pets) and their equip slot count (for the Pets screen).
	EQUIPPED_ATTRIBUTE = "EquippedPets",
	SLOTS_ATTRIBUTE = "EquipSlots",
}

return table.freeze(PetRules)
