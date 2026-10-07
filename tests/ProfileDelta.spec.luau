local ProfileDelta = require("../src/shared/Data/ProfileDelta")

local tests = {}

-- True if two plain values hold the same data, tables compared key by key.
local function deepEqual(a: any, b: any): boolean
	if typeof(a) ~= "table" or typeof(b) ~= "table" then
		return a == b
	end
	for key, value in a do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

local function sampleProfile()
	return {
		currencies = { gems = 5, coins = { m = 1.5, e = 3 } },
		pets = { a = { level = 1 }, b = { level = 2 } },
		equippedPets = { "a" },
	}
end

tests["get reads a path and returns nil when any part is missing"] = function()
	local profile = sampleProfile()
	assert(ProfileDelta.get(profile, { "currencies", "gems" }) == 5, "gems")
	assert(ProfileDelta.get(profile, { "equippedPets", 1 }) == "a", "array index")
	assert(ProfileDelta.get(profile, { "pets", "zzz", "level" }) == nil, "missing pet")
	assert(ProfileDelta.get(profile, { "currencies", "gems", "deeper" }) == nil, "through a number")
	assert(ProfileDelta.get(profile, {}) == profile, "empty path is the root")
end

tests["set writes in place and nil removes the key"] = function()
	local profile = sampleProfile()
	ProfileDelta.set(profile, { "currencies", "gems" }, 9)
	assert(profile.currencies.gems == 9, "gems written")
	ProfileDelta.set(profile, { "pets", "c" }, { level = 3 })
	assert(profile.pets.c.level == 3, "new key under an existing table")
	ProfileDelta.set(profile, { "pets", "a" }, nil)
	assert(profile.pets.a == nil, "pet removed")
end

tests["set refuses an empty path or a missing parent"] = function()
	local profile = sampleProfile()
	assert(not pcall(ProfileDelta.set, profile, {}, {}), "empty path")

	local ok, err = pcall(ProfileDelta.set, profile, { "quests", "q1", "progress" }, 1)
	assert(not ok, "missing parent table")
	assert(string.find(tostring(err), "quests.q1", 1, true), `error names the path: {err}`)

	assert(
		not pcall(ProfileDelta.set, profile, { "currencies", "gems", "x" }, 1),
		"parent is a number"
	)
end

tests["apply leaves the old profile alone and shares untouched tables"] = function()
	local old = sampleProfile()
	local new = ProfileDelta.apply(old, { { path = { "pets", "a", "level" }, value = 7 } })

	assert(old.pets.a.level == 1, "old profile unchanged")
	assert(new.pets.a.level == 7, "new profile changed")
	assert(new ~= old and new.pets ~= old.pets and new.pets.a ~= old.pets.a, "path copied")
	assert(new.pets.b == old.pets.b, "sibling pet shared")
	assert(new.currencies == old.currencies, "untouched branch shared")
end

tests["apply handles a whole-profile change and removals"] = function()
	local snapshot = sampleProfile()
	local profile = ProfileDelta.apply(nil, { { path = {}, value = snapshot } })
	assert(profile == snapshot, "empty path replaces the root, even from nil")

	profile = ProfileDelta.apply(profile, {
		{ path = { "pets", "a" }, value = nil },
		{ path = { "currencies", "gems" }, value = 6 },
	})
	assert(profile.pets.a == nil and profile.pets.b ~= nil, "pet a removed")
	assert(profile.currencies.gems == 6, "later change in the same batch applied")
end

tests["apply errors when a parent table is missing"] = function()
	local ok = pcall(ProfileDelta.apply, sampleProfile(), {
		{ path = { "quests", "q1", "progress" }, value = 1 },
	})
	assert(not ok, "missing parent")
	assert(
		not pcall(ProfileDelta.apply, nil, { { path = { "gems" }, value = 1 } }),
		"no profile yet"
	)
end

tests["deepCopy shares nothing with the original"] = function()
	local original = sampleProfile()
	local copy = ProfileDelta.deepCopy(original)
	assert(deepEqual(copy, original), "same data")
	copy.pets.a.level = 99
	assert(original.pets.a.level == 1, "nested table not shared")
	assert(ProfileDelta.deepCopy(5) == 5, "plain values pass through")
end

