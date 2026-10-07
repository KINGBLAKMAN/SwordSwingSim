--!strict
-- PlaceholderScreen: a titled screen that says it's coming soon. Each menu
-- button opens one until its real screen is built.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local ScreenFrame = require(script.Parent.ScreenFrame)

local e = React.createElement

local PlaceholderScreen = {}

-- Returns a screen component with the given title.
function PlaceholderScreen.make(title: string): () -> any
	return function()
		return e(ScreenFrame, { title = title }, {
			Message = e("TextLabel", {
				Text = "Coming soon",
				Font = UI.FONT,
				TextSize = UI.TEXT_SIZE.body,
				TextColor3 = UI.COLORS.textMuted,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}),
		})
	end
end

return PlaceholderScreen
