--!strict
-- DataController: the client's read-only copy of its own profile (TDD B9).
--
-- The server sends ProfileDelta changes; this applies them and tells
-- listeners. UI reads from here and never changes the data. To change
-- something, send intent to the server and wait for the delta.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileDelta = require(ReplicatedStorage.Shared.Data.ProfileDelta)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Remotes = require(script.Parent.Parent.Net.Remotes)

type Profile = ProfileTypes.Profile

local DataController = {}

-- nil until the server sends the profile.
local profile: Profile? = nil
-- (profile, changes) after every update.
local changed = Signal.new()

function DataController.start()
	Remotes.on("ProfileDelta", function(changes: { ProfileDelta.Change })
		-- apply returns new tables along each changed path, so UI code can
		-- compare references to see what changed.
		local updated: Profile = ProfileDelta.apply(profile, changes)
		profile = updated
		changed:Fire(updated, changes)
	end)
end

-- The latest copy, or nil before the profile arrives. Treat it as read-only.
function DataController.get(): Profile?
	return profile
end

-- Calls callback(profile, changes) after every update. Returns the
-- connection so a caller can disconnect it (or hand it to a Trove).
function DataController.onChanged(
	callback: (profile: Profile, changes: { ProfileDelta.Change }) -> ()
)
	return changed:Connect(callback)
end

return DataController
