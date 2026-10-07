--!strict
-- Client side of the Remotes module (TDD B6). The client only sends intent
-- and listens for results; the server decides every outcome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteSchemas = require(ReplicatedStorage.Shared.Net.RemoteSchemas)

local Remotes = {}

local function getRemoteEvent(name: string, direction: RemoteSchemas.Direction): RemoteEvent
	local schema = RemoteSchemas[name]
	assert(schema, `Remotes: no schema named "{name}"`)
	assert(schema.direction == direction, `Remotes: "{name}" is not a {direction} remote`)

	-- The server creates the folder at startup; wait for it on first use.
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	local remoteEvent = folder:WaitForChild(name)
	assert(remoteEvent:IsA("RemoteEvent"), `Remotes: "{name}" is not a RemoteEvent`)
	return remoteEvent
end

-- Asks the server to do something. The server may ignore the request.
function Remotes.fire(name: string, ...: any)
	getRemoteEvent(name, "ToServer"):FireServer(...)
end

-- Listens for a result sent by the server. Returns the connection so a
-- controller can disconnect it (or hand it to a Trove).
function Remotes.on(name: string, handler: (...any) -> ()): RBXScriptConnection
	return getRemoteEvent(name, "ToClient").OnClientEvent:Connect(handler)
end

return Remotes
