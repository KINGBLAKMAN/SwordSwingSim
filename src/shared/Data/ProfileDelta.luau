--!strict
-- ProfileDelta: keeps each client's copy of its profile matching the
-- server's (TDD B6, B9).
--
-- A change says "the value at this path is now this", for example
-- { path = { "currencies", "gems" }, value = 50 }. A nil value removes the
-- key (a deleted pet). An empty path replaces the whole profile; the server
-- sends one of those when the profile loads.
--
-- The server writes with set(), queues each write in a Batch, and sends the
-- batch a few times a second. The client runs apply() on its copy.
--
-- This module has no requires, so Lune tests can load it.

export type Key = string | number
export type Path = { Key }
export type Change = { path: Path, value: any }

export type Batch = {
	-- Queued changes by the order they were written in.
	queued: { [number]: Change },
	nextOrder: number,
}

local ProfileDelta = {}

-- "currencies.gems", for error messages.
local function describe(path: Path, length: number?): string
	local parts = {}
	for index = 1, length or #path do
		table.insert(parts, tostring(path[index]))
	end
	return if #parts == 0 then "(root)" else table.concat(parts, ".")
end

-- True if path is ancestor itself or somewhere inside it.
local function isAtOrInside(path: Path, ancestor: Path): boolean
	if #path < #ancestor then
		return false
	end
	for index, key in ancestor do
		if path[index] ~= key then
			return false
		end
	end
	return true
end

-- Copies a value and every table inside it.
function ProfileDelta.deepCopy(value: any): any
	if typeof(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value do
		copy[key] = ProfileDelta.deepCopy(child)
	end
	return copy
end

-- Follows the first `length` keys of path from root. Returns nil if any
-- part of the way is missing.
local function walk(root: any, path: Path, length: number): any
	local node = root
	for index = 1, length do
		if typeof(node) ~= "table" then
			return nil
		end
		node = node[path[index]]
	end
	return node
end

-- Reads the value at path. Returns nil if any part of the path is missing.
function ProfileDelta.get(root: any, path: Path): any
	return walk(root, path, #path)
end

-- Writes value at path, changing root in place (server side). Errors if the
-- table that should hold the last key is missing, which means the path has
-- a typo or the caller skipped creating the parent first.
function ProfileDelta.set(root: any, path: Path, value: any)
	assert(#path > 0, "ProfileDelta.set: an empty path would replace the whole profile")

	local parent = walk(root, path, #path - 1)
	if typeof(parent) ~= "table" then
		error(`ProfileDelta.set: no table at {describe(path, #path - 1)}`)
	end
	parent[path[#path]] = value
end

-- Returns node with the value at path[depth...] replaced. Copies node and
-- every table below it along the path; shares everything else.
local function withValue(node: any, path: Path, depth: number, value: any): any
	if depth > #path then
		return value
	end
	if typeof(node) ~= "table" then
		error(`ProfileDelta.apply: no table at {describe(path, depth - 1)}`)
	end
	local key = path[depth]
	local copy = table.clone(node)
	copy[key] = withValue(node[key], path, depth + 1, value)
	return copy
end

-- Returns root with every change applied, in order (client side). Doesn't
-- change root or anything inside it: each table along a changed path is
-- copied and the rest is shared, so UI code can spot what changed by
-- comparing table references.
function ProfileDelta.apply(root: any, changes: { Change }): any
	local current = root
	for _, change in changes do
		current = withValue(current, change.path, 1, change.value)
	end
	return current
end

function ProfileDelta.newBatch(): Batch
	return { queued = {}, nextOrder = 1 }
end

-- Queues a change to send later. A write replaces everything at and inside
-- its path, so queued writes there are dropped: a value that changes 12
-- times between sends goes out once, and a write into a table that was
-- later removed is never sent (the client would have no table to put it in).
function ProfileDelta.queue(batch: Batch, path: Path, value: any)
	for order, queued in batch.queued do
		if isAtOrInside(queued.path, path) then
			batch.queued[order] = nil
		end
	end
	batch.queued[batch.nextOrder] = { path = table.clone(path), value = value }
	batch.nextOrder += 1
end

function ProfileDelta.isEmpty(batch: Batch): boolean
	return next(batch.queued) == nil
end

-- Returns the queued changes in the order they were written and empties
-- the batch.
function ProfileDelta.take(batch: Batch): { Change }
	local orders = {}
	for order in batch.queued do
		table.insert(orders, order)
	end
	table.sort(orders)

	local changes = {}
	for _, order in orders do
		table.insert(changes, batch.queued[order])
	end
	table.clear(batch.queued)
	return changes
end

return ProfileDelta
