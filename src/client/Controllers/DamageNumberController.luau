--!strict
-- DamageNumberController: the numbers that pop off an enemy when the
-- player hits it (GDD A9, TDD B8). Labels are pooled: at most
-- MAX_ON_SCREEN exist, and when all are showing, the oldest is reused.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage.Shared.Util.Format)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local Remotes = require(script.Parent.Parent.Net.Remotes)
local EnemyController = require(script.Parent.EnemyController)

local NUMBERS = UI.DAMAGE_NUMBERS
local FADE = TweenInfo.new(NUMBERS.SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

type Slot = {
	billboard: BillboardGui,
	label: TextLabel,
	tween: Tween?,
}

local DamageNumberController = {}

local slots: { Slot } = {}
-- Index of the slot to use next; slots are reused oldest first.
local nextSlot = 1
local random = Random.new()

local function newSlot(): Slot
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageNumber"
	billboard.Size = UDim2.fromOffset(NUMBERS.SIZE.X, NUMBERS.SIZE.Y)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Enabled = false

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = UI.FONT
	label.TextStrokeTransparency = 0
	label.Parent = billboard
	return { billboard = billboard, label = label, tween = nil }
end

local function takeSlot(): Slot
	if #slots < NUMBERS.MAX_ON_SCREEN then
		local slot = newSlot()
		table.insert(slots, slot)
		return slot
	end
	local slot = slots[nextSlot]
	nextSlot = nextSlot % NUMBERS.MAX_ON_SCREEN + 1
	if slot.tween then
		slot.tween:Cancel()
	end
	return slot
end

local function show(enemyUid: string, damage: number, isCrit: boolean)
	local model = EnemyController.byUid(enemyUid)
	local body = model and model.PrimaryPart
	if body == nil then
		return
	end

	local slot = takeSlot()
	local label = slot.label
	label.Text = if isCrit then `{Format.number(damage)}!` else Format.number(damage)
	label.TextColor3 = if isCrit then NUMBERS.CRIT_COLOR else NUMBERS.COLOR
	label.TextSize = if isCrit then NUMBERS.CRIT_TEXT_SIZE else NUMBERS.TEXT_SIZE
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0

	local start = Vector3.new(
		random:NextNumber(-NUMBERS.SPREAD, NUMBERS.SPREAD),
		body.Size.Y / 2,
		random:NextNumber(-NUMBERS.SPREAD, NUMBERS.SPREAD)
	)
	local billboard = slot.billboard
	billboard.Adornee = body
	billboard.StudsOffsetWorldSpace = start
	billboard.Enabled = true
	billboard.Parent = body

	local tween = TweenService:Create(billboard, FADE, {
		StudsOffsetWorldSpace = start + Vector3.new(0, NUMBERS.RISE, 0),
	})
	TweenService:Create(label, FADE, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then
			billboard.Enabled = false
		end
	end)
	slot.tween = tween
	tween:Play()
end

function DamageNumberController.start()
	Remotes.on("DamageFx", show)
end

return DamageNumberController
