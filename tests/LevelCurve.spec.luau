local RojoRequire = require("./support/RojoRequire")

local Levels = RojoRequire("src/shared/Config/Levels")
local LevelCurve = RojoRequire("src/shared/Util/LevelCurve")

local tests = {}

tests["expToNext matches the tuning sheet's Levels tab"] = function()
	-- floor(100 × L^1.6): level 1 = 100, level 2 = 303, level 10 = 3981.
	assert(
		Levels.LEVEL_EXP_BASE == 100 and Levels.LEVEL_EXP_EXP == 1.6,
		"sheet values changed; update the expected numbers"
	)
	assert(LevelCurve.expToNext(1) == 100, `level 1: got {LevelCurve.expToNext(1)}`)
	assert(LevelCurve.expToNext(2) == 303, `level 2: got {LevelCurve.expToNext(2)}`)
	assert(LevelCurve.expToNext(10) == 3981, `level 10: got {LevelCurve.expToNext(10)}`)
end

tests["each level needs more EXP than the last"] = function()
	for level = 1, 200 do
		assert(LevelCurve.expToNext(level + 1) > LevelCurve.expToNext(level), `level {level}`)
	end
end

tests["progress is the share of the level done, kept between 0 and 1"] = function()
	assert(LevelCurve.progress(1, 0) == 0, "start of level")
	assert(LevelCurve.progress(1, 50) == 0.5, "halfway through level 1")
	assert(LevelCurve.progress(1, 500) == 1, "overflow clamps to 1")
	assert(LevelCurve.progress(1, -5) == 0, "negative clamps to 0")
end

return tests
