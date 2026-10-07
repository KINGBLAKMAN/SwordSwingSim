--!strict
-- Odds display and policy settings (TDD B11, checklist C6).

local Compliance = {
	-- Displayed odds keep this many digits after the first non-zero digit:
	-- 35.12%, 1.3200% -> "1.32%", 0.0012345% -> "0.0012345%". Trailing
	-- zeros are dropped.
	ODDS_DIGITS_AFTER_FIRST = 4,

	-- Shown under an odds list whose rounded percentages don't add up to
	-- exactly 100.
	ROUNDING_DISCLAIMER = "Odds are rounded, so they may not add up to exactly 100%.",

	-- Player attributes ComplianceService sets once a player's policy is
	-- known, so the client can hide paid luck and trading. They're display
	-- hints only: the server checks the policy again on every request.
	RESTRICTED_ATTRIBUTE = "PaidRandomRestricted",
	TRADING_ATTRIBUTE = "PaidTradingAllowed",
}

return table.freeze(Compliance)
