local BigNum = require("../src/shared/Util/BigNum")

local tests = {}

-- Floats pick up tiny errors, so compare mantissas with a tolerance.
local function assertNear(actual: number, expected: number, tolerance: number, label: string)
	assert(math.abs(actual - expected) <= tolerance, `{label}: expected {expected}, got {actual}`)
end

local function assertBig(value, m: number, e: number, label: string)
	assert(value.e == e, `{label}: expected exponent {e}, got {value.e}`)
	assertNear(value.m, m, 1e-9, `{label} mantissa`)
end

tests["normalizes so the mantissa sits in [1, 10)"] = function()
	assertBig(BigNum.fromNumber(1234), 1.234, 3, "1234")
	assertBig(BigNum.fromNumber(0.05), 5, -2, "0.05")
	assertBig(BigNum.fromNumber(-250), -2.5, 2, "-250")
	assertBig(BigNum.new(123, 10), 1.23, 12, "123e10")
	assertBig(BigNum.new(1, 2.5), 3.16227766, 2, "fractional exponent")
end

tests["normalizes exact powers of ten"] = function()
	for power = -5, 300 do
		local value = BigNum.fromNumber(10 ^ power)
		assert(value.e == power, `10^{power} got exponent {value.e}`)
		assertNear(value.m, 1, 1e-12, `10^{power} mantissa`)
	end
end

tests["zero is always {m = 0, e = 0}"] = function()
	assertBig(BigNum.fromNumber(0), 0, 0, "zero")
	assertBig(BigNum.new(0, 50), 0, 0, "0e50")
	assertBig(BigNum.sub(BigNum.fromNumber(7), BigNum.fromNumber(7)), 0, 0, "7 - 7")
	assert(BigNum.isZero(BigNum.zero()), "zero() is zero")
end

tests["round-trips plain numbers"] = function()
	for _, n in { 1, 42, 999.5, 123456789, 1.9e16, 1e300, -77 } do
		assertNear(BigNum.toNumber(BigNum.fromNumber(n)) / n, 1, 1e-12, `round trip {n}`)
	end
end

tests["refuses non-finite numbers"] = function()
	assert(not pcall(BigNum.fromNumber, 0 / 0), "NaN refused")
	assert(not pcall(BigNum.fromNumber, math.huge), "inf refused")
	assert(not pcall(BigNum.new, 1, math.huge), "inf exponent refused")
end

tests["adds and subtracts across exponents"] = function()
	local sum = BigNum.add(BigNum.fromNumber(1500), BigNum.fromNumber(25))
	assertBig(sum, 1.525, 3, "1500 + 25")

	local carry = BigNum.add(BigNum.new(9.5, 100), BigNum.new(5, 99))
	assertBig(carry, 1, 101, "9.5e100 + 5e99 carries")

	local difference = BigNum.sub(BigNum.new(1, 100), BigNum.new(1, 99))
	assertBig(difference, 9, 99, "1e100 - 1e99")

	local negative = BigNum.sub(BigNum.fromNumber(10), BigNum.fromNumber(25))
	assertBig(negative, -1.5, 1, "10 - 25")
end

tests["adding a far smaller number changes nothing"] = function()
	local big = BigNum.new(3, 200)
	assertBig(BigNum.add(big, BigNum.fromNumber(1)), 3, 200, "3e200 + 1")
	assertBig(BigNum.add(BigNum.fromNumber(1), big), 3, 200, "1 + 3e200")
end

tests["multiplies and divides"] = function()
	assertBig(BigNum.mul(BigNum.new(5, 200), BigNum.new(4, 300)), 2, 501, "5e200 × 4e300")
	assertBig(BigNum.div(BigNum.new(1, 10), BigNum.new(4, 3)), 2.5, 6, "1e10 / 4e3")
	assertBig(BigNum.mul(BigNum.fromNumber(-3), BigNum.fromNumber(3)), -9, 0, "-3 × 3")
	assert(not pcall(BigNum.div, BigNum.fromNumber(1), BigNum.zero()), "divide by zero errors")
end

