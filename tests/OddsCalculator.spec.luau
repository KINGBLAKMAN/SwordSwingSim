local RojoRequire = require("./support/RojoRequire")

local Compliance = RojoRequire("src/shared/Config/Compliance")
local Eggs = RojoRequire("src/shared/Config/Eggs")
local Pets = RojoRequire("src/shared/Config/Pets")
local Rarities = RojoRequire("src/shared/Config/Rarities")
local OddsCalculator = RojoRequire("src/shared/Util/OddsCalculator")

local tests = {}

-- Luck values to check odds at: none, one pass, every source stacked
-- (potion + pass + server luck + 1 friend), and far past anything reachable.
local LUCK_LEVELS = { 0, 0.5, 2.6, 10 }

local function close(a: number, b: number, tolerance: number): boolean
	return math.abs(a - b) <= tolerance
end

local function rank(rarity: string): number
	return table.find(Rarities.ORDER, rarity) :: number
end

-- Every option set the odds are checked with: each luck level, pity on and off.
local function allOptions()
	local list = {}
	for _, luck in LUCK_LEVELS do
		table.insert(list, { luck = luck, pityActive = false })
		table.insert(list, { luck = luck, pityActive = true })
	end
	return list
end

tests["every egg's base weights add up to 100"] = function()
	for eggId, egg in Eggs do
		local total = 0
		for _, entry in egg.entries do
			total += entry.weight
		end
		assert(close(total, 100, 1e-9), `{eggId} weights add up to {total}`)
	end
end

tests["every egg's shown odds add up to exactly 100% with no luck"] = function()
	for eggId, egg in Eggs do
		local display = OddsCalculator.display(egg)
		local total = 0
		for _, row in display.rows do
			total += tonumber(string.sub(row.percent, 1, -2))
		end
		assert(close(total, 100, 1e-9), `{eggId} shows {total}%`)
		assert(not display.needsDisclaimer, `{eggId} shouldn't need the rounding disclaimer`)
	end
end

tests["every egg's odds add up to 100% at any luck, with or without pity"] = function()
	for eggId, egg in Eggs do
		for _, options in allOptions() do
			local total = 0
			for _, chance in OddsCalculator.odds(egg, options) do
				assert(chance.chance > 0, `{eggId} has a pet with no chance`)
				total += chance.chance
			end
			assert(close(total, 1, 1e-12), `{eggId} at luck {options.luck} adds up to {total}`)
		end
	end
end

tests["shown odds add up to 100% or come with the rounding disclaimer"] = function()
	for eggId, egg in Eggs do
		for _, options in allOptions() do
			local display = OddsCalculator.display(egg, options)
			local total = 0
			for _, row in display.rows do
				total += tonumber(string.sub(row.percent, 1, -2))
			end
			if not display.needsDisclaimer then
				assert(close(total, 100, 1e-9), `{eggId} shows {total}% with no disclaimer`)
			end
			-- Rounding to 5 significant digits can't drift far.
			assert(close(total, 100, 0.01), `{eggId} shows {total}%`)
		end
	end
end

