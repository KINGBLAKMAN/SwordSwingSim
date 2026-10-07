--!strict
-- IslandsScreen: every island in order with what the player can do there
-- (GDD A12): travel to an unlocked one, pay to unlock the next, or see
-- what's still needed. Opened from the menu or an island gate.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Util.Format)
local IslandRules = require(ReplicatedStorage.Shared.Util.IslandRules)
local Islands = require(ReplicatedStorage.Shared.Config.Islands)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local IslandController = require(script.Parent.Parent.Parent.Controllers.IslandController)
local Button = require(script.Parent.Parent.Components.Button)
local ScreenFrame = require(script.Parent.ScreenFrame)
local useProfile = require(script.Parent.Parent.Hooks.useProfile)

local e = React.createElement

type Progress = {
	currentIsland: string,
	islandsUnlocked: { [string]: boolean },
	quests: { [string]: { progress: number, claimed: boolean, assignedAt: number } },
}

local ROW_HEIGHT = UI.QUESTS_SCREEN.ROW_HEIGHT
local BUTTON_WIDTH = UI.MIN_TOUCH_TARGET * 3.5

-- What the row says under the island's name, and its button, if any.
local function actionFor(islandId: string, status: IslandRules.Status): (string, any?)
	local island = Islands[islandId]
	local buttonSize = UDim2.fromOffset(BUTTON_WIDTH, UI.MIN_TOUCH_TARGET)
	local function button(text: string, onActivated: () -> ())
		return e(Button, {
			text = text,
			textSize = UI.TEXT_SIZE.small,
			size = buttonSize,
			position = UDim2.fromScale(1, 0.5),
			anchorPoint = Vector2.new(1, 0.5),
			onActivated = onActivated,
		})
	end

	if status == "here" then
		return "You are here", nil
	elseif status == "open" then
		return "Unlocked", button("Travel", function()
			IslandController.travel(islandId)
		end)
	elseif status == "unlockable" then
		return "Ready to unlock",
			button(`Unlock: {Format.number(island.unlockCost)} Coins`, function()
				IslandController.unlock(islandId)
			end)
	elseif status == "needsQuests" then
		local previous = IslandRules.previous(islandId)
		local previousName = if previous then Islands[previous].name else "the last island"
		return `Finish the {previousName} quests to unlock`, nil
	end
	return "Unlock the island before it first", nil
end

local function IslandRow(props: { islandId: string, progress: Progress, order: number })
	local island = Islands[props.islandId]
	local note, action =
		actionFor(props.islandId, IslandRules.status(props.islandId, props.progress))
	local textWidth = UDim2.new(1, -(BUTTON_WIDTH + UI.GAP), 0.5, 0)

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = UI.COLORS.panelLight,
		LayoutOrder = props.order,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, UI.CORNER_RADIUS) }),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, UI.GAP * 2),
			PaddingRight = UDim.new(0, UI.GAP),
		}),
		Name = e("TextLabel", {
			Text = `{island.number}. {island.name}`,
			Font = UI.FONT,
			TextSize = UI.TEXT_SIZE.body,
			TextColor3 = UI.COLORS.text,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = textWidth,
		}),
		Note = e("TextLabel", {
			Text = note,
			Font = UI.FONT,
			TextSize = UI.TEXT_SIZE.small,
			TextColor3 = UI.COLORS.textMuted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			BackgroundTransparency = 1,
			Size = textWidth,
			Position = UDim2.fromScale(0, 0.5),
		}),
		Action = action,
	})
end

local function selectProgress(profile: ProfileTypes.Profile): Progress
	return {
		currentIsland = profile.currentIsland,
		islandsUnlocked = profile.islandsUnlocked,
		quests = profile.quests,
	}
end

local function IslandsScreen()
	local progress = useProfile(selectProgress)
	local children: { [string]: any } = {
		List = e("UIListLayout", {
			Padding = UDim.new(0, UI.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	if progress then
		for order, islandId in IslandRules.inOrder() do
			children[islandId] =
				e(IslandRow, { islandId = islandId, progress = progress, order = order })
		end
	end

	return e(ScreenFrame, { title = "Islands" }, {
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

return IslandsScreen
