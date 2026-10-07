--!strict
-- StatMath: the formulas behind a player's multipliers (GDD A4, A7, A10).
-- Pure math, so the server and the client UI work numbers out the same way
-- and Lune tests can check them. StatService feeds it a player's data.

local Combat = require(script.Parent.Parent.Config.Combat)
local Rebirth = require(script.Parent.Parent.Config.Rebirth)

local StatMath = {}

-- Rebirth multiplier with `rebirths` owned:
-- (1 + STEP × r) × KICKER ^ floor(r / KICKER_EVERY).
function StatMath.rebirthMultiplier(rebirths: number): number
	local linear = 1 + Rebirth.STEP * rebirths
	local kicker = Rebirth.KICKER ^ (rebirths // Rebirth.KICKER_EVERY)
	return linear * kicker
end

-- Pet multiplier from each equipped pet's bonus. Bonuses add together
-- (GDD decision 3): 1 + the sum.
function StatMath.petMultiplier(bonuses: { number }): number
	local total = 1
	for _, bonus in bonuses do
		total += bonus
	end
	return total
end

-- Energy one click earns.
function StatMath.energyPerClick(petMultiplier: number, rebirthMultiplier: number): number
	return Combat.BASE_ENERGY_PER_CLICK * petMultiplier * rebirthMultiplier
end

return StatMath
