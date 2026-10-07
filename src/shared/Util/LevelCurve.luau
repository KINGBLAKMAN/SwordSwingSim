--!strict
-- LevelCurve: how much EXP each player level needs (GDD A4).
--
-- Pure math over Config/Levels, so the server's level-up check and the
-- client's level bar can't disagree.

local Levels = require(script.Parent.Parent.Config.Levels)

local LevelCurve = {}

-- EXP needed to go from `level` to `level + 1`.
function LevelCurve.expToNext(level: number): number
	return math.floor(Levels.LEVEL_EXP_BASE * level ^ Levels.LEVEL_EXP_EXP)
end

-- How far through the current level `exp` is, from 0 to 1. `exp` is the EXP
-- earned since reaching `level`.
function LevelCurve.progress(level: number, exp: number): number
	local needed = LevelCurve.expToNext(level)
	if needed <= 0 then
		return 1
	end
	return math.clamp(exp / needed, 0, 1)
end

return LevelCurve
