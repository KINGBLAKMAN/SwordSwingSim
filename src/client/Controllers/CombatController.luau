--!strict
-- CombatController: picks what the player attacks and swings at it
-- (GDD A3, A9).
--
-- Targeting: the nearest live enemy in reach, unless the player tapped or
-- clicked an enemy to lock it. A locked target stays until it dies or the
-- player walks LOCK_BREAK_RANGE away. A ring sits under the target.
--
-- Inspecting: the enemy under the mouse (PC) or the tapped, locked target
-- is the inspected enemy, whose drop table the info panel shows.
--
-- Swinging: while the target is in reach, the client asks the server to
-- hit it SWING_RATE times a second. The server checks reach and rate again
-- and decides the damage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Combat = require(ReplicatedStorage.Shared.Config.Combat)
local EnemySpawning = require(ReplicatedStorage.Shared.Config.EnemySpawning)
local Signal = require(ReplicatedStorage.Packages.Signal)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local Remotes = require(script.Parent.Parent.Net.Remotes)
local EnemyController = require(script.Parent.EnemyController)

local SECONDS_PER_SWING = 1 / Combat.SWING_RATE
-- Farthest a tap can be from the camera and still pick an enemy.
local TAP_RAY_LENGTH = 500

local CombatController = {}

local target: Model? = nil
local locked = false
local lastSwingAt = -math.huge
local ring: Part
-- (target: Model?) whenever the target changes.
local targetChanged = Signal.new()
local hovered: Model? = nil
local inspected: Model? = nil
-- (inspected: Model?) whenever the inspected enemy changes.
local inspectedChanged = Signal.new()

local function rootPart(): BasePart?
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function edgeDistance(root: BasePart, model: Model): number
	local body = model.PrimaryPart :: BasePart
	local radius = math.max(body.Size.X, body.Size.Z) / 2
	return (root.Position - body.Position).Magnitude - radius
end

local function setTarget(model: Model?, isLocked: boolean)
	locked = isLocked and model ~= nil
	if target == model then
		return
	end
	target = model
	targetChanged:Fire(model)
end

local function nearestInReach(root: BasePart): Model?
	local best: Model? = nil
	local bestDistance = EnemySpawning.ATTACK_RANGE
	for model in EnemyController.all() do
		if EnemyController.isAlive(model) and model.PrimaryPart then
			local distance = edgeDistance(root, model)
			if distance <= bestDistance then
				best = model
				bestDistance = distance
			end
		end
	end
	return best
end

local function updateTarget(root: BasePart)
	local current = target
	local stillValid = current ~= nil
		and EnemyController.isAlive(current)
		and current.PrimaryPart ~= nil
	if
		locked
		and stillValid
		and edgeDistance(root, current :: Model) <= EnemySpawning.LOCK_BREAK_RANGE
	then
		return
	end
	setTarget(nearestInReach(root), false)
end

local function updateRing()
	local current = target
	local body = current and current.PrimaryPart
	if body == nil then
		ring.Parent = nil
		return
	end
	local width = math.max(body.Size.X, body.Size.Z) + UI.TARGET_RING.PADDING
	ring.Size = Vector3.new(UI.TARGET_RING.THICKNESS, width, width)
	-- A cylinder's axis is its X axis; turn it upright, at the enemy's feet.
	local feet = body.Position - Vector3.new(0, body.Size.Y / 2, 0)
	ring.CFrame = CFrame.new(feet) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = Workspace.CurrentCamera
end

local function trySwing(root: BasePart)
	local current = target
	if current == nil or edgeDistance(root, current) > EnemySpawning.ATTACK_RANGE then
		return
	end
	local now = os.clock()
	if now - lastSwingAt < SECONDS_PER_SWING then
		return
	end
	local uid = EnemyController.uid(current)
	if uid then
		lastSwingAt = now
		Remotes.fire("AttackTarget", uid)
	end
end

local function updateInspected()
	if hovered and not EnemyController.isAlive(hovered) then
		hovered = nil
	end
	local now = hovered or (if locked then target else nil)
	if now ~= inspected then
		inspected = now
		inspectedChanged:Fire(now)
	end
end

local function onHeartbeat()
	local root = rootPart()
	if root == nil then
		setTarget(nil, false)
	else
		updateTarget(root)
		trySwing(root)
	end
	updateRing()
	updateInspected()
end

-- The enemy model under a screen position, if any.
local function enemyAt(screenPosition: Vector3): Model?
	local camera = Workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local character = Players.LocalPlayer.Character
	params.FilterDescendantsInstances = if character then { character } else {}
	local result = Workspace:Raycast(ray.Origin, ray.Direction * TAP_RAY_LENGTH, params)
	local model = result and result.Instance:FindFirstAncestorOfClass("Model")
	if model and EnemyController.isAlive(model) then
		return model
	end
	return nil
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	local isTap = input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	if not isTap then
		return
	end
	local model = enemyAt(input.Position)
	if model then
		setTarget(model, true)
	end
end

local function onInputChanged(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		hovered = enemyAt(input.Position)
	end
end

function CombatController.start()
	ring = Instance.new("Part")
	ring.Name = "TargetRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = UI.TARGET_RING.COLOR
	ring.Transparency = UI.TARGET_RING.TRANSPARENCY
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false

	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputChanged:Connect(onInputChanged)
	RunService.Heartbeat:Connect(onHeartbeat)
end

-- The enemy the player is attacking, or nil.
function CombatController.target(): Model?
	return target
end

-- Calls callback(target) whenever the target changes.
function CombatController.onTargetChanged(callback: (target: Model?) -> ())
	return targetChanged:Connect(callback)
end

-- The enemy being hovered or tapped, whose info the panel shows, or nil.
function CombatController.inspected(): Model?
	return inspected
end

function CombatController.onInspectedChanged(callback: (inspected: Model?) -> ())
	return inspectedChanged:Connect(callback)
end

return CombatController
