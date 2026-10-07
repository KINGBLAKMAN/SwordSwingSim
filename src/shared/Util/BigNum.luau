--!strict
-- BigNum: numbers too large for a plain Luau number (TDD B5).
--
-- A value is m × 10^e. After every operation it is normalized so that
-- 1 <= |m| < 10 and e is a whole number, or m = 0 and e = 0 for zero. The
-- sign lives in m. Plain numbers stop near 1.8e308; game values (coins,
-- power, enemy HP) grow past that over enough rebirths.
--
-- Values are plain {m, e} tables so they replicate and save as-is. Treat
-- them as read-only: every function returns a new table.

export type BigNum = { m: number, e: number }

local BigNum = {}

-- Doubles hold about 16 significant digits. When two exponents differ by
-- more than this, the smaller number can't change the larger one's digits,
-- so add() skips it instead of computing a meaningless tiny shift.
local MAX_DIGIT_GAP = 17

-- Leaderboards (OrderedDataStore) only sort integers, so they store
-- floor(log10(x) × LEADERBOARD_SCALE) per TDD B5.
local LEADERBOARD_SCALE = 1e6

-- fromNumber treats anything smaller than this as zero. Game values never
-- get this small, and it keeps 10^-e from overflowing during normalize.
local SMALLEST_NUMBER = 1e-300

local function zero(): BigNum
	return { m = 0, e = 0 }
end

local function isFinite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

-- Shifts digits between m and e until 1 <= |m| < 10.
local function normalize(m: number, e: number): BigNum
	if m == 0 then
		return zero()
	end

	-- Fold any fractional exponent into the mantissa so e stays whole.
	local wholeE = math.floor(e)
	m *= 10 ^ (e - wholeE)

	local shift = math.floor(math.log10(math.abs(m)))
	m /= 10 ^ shift
	local newE = wholeE + shift

	-- log10 can land one step off for values right at a power of ten.
	if math.abs(m) >= 10 then
		m /= 10
		newE += 1
	elseif math.abs(m) < 1 then
		m *= 10
		newE -= 1
	end

	return { m = m, e = newE }
end

function BigNum.new(m: number, e: number): BigNum
	assert(isFinite(m) and isFinite(e), "BigNum.new needs finite numbers")
	return normalize(m, e)
end

function BigNum.zero(): BigNum
	return zero()
end

function BigNum.fromNumber(n: number): BigNum
	assert(isFinite(n), `BigNum.fromNumber needs a finite number, got {n}`)
	if math.abs(n) < SMALLEST_NUMBER then
		return zero()
	end
	return normalize(n, 0)
end

-- Builds 10^x. Handy for exponential formulas whose result is too big for
-- a plain number.
function BigNum.fromLog10(x: number): BigNum
	assert(isFinite(x), `BigNum.fromLog10 needs a finite number, got {x}`)
	return normalize(1, x)
end

-- Returns math.huge (or 0) when the value is outside the plain number range.
function BigNum.toNumber(value: BigNum): number
	return value.m * 10 ^ value.e
end

function BigNum.isZero(value: BigNum): boolean
	return value.m == 0
end

function BigNum.negate(value: BigNum): BigNum
	if value.m == 0 then
		return zero()
	end
	return { m = -value.m, e = value.e }
end

function BigNum.add(a: BigNum, b: BigNum): BigNum
	if a.m == 0 then
		return { m = b.m, e = b.e }
	end
	if b.m == 0 then
		return { m = a.m, e = a.e }
	end

	-- Line both numbers up on the larger exponent, then add mantissas.
	local larger, smaller = a, b
	if b.e > a.e then
		larger, smaller = b, a
	end
	local gap = larger.e - smaller.e
	if gap > MAX_DIGIT_GAP then
		return { m = larger.m, e = larger.e }
	end
	return normalize(larger.m + smaller.m / 10 ^ gap, larger.e)
end

function BigNum.sub(a: BigNum, b: BigNum): BigNum
	return BigNum.add(a, BigNum.negate(b))
end

function BigNum.mul(a: BigNum, b: BigNum): BigNum
	return normalize(a.m * b.m, a.e + b.e)
end

function BigNum.div(a: BigNum, b: BigNum): BigNum
	assert(b.m ~= 0, "BigNum.div: division by zero")
	return normalize(a.m / b.m, a.e - b.e)
end

-- Raises a positive base to any power, e.g. the rebirth cost 2^r (GDD A4).
-- Works through log10, so the result keeps about 10 significant digits.
function BigNum.pow(base: BigNum, power: number): BigNum
	assert(isFinite(power), `BigNum.pow needs a finite power, got {power}`)
	if base.m == 0 then
		assert(power > 0, "BigNum.pow: zero to a non-positive power")
		return zero()
	end
	assert(base.m > 0, "BigNum.pow needs a positive base")
	return BigNum.fromLog10(BigNum.log10(base) * power)
end

function BigNum.log10(value: BigNum): number
	assert(value.m > 0, "BigNum.log10 needs a positive number")
	return value.e + math.log10(value.m)
end

-- Returns -1 if a < b, 0 if equal, 1 if a > b.
function BigNum.compare(a: BigNum, b: BigNum): number
	local signA = math.sign(a.m)
	local signB = math.sign(b.m)
	if signA ~= signB then
		return if signA < signB then -1 else 1
	end
	if signA == 0 then
		return 0
	end

	if a.e ~= b.e then
		-- For negative numbers a bigger exponent means a smaller value.
		local byExponent = if a.e < b.e then -1 else 1
		return byExponent * signA
	end
	if a.m == b.m then
		return 0
	end
	return if a.m < b.m then -1 else 1
end

function BigNum.eq(a: BigNum, b: BigNum): boolean
	return BigNum.compare(a, b) == 0
end

function BigNum.lt(a: BigNum, b: BigNum): boolean
	return BigNum.compare(a, b) < 0
end

function BigNum.le(a: BigNum, b: BigNum): boolean
	return BigNum.compare(a, b) <= 0
end

-- Integer sort key for an OrderedDataStore leaderboard. Values below 1
-- (including zero and negatives) all map to 0.
function BigNum.toLeaderboardKey(value: BigNum): number
	if value.m <= 0 or value.e < 0 then
		return 0
	end
	return math.floor(BigNum.log10(value) * LEADERBOARD_SCALE)
end

-- Decodes a leaderboard key for display. Accurate to about 6 digits,
-- which is more than Format shows. Key 0 decodes to 1.
function BigNum.fromLeaderboardKey(key: number): BigNum
	return BigNum.fromLog10(math.max(key, 0) / LEADERBOARD_SCALE)
end

-- Plain table for saving or sending over a remote.
function BigNum.serialize(value: BigNum): { m: number, e: number }
	return { m = value.m, e = value.e }
end

-- Reads a value back from a save or remote. Returns nil for anything that
-- isn't a normalized BigNum, so callers decide the fallback.
function BigNum.deserialize(data: unknown): BigNum?
	if typeof(data) ~= "table" then
		return nil
	end
	local m = (data :: any).m
	local e = (data :: any).e
	if typeof(m) ~= "number" or typeof(e) ~= "number" then
		return nil
	end
	if not isFinite(m) or not isFinite(e) or e ~= math.floor(e) then
		return nil
	end

	if m == 0 then
		return if e == 0 then zero() else nil
	end
	local size = math.abs(m)
	if size < 1 or size >= 10 then
		return nil
	end
	return { m = m, e = e }
end

return BigNum
