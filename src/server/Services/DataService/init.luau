--!strict
-- DataService: loads, saves and replicates player profiles (TDD B2–B4, B6).
--
-- Loading: each player's profile opens in a ProfileStore session, which
-- locks it so no other server can write it at the same time. Saves from
-- older versions are migrated (Migrations), then Reconcile fills in fields
-- added since (ProfileTemplate).
--
-- Safety (checklist C7): nobody plays on a blank profile. If a profile can't
-- be loaded or upgraded, the player is kicked with a message to rejoin and
-- nothing is written over their save. Until a profile loads, get() returns
-- nil, and other services should ignore that player's requests.
--
-- Writing: other services change data only through set() and update().
-- Each write is queued and sent to the player's client as a ProfileDelta a
-- few times a second. A write straight into the table get() returns would
-- still save, but the client would never hear about it.
--
-- Saving: ProfileStore auto-saves every few minutes and when the session
-- ends. Call saveNow() right after a purchase (TDD B4); never save on every
-- change.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local DataConfig = require(ReplicatedStorage.Shared.Config.Data)
local ProfileDelta = require(ReplicatedStorage.Shared.Data.ProfileDelta)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Remotes = require(script.Parent.Parent.Net.Remotes)
local Migrations = require(script.Migrations)
local ProfileTemplate = require(script.ProfileTemplate)

type Profile = ProfileTypes.Profile

-- The parts of ProfileStore this service uses. Wally's link module doesn't
-- pass ProfileStore's exported types through, so they're restated here.
type StoredProfile = {
	Data: Profile,
	AddUserId: (self: any, userId: number) -> (),
	Reconcile: (self: any) -> (),
	Save: (self: any) -> (),
	EndSession: (self: any) -> (),
	OnSessionEnd: { Connect: (self: any, listener: () -> ()) -> any },
}
type Store = {
	StartSessionAsync: (self: any, key: string, options: any) -> StoredProfile?,
}

type Session = {
	profile: StoredProfile,
	-- Changes waiting for the next send to this player's client.
	batch: ProfileDelta.Batch,
}

-- What the player sees when kicked. They can only rejoin, so keep it short.
local KICK_MESSAGES = {
	loadFailed = "Your data couldn't load, so we stopped here to keep it safe. Please rejoin.",
	outdatedServer = "This server is running an older version of the game. Please rejoin.",
	sessionEnded = "Your data was opened on another server. Please rejoin.",
}

local DataService = {}

local store: Store
local sessions: { [Player]: Session } = {}
-- Players whose load has started, so a player is never loaded twice.
local loadStarted: { [Player]: boolean } = {}

-- (player, data) once a profile is loaded and sent to the client.
local loaded = Signal.new()
-- (player, data) just before a profile is saved for the last time.
local releasing = Signal.new()

local function isInGame(player: Player): boolean
	return player.Parent == Players
end

local function kick(player: Player, message: string)
	if isInGame(player) then
		player:Kick(message)
	end
end

local function getSession(player: Player, caller: string): Session
	local session = sessions[player]
	if session == nil then
		error(`DataService.{caller}: {player.Name}'s profile isn't loaded`, 3)
	end
	return session
end

-- Opens the player's ProfileStore session. Returns nil if it can't: the
-- DataStore is down, the session lock never freed, or the player left.
local function startSession(player: Player): StoredProfile?
	if DataConfig.SIMULATE_LOAD_FAILURE_IN_STUDIO and RunService:IsStudio() then
		warn("[DataService] SIMULATE_LOAD_FAILURE_IN_STUDIO is on, so this load fails on purpose")
		return nil
	end

	local key = DataConfig.KEY_PREFIX .. player.UserId
	-- ProfileStore's type for these options leaves out Cancel, hence the cast.
	local options: any = {
		-- Stop retrying once the player has left.
		Cancel = function()
			return not isInGame(player)
		end,
	}
	local ok, result = pcall(function()
		return store:StartSessionAsync(key, options)
	end)
	if not ok then
		warn(`[DataService] couldn't start a session for {player.Name}: {result}`)
		return nil
	end
	return result
end

