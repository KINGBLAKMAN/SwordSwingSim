-- The click credit cap (Config/Clicking) as ClickService applies it: a
-- RateLimiter that refills CLICK_CAP_CPS credits a second.

local RojoRequire = require("./support/RojoRequire")

local Clicking = RojoRequire("src/shared/Config/Clicking")
local RateLimiter = RojoRequire("src/shared/Net/RateLimiter")

local tests = {}

-- Sends `clicksPerSecond` clicks for `seconds` and returns how many counted.
local function credited(clicksPerSecond: number, seconds: number): number
	local credit = RateLimiter.new({ calls = Clicking.CLICK_CAP_CPS, perSeconds = 1 })
	local count = 0
	local total = math.floor(clicksPerSecond * seconds)
	for index = 0, total - 1 do
		if credit.allow("player", index / clicksPerSecond) then
			count += 1
		end
	end
	return count
end

tests["clicking under the cap credits every click"] = function()
	assert(credited(6, 10) == 60)
end

tests["spamming far past the cap credits no more than the cap"] = function()
	local seconds = 10
	-- One second's worth can be banked, so allow that on top.
	local most = Clicking.CLICK_CAP_CPS * (seconds + 1)
	local count = credited(100, seconds)
	assert(count <= most, `credited {count}, cap allows {most}`)
	assert(count >= Clicking.CLICK_CAP_CPS * seconds, `credited only {count}`)
end

tests["the auto-click rates stay under the manual cap"] = function()
	assert(Clicking.AUTO_CLICK_CPS < Clicking.AUTO_CLICK_PLUS_CPS)
	assert(Clicking.AUTO_CLICK_PLUS_CPS <= Clicking.CLICK_CAP_CPS)
end

return tests
