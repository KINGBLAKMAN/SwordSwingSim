--!strict
-- QuestTracker: the current island's active quest under the menu, with a
-- progress bar and a Claim button once it's complete (GDD A13). Hidden
-- when the island's chain is finished.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local QuestRules = require(ReplicatedStorage.Shared.Util.QuestRules)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local QuestController = require(script.Parent.Parent.Parent.Controllers.QuestController)
local Button = require(script.Parent.Parent.Components.Button)
local ProgressBar = require(script.Parent.Parent.Components.ProgressBar)
local useProfile = require(script.Parent.Parent.Hooks.useProfile)

local e = React.createElement

local LAYOUT = UI.QUEST_TRACKER

type Active = { questId: string, entry: QuestRules.QuestEntry? }

local function selectActive(profile: ProfileTypes.Profile): Active?
	local questId = QuestRules.activeQuest(profile.currentIsland, profile.quests)
	if questId == nil then
		return nil
	end
	return { questId = questId, entry = profile.quests[questId] }
end

local function QuestTracker(props: { layoutOrder: number? })
	-- A new table every update, but the tracker is small, so re-rendering
	-- it on each profile change is fine.
	local active = useProfile(selectActive)
	if active == nil then
		return nil
	end
	local quest = Quests.BY_ID[active.questId]
	local progress = if active.entry then active.entry.progress else 0
	local complete = QuestRules.isComplete(quest, active.entry)

	return e("Frame", {
		Size = UDim2.fromOffset(LAYOUT.WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, {
		List = e("UIListLayout", {
			Padding = UDim.new(0, UI.GAP / 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Title = e("TextLabel", {
			Text = `Quest: {QuestRules.describe(quest)}`,
			Font = UI.FONT,
			TextSize = UI.TEXT_SIZE.small,
			TextColor3 = UI.COLORS.text,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, LAYOUT.TITLE_HEIGHT),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
		}),
		Progress = if complete
			then e(Button, {
				text = `Claim {quest.rewardCoins} Coins`,
				textSize = UI.TEXT_SIZE.small,
				size = UDim2.new(1, 0, 0, UI.MIN_TOUCH_TARGET),
				layoutOrder = 2,
				onActivated = function()
					QuestController.claim(quest.id)
				end,
			})
			else e(ProgressBar, {
				fraction = progress / quest.count,
				label = `{progress} / {quest.count}`,
				size = UDim2.new(1, 0, 0, LAYOUT.BAR_HEIGHT),
				layoutOrder = 2,
			}),
	})
end

return QuestTracker
