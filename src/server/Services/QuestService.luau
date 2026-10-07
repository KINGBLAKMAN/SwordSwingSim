--!strict
-- QuestService: island quest chains (GDD A13). Each unlocked island has one
-- active quest. Kills (with shared kill credit) and egg opens move it
-- forward; once it's complete the player claims the reward with
-- ClaimQuest, and the next quest in the chain starts.
--
-- Progress lives in profile.quests[questId], so the client's tracker and
-- Quests screen read it straight from the profile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BigNum = require(ReplicatedStorage.Shared.Util.BigNum)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local QuestRules = require(ReplicatedStorage.Shared.Util.QuestRules)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local Remotes = require(script.Parent.Parent.Net.Remotes)
local CombatService = require(script.Parent.CombatService)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local EggService = require(script.Parent.EggService)
local EnemyService = require(script.Parent.EnemyService)
local StatService = require(script.Parent.StatService)

local QuestService = {}

-- Starts the active quest of each unlocked island that hasn't started yet.
-- Call it again when an island unlocks.
function QuestService.refresh(player: Player)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	for island in Quests.CHAINS do
		local questId = QuestRules.activeQuest(island, data.quests)
		if data.islandsUnlocked[island] and questId and data.quests[questId] == nil then
			DataService.set(player, { "quests", questId }, {
				progress = 0,
				claimed = false,
				assignedAt = os.time(),
			})
		end
	end
end

-- Adds `amount` to every active quest this goal counts toward.
local function advance(player: Player, kind: Quests.GoalKind, target: string, amount: number)
	local data = DataService.get(player)
	if data == nil then
		return
	end
	for island in Quests.CHAINS do
		local questId = QuestRules.activeQuest(island, data.quests)
		local quest = if questId then Quests.BY_ID[questId] else nil
		local entry = if questId then data.quests[questId] else nil
		if quest and entry and QuestRules.countsToward(quest, kind, target) then
			local progress = QuestRules.advance(quest, entry.progress, amount)
			DataService.set(player, { "quests", quest.id, "progress" }, progress)
			if entry.progress < quest.count and progress >= quest.count then
				Remotes.fire("Notify", player, "Quest complete! Claim your reward.")
			end
		end
	end
end

local function onClaimQuest(player: Player, questId: string)
	local data = DataService.get(player)
	local quest = Quests.BY_ID[questId]
	if data == nil or quest == nil then
		return
	end
	if QuestRules.status(quest, data.quests) ~= "complete" then
		return
	end
	DataService.set(player, { "quests", quest.id, "claimed" }, true)
	local coins = quest.rewardCoins * StatService.coinMultiplier(player)
	CurrencyService.add(player, "coins", BigNum.fromNumber(coins), `Quest:{quest.id}`)
	QuestService.refresh(player)
end

local function onKillCredited(player: Player, enemy: EnemyService.Enemy)
	advance(player, "kill", enemy.def.id, 1)
end

local function onEggOpened(player: Player, eggId: string, opens: number)
	advance(player, "open", eggId, opens)
end

local function onProfileLoaded(player: Player, _data: ProfileTypes.Profile)
	QuestService.refresh(player)
end

function QuestService.start()
	Remotes.on("ClaimQuest", onClaimQuest)
	CombatService.killCredited:Connect(onKillCredited)
	EggService.opened:Connect(onEggOpened)
	DataService.onLoaded(onProfileLoaded)
end

return QuestService
