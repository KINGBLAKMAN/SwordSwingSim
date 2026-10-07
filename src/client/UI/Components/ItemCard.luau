--!strict
-- ItemCard: one pet, weapon or drop in a grid: icon, name and an optional
-- badge (level, count, "Shiny"), on a RarityFrame. Tappable when given
-- onActivated.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local Icon = require(script.Parent.Icon)
local RarityFrame = require(script.Parent.RarityFrame)

local e = React.createElement

export type Props = {
	name: string,
	rarity: Rarities.Rarity,
	-- Key in Config/Assets.
	icon: string,
	badge: string?,
	selected: boolean?,
	onActivated: (() -> ())?,
	layoutOrder: number?,
}

-- Share of the card's height for the name strip at the bottom.
local NAME_HEIGHT = 0.24

local function ItemCard(props: Props)
	local cardSize = UI.ITEM_CARD_SIZE
	local onActivated = props.onActivated

	return e("TextButton", {
		Text = "",
		Size = UDim2.fromOffset(cardSize.X, cardSize.Y),
		LayoutOrder = props.layoutOrder,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Active = onActivated ~= nil,
		Selectable = onActivated ~= nil,
		[React.Event.Activated] = function()
			if onActivated then
				onActivated()
			end
		end,
	}, {
		Frame = e(RarityFrame, {
			rarity = props.rarity,
			selected = props.selected,
		}, {
			Icon = e(Icon, {
				asset = props.icon,
				fallbackText = props.name,
				color = UI.RARITY_COLORS[props.rarity],
				size = UDim2.fromScale(0.7, 1 - NAME_HEIGHT - 0.1),
				position = UDim2.fromScale(0.5, 0.06),
				anchorPoint = Vector2.new(0.5, 0),
			}),
			Name = e("TextLabel", {
				Text = props.name,
				Font = UI.FONT,
				TextScaled = true,
				TextColor3 = UI.COLORS.text,
				TextStrokeTransparency = 0,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.92, NAME_HEIGHT),
				Position = UDim2.fromScale(0.5, 0.97),
				AnchorPoint = Vector2.new(0.5, 1),
			}),
			Badge = props.badge and e("TextLabel", {
				Text = props.badge,
				Font = UI.FONT,
				TextSize = UI.TEXT_SIZE.small,
				TextColor3 = UI.COLORS.text,
				TextStrokeTransparency = 0,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Size = UDim2.new(1, -UI.GAP, 0, UI.TEXT_SIZE.small),
				Position = UDim2.fromOffset(0, UI.GAP / 2),
			}),
		}),
	})
end

return ItemCard
