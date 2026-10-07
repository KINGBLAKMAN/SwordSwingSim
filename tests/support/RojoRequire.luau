-- Loads src modules that use Roblox-style requires, like
-- require(script.Parent.Config.Eggs), so Lune tests can run them.
--
-- Each loaded module gets a fake `script` that stands for its place in the
-- Rojo tree: indexing it with a name finds the child file or folder, and
-- Parent goes up a folder. A folder's init.luau is the folder itself, as
-- in Rojo. Only plain modules work: anything that calls Roblox services
-- (game, Instance, task) still can't run under Lune.
--
-- Paths are relative to the repo root, where `lune run tests/run.luau` runs.
--
-- Usage: local Eggs = RojoRequire("src/shared/Config/Eggs")

local fs = require("@lune/fs")
local luau = require("@lune/luau")

-- A spot in the tree: a folder or a module file, by its path without ".luau".
type Node = { path: string }

local nodeMetatable = {}
local cache: { [string]: any } = {}

local function newNode(path: string): Node
	return setmetatable({ path = path }, nodeMetatable) :: any
end

local function parentPath(path: string): string
	return string.match(path, "^(.*)/[^/]+$") or ""
end

-- The file that holds a node's code, or nil if it's a plain folder.
local function sourceFile(path: string): string?
	if fs.isFile(path .. ".luau") then
		return path .. ".luau"
	elseif fs.isFile(path .. "/init.luau") then
		return path .. "/init.luau"
	end
	return nil
end

nodeMetatable.__index = function(node: Node, key: string)
	if key == "Parent" then
		return newNode(parentPath(node.path))
	end
	-- Lune's fs calls can't run inside a metamethod, so a missing child
	-- only shows up when it's required.
	return newNode(node.path .. "/" .. key)
end

local function load(path: string): any
	local cached = cache[path]
	if cached ~= nil then
		return cached
	end

	local file = sourceFile(path)
	assert(file, `RojoRequire: no module at {path}`)

	local environment = {
		script = newNode(path),
		require = function(target: Node)
			return load(target.path)
		end,
	}
	local chunk = luau.load(fs.readFile(file), { debugName = file, environment = environment })
	local result = chunk()
	cache[path] = result
	return result
end

return load
