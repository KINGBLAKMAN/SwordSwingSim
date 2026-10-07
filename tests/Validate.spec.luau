local Validate = require("../src/shared/Net/Validate")

local tests = {}

tests["number accepts values in range"] = function()
	local check = Validate.number({ min = 1, max = 10 })
	assert(check(1) and check(5.5) and check(10), "in-range values pass")
end

tests["number refuses wrong types, NaN, infinity and out-of-range values"] = function()
	local check = Validate.number({ min = 1, max = 10 })
	assert(not check("5"), "string")
	assert(not check(nil), "nil")
	assert(not check(0 / 0), "NaN")
	assert(not check(math.huge), "infinity")
	assert(not check(-math.huge), "negative infinity")
	assert(not check(0) and not check(11), "out of range")
end

tests["integer numbers refuse fractions"] = function()
	local check = Validate.number({ min = 1, max = 100, integer = true })
	assert(check(3), "whole number passes")
	assert(not check(3.5), "fraction fails")
end

tests["string enforces type and length"] = function()
	local check = Validate.string({ maxLength = 5 })
	assert(check("hello"), "5 chars pass")
	assert(not check("hello!"), "6 chars fail")
	assert(not check(5), "number fails")
	assert(not check("\255\255"), "invalid UTF-8 fails")
end

tests["oneOf accepts only listed values"] = function()
	local check = Validate.oneOf({ "Music", "Sound" })
	assert(check("Music"), "listed value passes")
	assert(not check("music"), "case matters")
	assert(not check(1), "number fails")
end

tests["optional accepts nil or a valid value"] = function()
	local check = Validate.optional(Validate.boolean())
	assert(check(nil) and check(true), "nil and boolean pass")
	assert(not check("true"), "string fails")
end

tests["args checks every argument and refuses extras"] = function()
	local checks = {
		Validate.string({ maxLength = 20 }),
		Validate.number({ min = 1, max = 10, integer = true }),
	}
	assert(Validate.args(checks, "egg_basic", 3), "valid call passes")
	assert(not Validate.args(checks, "egg_basic"), "missing argument fails")
	assert(not Validate.args(checks, "egg_basic", 3, "extra"), "extra argument fails")
	assert(not Validate.args(checks, "egg_basic", 999), "bad argument fails")
	assert(not Validate.args({}, nil), "an explicit extra nil also counts as an extra argument")
	assert(Validate.args({}), "no arguments for a no-argument remote passes")
end

tests["arrayOf accepts short lists of valid items only"] = function()
	local check = Validate.arrayOf(Validate.string({ maxLength = 8 }), 3)
	assert(check({ "a" }) and check({ "a", "b", "c" }), "valid lists pass")
	assert(not check({}), "empty list")
	assert(not check({ "a", "b", "c", "d" }), "too long")
	assert(not check({ "a", 5 }), "bad item")
	assert(not check({ [1] = "a", [3] = "c" }), "gap")
	assert(not check({ "a", extra = "b" }), "dictionary key")
	assert(not check("a"), "not a table")
end

return tests
