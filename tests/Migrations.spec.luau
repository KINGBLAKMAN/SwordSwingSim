local Migrations = require("../src/server/Services/DataService/Migrations")

local tests = {}

-- Test steps: v1 -> v2 renames a field, v2 -> v3 adds one derived from it.
local function testSteps()
	return {
		function(data)
			data.stats.clicks = data.stats.totalClicks
			data.stats.totalClicks = nil
			return data
		end,
		function(data)
			data.stats.clicksDoubled = data.stats.clicks * 2
			return data
		end,
	}
end

tests["the shipped steps reach LATEST_VERSION"] = function()
	local result = Migrations.run({ schemaVersion = Migrations.LATEST_VERSION })
	assert(result.ok, "current data loads")
	if result.ok then
		assert(result.data.schemaVersion == Migrations.LATEST_VERSION, "version unchanged")
	end

	local legacy = Migrations.run({})
	assert(legacy.ok, "a save with no schemaVersion upgrades from version 1")
	if legacy.ok then
		assert(legacy.data.schemaVersion == Migrations.LATEST_VERSION, "stamped with latest")
	end
end

tests["runs every step after the saved version, in order"] = function()
	local result = Migrations.run({ schemaVersion = 1, stats = { totalClicks = 21 } }, testSteps())
	assert(result.ok, "migrated")
	if result.ok then
		assert(result.data.schemaVersion == 3, `version {result.data.schemaVersion}`)
		assert(result.data.stats.clicks == 21, "renamed")
		assert(result.data.stats.totalClicks == nil, "old name gone")
		assert(result.data.stats.clicksDoubled == 42, "second step saw the first step's result")
	end
end

tests["skips steps the save already has"] = function()
	local result = Migrations.run({ schemaVersion = 2, stats = { clicks = 5 } }, testSteps())
	assert(result.ok, "migrated")
	if result.ok then
		assert(result.data.stats.clicksDoubled == 10, "only step 2 ran")
	end
end

tests["treats a missing schemaVersion as version 1"] = function()
	local result = Migrations.run({ stats = { totalClicks = 3 } }, testSteps())
	assert(result.ok and result.data.stats.clicks == 3, "ran from version 1")
end

tests["refuses a save from a newer version"] = function()
	local result = Migrations.run({ schemaVersion = 4 }, testSteps())
	assert(not result.ok, "refused")
	if not result.ok then
		assert(result.kind == "NewerVersion", `kind {result.kind}`)
	end
end

tests["refuses a schemaVersion that isn't a whole number of 1 or more"] = function()
	for _, version in { 0, -1, 1.5, "2", 0 / 0 } do
		local result = Migrations.run({ schemaVersion = version } :: any, testSteps())
		assert(not result.ok, `version {version} refused`)
		if not result.ok then
			assert(result.kind == "BadVersion", `version {version} gave {result.kind}`)
		end
	end
end

tests["a failing step reports which step failed"] = function()
	local steps = testSteps()
	steps[2] = function(_data)
		error("boom")
	end
	local result = Migrations.run({ schemaVersion = 1, stats = { totalClicks = 1 } }, steps)
	assert(not result.ok, "failed")
	if not result.ok then
		assert(result.kind == "StepFailed", `kind {result.kind}`)
		assert(string.find(result.message, "step 2 -> 3", 1, true), result.message)
		assert(string.find(result.message, "boom", 1, true), result.message)
	end
end

tests["a step that forgets to return the data fails"] = function()
	local steps = testSteps()
	steps[1] = function(data)
		data.stats.clicks = 1
		return nil :: any
	end
	local result = Migrations.run({ schemaVersion = 1, stats = {} }, steps)
	assert(not result.ok, "failed")
	if not result.ok then
		assert(result.kind == "StepFailed", `kind {result.kind}`)
	end
end

return tests
