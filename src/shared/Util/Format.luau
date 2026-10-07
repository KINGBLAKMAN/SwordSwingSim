--!strict
-- Format: turns numbers into short display strings (GDD A4).
--
-- 1234 -> "1.23K", 12345 -> "12.3K", 1.5e9 -> "1.5B", 1.234e125 -> "1.23e125".
-- Digits are cut off, never rounded up, so a player never sees a total
-- they don't have yet (999,999 shows "999K", not "1M").
--
-- This module only formats. Replicate the number itself ({m, e} or a plain
-- number) and format it on the client (TDD B5).

local Format = {}

-- One suffix per power of 1000: K = 1e3, M = 1e6, ... NoTg = 1e120. The first
-- thirteen come from GDD A4; the rest continue the same Latin pattern.
-- Values of 1e123 and above use scientific notation instead.
local SUFFIXES = {
	"K",
	"M",
	"B",
	"T",
	"Qa",
	"Qi",
	"Sx",
	"Sp",
	"Oc",
	"No",
	"Dc",
	"UDc",
	"DDc",
	"TDc",
	"QaDc",
	"QiDc",
	"SxDc",
	"SpDc",
	"OcDc",
	"NoDc",
	"Vg",
	"UVg",
	"DVg",
	"TVg",
	"QaVg",
	"QiVg",
	"SxVg",
	"SpVg",
	"OcVg",
	"NoVg",
	"Tg",
	"UTg",
	"DTg",
	"TTg",
	"QaTg",
	"QiTg",
	"SxTg",
	"SpTg",
	"OcTg",
	"NoTg",
}

-- Suffixed values show 3 significant digits: 1.23K, 12.3K, 123K.
local SIGNIFICANT_DIGITS = 3

-- Values below 1000 show up to this many decimals: 12.5, 0.25.
local SMALL_VALUE_DECIMALS = 2

-- Scientific notation shows this many decimals: 1.23e125.
local SCIENTIFIC_DECIMALS = 2

-- Floating point can store 1.23 as 1.2299999999. This nudge stops cutting
-- digits from turning that into 1.22.
local CUT_EPSILON = 1e-9

-- Cuts n (not negative) to the given number of decimals. tostring then
-- prints the shortest form, which drops trailing zeros: 12.30 -> "12.3".
local function cutDecimals(n: number, decimals: number): string
	local scale = 10 ^ decimals
	return tostring(math.floor(n * scale + CUT_EPSILON) / scale)
end

-- Formats a positive value written as m × 10^e with 1 <= m < 10.
local function formatPositive(m: number, e: number): string
	if e < 3 then
		return cutDecimals(m * 10 ^ e, SMALL_VALUE_DECIMALS)
	end

	local tier = e // 3
	if tier > #SUFFIXES then
		return `{cutDecimals(m, SCIENTIFIC_DECIMALS)}e{e}`
	end

	-- e % 3 digits move in front of the point: 1.23K, 12.3K, 123K.
	local digitsBeforePoint = e % 3 + 1
	local scaled = m * 10 ^ (e % 3)
	return cutDecimals(scaled, SIGNIFICANT_DIGITS - digitsBeforePoint) .. SUFFIXES[tier]
end

-- Formats a BigNum ({m, e} with 1 <= |m| < 10, or m = 0).
function Format.big(value: { m: number, e: number }): string
	if value.m == 0 then
		return "0"
	end
	local text = formatPositive(math.abs(value.m), value.e)
	if value.m < 0 and text ~= "0" then
		return "-" .. text
	end
	return text
end

-- Formats a plain number, e.g. gems or a damage number.
function Format.number(n: number): string
	if n ~= n then
		return "NaN"
	elseif n == math.huge then
		return "inf"
	elseif n == -math.huge then
		return "-inf"
	elseif n == 0 then
		return "0"
	end

	-- Split n into m × 10^e, fixing the rare off-by-one from log10.
	local e = math.floor(math.log10(math.abs(n)))
	local m = n / 10 ^ e
	if math.abs(m) >= 10 then
		m /= 10
		e += 1
	elseif math.abs(m) < 1 then
		m *= 10
		e -= 1
	end
	return Format.big({ m = m, e = e })
end

-- Formats a countdown in whole seconds: 45 -> "0:45", 125 -> "2:05",
-- 3725 -> "1:02:05". Partial seconds round up, so a timer shows "0:01"
-- until it really runs out. Negative time shows "0:00".
function Format.duration(seconds: number): string
	local total = math.max(0, math.ceil(seconds))
	local hours = total // 3600
	local minutes = (total % 3600) // 60
	local secs = total % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end

return Format
