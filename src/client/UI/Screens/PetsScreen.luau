--!strict
-- PetsScreen: the pet inventory (GDD A7). A grid of owned pets, equipped
-- first and then strongest first, with a rarity filter. Tapping a pet shows
-- its detail on the right with Equip and Lock. Select mode picks several
-- pets to delete at once, after a ConfirmDialog.
--
-- Everything here is a request: the server checks it and the profile
-- update redraws the screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetMath = require(ReplicatedStorage.Shared.Util.PetMath)
local PetRules = require(ReplicatedStorage.Shared.Config.PetRules)
local Pets = require(ReplicatedStorage.Shared.Config.Pets)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local NotifyController = require(script.Parent.Parent.Parent.Controllers.NotifyController)
local PetController = require(script.Parent.Parent.Parent.Controllers.PetController)
local Button = require(script.Parent.Parent.Components.Button)
local ConfirmDialog = require(script.Parent.Parent.Components.ConfirmDialog)
local ItemCard = require(script.Parent.Parent.Components.ItemCard)
local ScreenFrame = require(script.Parent.ScreenFrame)
local usePlayerAttribute = require(script.Parent.Parent.Hooks.usePlayerAttribute)
local useProfile = require(script.Parent.Parent.Hooks.useProfile)

local e = React.createElement

type PetInstance = ProfileTypes.PetInstance
type Rarity = Rarities.Rarity
type Inventory = {
	pets: { [string]: PetInstance },
	equipped: { string },
	cap: number,
}

local LAYOUT = UI.PETS_SCREEN
local BAR_HEIGHT = UI.MIN_TOUCH_TARGET

local function label(props: {
	text: string,
	color: Color3?,
	textSize: number?,
	order: number?,
	size: UDim2?,
	alignment: Enum.TextXAlignment?,
})
	return e("TextLabel", {
		Text = props.text,
		Font = UI.FONT,
		TextSize = props.textSize or UI.TEXT_SIZE.body,
		TextColor3 = props.color or UI.COLORS.text,
		TextStrokeTransparency = 0,
		TextXAlignment = props.alignment or Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Size = props.size or UDim2.new(1, 0, 0, LAYOUT.ROW_HEIGHT),
		LayoutOrder = props.order,
	})
end

local function percent(bonus: number): string
	return `+{math.round(bonus * 100)}% Energy`
end

-- The next filter after `current`: All, then each rarity the player owns.
local function nextFilter(current: Rarity?, owned: { Rarity }): Rarity?
	if current == nil then
		return owned[1]
	end
	local index = table.find(owned, current)
	return if index then owned[index + 1] else nil
end

local function TopBar(props: {
	inventory: Inventory,
	slots: number,
	filter: Rarity?,
	selecting: boolean,
	onFilter: () -> (),
	onToggleSelect: () -> (),
})
	local inventory = props.inventory
	local buttonWidth = UI.MIN_TOUCH_TARGET * 2.4
	local counts = `Equipped {#inventory.equipped}/{props.slots}   Pets {PetMath.count(
		inventory.pets
	)}/{inventory.cap}`

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
		BackgroundTransparency = 1,
	}, {
		Counts = label({
			text = counts,
			color = UI.COLORS.textMuted,
			textSize = UI.TEXT_SIZE.small,
			size = UDim2.new(1, -(buttonWidth + UI.GAP) * 3, 1, 0),
		}),
		Buttons = e("Frame", {
			Size = UDim2.new(0, (buttonWidth + UI.GAP) * 3, 1, 0),
			Position = UDim2.fromScale(1, 0),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
		}, {
			List = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0, UI.GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Filter = e(Button, {
				text = props.filter or "All",
				color = if props.filter
					then UI.RARITY_COLORS[props.filter]
					else UI.COLORS.panelLight,
				textSize = UI.TEXT_SIZE.small,
				size = UDim2.fromOffset(buttonWidth, BAR_HEIGHT),
				layoutOrder = 1,
				onActivated = props.onFilter,
			}),
			EquipBest = e(Button, {
				text = "Equip Best",
				textSize = UI.TEXT_SIZE.small,
				disabled = PetMath.count(inventory.pets) == 0,
				size = UDim2.fromOffset(buttonWidth, BAR_HEIGHT),
				layoutOrder = 2,
				onActivated = PetController.equipBest,
			}),
			Select = e(Button, {
				text = if props.selecting then "Done" else "Select",
				color = UI.COLORS.secondary,
				textSize = UI.TEXT_SIZE.small,
				size = UDim2.fromOffset(buttonWidth, BAR_HEIGHT),
				layoutOrder = 3,
				onActivated = props.onToggleSelect,
			}),
		}),
	})
