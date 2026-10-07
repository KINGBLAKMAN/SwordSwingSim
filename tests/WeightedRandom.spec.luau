local WeightedRandom = require("../src/shared/Util/WeightedRandom")

local tests = {}

-- Egg tier base weights from GDD A6, including the optional Secret tier.
local EGG_WEIGHTS = {
	{ item = "Common", weight = 35.12 },
	{ item = "Uncommon", weight = 30.99 },
	{ item = "Rare", weight = 24.10 },
	{ item = "Epic", weight = 8.37 },
	{ item = "Legendary", weight = 1.32 },
	{ item = "Mythical", weight = 0.10 },
	{ item = "Secret", weight = 0.001 },
}

tests["roll 0 gives the first entry and roll 1 the last"] = function()
	local weighted = WeightedRandom.new(EGG_WEIGHTS)
	assert(WeightedRandom.pick(weighted, 0) == "Common", "roll 0")
	assert(WeightedRandom.pick(weighted, 0.999999999) == "Secret", "roll just under 1")
	assert(WeightedRandom.pick(weighted, 1) == "Secret", "roll 1")
end

tests["each entry owns a slice the size of its weight"] = function()
	local weighted = WeightedRandom.new({
		{ item = "a", weight = 1 },
		{ item = "b", weight = 2 },
		{ item = "c", weight = 1 },
	})
	-- Slices: a = [0, 0.25), b = [0.25, 0.75), c = [0.75, 1).
	assert(WeightedRandom.pick(weighted, 0.2499) == "a", "end of a")
	assert(WeightedRandom.pick(weighted, 0.25) == "b", "start of b")
	assert(WeightedRandom.pick(weighted, 0.7499) == "b", "end of b")
	assert(WeightedRandom.pick(weighted, 0.75) == "c", "start of c")
end

tests["a single entry always wins"] = function()
	local weighted = WeightedRandom.new({ { item = "only", weight = 0.5 } })
	for _, roll in { 0, 0.5, 1 } do
		assert(WeightedRandom.pick(weighted, roll) == "only", `roll {roll}`)
	end
end

tests["rejects bad weights, empty lists and bad rolls"] = function()
	local badWeights = { 0, -1, 0 / 0, math.huge }
	for _, weight in badWeights do
		local ok = pcall(WeightedRandom.new, { { item = "x", weight = weight } })
		assert(not ok, `weight {weight} should be refused`)
	end
	assert(not pcall(WeightedRandom.new, {}), "empty list refused")

	local weighted = WeightedRandom.new(EGG_WEIGHTS)
	for _, roll in { -0.1, 1.5, 0 / 0 } do
		assert(not pcall(WeightedRandom.pick, weighted, roll), `roll {roll} refused`)
	end
end

tests["the table is frozen so config can't be changed after building"] = function()
	local weighted = WeightedRandom.new(EGG_WEIGHTS)
	assert(table.isfrozen(weighted), "table frozen")
	assert(table.isfrozen(weighted.entries), "entries frozen")
	assert(table.isfrozen(weighted.entries[1]), "each entry frozen")
end

tests["probabilities add up to 1 and match the weights"] = function()
	local weighted = WeightedRandom.new(EGG_WEIGHTS)
	local chances = WeightedRandom.probabilities(weighted)
	local sum = 0
	for index, chance in chances do
		assert(chance.item == EGG_WEIGHTS[index].item, "same order as the entries")
		sum += chance.chance
	end
	assert(math.abs(sum - 1) < 1e-12, `chances sum to {sum}`)
	assert(math.abs(chances[1].chance - 35.12 / 100.001) < 1e-12, "Common chance")
end

-- Chi-squared goodness-of-fit: rolls 1,000,000 eggs and checks the tier
-- counts against the expected counts. With 7 tiers there are 6 degrees of
-- freedom; a fair picker scores above 22.458 only 0.1% of the time. The
-- seed is fixed so the test gives the same answer on every run.
tests["chi-squared over 1,000,000 rolls matches the GDD A6 weights"] = function()
	local ROLLS = 1_000_000
	local CRITICAL_VALUE = 22.458 -- df = 6, p = 0.001

	local weighted = WeightedRandom.new(EGG_WEIGHTS)
	math.randomseed(20261007)

	local counts: { [string]: number } = {}
	for _ = 1, ROLLS do
		local tier = WeightedRandom.pick(weighted, math.random())
		counts[tier] = (counts[tier] or 0) + 1
	end

	local chiSquared = 0
	for _, chance in WeightedRandom.probabilities(weighted) do
		local expected = chance.chance * ROLLS
		local observed = counts[chance.item] or 0
		chiSquared += (observed - expected) ^ 2 / expected
	end

	assert(
		chiSquared < CRITICAL_VALUE,
		`chi-squared {chiSquared} is above {CRITICAL_VALUE}: the picker is skewed`
	)
end

tests["chi-squared catches a skewed picker"] = function()
	-- Sanity check on the test above: the same check against the wrong
	-- weights (Common and Uncommon swapped) must fail.
	local weighted = WeightedRandom.new(EGG_WEIGHTS)
	local swapped = table.clone(EGG_WEIGHTS)
	swapped[1], swapped[2] =
		{ item = "Common", weight = 30.99 }, { item = "Uncommon", weight = 35.12 }
	local wrong = WeightedRandom.new(swapped)

	math.randomseed(1)
	local ROLLS = 100_000
	local counts: { [string]: number } = {}
	for _ = 1, ROLLS do
		local tier = WeightedRandom.pick(weighted, math.random())
		counts[tier] = (counts[tier] or 0) + 1
	end

	local chiSquared = 0
	for _, chance in WeightedRandom.probabilities(wrong) do
		local expected = chance.chance * ROLLS
		chiSquared += ((counts[chance.item] or 0) - expected) ^ 2 / expected
	end
	assert(chiSquared > 22.458, `skewed picker scored only {chiSquared}`)
end

return tests
