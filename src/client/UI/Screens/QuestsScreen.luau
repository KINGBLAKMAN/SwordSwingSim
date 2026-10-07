--!strict
-- QuestsScreen: every unlocked island's quest chain (GDD A13), in order.
-- Claimed quests show as done, the active one shows its progress or a
-- Claim button, and later ones wait until the one before is claimed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Islands = require(ReplicatedStorage.Shared.Config.Islands)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local QuestRules = require(ReplicatedStorage.Shared.Util.QuestRules)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local QuestController = require(script.Parent.Parent.Parent.Controllers.QuestController)
local Button = require(script.Parent.Parent.Components.Button)
local ProgressBar = require(script.Parent.Parent.Components.ProgressBar)
local ScreenFrame = require(script.Parent.ScreenFrame)
local useProfile = require(script.Parent.Parent.Hooks.useProfile)

local e = React.createElement

type QuestDef = Quests.QuestDef
type QuestEntry = QuestRules.QuestEntry
type Progress = {
	quests: { [string]: QuestEntry },
	islandsUnlocked: { [string]: boolean },
}

local ROW_HEIGHT = UI.QUESTS_SCREEN.ROW_HEIGHT
-- Share of a row's width for the status on the right.
local STATUS_WIDTH = 0.38

local function text(props: { text: string, color: Color3?, size: UDim2, position: UDim2? })
	return e("TextLabel", {
		Text = props.text,
		Font = UI.FONT,
		TextSize = UI.TEXT_SIZE.body,
		TextColor3 = props.color or UI.COLORS.text,
		TextStrokeTransparency = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Size = props.size,
		Position = props.position,
	})
end

local function statusFor(quest: QuestDef, quests: { [string]: QuestEntry })
	local status = QuestRules.status(quest, quests)
	local size = UDim2.new(STATUS_WIDTH, 0, 0, UI.MIN_TOUCH_TARGET)
	if status == "claimed" then
		return text({ text = "Done", color = UI.COLORS.barFill, size = size })
	elseif status == "locked" then
		return text({
			text = "Finish the quest above first",
			color = UI.COLORS.textMuted,
			size = size,
		})
	elseif status == "complete" then
		return e(Button, {
			text = "Claim",
			size = size,
			onActivated = function()
				QuestController.claim(quest.id)
			end,
		})
	end
	local entry = quests[quest.id]
	local progress = if entry then entry.progress else 0
	return e(ProgressBar, {
		fraction = progress / quest.count,
		label = `{progress} / {quest.count}`,
		size = UDim2.new(STATUS_WIDTH, 0, 0, UI.HUD.LEVEL_BAR_SIZE.Y),
	})
end

local function QuestRow(props: { quest: QuestDef, quests: { [string]: QuestEntry }, order: number })
	local quest = props.quest
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = UI.COLORS.panelLight,
		LayoutOrder = props.order,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, UI.CORNER_RADIUS) }),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, UI.GAP * 2),
			PaddingRight = UDim.new(0, UI.GAP * 2),
		}),
		Goal = text({
			text = QuestRules.describe(quest),
			size = UDim2.new(1 - STATUS_WIDTH, -UI.GAP, 0.55, 0),
		}),
		Reward = text({
			text = `Reward: {quest.rewardCoins} Coins`,
			color = UI.COLORS.textMuted,
			size = UDim2.new(1 - STATUS_WIDTH, -UI.GAP, 0.45, 0),
			position = UDim2.fromScale(0, 0.55),
		}),
		Status = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Align = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			Status = statusFor(quest, props.quests),
		}),
	})
end

-- Island ids in order of play.
local function islandsInOrder(): { string }
	local ids = {}
	for id in Islands do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return Islands[a].number < Islands[b].number
	end)
	return ids
end

local function selectProgress(profile: ProfileTypes.Profile): Progress
	return { quests = profile.quests, islandsUnlocked = profile.islandsUnlocked }
end

local function QuestsScreen()
	local progress = useProfile(selectProgress)
	local children: { [string]: any } = {
		List = e("UIListLayout", {
			Padding = UDim.new(0, UI.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	if progress then
		local order = 0
		for _, island in islandsInOrder() do
			local chain = Quests.CHAINS[island]
			if chain and progress.islandsUnlocked[island] then
				order += 1
				children[`{island}Title`] = e("TextLabel", {
					Text = Islands[island].name,
					Font = UI.FONT,
					TextSize = UI.TEXT_SIZE.title,
					TextColor3 = UI.COLORS.text,
					TextStrokeTransparency = 0,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, UI.TEXT_SIZE.title + UI.GAP),
					LayoutOrder = order,
				})
				for _, questId in chain do
					order += 1
					children[questId] = e(QuestRow, {
						quest = Quests.BY_ID[questId],
						quests = progress.quests,
						order = order,
					})
				end
			end
		end
	end

	return e(ScreenFrame, { title = "Quests" }, {
		List = e("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 6,
		}, children),
	})
end

return QuestsScreen
