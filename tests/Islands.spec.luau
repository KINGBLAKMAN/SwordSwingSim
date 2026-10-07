local RojoRequire = require("./support/RojoRequire")

local Drops = RojoRequire("src/shared/Config/Drops")
local EnemySpawning = RojoRequire("src/shared/Config/EnemySpawning")
local Enemies = RojoRequire("src/shared/Config/Enemies")
local IslandRules = RojoRequire("src/shared/Util/IslandRules")
local Islands = RojoRequire("src/shared/Config/Islands")
local Quests = RojoRequire("src/shared/Config/Quests")
local Tokens = RojoRequire("src/shared/Config/Tokens")

local tests = {}

local function profile(unlocked: { string }, current: string, claimed: { string })
	local data = { currentIsland = current, islandsUnlocked = {}, quests = {} }
	for _, id in unlocked do
		data.islandsUnlocked[id] = true
	end
	for _, questId in claimed do
		data.quests[questId] =
			{ progress = Quests.BY_ID[questId].count, claimed = true, assignedAt = 0 }
	end
	return data
end

tests["islands come in play order, each after the one before"] = function()
	local order = IslandRules.inOrder()
	assert(order[1] == "NinjaVillage" and order[2] == "CursedCity")
	assert(IslandRules.previous("NinjaVillage") == nil)
	assert(IslandRules.previous("CursedCity") == "NinjaVillage")
end

tests["island 2 needs island 1's quests before it can be bought"] = function()
	local fresh = profile({ "NinjaVillage" }, "NinjaVillage", {})
	assert(IslandRules.status("NinjaVillage", fresh) == "here")
	assert(IslandRules.status("CursedCity", fresh) == "needsQuests")

	local done = profile({ "NinjaVillage" }, "NinjaVillage", Quests.CHAINS.NinjaVillage)
	assert(IslandRules.status("CursedCity", done) == "unlockable")
	assert(Islands.CursedCity.unlockCost > 0)
end

tests["an unlocked island is open to travel, from either side"] = function()
	local data = profile({ "NinjaVillage", "CursedCity" }, "CursedCity", Quests.CHAINS.NinjaVillage)
	assert(IslandRules.status("CursedCity", data) == "here")
	assert(IslandRules.status("NinjaVillage", data) == "open")
end

tests["every spawned enemy and island token belongs to its island"] = function()
	for islandId, enemyIds in EnemySpawning.SPAWNED do
		for _, enemyId in enemyIds do
			assert(Enemies[enemyId].island == islandId, enemyId)
		end
		for _, tokenId in Drops.ISLAND_TOKENS[islandId] do
			assert(Tokens[tokenId].island == islandId, tokenId)
		end
	end
	assert(#EnemySpawning.SPAWNED.CursedCity == 3)
end

tests["island 2 has its own three-quest chain"] = function()
	local chain = Quests.CHAINS.CursedCity
	assert(#chain == 3)
	for _, questId in chain do
		local quest = Quests.BY_ID[questId]
		if quest.kind == "kill" then
			assert(Enemies[quest.target].island == "CursedCity", questId)
		end
	end
end

return tests
