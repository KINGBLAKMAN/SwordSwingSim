local RojoRequire = require("./support/RojoRequire")

local TickScheduler = RojoRequire("src/shared/Util/TickScheduler")

local tests = {}

-- Steps time forward at `fps` frames a second up to `seconds` and adds up
-- the ticks each key gets.
local function run(scheduler, seconds: number, fps: number): { [any]: number }
	local totals = {}
	for frame = 0, seconds * fps do
		for key, ticks in scheduler.collect(frame / fps) do
			totals[key] = (totals[key] or 0) + ticks
		end
	end
	return totals
end

tests["a key ticks at its rate over time"] = function()
	local scheduler = TickScheduler.new()
	scheduler.add("a", 0.25, 0, 0)
	local totals = run(scheduler, 10, 60)
	-- First tick at 0, then every quarter second: 41 ticks through t = 10.
	assert(totals.a == 41, `got {totals.a}`)
end

tests["a slow frame pays every tick it missed"] = function()
	local scheduler = TickScheduler.new()
	scheduler.add("a", 0.25, 0, 0)
	assert(scheduler.collect(0).a == 1)
	assert(scheduler.collect(1).a == 4, "ticks at 0.25, 0.5, 0.75 and 1")
	assert(scheduler.collect(1.1).a == nil)
end

tests["phases spread keys across the interval"] = function()
	local scheduler = TickScheduler.new()
	scheduler.add("early", 1, 0, 0)
	scheduler.add("late", 1, 0, 0.5)
	local first = scheduler.collect(0)
	assert(first.early == 1 and first.late == nil)
	local second = scheduler.collect(0.5)
	assert(second.early == nil and second.late == 1)
end

tests["removed keys stop ticking and adding again changes the rate"] = function()
	local scheduler = TickScheduler.new()
	scheduler.add("a", 1, 0, 0)
	scheduler.add("a", 0.5, 0, 0)
	assert(scheduler.collect(0).a == 1)
	assert(scheduler.collect(0.5).a == 1, "new interval applies to the next tick")
	scheduler.remove("a")
	assert(not scheduler.has("a"))
	assert(scheduler.collect(5).a == nil)
end

return tests
