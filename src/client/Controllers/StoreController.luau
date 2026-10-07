--!strict
-- StoreController: opens Roblox's purchase prompts (GDD A17). Roblox
-- handles the payment; the server grants the item (MonetizationService),
-- so nothing here changes the player's data.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Products = require(ReplicatedStorage.Shared.Config.Products)

local StoreController = {}

function StoreController.buyPass(passKey: string)
	local pass = Products.PASSES[passKey]
	if pass and pass.id ~= 0 then
		MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, pass.id)
	end
end

function StoreController.buyProduct(productKey: string)
	local product = Products.PRODUCTS[productKey]
	if product and product.id ~= 0 then
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, product.id)
	end
end

return StoreController
