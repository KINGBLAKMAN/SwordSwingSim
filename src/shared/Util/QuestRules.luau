--!strict
-- QuestRules: which quest in a chain is active, what counts toward it and
-- how it reads on screen (GDD A13). Pure, so Lune tests can check it and
-- the client shows the same progress the server keeps.

local Eggs = require(script.Parent.Parent.Config.Eggs)
local Enemies = require(script.Parent.Parent.Config.Enemies)
local Islands = require(script.Parent.Parent.Config.Islands)
local Quests = require(script.Parent.Parent.Config.Quests)

type QuestDef = Quests.QuestDef
-- One entry in profile.quests.
export type QuestEntry = { progress: number, claimed: boolean, assignedAt: number }
export type Status = "claimed" | "complete" | "active" | "locked"

local QuestRules = {}

-- The first quest in the island's chain whose reward isn't claimed yet,
-- or nil once the whole chain is done.
function QuestRules.activeQuest(island: string, quests: { [string]: QuestEntry }): string?
	local chain: { string } = Quests.CHAINS[island] or {}
	for _, questId in chain do
		local entry = quests[questId]
		if entry == nil or not entry.claimed then
			return questId
		end
	end
	return nil
end

function QuestRules.countsToward(quest: QuestDef, kind: Quests.GoalKind, target: string): boolean
	return quest.kind == kind and quest.target == target
end

function QuestRules.isComplete(quest: QuestDef, entry: QuestEntry?): boolean
	return entry ~= nil and entry.progress >= quest.count
end

-- Progress after `amount` more toward the goal, never past the count.
function QuestRules.advance(quest: QuestDef, progress: number, amount: number): number
	return math.min(quest.count, progress + amount)
end

function QuestRules.status(quest: QuestDef, quests: { [string]: QuestEntry }): Status
	local entry = quests[quest.id]
	if entry and entry.claimed then
		return "claimed"
	elseif QuestRules.activeQuest(quest.island, quests) ~= quest.id then
		return "locked"
	elseif QuestRules.isComplete(quest, entry) then
		return "complete"
	end
	return "active"
end

-- "Defeat 25 Kōhai", "Open 3 Ninja village eggs".
function QuestRules.describe(quest: QuestDef): string
	if quest.kind == "kill" then
		return `Defeat {quest.count} {Enemies[quest.target].name}`
	end
	local islandName = Islands[Eggs[quest.target].island].name
	local noun = if quest.count == 1 then "egg" else "eggs"
	return `Open {quest.count} {islandName} {noun}`
end

return QuestRules
