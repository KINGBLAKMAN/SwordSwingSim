--!strict
-- Egg opening rules (GDD A6). Costs, weights and pity come from the tuning
-- sheet in Config/Eggs; these are the rules around opening.

local Hatching = {
	-- Studs from the player to the egg stand the server allows an open from.
	OPEN_RANGE = 14,
	-- Extra studs on top, for movement between the tap and the server check.
	RANGE_TOLERANCE = 4,

	-- Most eggs one Open may hatch. Open ×N comes with ranks and passes.
	MAX_OPEN_COUNT = 1,

	-- Player attribute with the luck the server rolls eggs with (after
	-- ComplianceService drops paid luck), so the odds panel shows the same
	-- odds. Display only: the server works it out again on every open.
	LUCK_ATTRIBUTE = "EggLuck",
}

return table.freeze(Hatching)
