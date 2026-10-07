--!strict
-- HatchOverlay: the hatch animation (GDD A6). The egg shakes (harder for
-- rarer pets), cracks, shows the pet in its rarity color, then a results
-- grid with a "New!" tag on pets the player never had. Tapping skips ahead;
-- the Skip Animation setting goes straight to the results.
--
-- The server already decided what hatched (HatchResult); this only shows it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Pets = require(ReplicatedStorage.Shared.Config.Pets)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local React = require(ReplicatedStorage.Packages.React)
local Settings = require(ReplicatedStorage.Shared.Config.Settings)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local DataController = require(script.Parent.Parent.Controllers.DataController)
local HatchController = require(script.Parent.Parent.Controllers.HatchController)
local Icon = require(script.Parent.Components.Icon)
local ItemCard = require(script.Parent.Components.ItemCard)

local e = React.createElement

local HATCH = UI.HATCH

-- The animation's phases, in order. A hatch stores its phase as a
-- position in this list.
local SHAKE, CRACK, REVEAL, RESULTS = 1, 2, 3, 4
local PHASE_SECONDS =
	{ HATCH.SHAKE_SECONDS, HATCH.CRACK_SECONDS, HATCH.REVEAL_SECONDS, HATCH.RESULTS_SECONDS }

type Hatch = {
	-- Counts up per hatch, so timers from an old hatch don't move a new one.
	id: number,
	pets: { HatchController.HatchedPet },
	phase: number,
}

local function withPhase(id: number, pets: { HatchController.HatchedPet }, phase: number): Hatch
	return { id = id, pets = pets, phase = phase }
end

local function rarestPet(pets: { HatchController.HatchedPet }): string
	local best = pets[1].pet
	for _, hatched in pets do
		local rank = table.find(Rarities.ORDER, Pets[hatched.pet].rarity) :: number
		local bestRank = table.find(Rarities.ORDER, Pets[best].rarity) :: number
		if rank > bestRank then
			best = hatched.pet
		end
	end
	return best
end

local function skipsAnimation(): boolean
	local profile = DataController.get()
	return profile ~= nil and Settings.value(profile.settings, "skipHatchAnimation")
end

local function bigText(text: string, color: Color3, y: number)
	return e("TextLabel", {
		Text = text,
		Font = UI.FONT,
		TextSize = UI.TEXT_SIZE.title,
		TextColor3 = color,
		TextStrokeTransparency = 0,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(400, 40),
		Position = UDim2.fromScale(0.5, y),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
end

local function Egg(props: { phase: number, rarity: Rarities.Rarity })
	local eggRef = React.useRef(nil :: Frame?)

	React.useEffect(function(): (() -> ())?
		local egg = eggRef.current
		if egg == nil or props.phase ~= SHAKE then
			return nil
		end
		local degrees = HATCH.SHAKE_DEGREES[props.rarity] or HATCH.SHAKE_DEGREES.Common
		egg.Rotation = -degrees
		local swing = TweenInfo.new(
			HATCH.SHAKE_SWING_SECONDS,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true
		)
		local tween = TweenService:Create(egg, swing, { Rotation = degrees })
		tween:Play()
		return function()
			tween:Cancel()
			egg.Rotation = 0
		end
	end, { props.phase })

	local cracked = props.phase == CRACK
	return e("Frame", {
		ref = eggRef,
		Size = UDim2.fromOffset(HATCH.EGG_SIZE.X, HATCH.EGG_SIZE.Y),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = if cracked then UI.COLORS.text else HATCH.EGG_COLOR,
	}, {
		Round = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		-- The crack flashes in the color of what's inside.
		Stroke = e("UIStroke", {
			Color = if cracked then UI.RARITY_COLORS[props.rarity] else UI.COLORS.stroke,
			Thickness = if cracked then UI.STROKE_THICKNESS * 4 else UI.STROKE_THICKNESS,
		}),
	})
end

local function Results(props: { pets: { HatchController.HatchedPet } })
	local cards: { [string]: any } = {
		Grid = e("UIGridLayout", {
			CellSize = UDim2.fromOffset(UI.ITEM_CARD_SIZE.X, UI.ITEM_CARD_SIZE.Y),
			CellPadding = UDim2.fromOffset(UI.GAP, UI.GAP),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for index, hatched in props.pets do
		local pet = Pets[hatched.pet]
		cards[hatched.uid] = e(ItemCard, {
			name = pet.name,
			rarity = pet.rarity,
			icon = `pet.{pet.id}.icon`,
			badge = if hatched.isNew then "New!" else nil,
			layoutOrder = index,
		})
	end
	return e("Frame", {
		Size = UDim2.fromScale(0.9, 0.6),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}, cards)
end

local function HatchOverlay()
	local hatch: Hatch?, setHatch = React.useState(nil :: Hatch?)
	local hatchCount = React.useRef(0)

	React.useEffect(function()
		local connection = HatchController.onHatched(function(_eggId, pets)
			if #pets == 0 then
				return
			end
			hatchCount.current += 1
			local firstPhase = if skipsAnimation() then RESULTS else SHAKE
			setHatch(withPhase(hatchCount.current, pets, firstPhase))
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	-- Moves to the next phase (or closes) when this phase's time is up.
	local hatchId = if hatch then hatch.id else nil
	local phase = if hatch then hatch.phase else nil
	React.useEffect(function()
		if hatchId == nil or phase == nil then
			return
		end
		task.delay(PHASE_SECONDS[phase], function()
			setHatch(function(current: Hatch?): Hatch?
				if current == nil or current.id ~= hatchId or current.phase ~= phase then
					return current
				end
				-- After the results, the overlay closes.
				return if phase < RESULTS
					then withPhase(current.id, current.pets, phase + 1)
					else nil
			end)
		end)
	end, { hatchId, phase } :: { any })

	if hatch == nil then
		return nil
	end

	local rarest = Pets[rarestPet(hatch.pets)]
	local content: any
	if hatch.phase == SHAKE or hatch.phase == CRACK then
		content = e(Egg, { phase = hatch.phase, rarity = rarest.rarity })
	elseif hatch.phase == REVEAL then
		content = e(React.Fragment, nil, {
			Icon = e(Icon, {
				asset = `pet.{rarest.id}.icon`,
				fallbackText = rarest.name,
				color = UI.RARITY_COLORS[rarest.rarity],
				size = UDim2.fromOffset(HATCH.EGG_SIZE.X, HATCH.EGG_SIZE.X),
				position = UDim2.fromScale(0.5, 0.45),
				anchorPoint = Vector2.new(0.5, 0.5),
			}),
			Name = bigText(rarest.name, UI.COLORS.text, 0.72),
			Rarity = bigText(rarest.rarity, UI.RARITY_COLORS[rarest.rarity], 0.8),
		})
	else
		content = e(Results, { pets = hatch.pets })
	end

	return e("TextButton", {
		-- Full-screen so taps skip ahead instead of reaching the HUD.
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UI.COLORS.backdrop,
		BackgroundTransparency = UI.BACKDROP_TRANSPARENCY,
		[React.Event.Activated] = function()
			setHatch(function(current: Hatch?): Hatch?
				if current == nil or current.phase == RESULTS then
					return nil
				end
				return withPhase(current.id, current.pets, RESULTS)
			end)
		end,
	}, {
		Content = content,
		Hint = bigText(
			if hatch.phase == RESULTS then "Tap to close" else "Tap to skip",
			UI.COLORS.textMuted,
			0.92
		),
	})
end

return HatchOverlay
