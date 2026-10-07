--!strict
-- DropController: passes the server's DropFx on to the UI, so the drop
-- toasts and the rare banner can listen without touching remotes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DropTables = require(ReplicatedStorage.Shared.Util.DropTables)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Remotes = require(script.Parent.Parent.Net.Remotes)

local DropController = {}

-- (enemyId: string, drops: { DropTables.Drop })
local dropped = Signal.new()

function DropController.start()
	Remotes.on("DropFx", function(enemyId: string, drops: { DropTables.Drop })
		dropped:Fire(enemyId, drops)
	end)
end

function DropController.onDropped(callback: (enemyId: string, drops: { DropTables.Drop }) -> ())
	return dropped:Connect(callback)
end

return DropController
