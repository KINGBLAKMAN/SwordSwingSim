--!strict
-- ScaleMath: picks the UIScale for a screen size (TDD B9). Pure, so Lune
-- tests can check it; App feeds it the camera's viewport size.
--
-- It compares the screen's long side with the reference long side and its
-- short side with the reference short side, so a phone held upright and one
-- held sideways get the same scale. The smaller ratio wins so nothing runs
-- off screen, then the result is clamped. The minimum of 1 is what keeps a
-- 44px button at least 44 points on every phone.

export type Settings = {
	REFERENCE_LONG_SIDE: number,
	REFERENCE_SHORT_SIDE: number,
	MIN: number,
	MAX: number,
}

local ScaleMath = {}

function ScaleMath.scaleFor(width: number, height: number, settings: Settings): number
	if width <= 0 or height <= 0 then
		-- The viewport reads 0x0 for a frame or two while the game loads.
		return settings.MIN
	end
	local longRatio = math.max(width, height) / settings.REFERENCE_LONG_SIDE
	local shortRatio = math.min(width, height) / settings.REFERENCE_SHORT_SIDE
	return math.clamp(math.min(longRatio, shortRatio), settings.MIN, settings.MAX)
end

return ScaleMath
