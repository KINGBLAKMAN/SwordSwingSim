--!strict
-- MonetizationService: developer product receipts and game passes
-- (TDD B10, GDD A17).
--
-- ProcessReceipt is set in init(), right after DataService, so no receipt
-- arrives before it's ready. ReceiptRules decides what each receipt does;
-- a grant and its purchase id go into the profile together, then the
-- profile saves right away.
--
-- Pass ownership is checked once on join (UserOwnsGamePassAsync), cached
-- here, and updated at once when a pass is bought in game.

local AnalyticsService = game:GetService("AnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BigNum = require(ReplicatedStorage.Shared.Util.BigNum)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local ReceiptRules = require(ReplicatedStorage.Shared.Util.ReceiptRules)
local Signal = require(ReplicatedStorage.Packages.Signal)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)

local MonetizationService = {}

-- (player, passKey) when a player is found to own a pass, on join or after
-- buying it.
MonetizationService.passOwned = Signal.new()

local ownedPasses: { [Player]: { [string]: boolean } } = {}

-- Grants one product. Runs before the purchase id is recorded, and must
-- not yield, so the grant and the record land in the same profile change.
local GRANTS: { [string]: (player: Player, product: Products.ProductDef) -> () } = {
	energy_pack = function(player, product)
		CurrencyService.add(
			player,
			"energy",
			BigNum.fromNumber(product.energy),
			`Product:{product.key}`
		)
	end,
}

local function logPurchase(player: Player, product: Products.ProductDef)
	local balance = BigNum.toNumber(CurrencyService.get(player, "energy"))
	local ok, err = pcall(function()
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Energy",
			product.energy,
			balance,
			Enum.AnalyticsEconomyTransactionType.IAP.Name,
			product.key
		)
	end)
	if not ok then
		warn(`[MonetizationService] analytics failed: {err}`)
	end
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = if player then DataService.get(player) else nil
	local purchaseId = tostring(receipt.PurchaseId)
	local product = Products.productById(receipt.ProductId)
	local grant = if product then GRANTS[product.key] else nil

	local receipts = if data then data.purchases.receipts else nil
	local decision = ReceiptRules.decide(receipts, purchaseId, grant ~= nil)
	if decision == "AlreadyGranted" then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif decision == "UnknownProduct" then
		warn(`[MonetizationService] no handler for product {receipt.ProductId}; not granting`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	elseif
		decision == "NoProfile"
		or player == nil
		or data == nil
		or product == nil
		or grant == nil
	then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	grant(player, product)
	DataService.set(
		player,
		{ "purchases", "receipts" },
		ReceiptRules.record(data.purchases.receipts, purchaseId, os.time(), Products.MAX_RECEIPTS)
	)
	DataService.update(player, { "purchases", "lifetimeRobux" }, function(total)
		return total + (receipt.CurrencySpent or 0)
	end)
	DataService.saveNow(player)
	logPurchase(player, product)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function publishOwned(player: Player)
	local keys = {}
	local owned: { [string]: boolean } = ownedPasses[player] or {}
	for key in owned do
		table.insert(keys, key)
	end
	table.sort(keys)
	player:SetAttribute(Products.OWNED_PASSES_ATTRIBUTE, table.concat(keys, ","))
end

local function markOwned(player: Player, passKey: string)
	local owned = ownedPasses[player]
	if owned == nil or owned[passKey] then
		return
	end
	owned[passKey] = true
	publishOwned(player)
	MonetizationService.passOwned:Fire(player, passKey)
end

local function checkPasses(player: Player)
	ownedPasses[player] = {}
	publishOwned(player)
	for key, pass in Products.PASSES do
		if pass.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if not ok then
				-- Counts as not owned for now; buying again is blocked by
				-- Roblox, and the next join checks again.
				warn(`[MonetizationService] pass check failed for {player.Name}: {owns}`)
			elseif owns then
				markOwned(player, key)
			end
		end
	end
end

function MonetizationService.ownsPass(player: Player, passKey: string): boolean
	local owned = ownedPasses[player]
	return owned ~= nil and owned[passKey] == true
end

function MonetizationService.init()
	MarketplaceService.ProcessReceipt = processReceipt
end

function MonetizationService.start()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local pass = Products.passById(passId)
		if purchased and pass then
			markOwned(player, pass.key)
		end
	end)
	Players.PlayerAdded:Connect(checkPasses)
	Players.PlayerRemoving:Connect(function(player)
		ownedPasses[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(checkPasses, player)
	end
end

return MonetizationService
