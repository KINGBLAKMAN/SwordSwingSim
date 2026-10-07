--!strict
-- EggController: finds the egg stands in the world and sends open
-- requests (GDD A6). The server checks everything about an open; this
-- only says which egg the player tapped.
--
-- It also remembers which egg's full odds list is open, for the EggOdds
-- screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Eggs = require(ReplicatedStorage.Shared.Config.Eggs)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Remotes = require(script.Parent.Parent.Net.Remotes)

export type Stand = { eggId: string, part: BasePart }

local EggController = {}

local stands: { [BasePart]: Stand } = {}
-- () whenever a stand appears or goes away.
local standsChanged = Signal.new()
local selectedEgg: string? = nil

local function watch(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local eggId = instance:GetAttribute("Egg")
	if typeof(eggId) ~= "string" or Eggs[eggId] == nil or stands[instance] then
		return
	end
	stands[instance] = { eggId = eggId, part = instance }
	instance.AncestryChanged:Connect(function()
		if not instance:IsDescendantOf(Workspace) and stands[instance] then
			stands[instance] = nil
			standsChanged:Fire()
		end
	end)
	standsChanged:Fire()
end

function EggController.start()
	local islands = Workspace:WaitForChild("Islands")
	islands.DescendantAdded:Connect(watch)
	for _, descendant in islands:GetDescendants() do
		watch(descendant)
	end
end

-- Every egg stand this client can see.
function EggController.stands(): { Stand }
	local list = {}
	for _, stand in stands do
		table.insert(list, stand)
	end
	return list
end

function EggController.onStandsChanged(callback: () -> ())
	return standsChanged:Connect(callback)
end

-- Asks the server to open the egg once.
function EggController.open(eggId: string)
	Remotes.fire("OpenEgg", eggId, 1)
end

-- The egg whose odds the EggOdds screen shows.
function EggController.selected(): string?
	return selectedEgg
end

function EggController.select(eggId: string)
	selectedEgg = eggId
end

return EggController
