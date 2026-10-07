--!strict
-- StatService: the one place a player's multipliers are worked out (TDD B2).
-- Other services ask here and never compute a multiplier themselves, so a
-- new source (a pet, a rebirth, a pass) only has to be added once.
--
-- Results are cached per player. Whatever changes a source (equipping a
-- pet, rebirthing, buying a pass) calls StatService.invalidate(player) so
-- the next read works the numbers out again.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Clicking = require(ReplicatedStorage.Shared.Config.Clicking)
local Drops = require(ReplicatedStorage.Shared.Config.Drops)
local Hatching = require(ReplicatedStorage.Shared.Config.Hatching)
local PetMath = require(ReplicatedStorage.Shared.Util.PetMath)
local PetRules = require(ReplicatedStorage.Shared.Config.PetRules)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local StatMath = require(ReplicatedStorage.Shared.Util.StatMath)
local ComplianceService = require(script.Parent.ComplianceService)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)

type Stats = {
	petMultiplier: number,
	rebirthMultiplier: number,
	energyPerClick: number,
}

local StatService = {}

local cache: { [Player]: Stats } = {}

-- Pet multiplier from equipped pets: 1 + each one's Energy bonus.
local function petMultiplierFor(player: Player): number
	local data = DataService.get(player)
	if data == nil then
		return StatMath.petMultiplier({})
	end
	return StatMath.petMultiplier(PetMath.equippedBonuses(data.pets, data.equippedPets))
end

local function rebirthMultiplierFor(player: Player): number
	local data = DataService.get(player)
	local rebirths = if data then data.stats.rebirths else 0
	return StatMath.rebirthMultiplier(rebirths)
end

local function compute(player: Player): Stats
	local petMultiplier = petMultiplierFor(player)
	local rebirthMultiplier = rebirthMultiplierFor(player)
	return {
		petMultiplier = petMultiplier,
		rebirthMultiplier = rebirthMultiplier,
		energyPerClick = StatMath.energyPerClick(petMultiplier, rebirthMultiplier),
	}
end

local function statsFor(player: Player): Stats
	local stats = cache[player]
	if stats == nil then
		stats = compute(player)
		-- Only cache once the profile is in, or the cache would keep the
		-- defaults a not-yet-loaded player gets.
		if DataService.isLoaded(player) then
			cache[player] = stats
		end
	end
	return stats
end

-- Mirrors the numbers the client needs to show real odds into player
-- attributes. Call again when a source changes.
function StatService.publishDisplayStats(player: Player)
	player:SetAttribute(Drops.DROP_BOOST_ATTRIBUTE, StatService.dropBoost(player))
	local luck = ComplianceService.luckFor(player, StatService.luckSources(player))
	player:SetAttribute(Hatching.LUCK_ATTRIBUTE, luck)
end

function StatService.start()
	Players.PlayerRemoving:Connect(StatService.invalidate)
	DataService.onLoaded(StatService.publishDisplayStats)
end

-- Drops the player's cached numbers. Call after changing anything a
-- multiplier depends on.
function StatService.invalidate(player: Player)
	cache[player] = nil
end

function StatService.petMultiplier(player: Player): number
	return statsFor(player).petMultiplier
end

function StatService.rebirthMultiplier(player: Player): number
	return statsFor(player).rebirthMultiplier
end

-- Energy one click earns: BASE_ENERGY_PER_CLICK × pet × rebirth multipliers.
function StatService.energyPerClick(player: Player): number
	return statsFor(player).energyPerClick
end

-- Pets the player can equip at once. Ranks and passes add to it later.
function StatService.equipSlots(_player: Player): number
	return PetRules.BASE_EQUIP_SLOTS
end

-- Sword damage multiplier. Swords arrive in Phase 2 (WeaponService); until
-- then every hit uses 1.
function StatService.swordMultiplier(_player: Player): number
	return 1
end

-- Coins multiplier on kill and quest rewards: x2 with the x2 Coins pass.
function StatService.coinMultiplier(player: Player): number
	if MonetizationService.ownsPass(player, "x2_coins") then
		return Products.X2_COINS_MULTIPLIER
	end
	return 1
end

-- Drop boost: each rolled drop chance is multiplied by (1 + boost). Nothing
-- gives one yet. The value is mirrored in the player's DROP_BOOST_ATTRIBUTE
-- so the enemy info panel shows boosted odds.
function StatService.dropBoost(_player: Player): number
	return 0
end

-- The player's active luck sources (Config/Luck id -> count). None exist
-- yet; potions, passes, server luck and friends add theirs here. Pass the
-- result to ComplianceService.luckFor, never sum it directly.
function StatService.luckSources(_player: Player): { [string]: number }
	return {}
end

-- Auto-clicks per second. The Auto-Click+ pass raises it once purchases
-- exist (MonetizationService).
function StatService.autoClickRate(_player: Player): number
	return Clicking.AUTO_CLICK_CPS
end

return StatService
