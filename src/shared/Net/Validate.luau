--!strict
-- Argument checks for remotes (TDD B6). Every value a client sends is
-- treated as hostile until a check says otherwise.
--
-- Each builder returns a Check: a function that takes any value and
-- returns true only if it is safe to use. Numbers and strings must always
-- be given bounds, so there's no way to accept "any number" by accident.
--
-- Pure module (no Roblox APIs) so it can be unit tested outside Studio.

export type Check = (value: unknown) -> boolean

export type NumberOptions = {
	min: number,
	max: number,
	integer: boolean?,
}

export type StringOptions = {
	maxLength: number,
}

local Validate = {}

function Validate.number(options: NumberOptions): Check
	return function(value: unknown): boolean
		if typeof(value) ~= "number" then
			return false
		end
		-- NaN is the only value not equal to itself; it passes most other checks.
		if value ~= value then
			return false
		end
		if value < options.min or value > options.max then
			return false
		end
		if options.integer and value ~= math.floor(value) then
			return false
		end
		return true
	end
end

function Validate.string(options: StringOptions): Check
	return function(value: unknown): boolean
		if typeof(value) ~= "string" then
			return false
		end
		-- Byte length first: it's cheap and stops huge strings early.
		if #value > options.maxLength * 4 then
			return false
		end
		-- utf8.len returns nil for invalid UTF-8.
		local length = utf8.len(value)
		return length ~= nil and length <= options.maxLength
	end
end

function Validate.boolean(): Check
	return function(value: unknown): boolean
		return typeof(value) == "boolean"
	end
end

-- Accepts only one of the listed strings, e.g. a setting name.
function Validate.oneOf(allowed: { string }): Check
	local allowedSet: { [string]: boolean } = {}
	for _, item in allowed do
		allowedSet[item] = true
	end
	return function(value: unknown): boolean
		return typeof(value) == "string" and allowedSet[value] == true
	end
end

-- Accepts nil, or anything the inner check accepts.
function Validate.optional(inner: Check): Check
	return function(value: unknown): boolean
		return value == nil or inner(value)
	end
end

-- Checks a full argument list against a list of checks. Extra arguments
-- are refused, so a client can't smuggle in values a handler might read.
-- Returns false and a short reason when something fails.
function Validate.args(checks: { Check }, ...: unknown): (boolean, string?)
	local count = select("#", ...)
	if count > #checks then
		return false, `expected at most {#checks} arguments, got {count}`
	end
	for index, check in checks do
		local value = select(index, ...)
		if not check(value) then
			return false, `argument {index} failed validation`
		end
	end
	return true, nil
end

return Validate
