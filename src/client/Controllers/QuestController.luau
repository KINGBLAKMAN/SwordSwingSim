--!strict
-- QuestController: asks the server for a completed quest's reward
-- (GDD A13). The server checks the quest is done; the profile update
-- moves the tracker on to the next quest.

local Remotes = require(script.Parent.Parent.Net.Remotes)

local QuestController = {}

function QuestController.claim(questId: string)
	Remotes.fire("ClaimQuest", questId)
end

return QuestController
