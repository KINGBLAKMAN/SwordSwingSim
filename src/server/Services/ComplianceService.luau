--!strict
-- ComplianceService: knows which players can have paid random items and
-- paid trading (TDD B11, checklist C6).
--
-- On join it asks PolicyService for the player's policy. Until the answer
-- comes back, and if the lookup fails, the player counts as restricted.
--
-- Other services ask before acting:
--   * EggService: canOpenEgg before charging, and luckFor to get the luck
--     it passes to OddsCalculator.roll. luckFor drops paid luck for
--     restricted players, so their roll never has a paid modifier.
--   * ShopService: canBuyPaidRandom before selling luck or anything that
--     ends in a random roll.
--   * TradeService: canTrade before a trade with paid items.
-- The rules themselves live in Shared/Util/PaidRandomRules.

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComplianceConfig = require(ReplicatedStorage.Shared.Config.Compliance)
local Eggs = require(ReplicatedStorage.Shared.Config.Eggs)
local PaidRandomRules = require(ReplicatedStorage.Shared.Util.PaidRandomRules)

local ComplianceService = {}

local states: { [Player]: PaidRandomRules.PolicyState } = {}

local function stateOf(player: Player): PaidRandomRules.PolicyState
	return states[player] or PaidRandomRules.UNKNOWN_STATE
end

local function lookUpPolicy(player: Player)
	local ok, result = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if not ok then
		warn(
			`[ComplianceService] policy lookup failed for {player.Name}, treating as restricted: {result}`
		)
	end

	-- The player may have left during the lookup.
	if player.Parent ~= Players then
		return
	end

	local state = PaidRandomRules.policyState(ok, if ok then result else nil)
	states[player] = state
	player:SetAttribute(ComplianceConfig.RESTRICTED_ATTRIBUTE, state.paidRandomRestricted)
	player:SetAttribute(ComplianceConfig.TRADING_ATTRIBUTE, state.paidTradingAllowed)
end

function ComplianceService.start()
	Players.PlayerAdded:Connect(lookUpPolicy)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	-- Players who joined before this connected.
	for _, player in Players:GetPlayers() do
		task.spawn(lookUpPolicy, player)
	end
end

-- True if the player can't have paid random items, or their policy isn't
-- known yet.
function ComplianceService.isPaidRandomRestricted(player: Player): boolean
	return stateOf(player).paidRandomRestricted
end

-- Whether the player may buy something whose result is random or that
-- changes a random roll (luck potions, luck passes, server luck).
function ComplianceService.canBuyPaidRandom(player: Player): boolean
	return not ComplianceService.isPaidRandomRestricted(player)
end

-- Whether the player may trade items bought with Robux.
function ComplianceService.canTrade(player: Player): boolean
	return stateOf(player).paidTradingAllowed
end

-- Whether the player may open this egg at all.
function ComplianceService.canOpenEgg(player: Player, egg: Eggs.EggDef): boolean
	return PaidRandomRules.canOpenEgg(egg, ComplianceService.isPaidRandomRestricted(player))
end

-- The luck to roll with, from the player's active sources (source id ->
-- count). Paid sources are left out for restricted players.
function ComplianceService.luckFor(player: Player, activeSources: { [string]: number }): number
	return PaidRandomRules.luckFor(activeSources, ComplianceService.isPaidRandomRestricted(player))
end

return ComplianceService
