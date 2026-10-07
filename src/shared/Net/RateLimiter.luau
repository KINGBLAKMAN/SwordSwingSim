--!strict
-- Per-key rate limiter (TDD B6). The server keeps one per remote and uses
-- the Player as the key, so each player gets their own budget.
--
-- Each key has a bucket that holds up to `calls` tokens and refills
-- smoothly at `calls / perSeconds` tokens per second. Every allowed call
-- spends one token; a call with no token left is refused. A full bucket
-- lets a player do a short burst, then settles at the steady rate.
--
-- This module is pure (no Roblox APIs, the caller passes the time), so it
-- can be unit tested outside Studio.

export type Limit = {
	calls: number,
	perSeconds: number,
}

export type RateLimiter = {
	-- Returns true and spends a token if `key` may make a call at time `now`.
	allow: (key: any, now: number) -> boolean,
	-- Drops the bucket for `key`, e.g. when a player leaves.
	forget: (key: any) -> (),
}

type Bucket = {
	tokens: number,
	lastRefill: number,
}

local RateLimiter = {}

function RateLimiter.new(limit: Limit): RateLimiter
	assert(limit.calls > 0, "RateLimiter: calls must be positive")
	assert(limit.perSeconds > 0, "RateLimiter: perSeconds must be positive")

	local refillPerSecond = limit.calls / limit.perSeconds
	local buckets: { [any]: Bucket } = {}

	local function allow(key: any, now: number): boolean
		local bucket = buckets[key]
		if bucket == nil then
			bucket = { tokens = limit.calls, lastRefill = now }
			buckets[key] = bucket
		end

		-- If time goes backwards (a clock change), refill nothing and keep the
		-- later timestamp, so the gap can't be counted twice to mint tokens.
		local elapsed = math.max(0, now - bucket.lastRefill)
		bucket.tokens = math.min(limit.calls, bucket.tokens + elapsed * refillPerSecond)
		bucket.lastRefill = math.max(bucket.lastRefill, now)

		if bucket.tokens < 1 then
			return false
		end
		bucket.tokens -= 1
		return true
	end

	local function forget(key: any)
		buckets[key] = nil
	end

	return {
		allow = allow,
		forget = forget,
	}
end

return RateLimiter
