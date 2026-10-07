--!strict
-- EnemyService: spawns, pools and respawns enemies (GDD A9, TDD B8).
--
-- Each spawn point (WorldService) holds one enemy of the kind its Enemy
-- attribute names. Every SPAWN_TICK the service fills empty points whose
-- respawn time has passed, within each kind's maxAlive and the island's
-- MAX_ALIVE_PER_ISLAND. Only islands with a player on them run; an island
-- that empties is cleared.
--
-- HP lives here in server tables. Clients see it through attributes on the
-- model (Config/EnemySpawning.ATTRIBUTES). Dead enemies' models go back to
-- a pool and are reused for the next spawn of the same kind.
--
-- CombatService deals damage through applyDamage(); EnemyService.killed
-- fires (enemy) when one dies so rewards and drops can be handed out.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EnemyLooks = require(ReplicatedStorage.Shared.Config.EnemyLooks)
local EnemySpawning = require(ReplicatedStorage.Shared.Config.EnemySpawning)
local Enemies = require(ReplicatedStorage.Shared.Config.Enemies)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DataService = require(script.Parent.DataService)
local WorldService = require(script.Parent.WorldService)

local ATTRIBUTES = EnemySpawning.ATTRIBUTES

export type Enemy = {
	uid: string,
	def: Enemies.EnemyDef,
	island: string,
	model: Model,
	body: BasePart,
	hp: number,
	maxHp: number,
	-- Damage dealt so far by each player, for shared kill credit.
	damageBy: { [Player]: number },
	point: BasePart,
}

local EnemyService = {}

-- Fired with (enemy: Enemy) right after an enemy dies.
EnemyService.killed = Signal.new()

local enemiesFolder: Folder
local liveByUid: { [string]: Enemy } = {}
local occupantOf: { [BasePart]: Enemy } = {}
-- os.clock() when an emptied spawn point may spawn again.
local readyAt: { [BasePart]: number } = {}
local pools: { [string]: { Model } } = {}
local nextUid = 0

-- Spawn points per island, looked up once.
local pointsByIsland: { [string]: { BasePart } } = {}
-- Which enemy ids may spawn on each island (Config/EnemySpawning.SPAWNED).
local spawnable: { [string]: { [string]: boolean } } = {}

local function newUid(): string
	nextUid += 1
	return `e{nextUid}`
end

local function countAlive(islandId: string, enemyId: string?): number
	local count = 0
	for _, enemy in liveByUid do
		if enemy.island == islandId and (enemyId == nil or enemy.def.id == enemyId) then
			count += 1
		end
	end
	return count
end

-- A placeholder block model for an enemy kind, until real rigs exist.
local function buildModel(def: Enemies.EnemyDef): Model
	local look = EnemyLooks[def.tier]
	local model = Instance.new("Model")
	model.Name = def.name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = look.bodySize
	body.Color = look.bodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.Parent = model
	model.PrimaryPart = body
	return model
end

local function takeModel(def: Enemies.EnemyDef): Model
	local pool = pools[def.id]
	if pool and #pool > 0 then
		return table.remove(pool) :: Model
	end
	return buildModel(def)
end

local function returnModel(enemy: Enemy)
	CollectionService:RemoveTag(enemy.model, EnemySpawning.TAG)
	enemy.model.Parent = nil
	local pool = pools[enemy.def.id]
	if pool == nil then
		pool = {}
		pools[enemy.def.id] = pool
	end
	table.insert(pool, enemy.model)
end

local function spawnAt(point: BasePart, islandId: string, def: Enemies.EnemyDef)
	local model = takeModel(def)
	local body = model.PrimaryPart :: BasePart
	body.CFrame = CFrame.new(point.Position + Vector3.new(0, body.Size.Y / 2, 0))

	local enemy: Enemy = {
		uid = newUid(),
		def = def,
		island = islandId,
		model = model,
		body = body,
		hp = def.hp,
		maxHp = def.hp,
		damageBy = {},
		point = point,
	}
	model:SetAttribute(ATTRIBUTES.uid, enemy.uid)
	model:SetAttribute(ATTRIBUTES.id, def.id)
	model:SetAttribute(ATTRIBUTES.name, def.name)
	model:SetAttribute(ATTRIBUTES.tier, def.tier)
	model:SetAttribute(ATTRIBUTES.island, islandId)
	model:SetAttribute(ATTRIBUTES.maxHp, enemy.maxHp)
	model:SetAttribute(ATTRIBUTES.hp, enemy.hp)

	liveByUid[enemy.uid] = enemy
	occupantOf[point] = enemy
	model.Parent = enemiesFolder
	-- Tag last, so a client that sees the tag also sees every attribute.
	CollectionService:AddTag(model, EnemySpawning.TAG)
