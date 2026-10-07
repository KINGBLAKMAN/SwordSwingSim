--!strict
-- DropService: hands out what a kill drops (GDD A9).
--
-- For each player credited with a kill (CombatService.killCredited), it
-- gives every granted entry (the enemy's Coins) and rolls every rolled
-- entry on its own with the player's server-side Random. The table comes
-- from Util/DropTables with the player's drop boost, the same table the
-- enemy info panel shows. Nothing about a drop is decided on the client.
--
-- The player gets a DropFx with what dropped, for the toast and the rare
-- banner. Rare drops are logged.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BigNum = require(ReplicatedStorage.Shared.Util.BigNum)
local DropTables = require(ReplicatedStorage.Shared.Util.DropTables)
local Remotes = require(script.Parent.Parent.Net.Remotes)
local CombatService = require(script.Parent.CombatService)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)
local PetService = require(script.Parent.PetService)
local StatService = require(script.Parent.StatService)

local DropService = {}

-- One server-side Random per player (TDD B7).
local randoms: { [Player]: Random } = {}

local function randomFor(player: Player): Random
	local existing = randoms[player]
	if existing then
		return existing
	end
	local random = Random.new()
	randoms[player] = random
	return random
end

local function grantPet(player: Player, petId: string)
	if PetService.addPet(player, petId, "Drop") == nil then
		Remotes.fire("Notify", player, "Your pet storage is full, so a pet drop was lost.")
	end
end

-- Stores a sword in the profile's weapon list. Equipping and stats come
-- with WeaponService in Phase 2.
local function grantWeapon(player: Player, weaponId: string)
	local uid = HttpService:GenerateGUID(false)
	DataService.set(player, { "weapons", uid }, {
		uid = uid,
		id = weaponId,
		variant = "Normal",
		level = 1,
		locked = false,
		obtainedAt = os.time(),
		source = "Drop",
	})
	DataService.set(player, { "index", "weapons", weaponId }, true)
end

local function grant(player: Player, drop: DropTables.Drop)
	if drop.kind == "coins" then
		local coins = drop.amount * StatService.coinMultiplier(player)
		drop.amount = coins
		CurrencyService.add(player, "coins", BigNum.fromNumber(coins), "Kill")
	elseif drop.kind == "token" then
		CurrencyService.addToken(player, drop.item, drop.amount, "Kill")
	elseif drop.kind == "pet" then
		grantPet(player, drop.item)
	elseif drop.kind == "weapon" then
		for _ = 1, drop.amount do
			grantWeapon(player, drop.item)
		end
	end
end

local function onKillCredited(player: Player, enemy: EnemyService.Enemy)
	local dropTable =
		DropTables.withBoost(DropTables.forEnemy(enemy.def.id), StatService.dropBoost(player))
	local random = randomFor(player)
	local drops = DropTables.roll(dropTable, function()
		return random:NextNumber()
	end)

	for _, drop in drops do
		grant(player, drop)
		if DropTables.isRare(drop.chance) then
			print(
				`[DropService] rare drop: {player.Name} got {drop.item} from {enemy.def.id} ({drop.chance})`
			)
		end
	end
	Remotes.fire("DropFx", player, enemy.def.id, drops)
end

function DropService.start()
	CombatService.killCredited:Connect(onKillCredited)
	Players.PlayerRemoving:Connect(function(player)
		randoms[player] = nil
	end)
end

return DropService
