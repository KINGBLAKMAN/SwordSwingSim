--!strict
-- ProgressBar: a filled bar with an optional label on top, like the level
-- bar or an egg's pity meter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)

local e = React.createElement

export type Props = {
	-- How full the bar is, from 0 to 1. Values outside are clamped.
	fraction: number,
	label: string?,
	fillColor: Color3?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
}

local function ProgressBar(props: Props)
	local fraction = math.clamp(props.fraction, 0, 1)
	local barSize = UI.HUD.LEVEL_BAR_SIZE

	return e("Frame", {
		Size = props.size or UDim2.fromOffset(barSize.X, barSize.Y),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = UI.COLORS.barBack,
		-- Keeps the fill's square end inside the rounded corners.
		ClipsDescendants = true,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = UI.COLORS.stroke,
			Thickness = UI.STROKE_THICKNESS,
		}),
		Fill = e("Frame", {
			Size = UDim2.fromScale(fraction, 1),
			BackgroundColor3 = props.fillColor or UI.COLORS.barFill,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		}),
		Label = props.label and e("TextLabel", {
			Text = props.label,
			Font = UI.FONT,
			TextSize = UI.TEXT_SIZE.small,
			TextColor3 = UI.COLORS.text,
			TextStrokeTransparency = 0,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
		}),
	})
end

return ProgressBar