local function loadProfile(player: Player)
	if loadStarted[player] then
		return
	end
	loadStarted[player] = true

	local profile = startSession(player)
	if profile == nil then
		kick(player, KICK_MESSAGES.loadFailed)
		return
	end

	-- Links the save to the player, so a Right-to-Erasure request can find
	-- it (checklist C6).
	profile:AddUserId(player.UserId)

	-- Migrate a copy, so a failing step can't leave half-upgraded data
	-- behind to be saved.
	local result = Migrations.run(ProfileDelta.deepCopy(profile.Data))
	if not result.ok then
		warn(`[DataService] {player.Name}'s profile can't be loaded: {result.message}`)
		-- Ending the session saves the untouched data and frees the lock.
		profile:EndSession()
		local message = if result.kind == "NewerVersion"
			then KICK_MESSAGES.outdatedServer
			else KICK_MESSAGES.loadFailed
		kick(player, message)
		return
	end
	profile.Data = result.data :: any
	profile:Reconcile()

	-- The player may have left while the profile loaded.
	if not isInGame(player) then
		profile:EndSession()
		return
	end

	local session: Session = { profile = profile, batch = ProfileDelta.newBatch() }
	sessions[player] = session

	profile.OnSessionEnd:Connect(function()
		-- Releasing on leave clears sessions[player] first, so this only acts
		-- when the session ended while the player is still here: another
		-- server took the profile, or the server is shutting down.
		if sessions[player] ~= session then
			return
		end
		sessions[player] = nil
		if not ProfileStore.IsClosing then
			kick(player, KICK_MESSAGES.sessionEnded)
		end
	end)

	-- The first delta is the whole profile.
	Remotes.fire("ProfileDelta", player, { { path = {}, value = profile.Data } })
	loaded:Fire(player, profile.Data)
end

local function releaseProfile(player: Player)
	loadStarted[player] = nil

	local session = sessions[player]
	if session == nil then
		return
	end

	-- Last chance for other services to write. Their handlers must not
	-- yield, because the session ends right after.
	releasing:Fire(player, session.profile.Data)
	DataService.set(player, { "lastOnline" }, os.time())

	sessions[player] = nil
	session.profile:EndSession()
end

-- Sends each player's queued changes in one remote call.
local function sendQueuedChanges()
	for player, session in sessions do
		if not ProfileDelta.isEmpty(session.batch) then
			Remotes.fire("ProfileDelta", player, ProfileDelta.take(session.batch))
		end
	end
end

function DataService.init()
	-- Cast to the restated Store type above.
	store = ProfileStore.New(DataConfig.STORE_NAME, ProfileTemplate) :: any

	ProfileStore.OnError:Connect(function(message, storeName, profileKey)
		warn(`[DataService] ProfileStore error ({storeName}/{profileKey}): {message}`)
	end)
end

function DataService.start()
	Players.PlayerAdded:Connect(loadProfile)
	Players.PlayerRemoving:Connect(releaseProfile)
	-- Players who joined before this connected.
	for _, player in Players:GetPlayers() do
		task.spawn(loadProfile, player)
	end

	task.spawn(function()
		while true do
			task.wait(DataConfig.DELTA_SEND_INTERVAL)
			sendQueuedChanges()
		end
	end)
end

-- The player's profile, or nil if it isn't loaded. Read only: change it
-- with set() or update() so the client hears about it.
function DataService.get(player: Player): Profile?
	local session = sessions[player]
	return if session then session.profile.Data else nil
end

function DataService.isLoaded(player: Player): boolean
	return sessions[player] ~= nil
end

-- Writes value at path and queues the change for the client, e.g.
-- DataService.set(player, { "currencies", "gems" }, 50). A nil value
-- removes the key. Tables are copied, so later edits to the caller's table
-- can't change saved data behind DataService's back. Errors if the
-- profile isn't loaded.
function DataService.set(player: Player, path: ProfileDelta.Path, value: any)
	local session = getSession(player, "set")
	local copy = ProfileDelta.deepCopy(value)
	ProfileDelta.set(session.profile.Data, path, copy)
	ProfileDelta.queue(session.batch, path, copy)
end

-- Replaces the value at path with transform(current value), e.g.
-- DataService.update(player, { "stats", "totalClicks" }, function(clicks)
-- 	return clicks + 1
-- end)
-- transform gets a copy, so changing it in place does nothing until it's
-- returned.
function DataService.update(
	player: Player,
	path: ProfileDelta.Path,
	transform: (current: any) -> any
)
	local session = getSession(player, "update")
	local current = ProfileDelta.deepCopy(ProfileDelta.get(session.profile.Data, path))
	DataService.set(player, path, transform(current))
end

-- Saves now instead of waiting for the next auto-save. Use right after a
-- purchase grant (TDD B4, B10).
function DataService.saveNow(player: Player)
	getSession(player, "saveNow").profile:Save()
end

-- Calls callback(player, data) for every loaded profile, now and from now
-- on, so a service that starts late doesn't miss players who loaded first.
function DataService.onLoaded(callback: (player: Player, data: Profile) -> ())
	for player, session in sessions do
		task.spawn(callback, player, session.profile.Data)
	end
	return loaded:Connect(callback)
end

-- Calls callback(player, data) just before a leaving player's profile is
-- saved for the last time. The callback must not yield.
function DataService.onReleasing(callback: (player: Player, data: Profile) -> ())
	return releasing:Connect(callback)
end

return DataService
