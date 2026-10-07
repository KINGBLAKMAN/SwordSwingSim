--!strict
-- ClickController: sends clicks to the server (GDD A10). The Click! button
-- (mobile) and a left mouse click on the world (PC) both come through here.
--
-- Clicks faster than the server credits (Config/Clicking.CLICK_CAP_CPS)
-- are dropped here, since the server would drop them anyway and they would
-- only eat into the rate limit. The server decides what a click is worth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Clicking = require(ReplicatedStorage.Shared.Config.Clicking)
local Remotes = require(script.Parent.Parent.Net.Remotes)

local ClickController = {}

local MIN_SECONDS_BETWEEN_CLICKS = 1 / Clicking.CLICK_CAP_CPS

local lastClickAt = -math.huge

-- Sends one click. Returns false if it came too soon after the last one
-- and wasn't sent.
function ClickController.click(): boolean
	local now = os.clock()
	if now - lastClickAt < MIN_SECONDS_BETWEEN_CLICKS then
		return false
	end
	lastClickAt = now
	Remotes.fire("Click")
	return true
end

-- Asks the server to switch auto-click on or off. The HUD shows the saved
-- value once the server's ProfileDelta arrives.
function ClickController.setAutoClick(enabled: boolean)
	Remotes.fire("SetAuto", Clicking.AUTO_KEY, enabled)
end

function ClickController.start()
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		-- gameProcessed is true when the click hit a UI button or a text box.
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			ClickController.click()
		end
	end)
end

return ClickController
