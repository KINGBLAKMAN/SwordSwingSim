--!strict
-- PetMath: pet bonuses, Equip Best and delete rules (GDD A7). Pure, so Lune
-- tests can check it and the Pets screen shows the same numbers the server
-- uses.

local Pets = require(script.Parent.Parent.Config.Pets)
local ProfileTypes = require(script.Parent.Parent.Data.ProfileTypes)
local Rarities = require(script.Parent.Parent.Config.Rarities)

type PetInstance = ProfileTypes.PetInstance

local PetMath = {}

local function rarityRank(petId: string): number
	return table.find(Rarities.ORDER, Pets[petId].rarity) :: number
end

-- What one pet adds to the Energy multiplier.
function PetMath.energyBonus(pet: PetInstance): number
	return Pets[pet.id].energyBonus
end

-- Each equipped pet's bonus, for StatMath.petMultiplier. Uids that no
-- longer point at an owned pet are skipped.
function PetMath.equippedBonuses(pets: { [string]: PetInstance }, equipped: { string }): { number }
	local bonuses = {}
	for _, uid in equipped do
		local pet = pets[uid]
		if pet then
			table.insert(bonuses, PetMath.energyBonus(pet))
		end
	end
	return bonuses
end

-- True if a should come before b in "strongest first" order: higher
-- Energy bonus, then rarer, then newer. Locked pets count like any other.
function PetMath.isStronger(a: PetInstance, b: PetInstance): boolean
	local bonusA, bonusB = PetMath.energyBonus(a), PetMath.energyBonus(b)
	if bonusA ~= bonusB then
		return bonusA > bonusB
	end
	local rankA, rankB = rarityRank(a.id), rarityRank(b.id)
	if rankA ~= rankB then
		return rankA > rankB
	end
	if a.obtainedAt ~= b.obtainedAt then
		return a.obtainedAt > b.obtainedAt
	end
	-- Same everything: order by uid so the pick never flickers.
	return a.uid < b.uid
end

-- The uids Equip Best picks: the strongest pets, up to `slots`.
function PetMath.bestPets(pets: { [string]: PetInstance }, slots: number): { string }
	local list: { PetInstance } = {}
	for _, pet in pets do
		table.insert(list, pet)
	end
	table.sort(list, PetMath.isStronger)
	local best = {}
	for index = 1, math.min(slots, #list) do
		table.insert(best, list[index].uid)
	end
	return best
end

-- Why a pet can't be deleted, or nil if it can.
function PetMath.deleteBlocker(pet: PetInstance?, equipped: { string }): string?
	if pet == nil then
		return "not owned"
	elseif pet.locked then
		return "locked"
	elseif table.find(equipped, pet.uid) then
		return "equipped"
	end
	return nil
end

function PetMath.count(pets: { [string]: PetInstance }): number
	local count = 0
	for _ in pets do
		count += 1
	end
	return count
end

return PetMath
