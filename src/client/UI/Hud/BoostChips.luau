--!strict
-- BoostChips: a countdown chip for each active boost, under the level bar
-- (GDD A14). Boost names come from their ids until Config/Boosts exists.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local TimerChip = require(script.Parent.Parent.Components.TimerChip)
local useProfile = require(script.Parent.Parent.Hooks.useProfile)

local e = React.createElement

type ActiveBoosts = typeof(({} :: ProfileTypes.Profile).boosts.active)

local function selectActive(profile: ProfileTypes.Profile): ActiveBoosts
	return profile.boosts.active
end

local function BoostChips(props: { layoutOrder: number? })
	local active = useProfile(selectActive)

	local children: { [string]: any } = {
		List = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, UI.GAP),
			SortOrder = Enum.SortOrder.Name,
		}),
	}
	if active then
		local now = Workspace:GetServerTimeNow()
		for boostId, boost in active do
			-- The server removes expired boosts; skip any it hasn't yet.
			if boost.endsAt > now then
				children[boostId] = e(TimerChip, { label = boostId, endsAt = boost.endsAt })
			end
		end
	end

	return e("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, children)
end

return BoostChips
