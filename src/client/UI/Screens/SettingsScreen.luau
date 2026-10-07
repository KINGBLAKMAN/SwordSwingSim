--!strict
-- SettingsScreen: an on/off switch for each setting in Config/Settings
-- (GDD A22). Tapping one asks the server to save the new value; the switch
-- shows the saved value once the server's ProfileDelta arrives.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local React = require(ReplicatedStorage.Packages.React)
local Settings = require(ReplicatedStorage.Shared.Config.Settings)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local Remotes = require(script.Parent.Parent.Parent.Net.Remotes)
local Button = require(script.Parent.Parent.Components.Button)
local ScreenFrame = require(script.Parent.ScreenFrame)
local useProfile = require(script.Parent.Parent.Hooks.useProfile)

local e = React.createElement

local function selectSettings(profile: ProfileTypes.Profile)
	return profile.settings
end

local function SettingsScreen()
	local saved = useProfile(selectSettings) or {}

	local rows: { [string]: any } = {
		List = e(
			"UIListLayout",
			{ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, UI.GAP) }
		),
	}
	for order, def in Settings.LIST do
		local isOn = Settings.value(saved, def.key)
		rows[def.key] = e("Frame", {
			Size = UDim2.new(1, 0, 0, UI.MIN_TOUCH_TARGET),
			BackgroundTransparency = 1,
			LayoutOrder = order,
		}, {
			Label = e("TextLabel", {
				Text = def.label,
				Font = UI.FONT,
				TextSize = UI.TEXT_SIZE.body,
				TextColor3 = UI.COLORS.text,
				TextStrokeTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.65, 1),
			}),
			Toggle = e(Button, {
				text = if isOn then "ON" else "OFF",
				color = if isOn then UI.COLORS.barFill else UI.COLORS.panelLight,
				size = UDim2.fromOffset(UI.MIN_TOUCH_TARGET * 2, UI.MIN_TOUCH_TARGET),
				position = UDim2.fromScale(1, 0),
				anchorPoint = Vector2.new(1, 0),
				onActivated = function()
					Remotes.fire("UpdateSetting", def.key, not isOn)
				end,
			}),
		})
	end

	return e(ScreenFrame, { title = "Settings" }, rows)
end

return SettingsScreen
