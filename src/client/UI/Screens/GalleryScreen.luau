--!strict
-- GalleryScreen: every component in the kit with sample data, so a change
-- to one can be checked by eye in Studio. The menu only shows it in Studio
-- (Config/UI.MENU, studioOnly). Nothing here talks to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Pets = require(ReplicatedStorage.Shared.Config.Pets)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local Button = require(script.Parent.Parent.Components.Button)
local ConfirmDialog = require(script.Parent.Parent.Components.ConfirmDialog)
local CurrencyChip = require(script.Parent.Parent.Components.CurrencyChip)
local ItemCard = require(script.Parent.Parent.Components.ItemCard)
local ProgressBar = require(script.Parent.Parent.Components.ProgressBar)
local TimerChip = require(script.Parent.Parent.Components.TimerChip)
local ScreenFrame = require(script.Parent.ScreenFrame)

local e = React.createElement

-- How long the sample timer runs, in seconds.
local SAMPLE_TIMER_SECONDS = 90

-- One sample per pet in Config/Pets, rarest last.
local function sortedPets(): { Pets.PetDef }
	local list = {}
	for _, pet in Pets do
		table.insert(list, pet)
	end
	table.sort(list, function(a, b)
		local rankA = table.find(Rarities.ORDER, a.rarity) or 0
		local rankB = table.find(Rarities.ORDER, b.rarity) or 0
		if rankA ~= rankB then
			return rankA < rankB
		end
		return a.name < b.name
	end)
	return list
end

-- A labelled row in the gallery's scrolling list.
local function Row(props: { order: number, height: number, children: any? })
	return e("Frame", {
		LayoutOrder = props.order,
		Size = UDim2.new(1, 0, 0, props.height),
		BackgroundTransparency = 1,
	}, {
		List = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, UI.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Wraps = true,
		}),
		Items = e(React.Fragment, nil, props.children),
	})
end

local function GalleryScreen()
	local confirmOpen, setConfirmOpen = React.useState(false)
	local selectedPet, setSelectedPet = React.useState(nil :: string?)
	-- Fixed when the screen opens so the sample timer counts down.
	local timerEndsAt = React.useMemo(function()
		return Workspace:GetServerTimeNow() + SAMPLE_TIMER_SECONDS
	end, {})

	local cards: { [string]: any } = {}
	for order, pet in sortedPets() do
		cards[pet.id] = e(ItemCard, {
			name = pet.name,
			rarity = pet.rarity,
			icon = `pet.{pet.id}.icon`,
			badge = pet.rarity,
			selected = selectedPet == pet.id,
			layoutOrder = order,
			onActivated = function()
				setSelectedPet(pet.id)
			end,
		})
	end

	local cardHeight = UI.ITEM_CARD_SIZE.Y
	local cardRows = math.ceil(#sortedPets() / 4)

	return e(React.Fragment, nil, {
		Screen = e(ScreenFrame, { title = "Component kit" }, {
			Scroll = e("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				ScrollBarThickness = UI.GAP,
			}, {
				List = e("UIListLayout", {
					Padding = UDim.new(0, UI.GAP * 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Chips = e(Row, { order = 1, height = UI.HUD.CURRENCY_CHIP_SIZE.Y }, {
					Coins = e(CurrencyChip, {
						label = "Coins",
						amount = "12.3K",
						icon = "ui.icon.coins",
						color = UI.HUD_CURRENCIES[2].color,
						layoutOrder = 1,
					}),
					Timer = e(
						TimerChip,
						{ label = "x2 Luck", endsAt = timerEndsAt, layoutOrder = 2 }
					),
				}),
				Bar = e(Row, { order = 2, height = UI.HUD.LEVEL_BAR_SIZE.Y }, {
					Progress = e(ProgressBar, { fraction = 0.6, label = "Pity 60 / 100" }),
				}),
				Buttons = e(Row, { order = 3, height = UI.MIN_TOUCH_TARGET }, {
					Primary = e(
						Button,
						{ text = "Open", layoutOrder = 1, onActivated = function() end }
					),
					Secondary = e(Button, {
						text = "Equip",
						color = UI.COLORS.secondary,
						layoutOrder = 2,
						onActivated = function() end,
					}),
					Danger = e(Button, {
						text = "Delete",
						color = UI.COLORS.danger,
						layoutOrder = 3,
						onActivated = function()
							setConfirmOpen(true)
						end,
					}),
					Disabled = e(Button, {
						text = "Locked",
						disabled = true,
						layoutOrder = 4,
						onActivated = function() end,
					}),
				}),
				Cards = e(Row, { order = 4, height = (cardHeight + UI.GAP) * cardRows }, cards),
			}),
		}),
		Confirm = confirmOpen and e(ConfirmDialog, {
			title = "Delete pet?",
			message = "This can't be undone. (Sample only: nothing is deleted.)",
			confirmText = "Delete",
			danger = true,
			onConfirm = function()
				setConfirmOpen(false)
			end,
			onCancel = function()
				setConfirmOpen(false)
			end,
		}),
	})
end

return GalleryScreen
