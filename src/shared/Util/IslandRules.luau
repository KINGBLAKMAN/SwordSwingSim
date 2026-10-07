--!strict
-- IslandRules: which islands a player may unlock or travel to (GDD A12).
-- Pure, so Lune tests can check it and the Islands screen shows the same
-- answer the server acts on.

local Islands = require(script.Parent.Parent.Config.Islands)
local QuestRules = require(script.Parent.QuestRules)
local Travel = require(script.Parent.Parent.Config.Travel)

-- "here": the player is on it. "open": unlocked, can travel.
-- "unlockable": requirement met, pay to unlock. "needsQuests": finish the
-- previous island's quests first. "needsPrevious": unlock the island
-- before it first.
export type Status = "here" | "open" | "unlockable" | "needsQuests" | "needsPrevious"

local IslandRules = {}

-- Island ids in order of play.
function IslandRules.inOrder(): { string }
	local ids = {}
	for id in Islands do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return Islands[a].number < Islands[b].number
	end)
	return ids
end

-- The island played just before this one, or nil for the first.
function IslandRules.previous(islandId: string): string?
	local number = Islands[islandId].number
	for id, island in Islands do
		if island.number == number - 1 then
			return id
		end
	end
	return nil
end

-- `data` is the player's profile (only these fields are read).
function IslandRules.status(
	islandId: string,
	data: {
		currentIsland: string,
		islandsUnlocked: { [string]: boolean },
		quests: { [string]: QuestRules.QuestEntry },
	}
): Status
	if data.currentIsland == islandId then
		return "here"
	elseif data.islandsUnlocked[islandId] then
		return "open"
	end
	local previous = IslandRules.previous(islandId)
	if previous and not data.islandsUnlocked[previous] then
		return "needsPrevious"
	elseif
		previous
		and Travel.REQUIRE_PREVIOUS_QUESTS
		and QuestRules.activeQuest(previous, data.quests) ~= nil
	then
		return "needsQuests"
	end
	return "unlockable"
end

return IslandRules
