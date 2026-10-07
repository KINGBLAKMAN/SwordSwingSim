--!strict
-- Game passes and developer products (GDD A17, TDD B10).
--
-- `id` is the number from the Creator Dashboard. Leave it 0 until the item
-- exists there: the Store shows it as "Coming soon" and the server never
-- grants it.
--
-- Coins are never sold directly (Config/Currencies, D5 #1), so the x2
-- Coins pass only doubles Coins earned by playing and doesn't make Coin
-- eggs paid random items (TDD B11).

export type PassDef = {
	key: string,
	id: number,
	name: string,
	description: string,
	priceRobux: number,
}

export type ProductDef = {
	key: string,
	id: number,
	name: string,
	description: string,
	priceRobux: number,
	-- Energy granted per purchase.
	energy: number,
}

local Products = {
	PASSES = {
		x2_coins = {
			key = "x2_coins",
			id = 2016950295,
			name = "2x Coins",
			description = "Double the Coins from every enemy and quest, forever.",
			priceRobux = 199,
		},
	} :: { [string]: PassDef },

	PRODUCTS = {
		energy_pack = {
			key = "energy_pack",
			id = 3717145066,
			name = "Energy Pack",
			description = "+2,500 Energy right away.",
			priceRobux = 49,
			energy = 2500,
		},
	} :: { [string]: ProductDef },

	-- What owning x2 Coins multiplies Coin rewards by.
	X2_COINS_MULTIPLIER = 2,

	-- Granted purchase ids kept in the profile (TDD B3). Roblox only retries
	-- recent receipts, so older ones can go.
	MAX_RECEIPTS = 100,

	-- Player attribute listing owned pass keys (comma separated), so the
	-- Store can show "Owned".
	OWNED_PASSES_ATTRIBUTE = "OwnedPasses",
}

-- The product with this Creator Dashboard id, or nil. Ids of 0 never match.
function Products.productById(productId: number): ProductDef?
	for _, product in Products.PRODUCTS do
		if product.id ~= 0 and product.id == productId then
			return product
		end
	end
	return nil
end

function Products.passById(passId: number): PassDef?
	for _, pass in Products.PASSES do
		if pass.id ~= 0 and pass.id == passId then
			return pass
		end
	end
	return nil
end

return table.freeze(Products)
