--!strict
-- ClickButton: the big Click! button (GDD A10). It only tells the server
-- "I clicked" through ClickController; the server decides what that's
-- worth (TDD B6–B7).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local ClickController = require(script.Parent.Parent.Parent.Controllers.ClickController)

local e = React.createElement

local PRESS_TWEEN = TweenInfo.new(
	UI.HUD.CLICK_PRESS_SECONDS,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out,
	0,
	true
)

local function ClickButton(props: { layoutOrder: number? })
	local scaleRef = React.useRef(nil :: UIScale?)
	local size = UI.HUD.CLICK_BUTTON_SIZE

	local function onActivated()
		if not ClickController.click() then
			return
		end

		-- Quick squash and back, so every counted tap feels like it landed.
		local scale = scaleRef.current
		if scale then
			TweenService:Create(scale, PRESS_TWEEN, { Scale = UI.HUD.CLICK_PRESS_SCALE }):Play()
		end
	end

	return e("TextButton", {
		Text = "Click!",
		Font = UI.FONT,
		TextSize = UI.TEXT_SIZE.click,
		TextColor3 = UI.COLORS.text,
		TextStrokeTransparency = 0,
		BackgroundColor3 = UI.COLORS.primary,
		Size = UDim2.fromOffset(size, size),
		LayoutOrder = props.layoutOrder,
		[React.Event.Activated] = onActivated,
	}, {
		Round = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = UI.COLORS.stroke,
			Thickness = UI.STROKE_THICKNESS * 2,
		}),
		Press = e("UIScale", { ref = scaleRef }),
	})
end

return ClickButton
