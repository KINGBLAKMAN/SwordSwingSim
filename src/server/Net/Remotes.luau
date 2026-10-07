--!strict
-- Server side of the Remotes module (TDD B6–B7).
--
-- init() creates one RemoteEvent per schema in ReplicatedStorage.Remotes.
-- Services then call Remotes.on(name, handler) in their start() to handle
-- client intent, and Remotes.fire / fireAll to send results.
--
-- Every incoming call passes two gates before its handler runs:
--   1. The per-player rate limit from Config/RemoteLimits.
--   2. The argument checks from Shared/Net/RemoteSchemas.
-- A call that fails either gate is dropped silently, so an exploiter
-- learns nothing, and reported on Remotes.rejected for anti-cheat to count.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RateLimiter = require(ReplicatedStorage.Shared.Net.RateLimiter)
local RemoteLimits = require(ReplicatedStorage.Shared.Config.RemoteLimits)
local RemoteSchemas = require(ReplicatedStorage.Shared.Net.RemoteSchemas)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Validate = require(ReplicatedStorage.Shared.Net.Validate)

-- Handlers receive arguments that already passed the schema's checks.
export type Handler = (player: Player, ...any) -> ()

local Remotes = {}

-- Fired with (player: Player, remoteName: string, reason: string) whenever
-- a call is dropped. AntiCheatService will listen here to flag abusers.
Remotes.rejected = Signal.new()

local remoteEvents: { [string]: RemoteEvent } = {}
local limiters: { [string]: RateLimiter.RateLimiter } = {}
local handled: { [string]: boolean } = {}

local function getSchema(name: string, direction: RemoteSchemas.Direction): RemoteSchemas.Schema
	local schema = RemoteSchemas[name]
	assert(schema, `Remotes: no schema named "{name}"`)
	assert(schema.direction == direction, `Remotes: "{name}" is not a {direction} remote`)
	return schema
end

local function reject(player: Player, name: string, reason: string, shouldWarn: boolean)
	Remotes.rejected:Fire(player, name, reason)
	-- Warn only in Studio: in a live server an exploiter could spam calls
	-- just to flood the output.
	if shouldWarn and RunService:IsStudio() then
		warn(`[Remotes] dropped {name} from {player.Name}: {reason}`)
	end
end

function Remotes.init()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"

	for name, schema in RemoteSchemas do
		local remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = name
		remoteEvent.Parent = folder
		remoteEvents[name] = remoteEvent

		if schema.direction == "ToServer" then
			local limit = RemoteLimits[name]
			assert(limit, `Remotes: "{name}" needs a rate limit in Config/RemoteLimits`)
			limiters[name] = RateLimiter.new(limit)
		end
	end

	-- Parent last so clients never see a half-built folder.
	folder.Parent = ReplicatedStorage
end

function Remotes.start()
	Players.PlayerRemoving:Connect(function(player)
		for _, limiter in limiters do
			limiter.forget(player)
		end
	end)
end

-- Connects the one handler for a client-to-server remote.
function Remotes.on(name: string, handler: Handler)
	local schema = getSchema(name, "ToServer")
	assert(not handled[name], `Remotes: "{name}" already has a handler`)
	handled[name] = true

	local limiter = limiters[name]
	remoteEvents[name].OnServerEvent:Connect(function(player: Player, ...: unknown)
		if not limiter.allow(player, os.clock()) then
			reject(player, name, "rate limited", false)
			return
		end

		local ok, reason = Validate.args(schema.args, ...)
		if not ok then
			reject(player, name, reason or "invalid arguments", true)
			return
		end

		handler(player, ...)
	end)
end

-- Sends a server-to-client remote to one player.
function Remotes.fire(name: string, player: Player, ...: any)
	getSchema(name, "ToClient")
	remoteEvents[name]:FireClient(player, ...)
end

-- Sends a server-to-client remote to every player.
function Remotes.fireAll(name: string, ...: any)
	getSchema(name, "ToClient")
	remoteEvents[name]:FireAllClients(...)
end

return Remotes
