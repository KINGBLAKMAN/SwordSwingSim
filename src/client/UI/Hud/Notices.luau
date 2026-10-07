--!strict
-- Notices: the latest short message from the server ("Not enough
-- Coins."), shown near the top for a few seconds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local NotifyController = require(script.Parent.Parent.Parent.Controllers.NotifyController)

local e = React.createElement

local NOTICES = UI.NOTICES

local function Notices()
	local message: string?, setMessage = React.useState(nil :: string?)
	local shownCount = React.useRef(0)

	React.useEffect(function()
		local connection = NotifyController.onNotified(function(text: string)
			shownCount.current += 1
			local thisNotice = shownCount.current
			setMessage(text)
			task.delay(NOTICES.SECONDS, function()
				-- Only clear if no newer message replaced this one.
				if shownCount.current == thisNotice then
					setMessage(nil)
				end
			end)
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	if message == nil then
		return nil
	end
	return e("TextLabel", {
		Text = message,
		Font = UI.FONT,
		TextSize = UI.TEXT_SIZE.body,
		TextColor3 = NOTICES.COLOR,
		TextStrokeTransparency = 0,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(NOTICES.SIZE.X, NOTICES.SIZE.Y),
		Position = UDim2.fromScale(0.5, NOTICES.Y),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
end

return Notices
