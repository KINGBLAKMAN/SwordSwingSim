--!strict
-- Router: which full screen is open, if any (TDD B9).
--
-- One screen at a time; the HUD stays underneath. It lives outside React so
-- any controller can open a screen (an egg prompt opening its odds, say),
-- and the useRoute hook re-renders the UI when it changes. Screen names are
-- the keys in UI/Screens.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local Router = {}

local current: string? = nil
-- (screenName or nil) whenever the open screen changes.
local changed = Signal.new()

local function setCurrent(screen: string?)
	if current == screen then
		return
	end
	current = screen
	changed:Fire(screen)
end

-- Opens a screen, replacing whichever one was open.
function Router.open(screen: string)
	setCurrent(screen)
end

function Router.close()
	setCurrent(nil)
end

-- Opens the screen, or closes it if it's already open. Menu buttons use this.
function Router.toggle(screen: string)
	if current == screen then
		setCurrent(nil)
	else
		setCurrent(screen)
	end
end

-- The open screen's name, or nil when only the HUD shows.
function Router.current(): string?
	return current
end

function Router.onChanged(callback: (screen: string?) -> ())
	return changed:Connect(callback)
end

return Router
