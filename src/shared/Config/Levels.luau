--!strict
-- Player level curve (GDD A4). From the tuning sheet, Inputs tab, "Levels"
-- rows; the Levels tab lists the EXP each level needs.
--
-- EXP to go from level L to L + 1 = floor(LEVEL_EXP_BASE × L ^ LEVEL_EXP_EXP).
-- Util/LevelCurve does the math. The config pipeline will regenerate this
-- file from the sheet once it exists.

local Levels = {
	LEVEL_EXP_BASE = 100,
	LEVEL_EXP_EXP = 1.6,
}

return table.freeze(Levels)
