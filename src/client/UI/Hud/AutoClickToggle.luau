--!strict
-- AutoClickToggle: switches the server's auto-click on and off (GDD A10).
-- Shows the saved setting from the profile, so it's right after a rejoin.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Clicking = require(ReplicatedStorage.Shared.Config.Clicking)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local ClickController = require(script.Parent.Parent.Parent.Controllers.ClickController)
local Button = require(script.Parent.Parent.Components.Button)
local useProfile = require(script.Parent.Parent.Hooks.useProfile)

local e = React.createElement

local function selectAutoClick(profile: ProfileTypes.Profile): boolean
	return profile.autos[Clicking.AUTO_KEY] == true
end

local function AutoClickToggle(props: { layoutOrder: number? })
	local enabled = useProfile(selectAutoClick) == true
	local size = UI.HUD.AUTO_BUTTON_SIZE

	return e(Button, {
		text = if enabled then "Auto: ON" else "Auto: OFF",
		color = if enabled then UI.COLORS.barFill else UI.COLORS.panelLight,
		textSize = UI.TEXT_SIZE.small,
		size = UDim2.fromOffset(size.X, size.Y),
		layoutOrder = props.layoutOrder,
		onActivated = function()
			ClickController.setAutoClick(not enabled)
		end,
	})
end

return AutoClickToggle