end

-- Takes an enemy out of the world without a kill (its island emptied).
local function despawn(enemy: Enemy)
	liveByUid[enemy.uid] = nil
	occupantOf[enemy.point] = nil
	returnModel(enemy)
end

local function kill(enemy: Enemy)
	liveByUid[enemy.uid] = nil
	occupantOf[enemy.point] = nil
	readyAt[enemy.point] = os.clock() + EnemySpawning.BY_TIER[enemy.def.tier].respawnSeconds
	EnemyService.killed:Fire(enemy)
	returnModel(enemy)
end

-- Islands with at least one loaded player on them.
local function populatedIslands(): { [string]: boolean }
	local islands: { [string]: boolean } = {}
	for _, player in Players:GetPlayers() do
		local data = DataService.get(player)
		if data then
			islands[data.currentIsland] = true
		end
	end
	return islands
end

local function fillIsland(islandId: string, now: number)
	local allowed = spawnable[islandId]
	local points = pointsByIsland[islandId]
	if allowed == nil or points == nil then
		return
	end
	local aliveOnIsland = countAlive(islandId)
	for _, point in points do
		if aliveOnIsland >= EnemySpawning.MAX_ALIVE_PER_ISLAND then
			return
		end
		local enemyId = point:GetAttribute("Enemy") :: string
		local def = Enemies[enemyId]
		local isFree = occupantOf[point] == nil and now >= (readyAt[point] or 0)
		if def and allowed[enemyId] and isFree then
			if countAlive(islandId, enemyId) < EnemySpawning.BY_TIER[def.tier].maxAlive then
				spawnAt(point, islandId, def)
				aliveOnIsland += 1
			end
		end
	end
end

local function spawnTick()
	local populated = populatedIslands()
	local now = os.clock()
	for _, enemy in liveByUid do
		if not populated[enemy.island] then
			despawn(enemy)
		end
	end
	for islandId in populated do
		fillIsland(islandId, now)
	end
end

function EnemyService.init()
	enemiesFolder = Instance.new("Folder")
	enemiesFolder.Name = "Enemies"
	enemiesFolder.Parent = Workspace

	for islandId, enemyIds in EnemySpawning.SPAWNED do
		local allowed: { [string]: boolean } = {}
		for _, enemyId in enemyIds do
			assert(Enemies[enemyId], `EnemySpawning.SPAWNED: unknown enemy "{enemyId}"`)
			allowed[enemyId] = true
		end
		spawnable[islandId] = allowed
		pointsByIsland[islandId] = WorldService.enemySpawnPoints(islandId)
	end
end

function EnemyService.start()
	Players.PlayerRemoving:Connect(function(player)
		for _, enemy in liveByUid do
			enemy.damageBy[player] = nil
		end
	end)

	task.spawn(function()
		while true do
			spawnTick()
			task.wait(EnemySpawning.SPAWN_TICK)
		end
	end)
end

-- The live enemy with this uid, or nil if it's dead or never existed.
function EnemyService.get(uid: string): Enemy?
	return liveByUid[uid]
end

-- Studs from the enemy's center to its edge, for range checks.
function EnemyService.radius(enemy: Enemy): number
	local size = enemy.body.Size
	return math.max(size.X, size.Z) / 2
end

-- Takes up to `amount` HP off the enemy on the player's behalf and returns
-- the damage dealt. Kills it at 0 HP.
function EnemyService.applyDamage(enemy: Enemy, player: Player, amount: number): number
	if liveByUid[enemy.uid] ~= enemy then
		return 0
	end
	local dealt = math.min(amount, enemy.hp)
	enemy.hp -= dealt
	enemy.damageBy[player] = (enemy.damageBy[player] or 0) + dealt
	enemy.model:SetAttribute(ATTRIBUTES.hp, enemy.hp)
	if enemy.hp <= 0 then
		kill(enemy)
	end
	return dealt
end

return EnemyService
