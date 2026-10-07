--!strict
-- Clicking (GDD A10). The server enforces the cooldown; the client uses the
-- same number so the Click! button doesn't send clicks the server will drop.

local Clicking = {
	-- Seconds between clicks that count.
	CLICK_COOLDOWN = 0.1,
}

return table.freeze(Clicking)
