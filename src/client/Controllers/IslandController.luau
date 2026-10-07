--!strict
-- IslandController: the island gates and travel requests (GDD A12).
-- Using a gate's prompt opens the Islands screen; the screen's buttons
-- send UnlockIsland or Teleport, and the server checks both.

local ProximityPromptService = game:GetService("ProximityPromptService")

local Remotes = require(script.Parent.Parent.Net.Remotes)
local Router = require(script.Parent.Parent.UI.Router)

local IslandController = {}

function IslandController.start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "TravelPrompt" then
			Router.open("Islands")
		end
	end)
end

function IslandController.unlock(islandId: string)
	Remotes.fire("UnlockIsland", islandId)
end

function IslandController.travel(islandId: string)
	Remotes.fire("Teleport", islandId)
	Router.close()
end

return IslandController
