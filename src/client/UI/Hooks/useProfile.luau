--!strict
-- useProfile: reads part of the player's profile and re-renders when it
-- changes. The profile is the read-only copy DataController keeps from the
-- server's ProfileDelta updates (TDD B9: one store fed by ProfileDelta).
--
--   local stats = useProfile(function(profile) return profile.stats end)
--
-- Returns nil until the profile arrives. ProfileDelta gives changed parts
-- new tables and leaves the rest alone, so selecting a sub-table only
-- re-renders when that part changed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local React = require(ReplicatedStorage.Packages.React)
local DataController = require(script.Parent.Parent.Parent.Controllers.DataController)

type Profile = ProfileTypes.Profile

local function useProfile<T>(select: (profile: Profile) -> T): T?
	local function readNow(): T?
		local profile = DataController.get()
		return if profile then select(profile) else nil
	end

	local value, setValue = React.useState(readNow)

	-- Keep the newest selector so the listener below never uses a stale one.
	local selectRef = React.useRef(select)
	selectRef.current = select

	React.useEffect(function()
		local connection = DataController.onChanged(function(profile: Profile)
			setValue(selectRef.current(profile))
		end)
		-- The profile may have arrived between the first render and now.
		local profile = DataController.get()
		if profile then
			setValue(select(profile))
		end
		return function()
			connection:Disconnect()
		end
	end, {})

	return value
end

return useProfile
