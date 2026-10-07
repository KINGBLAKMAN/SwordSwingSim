--!strict
-- LevelBar: the player's level and EXP toward the next one (GDD A4).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BigNum = require(ReplicatedStorage.Shared.Util.BigNum)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local LevelCurve = require(ReplicatedStorage.Shared.Util.LevelCurve)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local React = require(ReplicatedStorage.Packages.React)
local ProgressBar = require(script.Parent.Parent.Components.ProgressBar)
local useProfile = require(script.Parent.Parent.Hooks.useProfile)

local e = React.createElement

type Stats = typeof(({} :: ProfileTypes.Profile).stats)

local function selectStats(profile: ProfileTypes.Profile): Stats
	return profile.stats
end

local function LevelBar(props: { layoutOrder: number? })
	local stats = useProfile(selectStats)

	local label = "Loading…"
	local fraction = 0
	if stats then
		-- stats.exp is the EXP earned since reaching this level. A level's
		-- EXP fits in a plain number, so converting is safe here.
		local exp = BigNum.toNumber(stats.exp)
		local needed = LevelCurve.expToNext(stats.level)
		label = `Lv. {stats.level}   {Format.number(exp)} / {Format.number(needed)}`
		fraction = LevelCurve.progress(stats.level, exp)
	end

	return e(ProgressBar, {
		fraction = fraction,
		label = label,
		layoutOrder = props.layoutOrder,
	})
end

return LevelBar
