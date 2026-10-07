--!strict
-- App: the root of the whole UI (TDD B9). One ScreenGui (named App by
-- UIController) holding the HUD and, above it, whichever screen the Router
-- has open.
--
-- Mobile-first scaling:
--   * ScreenInsets keeps everything inside the core UI safe area, clear of
--     the notch, rounded corners and Roblox's top bar.
--   * A UIScale picked from the screen size (ScaleMath) makes the UI
--     bigger on tablets and PCs, never smaller than designed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local HatchOverlay = require(script.Parent.HatchOverlay)
local Hud = require(script.Parent.Hud)
local Screens = require(script.Parent.Screens)
local useRoute = require(script.Parent.Hooks.useRoute)
local useViewportScale = require(script.Parent.Hooks.useViewportScale)

local e = React.createElement

local function App()
	local scale = useViewportScale()
	local screenName = useRoute()

	local screen = if screenName then Screens[screenName] else nil
	if screenName and not screen then
		warn(`App: no screen named "{screenName}" in UI/Screens`)
	end

	return e("ScreenGui", {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	}, {
		-- A UIScale grows its parent too, so the root starts at 1/scale of
		-- the screen and the scale brings it back to exactly full size.
		-- Centered, because a UIScale grows a frame around its center.
		Root = e("Frame", {
			Size = UDim2.fromScale(1 / scale, 1 / scale),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			Scale = e("UIScale", { Scale = scale }),
			Hud = e(Hud),
			-- Later siblings draw on top with Sibling ZIndexBehavior; ZIndex
			-- makes the order explicit.
			Screen = screen and e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 2,
			}, {
				Content = e(screen),
			}),
			-- The hatch animation covers everything, open screens included.
			Hatch = e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 3,
			}, {
				Overlay = e(HatchOverlay),
			}),
		}),
	})
end

return App
