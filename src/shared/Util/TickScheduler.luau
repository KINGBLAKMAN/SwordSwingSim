--!strict
-- TickScheduler: many repeating timers driven by one loop (TDD B7).
--
-- Server-side autos (auto-click now, auto-attack later) tick each player a
-- few times a second. Rather than a loop per player, one Heartbeat calls
-- collect(now) and gets back how many ticks each key is owed. Each key
-- starts at its own offset into the interval, so players' ticks spread
-- across frames instead of all landing on the same one.
--
-- Pure module (the caller passes the time and the offset), so it can be
-- unit tested outside Studio.

export type TickScheduler<K> = {
	-- Starts ticking `key` every `interval` seconds. Its first tick comes
	-- `interval × phase` seconds after `now`, with phase in [0, 1). Adding a
	-- key that's already there just changes its interval.
	add: (key: K, interval: number, now: number, phase: number) -> (),
	remove: (key: K) -> (),
	has: (key: K) -> boolean,
	-- Ticks owed to each key since the last collect, for keys owed at least one.
	collect: (now: number) -> { [K]: number },
}

type Timer = {
	interval: number,
	nextAt: number,
}

local TickScheduler = {}

function TickScheduler.new<K>(): TickScheduler<K>
	local timers: { [K]: Timer } = {}

	local function add(key: K, interval: number, now: number, phase: number)
		assert(interval > 0, "TickScheduler: interval must be positive")
		local existing = timers[key]
		if existing then
			existing.interval = interval
			return
		end
		timers[key] = { interval = interval, nextAt = now + interval * phase }
	end

	local function remove(key: K)
		timers[key] = nil
	end

	local function has(key: K): boolean
		return timers[key] ~= nil
	end

	local function collect(now: number): { [K]: number }
		local owed: { [K]: number } = {}
		for key, timer in timers do
			if now >= timer.nextAt then
				-- A slow frame can owe several ticks at once; pay them all so
				-- the rate holds over real time.
				local ticks = math.floor((now - timer.nextAt) / timer.interval) + 1
				timer.nextAt += ticks * timer.interval
				owed[key] = ticks
			end
		end
		return owed
	end

	return {
		add = add,
		remove = remove,
		has = has,
		collect = collect,
	}
end

return TickScheduler