tests["a batch keeps only the newest write per path, in write order"] = function()
	local batch = ProfileDelta.newBatch()
	assert(ProfileDelta.isEmpty(batch), "starts empty")
	for gems = 1, 12 do
		ProfileDelta.queue(batch, { "currencies", "gems" }, gems)
	end
	ProfileDelta.queue(batch, { "pets", "a", "level" }, 4)

	local changes = ProfileDelta.take(batch)
	assert(#changes == 2, `expected 2 changes, got {#changes}`)
	assert(changes[1].value == 12, "only the last gems value is sent")
	assert(changes[2].path[1] == "pets", "order follows the writes")
	assert(ProfileDelta.isEmpty(batch), "take empties the batch")
	assert(#ProfileDelta.take(batch) == 0, "nothing left to take")
end

tests["a batch keeps parent and child writes correct when coalescing"] = function()
	-- Server-side sequence: replace pet a, level it, then replace it again.
	local server = sampleProfile()
	local client = ProfileDelta.deepCopy(server)
	local batch = ProfileDelta.newBatch()
	local function write(path, value)
		ProfileDelta.set(server, path, value)
		ProfileDelta.queue(batch, path, value)
	end

	write({ "pets", "a" }, { level = 10 })
	write({ "pets", "a", "level" }, 11)
	write({ "pets" }, { a = { level = 20 } })
	write({ "pets", "a", "level" }, 21)
	write({ "pets", "a" }, { level = 30 })

	client = ProfileDelta.apply(client, ProfileDelta.take(batch))
	assert(deepEqual(client, server), "client matches server")
	assert(client.pets.a.level == 30, "newest whole-pet write wins")
end

tests["a write inside a table that's later removed is never sent"] = function()
	-- The client has never seen pet d. If the level write were sent, the
	-- client would have no pet table to put it in.
	local server = sampleProfile()
	local client = ProfileDelta.deepCopy(server)
	local batch = ProfileDelta.newBatch()
	local function write(path, value)
		ProfileDelta.set(server, path, value)
		ProfileDelta.queue(batch, path, value)
	end

	write({ "pets", "d" }, { level = 1 })
	write({ "pets", "d", "level" }, 5)
	write({ "pets", "d" }, nil)

	local changes = ProfileDelta.take(batch)
	assert(#changes == 1, `only the removal is sent, got {#changes} changes`)
	client = ProfileDelta.apply(client, changes)
	assert(deepEqual(client, server), "client matches server")
end

tests["paths that look alike never share a batch slot"] = function()
	local batch = ProfileDelta.newBatch()
	ProfileDelta.queue(batch, { "a.b" }, 1)
	ProfileDelta.queue(batch, { "a", "b" }, 2)
	ProfileDelta.queue(batch, { "list", 1 }, 3)
	ProfileDelta.queue(batch, { "list", "1" }, 4)
	assert(#ProfileDelta.take(batch) == 4, "four different paths")
end

tests["queue copies the path so later edits to it don't matter"] = function()
	local batch = ProfileDelta.newBatch()
	local path = { "currencies", "gems" }
	ProfileDelta.queue(batch, path, 1)
	path[2] = "coins"
	local changes = ProfileDelta.take(batch)
	assert(changes[1].path[2] == "gems", "queued path unchanged")
end

-- Random writes on a server copy, sent in batches, must leave the client
-- copy identical to the server copy after every send.
tests["random writes keep the client matching the server"] = function()
	math.randomseed(4242)
	local petIds = { "a", "b", "c", "d" }

	local function randomWrite(server): ({ any }, any)
		local roll = math.random(6)
		local petId = petIds[math.random(#petIds)]
		if roll == 1 then
			return { "currencies", "gems" }, math.random(1000)
		elseif roll == 2 then
			return { "pets", petId }, { level = math.random(50), tags = { "x" } }
		elseif roll == 3 then
			return { "pets", petId }, nil
		elseif roll == 4 and server.pets[petId] then
			return { "pets", petId, "level" }, math.random(50)
		elseif roll == 5 then
			return { "pets" }, { [petId] = { level = 1, tags = {} } }
		end
		return { "equippedPets" }, { petIds[math.random(#petIds)] }
	end

	local server = sampleProfile()
	local client = ProfileDelta.apply(nil, { { path = {}, value = ProfileDelta.deepCopy(server) } })
	local batch = ProfileDelta.newBatch()

	for send = 1, 500 do
		for _ = 1, math.random(0, 8) do
			local path, value = randomWrite(server)
			-- Like DataService.set: store a copy, queue that same copy.
			local copy = ProfileDelta.deepCopy(value)
			ProfileDelta.set(server, path, copy)
			ProfileDelta.queue(batch, path, copy)
		end
		-- The remote call copies the data on the way to the client.
		local sent = ProfileDelta.deepCopy(ProfileDelta.take(batch))
		client = ProfileDelta.apply(client, sent)
		assert(deepEqual(client, server), `client differs from server after send {send}`)
	end
end

return tests
