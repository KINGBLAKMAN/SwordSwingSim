--!strict
-- EggRules: pity counting and new pet records for egg opens (GDD A6, A7).
-- Pure, so Lune tests can check it; EggService applies it to profiles.

local Eggs = require(script.Parent.Parent.Config.Eggs)
local Pets = require(script.Parent.Parent.Config.Pets)
local ProfileTypes = require(script.Parent.Parent.Data.ProfileTypes)
local Rarities = require(script.Parent.Parent.Config.Rarities)

local EggRules = {}

local function rank(rarity: Rarities.Rarity): number
	return table.find(Rarities.ORDER, rarity) :: number
end

-- True if this pet counts for the egg's pity (pityMinRarity or rarer).
function EggRules.resetsPity(egg: Eggs.EggDef, petId: string): boolean
	return rank(Pets[petId].rarity) >= rank(egg.pityMinRarity)
end

-- Opens since the last pity-tier pet, after hatching petId.
function EggRules.nextPity(egg: Eggs.EggDef, opensSincePity: number, petId: string): number
	return if EggRules.resetsPity(egg, petId) then 0 else opensSincePity + 1
end

-- A freshly obtained pet: level 1, no traits yet, unlocked.
function EggRules.newPet(
	uid: string,
	petId: string,
	source: string,
	now: number
): ProfileTypes.PetInstance
	assert(Pets[petId], `EggRules.newPet: unknown pet "{petId}"`)
	return {
		uid = uid,
		id = petId,
		variant = "Normal",
		level = 1,
		xp = 0,
		traits = {},
		traitLocks = {},
		locked = false,
		obtainedAt = now,
		source = source,
	}
end

return EggRules
