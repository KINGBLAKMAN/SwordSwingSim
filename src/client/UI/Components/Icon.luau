--!strict
-- Icon: an image from Config/Assets, or, until that art is uploaded, a
-- colored circle with the first letter of `fallbackText`. Lets the UI ship
-- before its icons do.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Config.Assets)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)

local e = React.createElement

export type Props = {
	-- Key in Config/Assets, like "ui.icon.coins".
	asset: string,
	fallbackText: string,
	color: Color3?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
}

local function Icon(props: Props)
	local size = props.size or UDim2.fromScale(1, 1)
	local image = Assets[props.asset]

	if image then
		return e("ImageLabel", {
			Image = image,
			Size = size,
			Position = props.position,
			AnchorPoint = props.anchorPoint,
			LayoutOrder = props.layoutOrder,
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
		}, {
			-- Icons are square, whatever box the caller gives them.
			Aspect = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
		})
	end

	return e("TextLabel", {
		Text = string.sub(props.fallbackText, 1, 1),
		Size = size,
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = props.color or UI.COLORS.panelLight,
		TextColor3 = UI.COLORS.text,
		TextStrokeTransparency = 0,
		TextScaled = true,
		Font = UI.FONT,
	}, {
		Round = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Aspect = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
	})
end

return Icon
