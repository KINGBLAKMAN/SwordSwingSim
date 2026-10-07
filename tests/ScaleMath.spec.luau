local ScaleMath = require("../src/client/UI/ScaleMath")

local tests = {}

local SETTINGS = {
	REFERENCE_LONG_SIDE = 667,
	REFERENCE_SHORT_SIDE = 375,
	MIN = 1,
	MAX = 1.6,
}

local function close(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

tests["the reference phone gets a scale of exactly 1"] = function()
	assert(ScaleMath.scaleFor(667, 375, SETTINGS) == 1, "landscape reference")
	assert(ScaleMath.scaleFor(375, 667, SETTINGS) == 1, "portrait reference")
end

tests["a phone smaller than the reference never drops below MIN"] = function()
	-- Keeps 44px touch targets at least 44 points.
	assert(ScaleMath.scaleFor(568, 320, SETTINGS) == 1, "small phone clamps to MIN")
end

tests["bigger screens scale by the tighter of the two sides"] = function()
	-- 844/667 = 1.265, 390/375 = 1.04: the short side limits it.
	assert(close(ScaleMath.scaleFor(844, 390, SETTINGS), 390 / 375), "wide phone")
	assert(close(ScaleMath.scaleFor(390, 844, SETTINGS), 390 / 375), "same phone upright")
end

tests["large monitors clamp to MAX"] = function()
	assert(ScaleMath.scaleFor(1920, 1080, SETTINGS) == 1.6, "1080p clamps to MAX")
	assert(ScaleMath.scaleFor(3840, 2160, SETTINGS) == 1.6, "4K clamps to MAX")
end

tests["a 0x0 viewport while loading uses MIN"] = function()
	assert(ScaleMath.scaleFor(0, 0, SETTINGS) == 1, "zero viewport")
end

return tests
