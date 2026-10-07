local RojoRequire = require("./support/RojoRequire")

local Combat = RojoRequire("src/shared/Config/Combat")
local StatMath = RojoRequire("src/shared/Util/StatMath")

local tests = {}

local function close(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-9
end

tests["no rebirths and no pets leave every multiplier at 1"] = function()
	assert(StatMath.rebirthMultiplier(0) == 1)
	assert(StatMath.petMultiplier({}) == 1)
	assert(StatMath.energyPerClick(1, 1) == Combat.BASE_ENERGY_PER_CLICK)
end

tests["rebirth multiplier matches the Rebirth tab"] = function()
	-- Rebirth tab: r = 1 -> 1.5, r = 10 -> 6 × 1.1 = 6.6, r = 20 -> 11 × 1.21.
	assert(close(StatMath.rebirthMultiplier(1), 1.5))
	assert(close(StatMath.rebirthMultiplier(10), 6.6))
	assert(close(StatMath.rebirthMultiplier(20), 11 * 1.21))
end

tests["pet bonuses add together"] = function()
	assert(close(StatMath.petMultiplier({ 0.25, 0.4, 0.6 }), 2.25))
end

tests["energy per click multiplies base, pets and rebirths"] = function()
	assert(close(StatMath.energyPerClick(2.25, 1.5), Combat.BASE_ENERGY_PER_CLICK * 2.25 * 1.5))
end

return tests
