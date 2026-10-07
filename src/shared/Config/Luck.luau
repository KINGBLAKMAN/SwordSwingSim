--!strict
-- Luck sources (GDD A6). Luck from every active source adds up. A paid
-- source is one players can buy with Robux; it's a paid modifier on every
-- roll it touches (TDD B11), so restricted players never get it.

export type LuckSource = { amount: number, paid: boolean }

local Luck = {
	SOURCES = {
		potion = { amount = 1.0, paid = true },
		pass = { amount = 0.5, paid = true },
		serverLuck = { amount = 1.0, paid = true },
		-- Per friend in the server.
		friend = { amount = 0.1, paid = false },
	} :: { [string]: LuckSource },
}

return table.freeze(Luck)
