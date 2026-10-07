--!strict
-- Click rules (GDD A10). What a click is worth lives in Config/Combat
-- (generated from the tuning sheet); this file holds how often clicks count.

local Clicking = {
	-- Most clicks credited per second of real time, however fast they come
	-- in. Anything faster is dropped, so an autoclicker gains nothing extra.
	-- The client also waits 1 / CLICK_CAP_CPS between clicks it sends.
	CLICK_CAP_CPS = 12,

	-- Clicks per second the server's auto-click credits: free, and with the
	-- Auto-Click+ pass (GDD A10).
	AUTO_CLICK_CPS = 3,
	AUTO_CLICK_PLUS_CPS = 8,

	-- Key in profile.autos for the auto-click toggle.
	AUTO_KEY = "click",
}

return table.freeze(Clicking)
