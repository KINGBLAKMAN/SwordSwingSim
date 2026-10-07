--!strict
-- PaidRandomRules: the Paid Random Item rules from TDD B11, kept free of
-- Roblox services so Lune tests can check them. ComplianceService applies
-- them to real players.
--
-- A roll is a Paid Random Item when Robux can reach it: its cost is a
-- Robux-buyable currency, or a paid modifier (like bought luck) changes its
-- odds. In regions where PolicyService says paid random items are
-- restricted, players must not reach either path.
--
-- How this game follows that: an egg priced in a Robux-buyable currency is
-- closed to restricted players, and paid luck is left out of their rolls.
-- What's left for them is a free roll with free luck only.

local Currencies = require(script.Parent.Parent.Config.Currencies)
local Eggs = require(script.Parent.Parent.Config.Eggs)
local Luck = require(script.Parent.Parent.Config.Luck)
local Rarities = require(script.Parent.Parent.Config.Rarities)
local Pets = require(script.Parent.Parent.Config.Pets)

export type PolicyState = {
	paidRandomRestricted: boolean,
	paidTradingAllowed: boolean,
}

-- The fields of PolicyService:GetPolicyInfoForPlayerAsync's result this
-- game reads.
export type PolicyInfo = {
	ArePaidRandomItemsRestricted: boolean,
	IsPaidItemTradingAllowed: boolean,
}

local PaidRandomRules = {}

-- Turns a PolicyService lookup into this game's policy state. A failed
-- lookup counts as restricted, with no paid trading: when in doubt, the
-- safe answer (TDD B11).
function PaidRandomRules.policyState(lookupOk: boolean, info: PolicyInfo?): PolicyState
	if not lookupOk or info == nil then
		return { paidRandomRestricted = true, paidTradingAllowed = false }
	end
	return {
		paidRandomRestricted = info.ArePaidRandomItemsRestricted,
		paidTradingAllowed = info.IsPaidItemTradingAllowed,
	}
end

-- The state used before a player's lookup has finished.
PaidRandomRules.UNKNOWN_STATE = table.freeze(PaidRandomRules.policyState(false, nil))

-- A currency missing from Config/Currencies counts as Robux-buyable, so a
-- new currency stays locked for restricted players until someone lists it.
function PaidRandomRules.isCurrencyPurchasable(currency: string): boolean
	return Currencies.ROBUX_PURCHASABLE[currency] ~= false
end

local function anyPaidLuckSource(): boolean
	for _, source in Luck.SOURCES do
		if source.paid then
			return true
		end
	end
	return false
end

-- True if luck changes this egg's odds at all, i.e. some pet in it has a
-- rarity luck boosts.
local function luckChangesOdds(egg: Eggs.EggDef): boolean
	for _, entry in egg.entries do
		if Rarities.LUCK_SENSITIVITY[Pets[entry.pet].rarity] > 0 then
			return true
		end
	end
	return false
end

-- Whether Robux can reach this egg's roll, worked out from config. Each
-- egg's paidRandom tag must match this (a test checks).
function PaidRandomRules.isPaidRandom(egg: Eggs.EggDef): boolean
	return PaidRandomRules.isCurrencyPurchasable(egg.currency)
		or (anyPaidLuckSource() and luckChangesOdds(egg))
end

-- Whether a player may open the egg at all. Restricted players can't open
-- eggs priced in a Robux-buyable currency.
function PaidRandomRules.canOpenEgg(egg: Eggs.EggDef, paidRandomRestricted: boolean): boolean
	return not (paidRandomRestricted and PaidRandomRules.isCurrencyPurchasable(egg.currency))
end

-- Adds up luck from the active sources, given as source id -> how many
-- (1 for a potion or pass, the friend count for friends). Paid sources
-- count only for players who aren't restricted.
function PaidRandomRules.luckFor(
	activeSources: { [string]: number },
	paidRandomRestricted: boolean
): number
	local total = 0
	for sourceId, count in activeSources do
		local source = Luck.SOURCES[sourceId]
		assert(source, `PaidRandomRules.luckFor: unknown luck source "{sourceId}"`)
		if not (source.paid and paidRandomRestricted) then
			total += source.amount * count
		end
	end
	return total
end

return PaidRandomRules
