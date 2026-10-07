-- Runs the pure-logic unit tests with Lune: `lune run tests/run.luau`.
-- Each spec file returns a table of test name -> test function. A test
-- fails by erroring (assert). Exits with code 1 if any test fails, so CI
-- goes red.

local process = require("@lune/process")

local specs = {
	BigNum = require("./BigNum.spec"),
	Clicking = require("./Clicking.spec"),
	Combat = require("./Combat.spec"),
	Config = require("./Config.spec"),
	Drops = require("./Drops.spec"),
	Egg = require("./Egg.spec"),
	Format = require("./Format.spec"),
	LevelCurve = require("./LevelCurve.spec"),
	Migrations = require("./Migrations.spec"),
	OddsCalculator = require("./OddsCalculator.spec"),
	PaidRandomRules = require("./PaidRandomRules.spec"),
	PetMath = require("./PetMath.spec"),
	ProfileDelta = require("./ProfileDelta.spec"),
	Quests = require("./Quests.spec"),
	Receipts = require("./Receipts.spec"),
	RateLimiter = require("./RateLimiter.spec"),
	ScaleMath = require("./ScaleMath.spec"),
	StatMath = require("./StatMath.spec"),
	TickScheduler = require("./TickScheduler.spec"),
	Validate = require("./Validate.spec"),
	WeightedRandom = require("./WeightedRandom.spec"),
}

local passed = 0
local failed = 0

for specName, tests in specs do
	for testName, test in tests do
		local ok, err = pcall(test)
		if ok then
			passed += 1
		else
			failed += 1
			print(`FAIL {specName}: {testName}\n    {err}`)
		end
	end
end

print(`{passed} passed, {failed} failed`)
if failed > 0 then
	process.exit(1)
end
