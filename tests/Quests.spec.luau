local RojoRequire = require("./support/RojoRequire")

local Eggs = RojoRequire("src/shared/Config/Eggs")
local Enemies = RojoRequire("src/shared/Config/Enemies")
local QuestRules = RojoRequire("src/shared/Util/QuestRules")
local Quests = RojoRequire("src/shared/Config/Quests")

local tests = {}

local CHAIN = Quests.CHAINS.NinjaVillage

local function entry(progress: number, claimed: boolean)
	return { progress = progress, claimed = claimed, assignedAt = 0 }
end

tests["every quest targets a real enemy or egg and pays Coins"] = function()
	for questId, quest in Quests.BY_ID do
		if quest.kind == "kill" then
			assert(Enemies[quest.target] ~= nil, questId)
		else
			assert(Eggs[quest.target] ~= nil, questId)
		end
		assert(quest.count >= 1 and quest.rewardCoins > 0, questId)
		assert(table.find(Quests.CHAINS[quest.island], questId), questId)
	end
end

tests["island 1 has a chain of three quests"] = function()
	assert(#CHAIN == 3)
end

tests["the first unclaimed quest is active, and nil once the chain is done"] = function()
	assert(QuestRules.activeQuest("NinjaVillage", {}) == CHAIN[1])
	local quests = { [CHAIN[1]] = entry(25, true) }
	assert(QuestRules.activeQuest("NinjaVillage", quests) == CHAIN[2])
	quests[CHAIN[2]] = entry(3, true)
	quests[CHAIN[3]] = entry(1, true)
	assert(QuestRules.activeQuest("NinjaVillage", quests) == nil)
	assert(QuestRules.activeQuest("NoSuchIsland", {}) == nil)
end

tests["progress stops at the goal and only matching goals count"] = function()
	local quest = Quests.BY_ID[CHAIN[1]]
	assert(QuestRules.advance(quest, quest.count - 1, 5) == quest.count)
	assert(QuestRules.countsToward(quest, quest.kind, quest.target))
	assert(not QuestRules.countsToward(quest, quest.kind, "not_this_enemy"))
	assert(not QuestRules.countsToward(quest, "open", quest.target))
end

tests["status: claimed, complete, active and locked"] = function()
	local first, second = Quests.BY_ID[CHAIN[1]], Quests.BY_ID[CHAIN[2]]
	local quests = { [first.id] = entry(3, false) }
	assert(QuestRules.status(first, quests) == "active")
	assert(QuestRules.status(second, quests) == "locked")
	quests[first.id] = entry(first.count, false)
	assert(QuestRules.status(first, quests) == "complete")
	quests[first.id] = entry(first.count, true)
	assert(QuestRules.status(first, quests) == "claimed")
	assert(QuestRules.status(second, quests) == "active")
end

tests["quests read naturally"] = function()
	assert(QuestRules.describe(Quests.BY_ID.nv_kohai) == "Defeat 25 Kōhai")
	assert(QuestRules.describe(Quests.BY_ID.nv_open_eggs) == "Open 3 Ninja village eggs")
end

return tests
