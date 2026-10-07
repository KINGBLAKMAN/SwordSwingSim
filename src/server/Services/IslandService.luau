--!strict
-- IslandService: unlocking islands and traveling between them (GDD A12).
--
--   UnlockIsland(islandId): checks IslandRules (the island before it is
--     unlocked and its quests are done), then takes the unlock cost in
--     Coins and moves the player there.
--   Teleport(islandId): moves the player to an island they've unlocked.
--
-- profile.currentIsland decides which island's enemies run and where the
-- player respawns. Placeholder islands are far apart, so walking over isn't
-- possible.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BigNum = require(ReplicatedStorage.Shared.Util.BigNum)
local DataConfig = require(ReplicatedStorage.Shared.Config.Data)
local IslandRules = require(ReplicatedStorage.Shared.Util.IslandRules)
local Islands = require(ReplicatedStorage.Shared.Config.Islands)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local Travel = require(ReplicatedStorage.Shared.Config.Travel)
local Remotes = require(script.Parent.Parent.Net.Remotes)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local QuestService = require(script.Parent.QuestService)
local WorldService = require(script.Parent.WorldService)

local IslandService = {}

local function notify(player: Player, message: string)
	Remotes.fire("Notify", player, message)
end

-- Respawns go to this island, and a living character moves there now.
local function placeOn(player: Player, islandId: string)
	local spawn = WorldService.spawnLocation(islandId)
	if spawn == nil then
		return
	end
	player.RespawnLocation = spawn
	local character = player.Character
	if character then
		character:PivotTo(spawn.CFrame + Vector3.new(0, Travel.ARRIVE_HEIGHT, 0))
	end
end

local function moveTo(player: Player, islandId: string)
	DataService.set(player, { "currentIsland" }, islandId)
	placeOn(player, islandId)
end

local function onTeleport(player: Player, islandId: string)
	local data = DataService.get(player)
	if data == nil or Islands[islandId] == nil then
		return
	end
	local status = IslandRules.status(islandId, data)
	if status == "open" then
		moveTo(player, islandId)
	elseif status ~= "here" then
		notify(player, "Unlock that island first.")
	end
end

local function onUnlockIsland(player: Player, islandId: string)
	local data = DataService.get(player)
	local island = Islands[islandId]
	if data == nil or island == nil then
		return
	end
	local status = IslandRules.status(islandId, data)
	if status == "needsPrevious" then
		notify(player, "Unlock the island before it first.")
		return
	elseif status == "needsQuests" then
		notify(player, "Finish this island's quests first.")
		return
	elseif status ~= "unlockable" then
		return
	end

	-- Every island is priced in Coins (Config/Islands).
	assert(island.unlockCurrency == "coins", `IslandService: {islandId} isn't priced in Coins`)
	local cost = BigNum.fromNumber(island.unlockCost)
	if not CurrencyService.trySpend(player, "coins", cost, `Island:{islandId}`) then
		notify(player, "Not enough Coins.")
		return
	end
	DataService.set(player, { "islandsUnlocked", islandId }, true)
	notify(player, `{island.name} unlocked!`)
	QuestService.refresh(player)
	moveTo(player, islandId)
end

local function onProfileLoaded(player: Player, data: ProfileTypes.Profile)
	-- A saved island the config no longer has falls back to the first.
	local islandId = if Islands[data.currentIsland]
		then data.currentIsland
		else DataConfig.STARTING_ISLAND
	if islandId ~= data.currentIsland then
		DataService.set(player, { "currentIsland" }, islandId)
	end
	placeOn(player, islandId)
end

local function onPlayerAdded(player: Player)
	-- Until the profile loads, spawn on the first island rather than at a
	-- random island's SpawnLocation.
	local spawn = WorldService.spawnLocation(DataConfig.STARTING_ISLAND)
	if spawn then
		player.RespawnLocation = spawn
	end
end

function IslandService.start()
	Remotes.on("UnlockIsland", onUnlockIsland)
	Remotes.on("Teleport", onTeleport)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	DataService.onLoaded(onProfileLoaded)
end

return IslandService
