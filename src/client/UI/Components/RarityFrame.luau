--!strict
-- RarityFrame: a panel bordered and tinted in a rarity's color (GDD A6),
-- used behind pets, weapons and drops. Pass children to fill it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)

local e = React.createElement

export type Props = {
	rarity: Rarities.Rarity,
	-- A thicker border marks the selected item.
	selected: boolean?,
	size: UDim2?,
	position: UDim2?,
	layoutOrder: number?,
	children: any?,
}

local function RarityFrame(props: Props)
	local color = UI.RARITY_COLORS[props.rarity]
	local strokeThickness = if props.selected then UI.STROKE_THICKNESS * 2 else UI.STROKE_THICKNESS

	return e("Frame", {
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position,
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = UI.COLORS.panelLight,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, UI.CORNER_RADIUS) }),
		Stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = color,
			Thickness = strokeThickness,
		}),
		-- Fades from the plain panel at the top into the rarity color.
		Tint = e("UIGradient", {
			Color = ColorSequence.new(UI.COLORS.panelLight, color),
			Rotation = 90,
		}),
		Content = e(React.Fragment, nil, props.children),
	})
end

return RarityFrame
