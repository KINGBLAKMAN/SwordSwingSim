--!strict
-- CombatService: sword hits and kill rewards (GDD A4, A9, TDD B7).
--
-- The client asks to hit an enemy with AttackTarget(enemyUid). The server
-- checks the enemy is alive, on the player's island and within reach of
-- the player's character as the server sees it, and that the player isn't
-- swinging faster than SWING_RATE. Then it rolls the crit with its own RNG
-- and works out the damage from the player's Energy.
--
-- When an enemy dies, everyone who dealt at least KILL_CREDIT_SHARE of its
-- max HP gets the kill (shared kill credit): CombatService.killCredited
-- fires once per credited player, and DropService hands out the rewards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BigNum = require(ReplicatedStorage.Shared.Util.BigNum)
local Combat = require(ReplicatedStorage.Shared.Config.Combat)
local CombatMath = require(ReplicatedStorage.Shared.Util.CombatMath)
local EnemySpawning = require(ReplicatedStorage.Shared.Config.EnemySpawning)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Remotes = require(script.Parent.Parent.Net.Remotes)
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)
local StatService = require(script.Parent.StatService)

local CombatService = {}

-- Fired with (player: Player, enemy: EnemyService.Enemy) for each player
-- who earned credit for a kill.
CombatService.killCredited = Signal.new()

local MIN_SECONDS_BETWEEN_SWINGS = EnemySpawning.SWING_INTERVAL_TOLERANCE / Combat.SWING_RATE

local lastSwingAt: { [Player]: number } = {}
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

-- The player's root part if their character is alive, else nil.
local function aliveRoot(player: Player): BasePart?
	local character = player.Character
	if character == nil then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
		return nil
	end
	return root
end

local function isInReach(root: BasePart, enemy: EnemyService.Enemy): boolean
	local reach = EnemySpawning.ATTACK_RANGE
		+ EnemySpawning.RANGE_TOLERANCE
		+ EnemyService.radius(enemy)
	return (root.Position - enemy.body.Position).Magnitude <= reach
end

local function onAttackTarget(player: Player, enemyUid: string)
	local data = DataService.get(player)
	local enemy = EnemyService.get(enemyUid)
	if data == nil or enemy == nil or enemy.island ~= data.currentIsland then
		return
	end

	local now = os.clock()
	if now - (lastSwingAt[player] or -math.huge) < MIN_SECONDS_BETWEEN_SWINGS then
		return
	end

	local root = aliveRoot(player)
	if root == nil or not isInReach(root, enemy) then
		return
	end
	lastSwingAt[player] = now

	local energy = BigNum.toNumber(data.currencies.energy)
	local isCrit = CombatMath.isCrit(randomFor(player):NextNumber(), Combat.CRIT_CHANCE)
	local damage = CombatMath.damagePerHit(energy, StatService.swordMultiplier(player), isCrit)
	if damage <= 0 then
		return
	end

	local dealt = EnemyService.applyDamage(enemy, player, damage)
	Remotes.fire("DamageFx", player, enemyUid, dealt, isCrit)
end

local function onEnemyKilled(enemy: EnemyService.Enemy)
	for _, player in CombatMath.creditedPlayers(enemy.damageBy, enemy.maxHp) do
		if DataService.isLoaded(player) then
			DataService.update(player, { "stats", "totalKills" }, function(kills)
				return kills + 1
			end)
			CombatService.killCredited:Fire(player, enemy)
		end
	end
end

function CombatService.start()
	Remotes.on("AttackTarget", onAttackTarget)
	EnemyService.killed:Connect(onEnemyKilled)
	Players.PlayerRemoving:Connect(function(player)
		lastSwingAt[player] = nil
		randoms[player] = nil
	end)
end

return CombatService
