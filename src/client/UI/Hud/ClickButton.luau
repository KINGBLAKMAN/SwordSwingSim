--!strict
-- ClickButton: the big Click! button (GDD A10). It only tells the server
-- "I clicked"; the server decides what that's worth (TDD B6–B7).
--
-- Taps faster than the click cooldown are dropped here, because the server
-- would drop them anyway and they would only eat into the rate limit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Clicking = require(ReplicatedStorage.Shared.Config.Clicking)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local Remotes = require(script.Parent.Parent.Parent.Net.Remotes)

local e = React.createElement

local PRESS_TWEEN = TweenInfo.new(
	UI.HUD.CLICK_PRESS_SECONDS,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out,
	0,
	true
)

local function ClickButton(props: { position: UDim2, anchorPoint: Vector2 })
	local lastClickAt = React.useRef(-math.huge)
	local scaleRef = React.useRef(nil :: UIScale?)
	local size = UI.HUD.CLICK_BUTTON_SIZE

	local function onActivated()
		local now = os.clock()
		if now - lastClickAt.current < Clicking.CLICK_COOLDOWN then
			return
		end
		lastClickAt.current = now
		Remotes.fire("Click")

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
		Position = props.position,
		AnchorPoint = props.anchorPoint,
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
