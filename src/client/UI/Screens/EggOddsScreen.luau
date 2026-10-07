--!strict
-- EggOddsScreen: the full odds list for one egg, opened by its Details
-- button (GDD A6, TDD B11). Shows the luck and pity the odds include, and
-- Roblox's rounding disclaimer when the rounded percents don't add up to
-- 100.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compliance = require(ReplicatedStorage.Shared.Config.Compliance)
local Eggs = require(ReplicatedStorage.Shared.Config.Eggs)
local Islands = require(ReplicatedStorage.Shared.Config.Islands)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local EggController = require(script.Parent.Parent.Parent.Controllers.EggController)
local ScreenFrame = require(script.Parent.ScreenFrame)
local useEggOdds = require(script.Parent.Parent.Hooks.useEggOdds)

local e = React.createElement

local ROW_HEIGHT = 26

local function line(props: {
	text: string,
	color: Color3?,
	order: number,
	alignment: Enum.TextXAlignment?,
})
	return e("TextLabel", {
		Text = props.text,
		Font = UI.FONT,
		TextSize = UI.TEXT_SIZE.body,
		TextColor3 = props.color or UI.COLORS.text,
		TextStrokeTransparency = 0,
		TextXAlignment = props.alignment or Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		LayoutOrder = props.order,
	})
end

local function OddsList(props: { eggId: string })
	local egg = Eggs[props.eggId]
	local odds = useEggOdds(props.eggId)

	local children: { [string]: any } = {
		List = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
	}
	for index, row in odds.display.rows do
		children[`Row{index}`] = e("Frame", {
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			BackgroundTransparency = 1,
			LayoutOrder = index,
		}, {
			Name = e("TextLabel", {
				Text = `{row.name}  ·  {row.rarity}`,
				Font = UI.FONT,
				TextSize = UI.TEXT_SIZE.body,
				TextColor3 = UI.RARITY_COLORS[row.rarity],
				TextStrokeTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.7, 1),
			}),
			Percent = e("TextLabel", {
				Text = row.percent,
				Font = UI.FONT,
				TextSize = UI.TEXT_SIZE.body,
				TextColor3 = UI.COLORS.text,
				TextStrokeTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.3, 1),
				Position = UDim2.fromScale(0.7, 0),
			}),
		})
	end

	local after = #odds.display.rows
	children.Luck =
		line({ text = `Total Luck +{odds.luck}`, color = UI.COLORS.textMuted, order = after + 1 })
	local pityText = if odds.pityActive
		then `Pity is ready: this open is guaranteed {egg.pityMinRarity} or better.`
		else `{egg.pityMinRarity} pity: {odds.opensSincePity}/{egg.pityThreshold}. At {egg.pityThreshold} opens without one, the next is guaranteed.`
	children.Pity = line({ text = pityText, color = UI.COLORS.textMuted, order = after + 2 })
	if odds.display.needsDisclaimer then
		children.Disclaimer = line({
			text = Compliance.ROUNDING_DISCLAIMER,
			color = UI.COLORS.textMuted,
			order = after + 3,
		})
	end

	return e("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
	}, children)
end

local function EggOddsScreen()
	local eggId = EggController.selected()
	local egg = if eggId then Eggs[eggId] else nil
	local island = if egg then Islands[egg.island] else nil
	local title = if island then `{island.name} egg odds` else "Egg odds"

	return e(ScreenFrame, { title = title }, {
		List = if eggId and egg then e(OddsList, { eggId = eggId }) else nil,
	})
end

return EggOddsScreen
