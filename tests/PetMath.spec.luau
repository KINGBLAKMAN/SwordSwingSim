local RojoRequire = require("./support/RojoRequire")

local EggRules = RojoRequire("src/shared/Util/EggRules")
local PetMath = RojoRequire("src/shared/Util/PetMath")
local Pets = RojoRequire("src/shared/Config/Pets")
local StatMath = RojoRequire("src/shared/Util/StatMath")

local tests = {}

-- A small inventory: uid -> pet, made the same way the server makes them.
local function inventory(list: { { string } })
	local pets = {}
	for index, entry in list do
		local uid, petId = entry[1], entry[2]
		pets[uid] = EggRules.newPet(uid, petId, "test", index)
	end
	return pets
end

tests["equipped pets add their bonuses to the Energy multiplier"] = function()
	local pets = inventory({ { "a", "kohai" }, { "b", "karasu_ren" } })
	local bonuses = PetMath.equippedBonuses(pets, { "a", "b", "gone" })
	assert(#bonuses == 2, "a uid that isn't owned is skipped")
	local expected = 1 + Pets.kohai.energyBonus + Pets.karasu_ren.energyBonus
	assert(StatMath.petMultiplier(bonuses) == expected)
end

tests["Equip Best picks the strongest pets up to the slot count"] = function()
	local pets = inventory({
		{ "common", "kohai" },
		{ "secret", "kurai" },
		{ "rare", "elder_kurogane" },
		{ "mythical", "karasu_ren" },
	})
	local best = PetMath.bestPets(pets, 3)
	assert(#best == 3)
	assert(best[1] == "secret" and best[2] == "mythical" and best[3] == "rare")
	assert(#PetMath.bestPets(pets, 10) == 4, "never more than the pets owned")
	assert(#PetMath.bestPets({}, 3) == 0)
end

tests["ties go to the newer pet, then the uid, so Equip Best never flickers"] = function()
	local pets = inventory({ { "old", "kohai" }, { "new", "kohai" } })
	assert(PetMath.isStronger(pets.new, pets.old))
	assert(not PetMath.isStronger(pets.old, pets.new))
	pets.old.obtainedAt = pets.new.obtainedAt
	assert(PetMath.isStronger(pets.new, pets.old) == ("new" < "old"))
end

tests["locked, equipped and unowned pets can't be deleted"] = function()
	local pets = inventory({ { "a", "kohai" }, { "b", "kohai" }, { "c", "kohai" } })
	pets.b.locked = true
	assert(PetMath.deleteBlocker(pets.a, { "c" }) == nil)
	assert(PetMath.deleteBlocker(pets.b, { "c" }) == "locked")
	assert(PetMath.deleteBlocker(pets.c, { "c" }) == "equipped")
	assert(PetMath.deleteBlocker(nil, {}) == "not owned")
end

tests["the inventory lists equipped pets first, then strongest, and filters by rarity"] = function()
	local pets = inventory({
		{ "weak", "kohai" },
		{ "strong", "karasu_ren" },
		{ "epic", "kaeru_jin" },
		{ "weak2", "kohai" },
	})
	local list = PetMath.inventoryList(pets, { "weak" })
	assert(list[1].uid == "weak" and list[2].uid == "strong" and list[3].uid == "epic")
	local commons = PetMath.inventoryList(pets, {}, "Common")
	assert(#commons == 2 and commons[1].uid == "weak2", "newer first among equals")
	local owned = PetMath.ownedRarities(pets)
	assert(#owned == 3 and owned[1] == "Common" and owned[2] == "Epic" and owned[3] == "Mythical")
	assert(PetMath.count(pets) == 4)
end

return tests
