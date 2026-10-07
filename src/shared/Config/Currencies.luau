--!strict
-- Which currencies can be bought with Robux (GDD A5, TDD B11). A random
-- roll paid for with a Robux-buyable currency is a Paid Random Item, so
-- flipping one of these to true makes every egg that costs it PRI.

local Currencies = {
	ROBUX_PURCHASABLE = {
		energy = false,
		-- Open decision D5 #1: Coins stay non-purchasable, which keeps Coin
		-- eggs open to restricted players.
		coins = false,
		embers = false,
		-- GDD A5 lists Gems as "optional"; not sold yet.
		gems = false,
		tokens = false,
	} :: { [string]: boolean },
}

return table.freeze(Currencies)
