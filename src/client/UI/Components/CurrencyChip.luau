--!strict
-- CurrencyChip: an icon and an amount, like the Coins counter on the HUD.
-- The caller formats the amount (Util/Format) so this stays dumb.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local Icon = require(script.Parent.Icon)

local e = React.createElement

export type Props = {
	label: string,
	amount: string,
	-- Key in Config/Assets.
	icon: string,
	color: Color3,
	size: UDim2?,
	layoutOrder: number?,
}

local function CurrencyChip(props: Props)
	local chipSize = UI.HUD.CURRENCY_CHIP_SIZE

	return e("Frame", {
		Size = props.size or UDim2.fromOffset(chipSize.X, chipSize.Y),
		BackgroundColor3 = UI.COLORS.panel,
		BackgroundTransparency = 0.15,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Stroke = e("UIStroke", { Color = props.color, Thickness = UI.STROKE_THICKNESS }),
		Icon = e(Icon, {
			asset = props.icon,
			fallbackText = props.label,
			color = props.color,
			-- A square as tall as the chip, on the left.
			size = UDim2.fromScale(1, 1),
		}),
		Amount = e("TextLabel", {
			Text = props.amount,
			Font = UI.FONT,
			TextSize = UI.TEXT_SIZE.body,
			TextColor3 = UI.COLORS.text,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			-- Everything right of the icon, minus a little padding.
			Size = UDim2.new(1, -(chipSize.Y + UI.GAP * 2), 1, 0),
			Position = UDim2.new(1, -UI.GAP * 2, 0, 0),
			AnchorPoint = Vector2.new(1, 0),
		}),
	})
end

return CurrencyChip
