local RojoRequire = require("./support/RojoRequire")

local Combat = RojoRequire("src/shared/Config/Combat")
local CombatMath = RojoRequire("src/shared/Util/CombatMath")
local EnemySpawning = RojoRequire("src/shared/Config/EnemySpawning")
local Enemies = RojoRequire("src/shared/Config/Enemies")
local Islands = RojoRequire("src/shared/Config/Islands")
local SpawnLayout = RojoRequire("src/shared/Util/SpawnLayout")

local tests = {}

local function close(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-6 * math.max(1, math.abs(b))
end

tests["damage is Energy x DAMAGE_PER_ENERGY x sword, times CRIT_MULT on a crit"] = function()
	assert(close(CombatMath.damagePerHit(500, 1, false), 500 * Combat.DAMAGE_PER_ENERGY))
	assert(
		close(
			CombatMath.damagePerHit(500, 1, true),
			500 * Combat.DAMAGE_PER_ENERGY * Combat.CRIT_MULT
		)
	)
	assert(close(CombatMath.damagePerHit(500, 3, false), 1500 * Combat.DAMAGE_PER_ENERGY))
end

tests["a crit lands when the roll is under the chance"] = function()
	assert(CombatMath.isCrit(0.01, 0.05))
	assert(not CombatMath.isCrit(0.05, 0.05))
	assert(not CombatMath.isCrit(0.9, 0.05))
end

tests["kill credit goes to everyone with at least the credit share of max HP"] = function()
	local maxHp = 1000
	local share = EnemySpawning.KILL_CREDIT_SHARE * maxHp
	local credited =
		CombatMath.creditedPlayers({ a = maxHp - share + 1, b = share, c = share - 1 }, maxHp)
	table.sort(credited)
	assert(#credited == 2 and credited[1] == "a" and credited[2] == "b", "a and b, not c")
end

-- HP = HP_BASE × ISLAND_GROWTH^(island − 1) × tier HP mult, from the prompt
-- for this step (HP_BASE 5,000, ISLAND_GROWTH 25).
tests["enemy HP follows the island and tier formula"] = function()
	local tierMult =
		{ ["Very Easy"] = 1, Easy = 3, Medium = 15, Hard = 50, ["Very Hard"] = 100, Boss = 200 }
	for enemyId, enemy in Enemies do
		local island = Islands[enemy.island].number
		local expected = 5000 * 25 ^ (island - 1) * tierMult[enemy.tier]
		assert(close(enemy.hp, expected), `{enemyId} has {enemy.hp} HP, expected {expected}`)
	end
end

tests["the spawned enemies exist on their island with tier rules"] = function()
	for islandId, enemyIds in EnemySpawning.SPAWNED do
		assert(Islands[islandId], `unknown island {islandId}`)
		for _, enemyId in enemyIds do
			local enemy = Enemies[enemyId]
			assert(enemy, `unknown enemy {enemyId}`)
			assert(enemy.island == islandId, `{enemyId} is not on {islandId}`)
		end
	end
	for _, enemy in Enemies do
		local rules = EnemySpawning.BY_TIER[enemy.tier]
		assert(
			rules and rules.maxAlive > 0 and rules.respawnSeconds > 0,
			`no rules for {enemy.tier}`
		)
	end
end

tests["a spawn ring spaces its points evenly at the radius"] = function()
	local points = SpawnLayout.ring(4, 10)
	assert(#points == 4)
	for _, point in points do
		assert(close(math.sqrt(point.x ^ 2 + point.z ^ 2), 10))
	end
	assert(close(points[1].x, 10) and close(points[3].x, -10))
	local single = SpawnLayout.ring(1, 10)
	assert(#single == 1 and single[1].x == 0 and single[1].z == 0)
end

return tests
