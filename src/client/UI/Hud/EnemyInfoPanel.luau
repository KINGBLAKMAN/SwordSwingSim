--!strict
-- EnemyInfoPanel: every drop an enemy can give and its chance (GDD A9),
-- shown while the player hovers (PC) or taps (mobile) an enemy.
--
-- The rows come from Util/DropTables with the player's drop boost, the
-- same table the server rolls, so the shown odds are the real odds, boost
-- included.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Drops = require(ReplicatedStorage.Shared.Config.Drops)
local DropTables = require(ReplicatedStorage.Shared.Util.DropTables)
local EnemySpawning = require(ReplicatedStorage.Shared.Config.EnemySpawning)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local OddsCalculator = require(ReplicatedStorage.Shared.Util.OddsCalculator)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local useInspectedEnemy = require(script.Parent.Parent.Hooks.useInspectedEnemy)

local e = React.createElement

local INFO = UI.ENEMY_INFO
local ATTRIBUTES = EnemySpawning.ATTRIBUTES

local function dropBoost(): number
	local boost = Players.LocalPlayer:GetAttribute(Drops.DROP_BOOST_ATTRIBUTE)
	return if typeof(boost) == "number" and boost >= 0 then boost else 0
end

local function amountText(min: number, max: number): string
	return if min == max then `×{min}` else `×{min}–{max}`
end

local function row(left: string, right: string, color: Color3, order: number)
	local function cell(text: string, alignment: Enum.TextXAlignment, position: UDim2)
		return e("TextLabel", {
			Text = text,
			Font = UI.FONT,
			TextSize = UI.TEXT_SIZE.small,
			TextColor3 = color,
			TextStrokeTransparency = 0,
			TextXAlignment = alignment,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.7, 1),
			Position = position,
		})
	end
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, INFO.ROW_HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, {
		Left = cell(left, Enum.TextXAlignment.Left, UDim2.fromScale(0, 0)),
		Right = cell(right, Enum.TextXAlignment.Right, UDim2.fromScale(0.3, 0)),
	})
end

local function EnemyInfoPanel()
	local model = useInspectedEnemy()
	local enemyId = model and model:GetAttribute(ATTRIBUTES.id)
	if model == nil or typeof(enemyId) ~= "string" then
		return nil
	end

	local tier = tostring(model:GetAttribute(ATTRIBUTES.tier))
	local dropTable = DropTables.withBoost(DropTables.forEnemy(enemyId), dropBoost())

	local rows: { [string]: any } = {
		List = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, UI.GAP),
			PaddingRight = UDim.new(0, UI.GAP),
			PaddingTop = UDim.new(0, UI.GAP),
			PaddingBottom = UDim.new(0, UI.GAP),
		}),
		Corner = e("UICorner", { CornerRadius = UDim.new(0, UI.CORNER_RADIUS) }),
		Title = row(
			tostring(model:GetAttribute(ATTRIBUTES.name)),
			tier,
			UI.TIER_COLORS[tier] or UI.COLORS.text,
			0
		),
	}
	local order = 1
	for _, entry in dropTable.granted do
		local name = DropTables.itemName(entry.kind, entry.item)
		rows[`Granted{order}`] =
			row(`{name} ×{Format.number(entry.amount)}`, "Always", UI.COLORS.text, order)
		order += 1
	end
	for _, entry in dropTable.rolled do
		local name = DropTables.itemName(entry.kind, entry.item)
		local label = if entry.kind == "pet"
			then `{name} (pet)`
			else `{name} {amountText(entry.min, entry.max)}`
		local color = if DropTables.isRare(entry.chance)
			then UI.RARE_BANNER.COLOR
			else UI.COLORS.textMuted
		rows[`Rolled{order}`] = row(label, OddsCalculator.formatPercent(entry.chance), color, order)
		order += 1
	end

	return e("Frame", {
		Size = UDim2.fromOffset(INFO.WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 0, INFO.TOP_OFFSET),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = UI.COLORS.panel,
		BackgroundTransparency = 0.15,
	}, rows)
end

return EnemyInfoPanel
