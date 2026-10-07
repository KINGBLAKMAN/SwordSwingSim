--!strict
-- WorldService: makes sure every island in Config/World has a place to
-- stand (GDD A12). If the place already has Workspace.Islands.<island id>
-- (a real map), it's used as is. Otherwise a flat placeholder block-out is
-- built from Config/World: ground, a spawn, and enemy spawn points.
--
-- Other services find islands through WorldService.island(id).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Islands = require(ReplicatedStorage.Shared.Config.Islands)
local SpawnLayout = require(ReplicatedStorage.Shared.Util.SpawnLayout)
local World = require(ReplicatedStorage.Shared.Config.World)

local WorldService = {}

local islandsFolder: Folder

local function makePart(name: string, size: Vector3, position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- Invisible marker the enemy stands on. It doesn't collide or block
-- raycasts, so only the enemy itself is hit.
local function makeSpawnPoint(enemyId: string, position: Vector3): Part
	local point = makePart("EnemySpawn", Vector3.new(1, 1, 1), position)
	point.Transparency = 1
	point.CanCollide = false
	point.CanQuery = false
	point.CanTouch = false
	point:SetAttribute("Enemy", enemyId)
	return point
end

-- A big egg on a pedestal. EggService checks players are near it.
local function makeEggStand(eggId: string, groundPosition: Vector3): Part
	local pedestal =
		makePart("EggPedestal", Vector3.new(8, 2, 8), groundPosition + Vector3.new(0, 1, 0))
	pedestal.Color = Color3.fromRGB(90, 80, 70)

	local egg = makePart("EggStand", Vector3.new(5, 7, 5), groundPosition + Vector3.new(0, 5.5, 0))
	egg.Shape = Enum.PartType.Ball
	egg.Color = Color3.fromRGB(245, 235, 210)
	egg.Material = Enum.Material.SmoothPlastic
	egg:SetAttribute("Egg", eggId)
	pedestal.Parent = egg
	return egg
end

local function buildPlaceholder(islandId: string, layout: World.IslandLayout): Model
	local model = Instance.new("Model")
	model.Name = islandId

	local groundTop = layout.origin.Y
	local ground = makePart(
		"Ground",
		layout.groundSize,
		layout.origin - Vector3.new(0, layout.groundSize.Y / 2, 0)
	)
	ground.Color = layout.groundColor
	ground.Material = Enum.Material.Grass
	ground.Parent = model

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Anchored = true
	spawn.Position = layout.origin + layout.spawn + Vector3.new(0, 0.5, 0)
	spawn.Neutral = true
	spawn.Parent = model

	local island = Islands[islandId]
	if island then
		makeEggStand(island.egg, layout.origin + layout.egg).Parent = model
	end

	local spawns = Instance.new("Folder")
	spawns.Name = "EnemySpawns"
	for _, zone in layout.zones do
		for _, offset in SpawnLayout.ring(zone.count, zone.radius) do
			local position = layout.origin + zone.center + Vector3.new(offset.x, 0, offset.z)
			makeSpawnPoint(zone.enemy, Vector3.new(position.X, groundTop, position.Z)).Parent =
				spawns
		end
	end
	spawns.Parent = model

	return model
end

function WorldService.init()
	local existing = Workspace:FindFirstChild("Islands")
	if existing and existing:IsA("Folder") then
		islandsFolder = existing
	else
		islandsFolder = Instance.new("Folder")
		islandsFolder.Name = "Islands"
		islandsFolder.Parent = Workspace
	end

	for islandId, layout in World.ISLANDS do
		if islandsFolder:FindFirstChild(islandId) == nil then
			buildPlaceholder(islandId, layout).Parent = islandsFolder
		end
	end
end

-- The island's model in Workspace, or nil if the place doesn't have it.
function WorldService.island(islandId: string): Instance?
	return islandsFolder:FindFirstChild(islandId)
end

-- The island's enemy spawn points: parts with an Enemy attribute.
function WorldService.enemySpawnPoints(islandId: string): { BasePart }
	local points: { BasePart } = {}
	local island = WorldService.island(islandId)
	local folder = island and island:FindFirstChild("EnemySpawns")
	if folder == nil then
		return points
	end
	for _, child in folder:GetChildren() do
		if child:IsA("BasePart") and typeof(child:GetAttribute("Enemy")) == "string" then
			table.insert(points, child)
		end
	end
	return points
end

-- The island's egg stand: the part players open its egg at.
function WorldService.eggStand(islandId: string): BasePart?
	local island = WorldService.island(islandId)
	local stand = island and island:FindFirstChild("EggStand", true)
	if stand and stand:IsA("BasePart") then
		return stand
	end
	return nil
end

-- Where players arrive on the island, or nil if it has no Spawn.
function WorldService.spawnLocation(islandId: string): SpawnLocation?
	local island = WorldService.island(islandId)
	local spawn = island and island:FindFirstChild("Spawn")
	if spawn and spawn:IsA("SpawnLocation") then
		return spawn
	end
	return nil
end

return WorldService
