-- Cross-checks between the generated config modules (tools/gen_config.py):
-- every id one module points at must exist in the module it names.

local RojoRequire = require("./support/RojoRequire")

local Eggs = RojoRequire("src/shared/Config/Eggs")
local Enemies = RojoRequire("src/shared/Config/Enemies")
local Islands = RojoRequire("src/shared/Config/Islands")
local Pets = RojoRequire("src/shared/Config/Pets")
local Rarities = RojoRequire("src/shared/Config/Rarities")
local Traits = RojoRequire("src/shared/Config/Traits")

local tests = {}

tests["each island's egg exists and belongs to that island"] = function()
	for islandId, island in Islands do
		local egg = Eggs[island.egg]
		assert(egg ~= nil, `{islandId} egg {island.egg} is missing`)
		assert(egg.island == islandId, `{island.egg} belongs to {egg.island}, not {islandId}`)
	end
end

tests["island numbers run 1, 2, 3 with only island 1 free"] = function()
	local count = 0
	for _ in Islands do
		count += 1
	end
	for number = 1, count do
		local found = nil
		for _, island in Islands do
			if island.number == number then
				found = island
			end
		end
		assert(found ~= nil, `no island number {number}`)
		if number == 1 then
			assert(found.unlockCost == 0, "island 1 should be free")
		else
			assert(found.unlockCost > 0, `{found.id} should cost something to unlock`)
		end
	end
end

tests["egg entries are pets from the egg's own island"] = function()
	for eggId, egg in Eggs do
		for _, entry in egg.entries do
			local pet = Pets[entry.pet]
			assert(pet ~= nil, `{eggId} has unknown pet {entry.pet}`)
			assert(
				pet.island == egg.island,
				`{entry.pet} is from {pet.island}, egg is {egg.island}`
			)
		end
	end
end

tests["enemies sit on known islands and drop known pets"] = function()
	for enemyId, enemy in Enemies do
		assert(Islands[enemy.island] ~= nil, `{enemyId} is on unknown island {enemy.island}`)
		assert(Pets[enemy.pet] ~= nil, `{enemyId} drops unknown pet {enemy.pet}`)
		assert(enemy.hp > 0, `{enemyId} has no HP`)
	end
end

tests["pets have a known rarity, island and a positive Energy bonus"] = function()
	for petId, pet in Pets do
		assert(table.find(Rarities.ORDER, pet.rarity) ~= nil, `{petId} rarity {pet.rarity}`)
		assert(Islands[pet.island] ~= nil, `{petId} is on unknown island {pet.island}`)
		assert(pet.energyBonus > 0, `{petId} energyBonus is {pet.energyBonus}`)
	end
end

tests["every trait tier has a positive weight"] = function()
	for _, tier in Traits.ORDER do
		assert((Traits.WEIGHTS[tier] or 0) > 0, `trait tier {tier} has no weight`)
	end
	assert(Traits.HARD_PITY_REROLLS > 0, "hard pity should be positive")
end

return tests
