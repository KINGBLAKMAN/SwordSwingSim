local RojoRequire = require("./support/RojoRequire")

local Drops = RojoRequire("src/shared/Config/Drops")
local DropTables = RojoRequire("src/shared/Util/DropTables")
local Enemies = RojoRequire("src/shared/Config/Enemies")

local tests = {}

tests["every enemy grants its Coins and can drop its own pet"] = function()
	for enemyId, enemy in Enemies do
		local dropTable = DropTables.forEnemy(enemyId)
		assert(dropTable.granted[1].kind == "coins" and dropTable.granted[1].amount == enemy.coins)
		local pet = dropTable.rolled[1]
		local expected = if enemy.tier == "Boss" then Drops.BOSS_PET_CHANCE else Drops.PET_CHANCE
		assert(pet.kind == "pet" and pet.item == enemy.pet and pet.chance == expected, enemyId)
	end
end

tests["every drop names a real item and has a sane chance and amount"] = function()
	for enemyId in Enemies do
		for _, entry in DropTables.forEnemy(enemyId).rolled do
			assert(DropTables.itemName(entry.kind, entry.item) ~= nil)
			assert(entry.chance > 0 and entry.chance <= 1, `{enemyId} {entry.item}`)
			assert(entry.min >= 1 and entry.max >= entry.min, `{enemyId} {entry.item}`)
		end
	end
end

tests["token chances stay between 10% and 75% and rise with tier"] = function()
	local order = { "Very Easy", "Easy", "Medium", "Hard", "Very Hard", "Boss" }
	local previous = 0
	for _, tier in order do
		local rule = Drops.TOKEN_BY_TIER[tier]
		assert(rule.chance >= 0.1 and rule.chance <= 0.75, tier)
		assert(rule.chance > previous, `{tier} should drop tokens more often than the tier below`)
		previous = rule.chance
	end
end

tests["Karasu Ren can drop Crowfeather Tachi at 1%, a rare drop"] = function()
	local found = false
	for _, entry in DropTables.forEnemy("karasu_ren").rolled do
		if entry.item == "crowfeather_tachi" then
			found = entry.chance == 0.01 and DropTables.isRare(entry.chance)
		end
	end
	assert(found)
end

tests["over many kills each drop comes up at about its chance"] = function()
	math.randomseed(1234)
	local dropTable = DropTables.forEnemy("elder_kurogane")
	local kills = 20000
	local counts = {}
	for _ = 1, kills do
		for _, drop in DropTables.roll(dropTable, math.random) do
			counts[drop.item] = (counts[drop.item] or 0) + 1
			if drop.kind ~= "coins" then
				assert(drop.amount >= 1 and drop.amount <= 2)
			end
		end
	end
	assert(counts.coins == kills, "Coins are granted on every kill")
	for _, entry in dropTable.rolled do
		local rate = (counts[entry.item] or 0) / kills
		-- Five standard deviations: fails by chance about once in 3 million runs.
		local tolerance = 5 * math.sqrt(entry.chance * (1 - entry.chance) / kills)
		assert(math.abs(rate - entry.chance) <= tolerance, `{entry.item}: {rate} vs {entry.chance}`)
	end
end

tests["a drop boost scales chances, caps them at 100% and leaves Coins alone"] = function()
	local base = DropTables.forEnemy("karasu_ren")
	assert(DropTables.withBoost(base, 0) == base)
	local boosted = DropTables.withBoost(base, 1)
	for index, entry in boosted.rolled do
		assert(entry.chance == math.min(1, base.rolled[index].chance * 2))
	end
	assert(boosted.granted == base.granted)
end

return tests
