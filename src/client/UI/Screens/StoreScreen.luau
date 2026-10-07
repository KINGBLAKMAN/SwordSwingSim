--!strict
-- StoreScreen: game passes and products for Robux (GDD A17). Items whose
-- Creator Dashboard id isn't in Config/Products yet show "Coming soon".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Products = require(ReplicatedStorage.Shared.Config.Products)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local StoreController = require(script.Parent.Parent.Parent.Controllers.StoreController)
local Button = require(script.Parent.Parent.Components.Button)
local ScreenFrame = require(script.Parent.ScreenFrame)
local usePlayerAttribute = require(script.Parent.Parent.Hooks.usePlayerAttribute)

local e = React.createElement

local ROW_HEIGHT = UI.QUESTS_SCREEN.ROW_HEIGHT
local BUTTON_WIDTH = UI.MIN_TOUCH_TARGET * 3

local function StoreRow(props: {
	name: string,
	description: string,
	buttonText: string,
	disabled: boolean,
	order: number,
	onBuy: () -> (),
})
	local textWidth = UDim2.new(1, -(BUTTON_WIDTH + UI.GAP), 0.5, 0)
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = UI.COLORS.panelLight,
		LayoutOrder = props.order,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, UI.CORNER_RADIUS) }),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, UI.GAP * 2),
			PaddingRight = UDim.new(0, UI.GAP),
		}),
		Name = e("TextLabel", {
			Text = props.name,
			Font = UI.FONT,
			TextSize = UI.TEXT_SIZE.body,
			TextColor3 = UI.COLORS.text,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = textWidth,
		}),
		Description = e("TextLabel", {
			Text = props.description,
			Font = UI.FONT,
			TextSize = UI.TEXT_SIZE.small,
			TextColor3 = UI.COLORS.textMuted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			BackgroundTransparency = 1,
			Size = textWidth,
			Position = UDim2.fromScale(0, 0.5),
		}),
		Buy = e(Button, {
			text = props.buttonText,
			disabled = props.disabled,
			size = UDim2.fromOffset(BUTTON_WIDTH, UI.MIN_TOUCH_TARGET),
			position = UDim2.fromScale(1, 0.5),
			anchorPoint = Vector2.new(1, 0.5),
			onActivated = props.onBuy,
		}),
	})
end

-- Sorted by price, so the list doesn't shuffle between sessions.
local function byPrice<T>(items: { [string]: T }, price: (T) -> number): { T }
	local list = {}
	for _, item in items do
		table.insert(list, item)
	end
	table.sort(list, function(a, b)
		return price(a) < price(b)
	end)
	return list
end

local PASSES = byPrice(Products.PASSES, function(def: Products.PassDef)
	return def.priceRobux
end)
local PRODUCTS = byPrice(Products.PRODUCTS, function(def: Products.ProductDef)
	return def.priceRobux
end)

local function StoreScreen()
	local ownedAttribute = usePlayerAttribute(Products.OWNED_PASSES_ATTRIBUTE)
	local owned = if typeof(ownedAttribute) == "string"
		then string.split(ownedAttribute, ",")
		else {}

	local children: { [string]: any } = {
		List = e("UIListLayout", {
			Padding = UDim.new(0, UI.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	local order = 0
	for _, pass in PASSES do
		order += 1
		local isOwned = table.find(owned, pass.key) ~= nil
		children[pass.key] = e(StoreRow, {
			name = pass.name,
			description = pass.description,
			buttonText = if isOwned
				then "Owned"
				elseif pass.id == 0 then "Coming soon"
				else `R$ {pass.priceRobux}`,
			disabled = isOwned or pass.id == 0,
			order = order,
			onBuy = function()
				StoreController.buyPass(pass.key)
			end,
		})
	end
	for _, product in PRODUCTS do
		order += 1
		children[product.key] = e(StoreRow, {
			name = product.name,
			description = product.description,
			buttonText = if product.id == 0 then "Coming soon" else `R$ {product.priceRobux}`,
			disabled = product.id == 0,
			order = order,
			onBuy = function()
				StoreController.buyProduct(product.key)
			end,
		})
	end

	return e(ScreenFrame, { title = "Store" }, {
		List = e("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 6,
		}, children),
	})
end

return StoreScreen
