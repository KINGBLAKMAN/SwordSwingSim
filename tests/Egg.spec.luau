local RojoRequire = require("./support/RojoRequire")

local EggRules = RojoRequire("src/shared/Util/EggRules")
local Eggs = RojoRequire("src/shared/Config/Eggs")
local OddsCalculator = RojoRequire("src/shared/Util/OddsCalculator")
local Settings = RojoRequire("src/shared/Config/Settings")

local tests = {}

local EGG = Eggs.ninja_village_egg

tests["island 1's egg costs 25 Coins"] = function()
	assert(EGG.cost == 25 and EGG.currency == "coins")
end

tests["pity counts up on commons and resets on Legendary or better"] = function()
	assert(EggRules.nextPity(EGG, 10, "kohai") == 11)
	assert(EggRules.nextPity(EGG, 10, "kaeru_jin") == 11, "Epic is below the pity tier")
	assert(EggRules.nextPity(EGG, 10, "utsushi") == 0, "Legendary resets")
	assert(EggRules.nextPity(EGG, 99, "karasu_ren") == 0, "Mythical resets")
end

tests["the 100th open without a Legendary only rolls Legendary or better"] = function()
	assert(not OddsCalculator.isPityOpen(EGG, 98))
	assert(OddsCalculator.isPityOpen(EGG, 99))
	for roll = 0, 0.999, 0.01 do
		local pet = OddsCalculator.roll(EGG, { pityActive = true }, roll)
		assert(EggRules.resetsPity(EGG, pet), `pity rolled {pet}`)
	end
end

tests["a new pet starts at level 1, unlocked, with the obtained time"] = function()
	local pet = EggRules.newPet("uid-1", "kohai", "Egg:ninja_village_egg", 1234)
	assert(pet.uid == "uid-1" and pet.id == "kohai" and pet.variant == "Normal")
	assert(pet.level == 1 and pet.xp == 0 and not pet.locked and pet.obtainedAt == 1234)
	assert(#pet.traits == 0 and #pet.traitLocks == 0)
end

-- The server rolls through OddsCalculator.roll and the board shows
-- OddsCalculator.display; over many opens the rolls land on the shown odds.
tests["10,000 rolls land on the shown odds at luck 0 and luck 2.6"] = function()
	math.randomseed(42)
	for _, luck in { 0, 2.6 } do
		local opens = 10000
		local counts = {}
		for _ = 1, opens do
			local pet = OddsCalculator.roll(EGG, { luck = luck }, math.random())
			counts[pet] = (counts[pet] or 0) + 1
		end
		for _, row in OddsCalculator.display(EGG, { luck = luck }).rows do
			local rate = (counts[row.pet] or 0) / opens
			local tolerance = 5 * math.sqrt(row.chance * (1 - row.chance) / opens) + 1e-4
			assert(
				math.abs(rate - row.chance) <= tolerance,
				`{row.pet} at luck {luck}: {rate} vs {row.chance}`
			)
		end
	end
end

tests["settings fall back to their defaults"] = function()
	assert(Settings.value({}, "skipHatchAnimation") == false)
	assert(Settings.value({ skipHatchAnimation = true }, "skipHatchAnimation") == true)
	assert(table.find(Settings.keys(), "skipHatchAnimation") ~= nil)
end

return tests
