local RojoRequire = require("./support/RojoRequire")

local Products = RojoRequire("src/shared/Config/Products")
local ReceiptRules = RojoRequire("src/shared/Util/ReceiptRules")

local tests = {}

-- A stand-in for MonetizationService's ProcessReceipt with a fake profile:
-- the same decide / grant / record steps, minus Roblox.
local function process(profile, purchaseId: string, hasHandler: boolean, now: number): string
	local receipts = if profile then profile.receipts else nil
	local decision = ReceiptRules.decide(receipts, purchaseId, hasHandler)
	if decision == "AlreadyGranted" then
		return "PurchaseGranted"
	elseif decision ~= "Grant" then
		return "NotProcessedYet"
	end
	profile.energy += 2500
	profile.receipts = ReceiptRules.record(profile.receipts, purchaseId, now, Products.MAX_RECEIPTS)
	return "PurchaseGranted"
end

tests["Roblox retrying the same receipt grants it only once"] = function()
	local profile = { energy = 0, receipts = {} }
	assert(process(profile, "purchase-1", true, 1) == "PurchaseGranted")
	assert(process(profile, "purchase-1", true, 2) == "PurchaseGranted")
	assert(process(profile, "purchase-1", true, 3) == "PurchaseGranted")
	assert(profile.energy == 2500, "granted exactly once")
	assert(process(profile, "purchase-2", true, 4) == "PurchaseGranted")
	assert(profile.energy == 5000, "a different purchase is granted")
end

tests["no loaded profile means try again later, not granted"] = function()
	assert(process(nil, "purchase-1", true, 1) == "NotProcessedYet")
	assert(ReceiptRules.decide(nil, "purchase-1", true) == "NoProfile")
end

tests["an unknown product is never granted"] = function()
	local profile = { energy = 0, receipts = {} }
	assert(process(profile, "purchase-1", false, 1) == "NotProcessedYet")
	assert(profile.energy == 0 and next(profile.receipts) == nil)
end

tests["old receipts are trimmed, but the newest is always kept"] = function()
	local profile = { energy = 0, receipts = {} }
	for index = 1, Products.MAX_RECEIPTS + 50 do
		-- Every purchase in the same second, the worst case for the trim.
		process(profile, `p{index}`, true, 1)
		assert(profile.receipts[`p{index}`] ~= nil, "the purchase just granted is kept")
	end
	local count = 0
	for _ in profile.receipts do
		count += 1
	end
	assert(count == Products.MAX_RECEIPTS)
end

tests["the oldest receipts are the ones trimmed"] = function()
	local receipts = {}
	for index = 1, 3 do
		receipts = ReceiptRules.record(receipts, `p{index}`, index, 2)
	end
	assert(receipts.p1 == nil and receipts.p2 == 2 and receipts.p3 == 3)
end

tests["dashboard ids of 0 never match a product or pass"] = function()
	assert(Products.productById(0) == nil and Products.passById(0) == nil)
	for _, product in Products.PRODUCTS do
		assert(product.energy > 0 and product.priceRobux > 0)
	end
end

return tests
