--!strict
-- PetFollowController: draws every player's equipped pets following them
-- (TDD B8). Pets are client-only: the server only says which pets each
-- player has equipped, in the EquippedPets player attribute, and each
-- client builds and moves its own copies.
--
-- One RenderStepped loop moves every pet. Pets far from the camera are
-- culled, and the "Hide other players' pets" setting hides everyone's but
-- your own.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PetLooks = require(ReplicatedStorage.Shared.Config.PetLooks)
local PetRules = require(ReplicatedStorage.Shared.Config.PetRules)
local Pets = require(ReplicatedStorage.Shared.Config.Pets)
local Settings = require(ReplicatedStorage.Shared.Config.Settings)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local DataController = require(script.Parent.DataController)

type Follower = {
	parts: { BasePart },
	connection: RBXScriptConnection,
}

local PetFollowController = {}

local localPlayer = Players.LocalPlayer
local folder: Folder
local followers: { [Player]: Follower } = {}
local hideOthers = false

local function makePetPart(petId: string): BasePart
	local def = Pets[petId]
	local size = PetLooks.SIZE[def.rarity] or PetLooks.SIZE.Common
	local part = Instance.new("Part")
	part.Name = def.name
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size, size)
	part.Color = UI.RARITY_COLORS[def.rarity]
	part.Material = Enum.Material.SmoothPlastic
	-- Pets are decoration: nothing collides with, touches or raycasts them.
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	return part
end

-- Pet ids from the attribute, skipping any this client doesn't know.
local function equippedIds(player: Player): { string }
	local value = player:GetAttribute(PetRules.EQUIPPED_ATTRIBUTE)
	local ids = {}
	if typeof(value) == "string" then
		for _, petId in string.split(value, ",") do
			if Pets[petId] then
				table.insert(ids, petId)
			end
		end
	end
	return ids
end

local function rebuild(player: Player, follower: Follower)
	for _, part in follower.parts do
		part:Destroy()
	end
	table.clear(follower.parts)
	for _, petId in equippedIds(player) do
		table.insert(follower.parts, makePetPart(petId))
	end
end

local function watchPlayer(player: Player)
	if followers[player] then
		return
	end
	local follower: Follower = {
		parts = {},
		connection = player
			:GetAttributeChangedSignal(PetRules.EQUIPPED_ATTRIBUTE)
			:Connect(function()
				local current = followers[player]
				if current then
					rebuild(player, current)
				end
			end),
	}
	followers[player] = follower
	rebuild(player, follower)
end

local function forgetPlayer(player: Player)
	local follower = followers[player]
	if follower == nil then
		return
	end
	follower.connection:Disconnect()
	for _, part in follower.parts do
		part:Destroy()
	end
	followers[player] = nil
end

local function shouldDraw(player: Player, root: BasePart?, cameraPosition: Vector3): boolean
	if root == nil then
		return false
	elseif hideOthers and player ~= localPlayer then
		return false
	end
	return (root.Position - cameraPosition).Magnitude <= PetLooks.CULL_DISTANCE
end

-- Where pet `index` of `count` floats: a row behind the owner, centered.
local function spotFor(root: BasePart, index: number, count: number, now: number): CFrame
	local sideways = (index - (count + 1) / 2) * PetLooks.SPACING
	local bob = math.sin(now * PetLooks.BOB_SPEED + index) * PetLooks.BOB_HEIGHT
	return root.CFrame * CFrame.new(sideways, PetLooks.HEIGHT + bob, PetLooks.BEHIND)
end

local function moveFollower(follower: Follower, root: BasePart, deltaTime: number, now: number)
	-- Frame-rate independent easing toward each pet's spot.
	local alpha = 1 - math.exp(-PetLooks.FOLLOW_SPEED * deltaTime)
	local count = #follower.parts
	for index, part in follower.parts do
		local spot = spotFor(root, index, count, now)
		local far = part.Parent == nil
			or (part.Position - spot.Position).Magnitude > PetLooks.SNAP_DISTANCE
		part.CFrame = if far then spot else part.CFrame:Lerp(spot, alpha)
		part.Parent = folder
	end
end

local function hideFollower(follower: Follower)
	for _, part in follower.parts do
		part.Parent = nil
	end
end

local function onRenderStepped(deltaTime: number)
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local cameraPosition = camera.CFrame.Position
	local now = os.clock()
	for player, follower in followers do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") and shouldDraw(player, root, cameraPosition) then
			moveFollower(follower, root, deltaTime, now)
		else
			hideFollower(follower)
		end
	end
end

local function readHideSetting()
	local profile = DataController.get()
	hideOthers = profile ~= nil and Settings.value(profile.settings, "hideOtherPets")
end

function PetFollowController.start()
	folder = Instance.new("Folder")
	folder.Name = "ClientPets"
	folder.Parent = Workspace

	Players.PlayerAdded:Connect(watchPlayer)
	Players.PlayerRemoving:Connect(forgetPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end

	readHideSetting()
	DataController.onChanged(readHideSetting)
	RunService.RenderStepped:Connect(onRenderStepped)
end

return PetFollowController
