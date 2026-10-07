local RateLimiter = require("../src/shared/Net/RateLimiter")

local tests = {}

tests["allows a full burst, then refuses the next call"] = function()
	local limiter = RateLimiter.new({ calls = 12, perSeconds = 1 })
	for call = 1, 12 do
		assert(limiter.allow("player", 0), `call {call} should be allowed`)
	end
	assert(not limiter.allow("player", 0), "call 13 in the same instant should be refused")
end

tests["refills at the steady rate"] = function()
	local limiter = RateLimiter.new({ calls = 12, perSeconds = 1 })
	for _ = 1, 12 do
		limiter.allow("player", 0)
	end
	-- 12 per second refills one token every 1/12 s.
	assert(not limiter.allow("player", 0.05), "less than one token refilled yet")
	assert(limiter.allow("player", 0.1), "one token refilled after 1/12 s")
	assert(not limiter.allow("player", 0.1), "that token was spent")
end

tests["never stores more than a full bucket"] = function()
	local limiter = RateLimiter.new({ calls = 3, perSeconds = 1 })
	limiter.allow("player", 0)
	-- A long idle gap must not bank extra calls.
	local allowed = 0
	for _ = 1, 10 do
		if limiter.allow("player", 1000) then
			allowed += 1
		end
	end
	assert(allowed == 3, `expected 3 calls after idling, got {allowed}`)
end

tests["handles slow limits like one call every 3 seconds"] = function()
	local limiter = RateLimiter.new({ calls = 1, perSeconds = 3 })
	assert(limiter.allow("player", 0), "first call allowed")
	assert(not limiter.allow("player", 2.9), "too soon")
	-- Refills add up in floating point, so check just past the 3 s mark.
	assert(limiter.allow("player", 3.001), "allowed again after 3 s")
end

tests["keeps a separate budget per key"] = function()
	local limiter = RateLimiter.new({ calls = 1, perSeconds = 1 })
	assert(limiter.allow("alice", 0), "alice's first call")
	assert(not limiter.allow("alice", 0), "alice is out of calls")
	assert(limiter.allow("bob", 0), "bob is unaffected by alice")
end

tests["time going backwards does not grant calls"] = function()
	local limiter = RateLimiter.new({ calls = 1, perSeconds = 1 })
	assert(limiter.allow("player", 100), "first call")
	assert(not limiter.allow("player", 50), "earlier timestamp must not refill")
	assert(not limiter.allow("player", 100.5), "still waiting on the real refill")
end

tests["forget resets a key to a full bucket"] = function()
	local limiter = RateLimiter.new({ calls = 1, perSeconds = 10 })
	assert(limiter.allow("player", 0), "first call")
	assert(not limiter.allow("player", 0), "out of calls")
	limiter.forget("player")
	assert(limiter.allow("player", 0), "fresh bucket after forget")
end

tests["sustained spam is held to the steady rate"] = function()
	local limiter = RateLimiter.new({ calls = 12, perSeconds = 1 })
	-- An exploiter firing 1000 times a second for 10 seconds.
	local allowed = 0
	for step = 0, 9999 do
		if limiter.allow("player", step / 1000) then
			allowed += 1
		end
	end
	-- 12 from the starting burst plus 12 per second for ~10 s.
	assert(allowed >= 120 and allowed <= 132, `expected about 132 calls, got {allowed}`)
end

tests["rejects a limit that could never allow a call"] = function()
	assert(not pcall(RateLimiter.new, { calls = 0, perSeconds = 1 }), "calls = 0 should error")
	assert(not pcall(RateLimiter.new, { calls = 1, perSeconds = 0 }), "perSeconds = 0 should error")
end

return tests
