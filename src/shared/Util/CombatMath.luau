--!strict
-- CombatMath: damage and kill credit (GDD A4, A9). Pure, so Lune tests can
-- check it; CombatService rolls the crit and passes the result in.

local Combat = require(script.Parent.Parent.Config.Combat)
local EnemySpawning = require(script.Parent.Parent.Config.EnemySpawning)

local CombatMath = {}

-- Damage of one hit: Energy × DAMAGE_PER_ENERGY × sword multiplier, times
-- CRIT_MULT on a crit.
function CombatMath.damagePerHit(energy: number, swordMultiplier: number, isCrit: boolean): number
	local damage = energy * Combat.DAMAGE_PER_ENERGY * swordMultiplier
	if isCrit then
		damage *= Combat.CRIT_MULT
	end
	return damage
end

-- True when a roll in [0, 1) lands a crit.
function CombatMath.isCrit(roll: number, critChance: number): boolean
	return roll < critChance
end

-- Everyone in damageBy who dealt at least KILL_CREDIT_SHARE of maxHp.
function CombatMath.creditedPlayers<K>(damageBy: { [K]: number }, maxHp: number): { K }
	local credited: { K } = {}
	local needed = maxHp * EnemySpawning.KILL_CREDIT_SHARE
	for key, damage in damageBy do
		if damage >= needed then
			table.insert(credited, key)
		end
	end
	return credited
end

return CombatMath
