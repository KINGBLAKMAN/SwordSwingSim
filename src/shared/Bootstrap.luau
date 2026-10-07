--!strict
-- Two-phase startup shared by the server and the client (TDD B1).
--
-- Phase 1, init: every module sets itself up (tables, remotes, config).
-- Nothing talks to another module yet, so the order of init calls only
-- matters for modules that say so in their own comments.
--
-- Phase 2, start: every module begins its real work (connect events,
-- start loops). By now every module has finished init, so any module can
-- safely call any other.
--
-- Modules are listed by hand in the entry scripts instead of discovered
-- from a folder, so the type checker can see every require.

-- A module has init, start or both. This is a union rather than one table
-- with two optional fields because Luau's type checker rejects a required
-- module that leaves an optional field out (a controller with only start).
export type Module = { init: () -> (), start: () -> () } | { init: () -> () } | { start: () -> () }

export type Entry = {
	name: string,
	module: Module,
}

local Bootstrap = {}

-- The module's init or start function, or nil if it doesn't have one.
local function phaseFunction(module: Module, phase: "init" | "start"): (() -> ())?
	return (module :: any)[phase]
end

local function initAll(side: string, entries: { Entry })
	for _, entry in entries do
		local init = phaseFunction(entry.module, "init")
		if init then
			local ok, err = pcall(function()
				init()
			end)
			if not ok then
				-- A module that failed to set up would break everything after
				-- it, so stop here with a clear message.
				error(`[{side}] {entry.name}.init failed: {err}`, 0)
			end
		end
	end
end

local function startAll(entries: { Entry })
	for _, entry in entries do
		local start = phaseFunction(entry.module, "start")
		if start then
			-- Each start runs in its own thread so one module waiting on
			-- something cannot hold up the rest.
			task.spawn(start)
		end
	end
end

function Bootstrap.run(side: string, entries: { Entry })
	initAll(side, entries)
	startAll(entries)
	print(`[{side}] started {#entries} modules`)
end

return Bootstrap
