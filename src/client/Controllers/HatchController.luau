--!strict
-- HatchController: passes the server's HatchResult on to the hatch
-- animation (UI/HatchOverlay).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Remotes = require(script.Parent.Parent.Net.Remotes)

export type HatchedPet = { uid: string, pet: string, isNew: boolean }

local HatchController = {}

-- (eggId: string, hatched: { HatchedPet })
local hatched = Signal.new()

function HatchController.start()
	Remotes.on("HatchResult", function(eggId: string, pets: { HatchedPet })
		hatched:Fire(eggId, pets)
	end)
end

function HatchController.onHatched(callback: (eggId: string, pets: { HatchedPet }) -> ())
	return hatched:Connect(callback)
end

return HatchController
