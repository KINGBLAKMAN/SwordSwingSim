--!strict
-- EnemyController: keeps track of the enemies the server spawns and draws
-- each one's name, difficulty and HP bar (GDD A9, TDD B8).
--
-- The server tags every live enemy model and puts its HP in attributes.
-- This listens for the tag, so it sees enemies come and go (models are
-- pooled on the server, so the same model can come back as a new enemy).
--
-- The billboards are plain Instances rather than React: there's one per
-- enemy in the world and each only changes its HP fill.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemySpawning = require(ReplicatedStorage.Shared.Config.EnemySpawning)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local UI = require(ReplicatedStorage.Shared.Config.UI)

local ATTRIBUTES = EnemySpawning.ATTRIBUTES
local BILLBOARD = UI.ENEMY_BILLBOARD

type Tracked = {
	uid: string,
	billboard: BillboardGui,
	connections: { RBXScriptConnection },
}

local EnemyController = {}

local tracked: { [Model]: Tracked } = {}
local byUid: { [string]: Model } = {}

-- The enemy's current and max HP from its attributes.
function EnemyController.hp(model: Model): (number, number)
	local hp = model:GetAttribute(ATTRIBUTES.hp)
	local maxHp = model:GetAttribute(ATTRIBUTES.maxHp)
	return (if typeof(hp) == "number" then hp else 0),
		(if typeof(maxHp) == "number" then maxHp else 1)
end

function EnemyController.isAlive(model: Model): boolean
	return tracked[model] ~= nil and (EnemyController.hp(model)) > 0
end

function EnemyController.uid(model: Model): string?
	local entry = tracked[model]
	return if entry then entry.uid else nil
end

function EnemyController.byUid(uid: string): Model?
	return byUid[uid]
end

-- Every live enemy model this client knows about.
function EnemyController.all(): { [Model]: any }
	return tracked
end

local function label(
	name: string,
	text: string,
	size: UDim2,
	position: UDim2,
	color: Color3
): TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = name
	textLabel.Text = text
	textLabel.Font = UI.FONT
	textLabel.TextScaled = true
	textLabel.TextColor3 = color
	textLabel.TextStrokeTransparency = 0
	textLabel.BackgroundTransparency = 1
	textLabel.Size = size
	textLabel.Position = position
	return textLabel
end

local function buildBillboard(model: Model, body: BasePart): BillboardGui
	local tier = tostring(model:GetAttribute(ATTRIBUTES.tier))

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EnemyInfo"
	billboard.Adornee = body
	billboard.Size = UDim2.fromOffset(BILLBOARD.SIZE.X, BILLBOARD.SIZE.Y)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, body.Size.Y / 2 + BILLBOARD.HEIGHT_ABOVE, 0)
	billboard.MaxDistance = BILLBOARD.MAX_DISTANCE
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false

	local name = tostring(model:GetAttribute(ATTRIBUTES.name))
	label("Name", name, UDim2.fromScale(1, 0.34), UDim2.fromScale(0, 0), UI.COLORS.text).Parent =
		billboard
	label(
		"Tier",
		tier,
		UDim2.fromScale(1, 0.26),
		UDim2.fromScale(0, 0.34),
		UI.TIER_COLORS[tier] or UI.COLORS.text
	).Parent =
		billboard

	local bar = Instance.new("Frame")
	bar.Name = "HpBar"
	bar.Size = UDim2.fromScale(1, 0.36)
	bar.Position = UDim2.fromScale(0, 0.64)
	bar.BackgroundColor3 = UI.COLORS.barBack
	bar.BorderSizePixel = 0
	bar.Parent = billboard

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = BILLBOARD.HP_FILL
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = bar

	label("Text", "", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), UI.COLORS.text).Parent = bar

	billboard.Parent = model
	return billboard
end

local function refreshHp(model: Model, billboard: BillboardGui)
	local hp, maxHp = EnemyController.hp(model)
	local bar = billboard:FindFirstChild("HpBar") :: Frame
	local fill = bar:FindFirstChild("Fill") :: Frame
	local text = bar:FindFirstChild("Text") :: TextLabel
	fill.Size = UDim2.fromScale(math.clamp(hp / maxHp, 0, 1), 1)
	text.Text = `{Format.number(hp)} / {Format.number(maxHp)}`
end

local function stopTracking(model: Model)
	local entry = tracked[model]
	if entry == nil then
		return
	end
	tracked[model] = nil
	if byUid[entry.uid] == model then
		byUid[entry.uid] = nil
	end
	for _, connection in entry.connections do
		connection:Disconnect()
	end
	entry.billboard:Destroy()
end

local function startTracking(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	local model = instance
	local body = model.PrimaryPart
	local uid = model:GetAttribute(ATTRIBUTES.uid)
	if body == nil or typeof(uid) ~= "string" then
		return
	end
	-- A pooled model can be re-tagged as a new enemy before the old entry
	-- was cleared.
	stopTracking(model)

	local billboard = buildBillboard(model, body)
	refreshHp(model, billboard)
	local connections = {
		model:GetAttributeChangedSignal(ATTRIBUTES.hp):Connect(function()
			refreshHp(model, billboard)
		end),
	}
	tracked[model] = { uid = uid, billboard = billboard, connections = connections }
	byUid[uid] = model
end

function EnemyController.start()
	CollectionService:GetInstanceAddedSignal(EnemySpawning.TAG):Connect(startTracking)
	CollectionService:GetInstanceRemovedSignal(EnemySpawning.TAG):Connect(function(instance)
		if instance:IsA("Model") then
			stopTracking(instance)
		end
	end)
	for _, instance in CollectionService:GetTagged(EnemySpawning.TAG) do
		startTracking(instance)
	end
end

return EnemyController
