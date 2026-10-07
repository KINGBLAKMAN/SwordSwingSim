--!strict
-- WeightedRandom: picks one entry from a list where each entry has a weight,
-- e.g. egg rarity tiers (GDD A6). An entry with weight 2 comes up twice as
-- often as one with weight 1. Weights don't need to add up to 100.
--
-- The caller passes in the roll (a number in [0, 1)) instead of this module
-- calling random itself. The server owns RNG with a Random per player (TDD
-- B7), and tests can pass exact rolls.

export type Entry<T> = { item: T, weight: number }
export type Table<T> = { entries: { Entry<T> }, total: number }
export type Chance<T> = { item: T, chance: number }

local WeightedRandom = {}

-- Builds a frozen table from entries. Every weight must be a finite number
-- above zero; leave an entry out to disable it.
function WeightedRandom.new<T>(entries: { Entry<T> }): Table<T>
	assert(#entries > 0, "WeightedRandom.new needs at least one entry")

	local copied: { Entry<T> } = {}
	local total = 0
	for index, entry in entries do
		local weight = entry.weight
		local isValid = typeof(weight) == "number" and weight > 0 and weight < math.huge
		assert(isValid, `WeightedRandom entry {index} has a bad weight: {weight}`)

		table.insert(copied, table.freeze({ item = entry.item, weight = weight }))
		total += weight
	end

	return table.freeze({ entries = table.freeze(copied), total = total })
end

-- Picks an entry. roll is in [0, 1), like Random:NextNumber() or
-- math.random(). Walks the entries, adding up weights, until the running
-- total passes roll × total.
function WeightedRandom.pick<T>(weighted: Table<T>, roll: number): T
	assert(roll >= 0 and roll <= 1, `WeightedRandom.pick needs a roll in [0, 1], got {roll}`)

	local target = roll * weighted.total
	local runningTotal = 0
	for _, entry in weighted.entries do
		runningTotal += entry.weight
		if target < runningTotal then
			return entry.item
		end
	end

	-- Only reached when roll is 1 or float rounding leaves runningTotal a
	-- hair under target. The last entry owns the top of the range.
	return weighted.entries[#weighted.entries].item
end

-- Each entry's chance from 0 to 1, in entry order. Use this for odds shown
-- in the UI so they match what pick() does.
function WeightedRandom.probabilities<T>(weighted: Table<T>): { Chance<T> }
	local chances: { Chance<T> } = {}
	for _, entry in weighted.entries do
		table.insert(chances, { item = entry.item, chance = entry.weight / weighted.total })
	end
	return chances
end

return WeightedRandom
