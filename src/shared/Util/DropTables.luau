--!strict
-- DropTables: each enemy's drop table, and the roll (GDD A9).
--
-- forEnemy() builds the table from Config/Drops. withBoost() applies a drop
-- boost to its chances. The server rolls the boosted table and the info
-- panel shows the same boosted table, so they can't disagree. The boost
-- is 0 until paid or earned drop boosts exist; when one does, the panel
-- already shows its effect.
--
-- Pure module: the server passes in its own Random (TDD B7), so Lune tests
-- can drive the roll.

local Drops = require(script.Parent.Parent.Config.Drops)
local Enemies = require(script.Parent.Parent.Config.Enemies)
local Pets = require(script.Parent.Parent.Config.Pets)
local Tokens = require(script.Parent.Parent.Config.Tokens)
local Weapons = require(script.Parent.Parent.Config.Weapons)

export type Kind = "pet" | "token" | "weapon" | "coins"

-- Rolled: independent chance on every kill, amount from min to max.
export type Rolled = { kind: Kind, item: string, chance: number, min: number, max: number }
-- Granted: always given on a kill.
export type Granted = { kind: Kind, item: string, amount: number }
export type DropTable = { rolled: { Rolled }, granted: { Granted } }
-- One thing that dropped.
export type Drop = { kind: Kind, item: string, amount: number, chance: number }

local DropTables = {}

local cache: { [string]: DropTable } = {}

local function build(enemy: Enemies.EnemyDef): DropTable
	local rolled: { Rolled } = {}

	local petChance = if enemy.tier == "Boss" then Drops.BOSS_PET_CHANCE else Drops.PET_CHANCE
	table.insert(rolled, { kind = "pet", item = enemy.pet, chance = petChance, min = 1, max = 1 })

	local tokenRule = Drops.TOKEN_BY_TIER[enemy.tier]
	local tokenIds: { string } = Drops.ISLAND_TOKENS[enemy.island] or {}
	for _, tokenId in tokenIds do
		table.insert(rolled, {
			kind = "token",
			item = tokenId,
			chance = tokenRule.chance,
			min = tokenRule.min,
			max = tokenRule.max,
		})
	end

	local extras: { Drops.ExtraDrop } = Drops.EXTRA[enemy.id] or {}
	for _, extra in extras do
		table.insert(rolled, {
			kind = extra.kind :: Kind,
			item = extra.item,
			chance = extra.chance,
			min = extra.min,
			max = extra.max,
		})
	end

	local granted: { Granted } = {
		{ kind = "coins", item = "coins", amount = enemy.coins },
	}
	return table.freeze({ rolled = table.freeze(rolled), granted = table.freeze(granted) })
end

-- The enemy's base drop table (no boost).
function DropTables.forEnemy(enemyId: string): DropTable
	local cached = cache[enemyId]
	if cached then
		return cached
	end
	local enemy = Enemies[enemyId]
	assert(enemy, `DropTables: unknown enemy "{enemyId}"`)
	local dropTable = build(enemy)
	cache[enemyId] = dropTable
	return dropTable
end

-- The table with a drop boost applied: each rolled chance becomes
-- chance × (1 + boost), at most 1. Boost 0 returns the table unchanged.
function DropTables.withBoost(dropTable: DropTable, boost: number): DropTable
	assert(boost >= 0, `DropTables: boost can't be negative, got {boost}`)
	if boost == 0 then
		return dropTable
	end
	local rolled: { Rolled } = {}
	for _, entry in dropTable.rolled do
		local boosted = table.clone(entry)
		boosted.chance = math.min(1, entry.chance * (1 + boost))
		table.insert(rolled, boosted)
	end
	return { rolled = rolled, granted = dropTable.granted }
end

-- Everything one kill gives: every granted entry, then each rolled entry
-- whose roll comes up. nextNumber returns a number in [0, 1), like
-- Random:NextNumber.
function DropTables.roll(dropTable: DropTable, nextNumber: () -> number): { Drop }
	local drops: { Drop } = {}
	for _, entry in dropTable.granted do
		table.insert(
			drops,
			{ kind = entry.kind, item = entry.item, amount = entry.amount, chance = 1 }
		)
	end
	for _, entry in dropTable.rolled do
		if nextNumber() < entry.chance then
			local amount = entry.min + math.floor(nextNumber() * (entry.max - entry.min + 1))
			table.insert(drops, {
				kind = entry.kind,
				item = entry.item,
				amount = math.min(amount, entry.max),
				chance = entry.chance,
			})
		end
	end
	return drops
end

-- Display name of a drop's item.
function DropTables.itemName(kind: Kind, item: string): string
	if kind == "pet" then
		return Pets[item].name
	elseif kind == "token" then
		return Tokens[item].name
	elseif kind == "weapon" then
		return Weapons[item].name
	end
	return "Coins"
end

function DropTables.isRare(chance: number): boolean
	return chance <= Drops.RARE_CHANCE
end

return DropTables
