--!strict
-- CurrencyService: the single place currencies change (TDD B2). Every Coin,
-- Energy or Ember gained or spent goes through add() or trySpend(), so
-- economy analytics and income checks have one place to hook in.
--
-- energy, coins and embers are BigNums in profile.currencies.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BigNum = require(ReplicatedStorage.Shared.Util.BigNum)
local DataService = require(script.Parent.DataService)

export type BigCurrency = "energy" | "coins" | "embers"

local CurrencyService = {}

-- The player's balance, or zero if their profile isn't loaded.
function CurrencyService.get(player: Player, currency: BigCurrency): BigNum.BigNum
	local data = DataService.get(player)
	if data == nil then
		return BigNum.zero()
	end
	return data.currencies[currency]
end

-- Adds a positive amount. `source` says where it came from ("Click",
-- "Kill"...), for analytics.
function CurrencyService.add(
	player: Player,
	currency: BigCurrency,
	amount: BigNum.BigNum,
	_source: string
)
	assert(amount.m >= 0, "CurrencyService.add: amount can't be negative")
	if not DataService.isLoaded(player) then
		return
	end
	DataService.update(player, { "currencies", currency }, function(balance)
		return BigNum.add(balance, amount)
	end)
end

-- Spends amount if the player has it. Returns false, and changes nothing,
-- if they don't. `sink` says what it was spent on, for analytics.
function CurrencyService.trySpend(
	player: Player,
	currency: BigCurrency,
	amount: BigNum.BigNum,
	_sink: string
): boolean
	assert(amount.m >= 0, "CurrencyService.trySpend: amount can't be negative")
	if not DataService.isLoaded(player) then
		return false
	end
	local balance = CurrencyService.get(player, currency)
	if BigNum.lt(balance, amount) then
		return false
	end
	DataService.set(player, { "currencies", currency }, BigNum.sub(balance, amount))
	return true
end

return CurrencyService
