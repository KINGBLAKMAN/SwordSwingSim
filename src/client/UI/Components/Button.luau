--!strict
-- Button: the one tappable button style (TDD B9). Never smaller than
-- Config/UI.MIN_TOUCH_TARGET on either side, so it's easy to hit on a
-- phone. A disabled button shows grey and ignores taps.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local Icon = require(script.Parent.Icon)

local e = React.createElement

export type Props = {
	text: string,
	onActivated: () -> (),
	-- Key in Config/Assets. Shows above the text when given.
	icon: string?,
	color: Color3?,
	textSize: number?,
	disabled: boolean?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
}

local MIN_SIZE = Vector2.new(UI.MIN_TOUCH_TARGET, UI.MIN_TOUCH_TARGET)

-- Share of the button's height the icon takes when there is one.
local ICON_HEIGHT = 0.6

local function Button(props: Props)
	local disabled = props.disabled == true
	local hasIcon = props.icon ~= nil

	local children: { [string]: any } = {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, UI.CORNER_RADIUS) }),
		Stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = UI.COLORS.stroke,
			Thickness = UI.STROKE_THICKNESS,
		}),
		MinSize = e("UISizeConstraint", { MinSize = MIN_SIZE }),
	}

	if props.icon then
		children.Icon = e(Icon, {
			asset = props.icon,
			fallbackText = props.text,
			color = UI.COLORS.panel,
			size = UDim2.fromScale(1, ICON_HEIGHT),
			position = UDim2.fromScale(0.5, 0.05),
			anchorPoint = Vector2.new(0.5, 0),
		})
	end

	return e("TextButton", {
		Text = props.text,
		Font = UI.FONT,
		TextSize = props.textSize or UI.TEXT_SIZE.button,
		TextColor3 = UI.COLORS.text,
		TextStrokeTransparency = 0,
		TextWrapped = true,
		-- With an icon, the label sits under it.
		TextYAlignment = if hasIcon then Enum.TextYAlignment.Bottom else Enum.TextYAlignment.Center,
		BackgroundColor3 = if disabled
			then UI.COLORS.disabled
			else props.color or UI.COLORS.primary,
		AutoButtonColor = not disabled,
		Selectable = not disabled,
		Size = props.size or UDim2.fromOffset(UI.MIN_TOUCH_TARGET * 3, UI.MIN_TOUCH_TARGET),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		[React.Event.Activated] = function()
			if not disabled then
				props.onActivated()
			end
		end,
	}, children)
end

return Button
