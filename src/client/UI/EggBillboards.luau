--!strict
-- EggBillboards: the odds board over every egg stand (GDD A6): the cost,
-- each pet's chance, pity progress, and Details and Open buttons.
--
-- Rendered into PlayerGui (not the world) because a BillboardGui only
-- takes taps there. Odds come from useEggOdds, the same numbers the
-- server rolls with.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compliance = require(ReplicatedStorage.Shared.Config.Compliance)
local Eggs = require(ReplicatedStorage.Shared.Config.Eggs)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local Islands = require(ReplicatedStorage.Shared.Config.Islands)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local EggController = require(script.Parent.Parent.Controllers.EggController)
local Button = require(script.Parent.Components.Button)
local Router = require(script.Parent.Router)
local useEggOdds = require(script.Parent.Hooks.useEggOdds)

local e = React.createElement

local BOARD = UI.EGG_BILLBOARD

local function text(props: {
	text: string,
	color: Color3?,
	size: number?,
	alignment: Enum.TextXAlignment?,
	layoutOrder: number,
	width: UDim?,
})
	return e("TextLabel", {
		Text = props.text,
		Font = UI.FONT,
		TextSize = props.size or UI.TEXT_SIZE.small,
		TextColor3 = props.color or UI.COLORS.text,
		TextStrokeTransparency = 0,
		TextXAlignment = props.alignment or Enum.TextXAlignment.Center,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Size = UDim2.new(props.width or UDim.new(1, 0), UDim.new(0, BOARD.ROW_HEIGHT)),
		LayoutOrder = props.layoutOrder,
	})
end

-- The display name of an island's egg, e.g. "Ninja village egg".
local function eggName(eggId: string): string
	local egg = Eggs[eggId]
	local island = Islands[egg.island]
	return if island then `{island.name} egg` else egg.id
end

local function EggBoard(props: { stand: EggController.Stand })
	local eggId = props.stand.eggId
	local egg = Eggs[eggId]
	local odds = useEggOdds(eggId)

	local rows: { [string]: any } = {
		List = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
		Title = text({ text = eggName(eggId), size = UI.TEXT_SIZE.body, layoutOrder = 1 }),
		Cost = text({
			text = `{Format.number(egg.cost)} Coins`,
			color = UI.COLORS.primary,
			layoutOrder = 2,
		}),
	}
	for index, row in odds.display.rows do
		rows[`Pet{index}`] = e("Frame", {
			Size = UDim2.new(1, 0, 0, BOARD.ROW_HEIGHT),
			BackgroundTransparency = 1,
			LayoutOrder = 2 + index,
		}, {
			Name = text({
				text = row.name,
				color = UI.RARITY_COLORS[row.rarity],
				alignment = Enum.TextXAlignment.Left,
				width = UDim.new(0.65, 0),
				layoutOrder = 0,
			}),
			Percent = e("TextLabel", {
				Text = row.percent,
				Font = UI.FONT,
				TextSize = UI.TEXT_SIZE.small,
				TextColor3 = UI.COLORS.text,
				TextStrokeTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.35, 1),
				Position = UDim2.fromScale(0.65, 0),
			}),
		})
	end
	local after = 3 + #odds.display.rows
	rows.Pity = text({
		text = `{egg.pityMinRarity} pity: {odds.opensSincePity}/{egg.pityThreshold}`,
		color = UI.COLORS.textMuted,
		layoutOrder = after,
	})
	if odds.display.needsDisclaimer then
		rows.Disclaimer = text({
			text = Compliance.ROUNDING_DISCLAIMER,
			color = UI.COLORS.textMuted,
			layoutOrder = after + 1,
		})
	end
	rows.Buttons = e("Frame", {
		Size = UDim2.new(1, 0, 0, UI.MIN_TOUCH_TARGET),
		BackgroundTransparency = 1,
		LayoutOrder = after + 2,
	}, {
		-- Roblox wants a word on the odds button, not just an (i) icon.
		Details = e(Button, {
			text = "Details",
			color = UI.COLORS.secondary,
			textSize = UI.TEXT_SIZE.small,
			size = UDim2.new(0.48, 0, 1, 0),
			onActivated = function()
				EggController.select(eggId)
				Router.open("EggOdds")
			end,
		}),
		Open = e(Button, {
			text = "Open",
			size = UDim2.new(0.48, 0, 1, 0),
			position = UDim2.fromScale(1, 0),
			anchorPoint = Vector2.new(1, 0),
			onActivated = function()
				EggController.open(eggId)
			end,
		}),
	})

	return e("BillboardGui", {
		Adornee = props.stand.part,
		Size = UDim2.fromOffset(BOARD.SIZE.X, BOARD.SIZE.Y),
		StudsOffsetWorldSpace = Vector3.new(0, BOARD.HEIGHT_ABOVE, 0),
		MaxDistance = BOARD.MAX_DISTANCE,
		LightInfluence = 0,
		ResetOnSpawn = false,
		Active = true,
	}, {
		Panel = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = UI.COLORS.panel,
			BackgroundTransparency = 0.1,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, UI.CORNER_RADIUS) }),
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, UI.GAP),
				PaddingRight = UDim.new(0, UI.GAP),
				PaddingTop = UDim.new(0, UI.GAP),
				PaddingBottom = UDim.new(0, UI.GAP),
			}),
			Rows = e("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, rows),
		}),
	})
end

local function EggBillboards()
	local stands, setStands = React.useState(EggController.stands)

	React.useEffect(function()
		local connection = EggController.onStandsChanged(function()
			setStands(EggController.stands())
		end)
		setStands(EggController.stands())
		return function()
			connection:Disconnect()
		end
	end, {})

	local boards: { [string]: any } = {}
	for _, stand in stands do
		boards[stand.part:GetFullName()] = e(EggBoard, { stand = stand })
	end
	return e(React.Fragment, nil, boards)
end

return EggBillboards
