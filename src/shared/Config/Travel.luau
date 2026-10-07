--!strict
-- Island unlocks and travel (GDD A12). Unlock costs come from the tuning
-- sheet (Config/Islands); the requirement on top of the cost is here.
--
-- No Roblox types in here, so Lune tests can load it.

local Travel = {
	-- To unlock an island, the player must have finished the quest chain of
	-- the island before it (GDD A12: "an unlock cost plus requirement").
	REQUIRE_PREVIOUS_QUESTS = true,

	-- The prompt on each island's gate pad (the pad's look is in
	-- Config/World).
	PROMPT_ACTION = "Travel",
	PROMPT_OBJECT = "Island gate",
	PROMPT_DISTANCE = 12,

	-- Studs above an island's Spawn that a traveling player lands at.
	ARRIVE_HEIGHT = 4,
}

return table.freeze(Travel)
