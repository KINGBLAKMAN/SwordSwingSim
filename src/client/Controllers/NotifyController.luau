--!strict
-- NotifyController: passes the server's Notify messages ("Not enough
-- Coins.") on to the HUD.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Remotes = require(script.Parent.Parent.Net.Remotes)

local NotifyController = {}

-- (message: string)
local notified = Signal.new()

function NotifyController.start()
	Remotes.on("Notify", function(message: string)
		notified:Fire(message)
	end)
end

-- Shows a message on this client only, e.g. a client-side hint.
function NotifyController.show(message: string)
	notified:Fire(message)
end

function NotifyController.onNotified(callback: (message: string) -> ())
	return notified:Connect(callback)
end

return NotifyController