end

local function PetGrid(props: {
	list: { PetInstance },
	equipped: { string },
	isPicked: (uid: string) -> boolean,
	onTap: (pet: PetInstance) -> (),
})
	local children: { [string]: any } = {
		Grid = e("UIGridLayout", {
			CellSize = UDim2.fromOffset(UI.ITEM_CARD_SIZE.X, UI.ITEM_CARD_SIZE.Y),
			CellPadding = UDim2.fromOffset(UI.GAP, UI.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for index, pet in props.list do
		local def = Pets[pet.id]
		local badge = if table.find(props.equipped, pet.uid)
			then "Equipped"
			elseif pet.locked then "Locked"
			else nil
		children[pet.uid] = e(ItemCard, {
			name = def.name,
			rarity = def.rarity,
			icon = `pet.{def.id}.icon`,
			badge = badge,
			selected = props.isPicked(pet.uid),
			layoutOrder = index,
			onActivated = function()
				props.onTap(pet)
			end,
		})
	end
	if #props.list == 0 then
		children.Empty = label({ text = "No pets yet. Open an egg or defeat enemies." })
	end

	return e("ScrollingFrame", {
		Size = UDim2.new(1 - LAYOUT.DETAIL_WIDTH, -UI.GAP, 1, -(BAR_HEIGHT + UI.GAP)),
		Position = UDim2.fromOffset(0, BAR_HEIGHT + UI.GAP),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
	}, children)
end

local function detailColumn(children: { [string]: any })
	children.List = e("UIListLayout", {
		Padding = UDim.new(0, UI.GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	return e("Frame", {
		Size = UDim2.new(LAYOUT.DETAIL_WIDTH, 0, 1, -(BAR_HEIGHT + UI.GAP)),
		Position = UDim2.new(1, 0, 0, BAR_HEIGHT + UI.GAP),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
	}, children)
end

local function PetDetail(props: { pet: PetInstance, equipped: { string }, slots: number })
	local pet = props.pet
	local def = Pets[pet.id]
	local isEquipped = table.find(props.equipped, pet.uid) ~= nil
	local slotsFull = #props.equipped >= props.slots
	local status = {}
	if isEquipped then
		table.insert(status, "Equipped")
	end
	if pet.locked then
		table.insert(status, "Locked")
	end

	return detailColumn({
		Name = label({ text = def.name, textSize = UI.TEXT_SIZE.title, order = 1 }),
		Rarity = label({ text = def.rarity, color = UI.RARITY_COLORS[def.rarity], order = 2 }),
		Bonus = label({ text = percent(def.energyBonus), order = 3 }),
		Status = label({
			text = table.concat(status, " · "),
			color = UI.COLORS.textMuted,
			order = 4,
		}),
		Equip = e(Button, {
			text = if isEquipped then "Unequip" elseif slotsFull then "Slots full" else "Equip",
			color = if isEquipped then UI.COLORS.panelLight else UI.COLORS.primary,
			disabled = not isEquipped and slotsFull,
			size = UDim2.new(1, 0, 0, UI.MIN_TOUCH_TARGET),
			layoutOrder = 5,
			onActivated = function()
				if isEquipped then
					PetController.unequip(pet.uid)
				else
					PetController.equip(pet.uid)
				end
			end,
		}),
		Lock = e(Button, {
			text = if pet.locked then "Unlock" else "Lock",
			color = UI.COLORS.secondary,
			size = UDim2.new(1, 0, 0, UI.MIN_TOUCH_TARGET),
			layoutOrder = 6,
			onActivated = function()
				PetController.setLocked(pet.uid, not pet.locked)
			end,
		}),
	})
end

local function SelectPanel(props: { count: number, onDelete: () -> (), onClear: () -> () })
	return detailColumn({
		Hint = label({
			text = "Tap pets to pick them. Locked and equipped pets can't be deleted.",
			color = UI.COLORS.textMuted,
			size = UDim2.new(1, 0, 0, LAYOUT.ROW_HEIGHT * 3),
			order = 1,
		}),
		Delete = e(Button, {
			text = `Delete ({props.count})`,
			color = UI.COLORS.danger,
			disabled = props.count == 0,
			size = UDim2.new(1, 0, 0, UI.MIN_TOUCH_TARGET),
			layoutOrder = 2,
			onActivated = props.onDelete,
		}),
		Clear = e(Button, {
			text = "Clear",
			color = UI.COLORS.panelLight,
			disabled = props.count == 0,
			size = UDim2.new(1, 0, 0, UI.MIN_TOUCH_TARGET),
			layoutOrder = 3,
			onActivated = props.onClear,
		}),
	})
end

local function selectInventory(profile: ProfileTypes.Profile): Inventory?
	return { pets = profile.pets, equipped = profile.equippedPets, cap = profile.petStorageCap }
end

local function PetsScreen()
	local inventory = useProfile(selectInventory)
	local slots = usePlayerAttribute(PetRules.SLOTS_ATTRIBUTE)
	local filter: Rarity?, setFilter = React.useState(nil :: Rarity?)
	local shownUid: string?, setShownUid = React.useState(nil :: string?)
	local selecting, setSelecting = React.useState(false)
	local picked: { [string]: boolean }, setPicked = React.useState({} :: { [string]: boolean })
	local confirming, setConfirming = React.useState(false)

	if inventory == nil then
		return e(ScreenFrame, { title = "Pets" })
	end
	local slotCount = if typeof(slots) == "number" then slots else PetRules.BASE_EQUIP_SLOTS

	-- Picks of pets that were deleted or traded away no longer count.
	local pickedUids = {}
	for uid in picked do
		if inventory.pets[uid] then
			table.insert(pickedUids, uid)
		end
	end
	local shownPet = if shownUid then inventory.pets[shownUid] else nil

	local function onTap(pet: PetInstance)
		if not selecting then
			setShownUid(pet.uid)
			return
		end
		local blocker = PetMath.deleteBlocker(pet, inventory.equipped)
		if blocker and not picked[pet.uid] then
			NotifyController.show(`That pet is {blocker}, so it can't be deleted.`)
			return
		end
		local nextPicked = table.clone(picked)
		if picked[pet.uid] then
			nextPicked[pet.uid] = nil
		else
			nextPicked[pet.uid] = true
		end
		setPicked(nextPicked)
	end

	local side
	if selecting then
		side = e(SelectPanel, {
			count = #pickedUids,
			onDelete = function()
				setConfirming(true)
			end,
			onClear = function()
				setPicked({})
			end,
		})
	elseif shownPet then
		side = e(PetDetail, { pet = shownPet, equipped = inventory.equipped, slots = slotCount })
	else
		side = detailColumn({
			Hint = label({ text = "Tap a pet to see it.", color = UI.COLORS.textMuted }),
		})
	end

	return e(ScreenFrame, { title = "Pets" }, {
		TopBar = e(TopBar, {
			inventory = inventory,
			slots = slotCount,
			filter = filter,
			selecting = selecting,
			onFilter = function()
				setFilter(nextFilter(filter, PetMath.ownedRarities(inventory.pets)))
			end,
			onToggleSelect = function()
				setSelecting(not selecting)
				setPicked({})
			end,
		}),
		Grid = e(PetGrid, {
			list = PetMath.inventoryList(inventory.pets, inventory.equipped, filter),
			equipped = inventory.equipped,
			isPicked = function(uid: string): boolean
				return if selecting then picked[uid] == true else uid == shownUid
			end,
			onTap = onTap,
		}),
		Side = side,
		Confirm = confirming and e(ConfirmDialog, {
			title = `Delete {#pickedUids} pets?`,
			message = "Deleted pets are gone for good.",
			confirmText = "Delete",
			danger = true,
			onConfirm = function()
				PetController.delete(pickedUids)
				setConfirming(false)
				setPicked({})
			end,
			onCancel = function()
				setConfirming(false)
			end,
		}),
	})
end

return PetsScreen
