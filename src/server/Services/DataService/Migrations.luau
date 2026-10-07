--!strict
-- Upgrades saved profiles to the current shape (TDD B4).
--
-- Every profile stores schemaVersion. STEPS[n] turns a version-n profile
-- into a version-(n + 1) profile, so a save from any older version runs
-- every step after its version, in order.
--
-- When to add a step: a field was renamed, moved or changed type, or a new
-- field was added inside per-item records like pets (see ProfileTypes). A
-- new field on a fixed table needs no step, because Reconcile copies it
-- from the template after migrations run. Steps run before Reconcile, so
-- a step can't count on such a field being there yet.
--
-- Never edit or delete a step once it has shipped: saves at that version
-- may still be waiting to load.
--
-- This module has no requires, so Lune tests can load it.

export type Data = { [string]: any }
export type Step = (data: Data) -> Data

export type FailureKind = "NewerVersion" | "BadVersion" | "StepFailed"
export type Result = { ok: true, data: Data } | { ok: false, kind: FailureKind, message: string }

local Migrations = {}

local STEPS: { Step } = {
	-- Example for when the first change ships (v1 -> v2):
	-- [1] = function(data)
	-- 	-- Renamed stats.totalClicks to stats.clicks.
	-- 	data.stats.clicks = data.stats.totalClicks
	-- 	data.stats.totalClicks = nil
	-- 	return data
	-- end,
}

-- The version the current code saves. It starts at 1 and goes up by one
-- with each step.
Migrations.LATEST_VERSION = #STEPS + 1

local function fail(kind: FailureKind, message: string): Result
	return { ok = false, kind = kind, message = message }
end

-- Upgrades data to the latest version. `steps` is only passed by tests;
-- the game uses STEPS.
--
-- Steps may change the table they're given, so pass a copy if the original
-- must stay untouched when a step fails (DataService does).
function Migrations.run(data: Data, steps: { Step }?): Result
	local stepList = steps or STEPS
	local latestVersion = #stepList + 1

	-- Saves from before schemaVersion existed count as version 1.
	local version = data.schemaVersion
	if version == nil then
		version = 1
	end

	if typeof(version) ~= "number" or version < 1 or version ~= math.floor(version) then
		return fail("BadVersion", `schemaVersion is {version}, not a whole number of 1 or more`)
	end
	if version > latestVersion then
		-- A newer server saved this. Loading it here could drop fields this
		-- code doesn't know about, so refuse.
		return fail(
			"NewerVersion",
			`saved at version {version}, but this server only knows up to {latestVersion}`
		)
	end

	local current = data
	for fromVersion = version, latestVersion - 1 do
		local ok, result = pcall(stepList[fromVersion], current)
		if not ok then
			return fail("StepFailed", `step {fromVersion} -> {fromVersion + 1} errored: {result}`)
		end
		if typeof(result) ~= "table" then
			return fail(
				"StepFailed",
				`step {fromVersion} -> {fromVersion + 1} didn't return the data`
			)
		end
		current = result
		current.schemaVersion = fromVersion + 1
	end

	current.schemaVersion = latestVersion
	return { ok = true, data = current }
end

return Migrations
