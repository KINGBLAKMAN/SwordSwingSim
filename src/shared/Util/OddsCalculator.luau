--!strict
-- OddsCalculator: the one place egg odds come from (TDD B11, GDD A6).
--
-- The odds a player sees and the roll the server makes both go through
-- build() below, so they can't drift apart. The client calls odds() or
-- display() to draw the odds list; the server calls roll() with its own RNG.
--
-- Luck: each pet's weight becomes weight × (1 + luck × sensitivity), where
-- sensitivity comes from its rarity (Config/Rarities). Commons don't move;
-- rarer pets move more. Pity: once it's due, only pets of the egg's
-- pityMinRarity or rarer can come up.
--
-- Callers work out luck themselves. On the server it must come from
-- ComplianceService.luckFor, which leaves out paid luck for players who
-- can't have it.

local Compliance = require(script.Parent.Parent.Config.Compliance)
local Eggs = require(script.Parent.Parent.Config.Eggs)
local Pets = require(script.Parent.Parent.Config.Pets)
local Rarities = require(script.Parent.Parent.Config.Rarities)
local WeightedRandom = require(script.Parent.WeightedRandom)

type EggDef = Eggs.EggDef

export type Options = {
	-- Total luck from the player's sources. The egg's own bonusLuck is
	-- added on top. Defaults to 0.
	luck: number?,
	-- True when this open is the pity open (see isPityOpen).
	pityActive: boolean?,
}

export type DisplayRow = {
	pet: string,
	name: string,
	rarity: Rarities.Rarity,
	-- From 0 to 1, unrounded.
	chance: number,
	-- Rounded for the UI, e.g. "35.12%".
	percent: string,
}

export type Display = {
	rows: { DisplayRow },
	-- True when the rounded percents don't add up to exactly 100, so the UI
	-- must show Compliance.ROUNDING_DISCLAIMER.
	needsDisclaimer: boolean,
}

local OddsCalculator = {}

-- Position of each rarity in Rarities.ORDER, lowest first.
local rarityRank: { [string]: number } = {}
for rank, rarity in Rarities.ORDER do
	rarityRank[rarity] = rank
end

local function rarityOf(petId: string): Rarities.Rarity
	local pet = Pets[petId]
	assert(pet, `OddsCalculator: unknown pet "{petId}"`)
	return pet.rarity
end

-- The weighted table every odds number and roll comes from.
function OddsCalculator.build(egg: EggDef, options: Options?): WeightedRandom.Table<string>
	local luck = (if options and options.luck then options.luck else 0) + egg.bonusLuck
	assert(luck >= 0, `OddsCalculator: luck can't be negative, got {luck}`)
	local pityActive = options ~= nil and options.pityActive == true
	local minRank = rarityRank[egg.pityMinRarity]

	local entries: { WeightedRandom.Entry<string> } = {}
	for _, entry in egg.entries do
		local rarity: Rarities.Rarity = rarityOf(entry.pet)
		local allowed = not pityActive or rarityRank[rarity] >= minRank
		if allowed then
			local weight = entry.weight * (1 + luck * Rarities.LUCK_SENSITIVITY[rarity])
			table.insert(entries, { item = entry.pet, weight = weight })
		end
	end

	assert(#entries > 0, `OddsCalculator: egg "{egg.id}" has no {egg.pityMinRarity}+ pet for pity`)
	return WeightedRandom.new(entries)
end

-- Each pet's chance from 0 to 1, in the egg's entry order.
function OddsCalculator.odds(egg: EggDef, options: Options?): { WeightedRandom.Chance<string> }
	return WeightedRandom.probabilities(OddsCalculator.build(egg, options))
end

-- Picks a pet id. Server only: roll is a number in [0, 1) from the
-- player's server-side Random (TDD B7).
function OddsCalculator.roll(egg: EggDef, options: Options?, roll: number): string
	return WeightedRandom.pick(OddsCalculator.build(egg, options), roll)
end

-- True if the next open is the pity open, given the opens since the player
-- last hatched a pet of pityMinRarity or rarer (Profile.pity[egg.id]).
function OddsCalculator.isPityOpen(egg: EggDef, opensSincePity: number): boolean
	return opensSincePity + 1 >= egg.pityThreshold
end

-- Formats a chance (0 to 1) as a percent with ODDS_DIGITS_AFTER_FIRST digits
-- after the first non-zero digit, trailing zeros dropped: 0.3512 -> "35.12%",
-- 0.000012345 -> "0.0012345%".
function OddsCalculator.formatPercent(chance: number): string
	local percent = chance * 100
	if percent <= 0 then
		return "0%"
	end

	local firstDigitPlace = math.floor(math.log10(percent))
	local decimals = math.max(0, Compliance.ODDS_DIGITS_AFTER_FIRST - firstDigitPlace)
	local text = string.format(`%.{decimals}f`, percent)
	if string.find(text, ".", 1, true) then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end
	return text .. "%"
end

-- The odds list for the UI: one row per pet with its rounded percent.
function OddsCalculator.display(egg: EggDef, options: Options?): Display
	local rows: { DisplayRow } = {}
	local roundedTotal = 0
	for _, chance in OddsCalculator.odds(egg, options) do
		local pet = Pets[chance.item]
		local percent = OddsCalculator.formatPercent(chance.chance)
		roundedTotal += tonumber(string.sub(percent, 1, -2)) :: number
		table.insert(rows, {
			pet = pet.id,
			name = pet.name,
			rarity = pet.rarity,
			chance = chance.chance,
			percent = percent,
		})
	end

	-- Float sums of exact decimals can land a hair off 100, so allow for that.
	local needsDisclaimer = math.abs(roundedTotal - 100) > 1e-9
	return { rows = rows, needsDisclaimer = needsDisclaimer }
end

return OddsCalculator