tests["every egg entry is a real pet from the egg's island"] = function()
	for eggId, egg in Eggs do
		assert(#egg.entries > 0, `{eggId} has no pets`)
		for _, entry in egg.entries do
			local pet = Pets[entry.pet]
			assert(pet, `{eggId} lists unknown pet {entry.pet}`)
			assert(pet.island == egg.island, `{eggId} lists {entry.pet} from {pet.island}`)
			assert(entry.weight > 0, `{eggId} gives {entry.pet} no weight`)
		end
	end
end

tests["the roll lands on the pet whose shown odds cover it"] = function()
	-- The roll and the shown odds come from the same table, so a roll in
	-- the middle of a pet's slice of [0, 1) must give that pet.
	for eggId, egg in Eggs do
		for _, options in allOptions() do
			local sliceStart = 0
			for _, chance in OddsCalculator.odds(egg, options) do
				local middle = sliceStart + chance.chance / 2
				local rolled = OddsCalculator.roll(egg, options, middle)
				assert(
					rolled == chance.item,
					`{eggId} roll {middle} gave {rolled}, odds say {chance.item}`
				)
				sliceStart += chance.chance
			end
		end
	end
end

tests["sampled rolls match the shown odds"] = function()
	local egg = Eggs.ninja_village_egg
	local options = { luck = 2.6 }
	local samples = 200000
	local counts = {}
	math.randomseed(1)
	for _ = 1, samples do
		local pet = OddsCalculator.roll(egg, options, math.random())
		counts[pet] = (counts[pet] or 0) + 1
	end
	for _, chance in OddsCalculator.odds(egg, options) do
		local observed = (counts[chance.item] or 0) / samples
		-- About five standard deviations, so this only fails on a real mismatch.
		local tolerance = 5 * math.sqrt(chance.chance * (1 - chance.chance) / samples)
		assert(
			close(observed, chance.chance, tolerance),
			`{chance.item}: {observed} vs {chance.chance}`
		)
	end
end

tests["luck moves odds toward rarer pets"] = function()
	for eggId, egg in Eggs do
		local base = OddsCalculator.odds(egg, { luck = 0 })
		local lucky = OddsCalculator.odds(egg, { luck = 1 })
		for index, chance in base do
			local rarity = Pets[chance.item].rarity
			local sensitivity = Rarities.LUCK_SENSITIVITY[rarity]
			if sensitivity == 0 then
				assert(
					lucky[index].chance < chance.chance,
					`{eggId} {rarity} should drop with luck`
				)
			elseif rank(rarity) >= rank("Legendary") then
				assert(
					lucky[index].chance > chance.chance,
					`{eggId} {rarity} should rise with luck`
				)
			end
		end
	end
end

tests["pity opens only roll the egg's pity rarity or rarer"] = function()
	for eggId, egg in Eggs do
		local minRank = rank(egg.pityMinRarity)
		for _, chance in OddsCalculator.odds(egg, { pityActive = true }) do
			local rarity = Pets[chance.item].rarity
			assert(rank(rarity) >= minRank, `{eggId} pity can give {rarity}`)
		end
		for step = 0, 100 do
			local pet = OddsCalculator.roll(egg, { pityActive = true }, step / 100)
			assert(rank(Pets[pet].rarity) >= minRank, `{eggId} pity rolled {pet}`)
		end
	end
end

tests["pity comes due on the threshold open"] = function()
	local egg = Eggs.ninja_village_egg
	assert(not OddsCalculator.isPityOpen(egg, egg.pityThreshold - 2), "one open early")
	assert(OddsCalculator.isPityOpen(egg, egg.pityThreshold - 1), "the threshold open")
	assert(OddsCalculator.isPityOpen(egg, egg.pityThreshold), "past the threshold")
end

tests["percents keep the configured digits after the first non-zero digit"] = function()
	assert(Compliance.ODDS_DIGITS_AFTER_FIRST == 4, "update these cases if the digit count changes")
	local cases = {
		{ 0.3512, "35.12%" },
		{ 0.241, "24.1%" },
		{ 1, "100%" },
		{ 0.001, "0.1%" },
		{ 0.000012345, "0.0012345%" },
		{ 0.0000123456, "0.0012346%" },
		{ 1 / 3, "33.333%" },
		{ 0, "0%" },
	}
	for _, case in cases do
		local text = OddsCalculator.formatPercent(case[1])
		assert(text == case[2], `{case[1]} formatted as {text}, expected {case[2]}`)
	end
end

tests["negative luck is rejected"] = function()
	local ok = pcall(OddsCalculator.build, Eggs.ninja_village_egg, { luck = -1 })
	assert(not ok, "luck -1 should error")
end

return tests
