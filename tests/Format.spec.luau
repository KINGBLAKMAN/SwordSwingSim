local BigNum = require("../src/shared/Util/BigNum")
local Format = require("../src/shared/Util/Format")

local tests = {}

local function expectNumber(n: number, expected: string)
	local actual = Format.number(n)
	assert(actual == expected, `Format.number({n}): expected "{expected}", got "{actual}"`)
end

local function expectBig(m: number, e: number, expected: string)
	local actual = Format.big(BigNum.new(m, e))
	assert(actual == expected, `Format.big({m}e{e}): expected "{expected}", got "{actual}"`)
end

tests["values below 1000 show up to 2 decimals"] = function()
	expectNumber(0, "0")
	expectNumber(5, "5")
	expectNumber(12.5, "12.5")
	expectNumber(12.345, "12.34")
	expectNumber(0.25, "0.25")
	expectNumber(0.001, "0")
	expectNumber(999.999, "999.99")
end

tests["suffixed values show 3 significant digits"] = function()
	expectNumber(1000, "1K")
	expectNumber(1234, "1.23K")
	expectNumber(12345, "12.3K")
	expectNumber(123456, "123K")
	expectNumber(1e6, "1M")
	expectNumber(1.5e9, "1.5B")
	expectNumber(2.07e12, "2.07T")
	expectNumber(1.9e16, "19Qa")
end

tests["digits are cut, never rounded up"] = function()
	expectNumber(999999, "999K")
	expectNumber(1999, "1.99K")
	expectNumber(1.0099e6, "1M")
end

tests["cutting survives float error like 1.23 stored as 1.2299999"] = function()
	expectNumber(1230, "1.23K")
	expectNumber(4.56e21, "4.56Sx")
	expectBig(1.23, 33, "1.23Dc")
	expectBig(0.1 + 0.2, 4, "3K")
end

tests["follows the GDD A4 suffix order"] = function()
	local gddOrder = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "UDc", "DDc" }
	for index, suffix in gddOrder do
		expectBig(1, index * 3, `1{suffix}`)
	end
end

tests["the last suffix is NoTg, then scientific from 1e123"] = function()
	expectBig(1, 120, "1NoTg")
	expectBig(9.999, 122, "999NoTg")
	expectBig(1, 123, "1e123")
	expectBig(1.234, 123, "1.23e123")
	expectBig(5, 4567, "5e4567")
end

tests["negative values keep their sign"] = function()
	expectNumber(-1234, "-1.23K")
	expectNumber(-0.5, "-0.5")
	expectNumber(-0.001, "0")
	expectBig(-1.234, 150, "-1.23e150")
end

tests["handles zero and non-finite plain numbers"] = function()
	assert(Format.big(BigNum.zero()) == "0", "BigNum zero")
	expectNumber(0 / 0, "NaN")
	expectNumber(math.huge, "inf")
	expectNumber(-math.huge, "-inf")
end

tests["duration shows minutes and seconds, adding hours past an hour"] = function()
	local cases: { { number | string } } = {
		{ 0, "0:00" },
		{ 45, "0:45" },
		{ 125, "2:05" },
		{ 3600, "1:00:00" },
		{ 3725, "1:02:05" },
	}
	for _, case in cases do
		local actual = Format.duration(case[1] :: number)
		assert(actual == case[2], `Format.duration({case[1]}): expected "{case[2]}", got "{actual}"`)
	end
end

tests["duration rounds partial seconds up and never goes negative"] = function()
	assert(Format.duration(0.2) == "0:01", "0.2s left should still show 0:01")
	assert(Format.duration(59.5) == "1:00", "59.5s should round up to 1:00")
	assert(Format.duration(-5) == "0:00", "time past the end should show 0:00")
end

return tests