tests["pow matches the rebirth cost formula 1e5 × 2^r"] = function()
	local two = BigNum.fromNumber(2)
	local base = BigNum.fromNumber(1e5)
	for _, rebirths in { 0, 1, 10, 40 } do
		local cost = BigNum.mul(base, BigNum.pow(two, rebirths))
		assertNear(BigNum.toNumber(cost) / (1e5 * 2 ^ rebirths), 1, 1e-9, `rebirth {rebirths}`)
	end

	-- 2^2000 is past the plain number range: log10 = 2000 × 0.30103 = 602.06.
	local huge = BigNum.pow(two, 2000)
	assert(huge.e == 602, `2^2000 exponent, got {huge.e}`)
	assertNear(huge.m, 1.1481306952742545, 1e-8, "2^2000 mantissa")

	assert(not pcall(BigNum.pow, BigNum.fromNumber(-2), 3), "negative base refused")
	assert(BigNum.isZero(BigNum.pow(BigNum.zero(), 3)), "0^3 is 0")
end

tests["compares by sign, then exponent, then mantissa"] = function()
	local ordered = {
		BigNum.new(-5, 100),
		BigNum.new(-2, 3),
		BigNum.new(-9, 1),
		BigNum.zero(),
		BigNum.new(9, -3),
		BigNum.new(1, 0),
		BigNum.new(2, 0),
		BigNum.new(1, 50),
	}
	for i = 1, #ordered do
		for j = 1, #ordered do
			local expected = if i < j then -1 elseif i > j then 1 else 0
			local actual = BigNum.compare(ordered[i], ordered[j])
			assert(
				actual == expected,
				`compare item {i} with {j}: expected {expected}, got {actual}`
			)
		end
	end
	assert(BigNum.lt(BigNum.fromNumber(1), BigNum.fromNumber(2)), "lt")
	assert(BigNum.le(BigNum.fromNumber(2), BigNum.fromNumber(2)), "le")
	assert(BigNum.eq(BigNum.new(10, 0), BigNum.new(1, 1)), "eq after normalizing")
end

tests["log10 and fromLog10 are inverses"] = function()
	assert(BigNum.log10(BigNum.fromNumber(1000)) == 3, "log10(1000) is exactly 3")
	assertNear(BigNum.log10(BigNum.new(5, 400)), 400.69897, 1e-5, "log10(5e400)")
	assertBig(BigNum.fromLog10(400.69897000433), 5, 400, "fromLog10")
	assert(not pcall(BigNum.log10, BigNum.zero()), "log10(0) errors")
end

tests["leaderboard keys sort like the values and decode back"] = function()
	local values = { BigNum.fromNumber(1), BigNum.fromNumber(1.9e16), BigNum.new(7.5, 450) }
	local previousKey = -1
	for _, value in values do
		local key = BigNum.toLeaderboardKey(value)
		assert(key == math.floor(key), "key is an integer")
		assert(key > previousKey, "keys increase with the value")
		previousKey = key

		local decoded = BigNum.fromLeaderboardKey(key)
		assert(decoded.e == value.e, `decoded exponent {decoded.e}`)
		assertNear(decoded.m / value.m, 1, 1e-5, "decoded mantissa within 6 digits")
	end
	assert(BigNum.toLeaderboardKey(BigNum.fromNumber(1e6)) == 6e6, "1e6 -> 6,000,000")
	assert(BigNum.toLeaderboardKey(BigNum.fromNumber(0.5)) == 0, "below 1 -> 0")
	assert(BigNum.toLeaderboardKey(BigNum.zero()) == 0, "zero -> 0")
end

tests["serialize and deserialize round-trip"] = function()
	local value = BigNum.new(4.2, 1234)
	local data = BigNum.serialize(value)
	assert(data ~= value, "serialize returns a new table")
	local restored = BigNum.deserialize(data)
	assert(restored and BigNum.eq(restored, value), "restored value matches")
	local zero = BigNum.deserialize({ m = 0, e = 0 })
	assert(zero and BigNum.isZero(zero), "zero restores")
end

tests["deserialize rejects bad data"] = function()
	local bad: { any } = {
		"1e5",
		5,
		{},
		{ m = "1", e = 2 },
		{ m = 0 / 0, e = 1 },
		{ m = 1, e = math.huge },
		{ m = 1.5, e = 2.5 },
		{ m = 12, e = 1 },
		{ m = 0.5, e = 1 },
		{ m = 0, e = 3 },
	}
	for index, data in bad do
		assert(BigNum.deserialize(data) == nil, `bad data {index} should be rejected`)
	end
	assert(BigNum.deserialize(nil) == nil, "nil rejected")
end

return tests
