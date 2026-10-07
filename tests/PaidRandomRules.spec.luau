local RojoRequire = require("./support/RojoRequire")

local Currencies = RojoRequire("src/shared/Config/Currencies")
local Eggs = RojoRequire("src/shared/Config/Eggs")
local Luck = RojoRequire("src/shared/Config/Luck")
local OddsCalculator = RojoRequire("src/shared/Util/OddsCalculator")
local PaidRandomRules = RojoRequire("src/shared/Util/PaidRandomRules")

local tests = {}

-- Every luck source switched on, with three friends in the server.
local function everySource(): { [string]: number }
	local sources = {}
	for sourceId in Luck.SOURCES do
		sources[sourceId] = 1
	end
	sources.friend = 3
	return sources
end

-- Only the sources nobody can buy.
local function freeSources(): { [string]: number }
	local sources = {}
	for sourceId, count in everySource() do
		if not Luck.SOURCES[sourceId].paid then
			sources[sourceId] = count
		end
	end
	return sources
end

local function sameOdds(a, b): boolean
	for index, chance in a do
		if chance.item ~= b[index].item or math.abs(chance.chance - b[index].chance) > 1e-12 then
			return false
		end
	end
	return #a == #b
end

-- A copy of an egg priced in another currency.
local function pricedIn(egg, currency: string)
	local copy = table.clone(egg)
	copy.currency = currency
	return copy
end

tests["a failed policy lookup counts as restricted with no trading"] = function()
	local state = PaidRandomRules.policyState(false, nil)
	assert(state.paidRandomRestricted, "should be restricted")
	assert(not state.paidTradingAllowed, "shouldn't allow trading")

	local unknown = PaidRandomRules.UNKNOWN_STATE
	assert(
		unknown.paidRandomRestricted and not unknown.paidTradingAllowed,
		"unknown state should be restricted"
	)
end

tests["a successful policy lookup is passed through"] = function()
	local open = PaidRandomRules.policyState(true, {
		ArePaidRandomItemsRestricted = false,
		IsPaidItemTradingAllowed = true,
	})
	assert(not open.paidRandomRestricted and open.paidTradingAllowed, "unrestricted player")

	local restricted = PaidRandomRules.policyState(true, {
		ArePaidRandomItemsRestricted = true,
		IsPaidItemTradingAllowed = false,
	})
	assert(
		restricted.paidRandomRestricted and not restricted.paidTradingAllowed,
		"restricted player"
	)
end

tests["restricted players get no luck from paid sources"] = function()
	local expected = 0
	for sourceId, count in freeSources() do
		expected += Luck.SOURCES[sourceId].amount * count
	end
	local luck = PaidRandomRules.luckFor(everySource(), true)
	assert(math.abs(luck - expected) < 1e-12, `restricted luck is {luck}, expected {expected}`)

	local paidOnly = { potion = 1, pass = 1, serverLuck = 1 }
	assert(
		PaidRandomRules.luckFor(paidOnly, true) == 0,
		"paid sources alone give a restricted player luck"
	)
	assert(
		PaidRandomRules.luckFor(paidOnly, false) > 0,
		"paid sources should count for everyone else"
	)
end

tests["a restricted player's odds are the free-luck odds on every egg"] = function()
	local freeLuck = PaidRandomRules.luckFor(freeSources(), false)
	for eggId, egg in Eggs do
		local restrictedOdds =
			OddsCalculator.odds(egg, { luck = PaidRandomRules.luckFor(everySource(), true) })
		local freeOdds = OddsCalculator.odds(egg, { luck = freeLuck })
		assert(
			sameOdds(restrictedOdds, freeOdds),
			`{eggId}: paid luck reached a restricted player's odds`
		)

		-- And paid luck does change the odds for everyone else, so the
		-- check above means something.
		local paidOdds =
			OddsCalculator.odds(egg, { luck = PaidRandomRules.luckFor(everySource(), false) })
		assert(
			not sameOdds(paidOdds, freeOdds),
			`{eggId}: paid luck should change unrestricted odds`
		)
	end
end

tests["restricted players can't open eggs priced in a Robux-buyable currency"] = function()
	local egg = Eggs.ninja_village_egg
	-- Not listed in Config/Currencies, so it counts as Robux-buyable.
	local paidEgg = pricedIn(egg, "unlisted_currency")
	assert(not PaidRandomRules.canOpenEgg(paidEgg, true), "restricted player opened a paid egg")
	assert(PaidRandomRules.canOpenEgg(paidEgg, false), "unrestricted player should open a paid egg")

	for currency, purchasable in Currencies.ROBUX_PURCHASABLE do
		local canOpen = PaidRandomRules.canOpenEgg(pricedIn(egg, currency), true)
		assert(canOpen == not purchasable, `{currency} egg: restricted canOpen is {canOpen}`)
	end
end

tests["no egg's random roll is reachable with Robux by a restricted player"] = function()
	for eggId, egg in Eggs do
		if PaidRandomRules.canOpenEgg(egg, true) then
			assert(
				not PaidRandomRules.isCurrencyPurchasable(egg.currency),
				`{eggId} is open but Robux-priced`
			)
		end
	end
end

tests["every egg's currency is listed in Config/Currencies"] = function()
	for eggId, egg in Eggs do
		assert(
			Currencies.ROBUX_PURCHASABLE[egg.currency] ~= nil,
			`{eggId} costs unlisted {egg.currency}`
		)
	end
end

tests["every egg's paidRandom tag matches the rules"] = function()
	for eggId, egg in Eggs do
		local expected = PaidRandomRules.isPaidRandom(egg)
		assert(
			egg.paidRandom == expected,
			`{eggId} paidRandom is {egg.paidRandom}, rules say {expected}`
		)
	end
end

tests["an unknown luck source is an error"] = function()
	local ok = pcall(PaidRandomRules.luckFor, { madeUp = 1 }, false)
	assert(not ok, "unknown luck source should error")
end

return tests
