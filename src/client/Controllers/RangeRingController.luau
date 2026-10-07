--!strict
-- RangeRingController: a ring on the ground around the local player that
-- shows attack range (GDD A9). Any enemy touching the ring can be hit.
--
-- The ring's radius is EnemySpawning.ATTACK_RANGE, the same reach
-- CombatController uses to pick and swing at targets, so what you see is
-- what you can hit. The server still checks reach itself (TDD B7); this is
-- only a picture of it.
--
-- It's a CylinderHandleAdornment with an InnerRadius, attached to the
-- character's root part, so it follows the player without moving parts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EnemySpawning = require(ReplicatedStorage.Shared.Config.EnemySpawning)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local CombatController = require(script.Parent.CombatController)

local RangeRingController = {}

local ring: CylinderHandleAdornment

-- How far below the root part the ground is, for a standing character.
local function groundOffset(character: Model, root: BasePart): number
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hipHeight = if humanoid then humanoid.HipHeight else 0
	return hipHeight + root.Size.Y / 2
end

local function onHeartbeat()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character == nil or root == nil or not root:IsA("BasePart") then
		ring.Parent = nil
		return
	end

	ring.Adornee = root
	ring.Parent = Workspace.CurrentCamera
	-- The adornment's axis is its Z axis; turn it to lie flat at the feet.
	local drop = groundOffset(character, root) - UI.RANGE_RING.LIFT
	ring.CFrame = CFrame.new(0, -drop, 0) * CFrame.Angles(math.pi / 2, 0, 0)
	ring.Transparency = if CombatController.targetInReach()
		then UI.RANGE_RING.ACTIVE_TRANSPARENCY
		else UI.RANGE_RING.IDLE_TRANSPARENCY
end

function RangeRingController.start()
	ring = Instance.new("CylinderHandleAdornment")
	ring.Name = "RangeRing"
	ring.Radius = EnemySpawning.ATTACK_RANGE
	ring.InnerRadius = EnemySpawning.ATTACK_RANGE - UI.RANGE_RING.WIDTH
	ring.Height = UI.RANGE_RING.THICKNESS
	ring.Color3 = UI.RANGE_RING.COLOR
	ring.Transparency = UI.RANGE_RING.IDLE_TRANSPARENCY
	ring.AlwaysOnTop = false
	ring.ZIndex = 0

	RunService.Heartbeat:Connect(onHeartbeat)
end

return RangeRingController
