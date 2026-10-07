--!strict
-- FunnelService: logs the onboarding funnel (TDD B12, Config/Analytics)
-- so the D2 exit test can see where new players drop off. It listens to
-- the services that own each moment; ClickService calls reached() for the
-- first click.
--
-- profile.flags.onboardingLogged remembers which steps were logged, so a
-- rejoining player never logs one twice.

local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Analytics = require(ReplicatedStorage.Shared.Config.Analytics)
local Islands = require(ReplicatedStorage.Shared.Config.Islands)
local CombatService = require(script.Parent.CombatService)
local DataService = require(script.Parent.DataService)
local EggService = require(script.Parent.EggService)
local IslandService = require(script.Parent.IslandService)
local PetService = require(script.Parent.PetService)
local QuestService = require(script.Parent.QuestService)

local FunnelService = {}

-- Logs the step the first time this player reaches it.
function FunnelService.reached(player: Player, stepName: string)
	local data = DataService.get(player)
	local step = table.find(Analytics.ONBOARDING_STEPS, stepName)
	assert(step, `FunnelService: "{stepName}" isn't in Config/Analytics`)
	if data == nil or data.flags.onboardingLogged[stepName] then
		return
	end
	DataService.set(player, { "flags", "onboardingLogged", stepName }, true)
	local ok, err = pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
	if not ok then
		warn(`[FunnelService] couldn't log {stepName}: {err}`)
	end
end

function FunnelService.start()
	DataService.onLoaded(function(player)
		FunnelService.reached(player, "Joined")
	end)
	CombatService.killCredited:Connect(function(player)
		FunnelService.reached(player, "FirstKill")
	end)
	EggService.opened:Connect(function(player)
		FunnelService.reached(player, "FirstEgg")
	end)
	PetService.equippedChanged:Connect(function(player, equippedCount: number)
		if equippedCount > 0 then
			FunnelService.reached(player, "FirstEquip")
		end
	end)
	QuestService.claimed:Connect(function(player)
		FunnelService.reached(player, "FirstQuestClaimed")
	end)
	IslandService.unlocked:Connect(function(player, islandId: string)
		if Islands[islandId].number == 2 then
			FunnelService.reached(player, "Island2Unlocked")
		end
	end)
end

return FunnelService
