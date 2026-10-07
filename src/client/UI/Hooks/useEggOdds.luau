--!strict
-- useEggOdds: an egg's odds exactly as the server would roll the next
-- open: the luck the server publishes (Config/Hatching.LUCK_ATTRIBUTE) and
-- the player's pity count, through the shared OddsCalculator.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Eggs = require(ReplicatedStorage.Shared.Config.Eggs)
local Hatching = require(ReplicatedStorage.Shared.Config.Hatching)
local OddsCalculator = require(ReplicatedStorage.Shared.Util.OddsCalculator)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local React = require(ReplicatedStorage.Packages.React)
local useProfile = require(script.Parent.useProfile)

export type EggOdds = {
	display: OddsCalculator.Display,
	luck: number,
	opensSincePity: number,
	pityActive: boolean,
}

local function readLuck(): number
	local luck = Players.LocalPlayer:GetAttribute(Hatching.LUCK_ATTRIBUTE)
	return if typeof(luck) == "number" and luck >= 0 then luck else 0
end

local function selectPity(profile: ProfileTypes.Profile)
	return profile.pity
end

local function useEggOdds(eggId: string): EggOdds
	local egg = Eggs[eggId]
	local luck, setLuck = React.useState(readLuck)
	local pity = useProfile(selectPity)

	React.useEffect(function()
		local connection = Players.LocalPlayer
			:GetAttributeChangedSignal(Hatching.LUCK_ATTRIBUTE)
			:Connect(function()
				setLuck(readLuck())
			end)
		return function()
			connection:Disconnect()
		end
	end, {})

	local opensSincePity = if pity then pity[eggId] or 0 else 0
	local pityActive = OddsCalculator.isPityOpen(egg, opensSincePity)
	return {
		display = OddsCalculator.display(egg, { luck = luck, pityActive = pityActive }),
		luck = luck,
		opensSincePity = opensSincePity,
		pityActive = pityActive,
	}
end

return useEggOdds
