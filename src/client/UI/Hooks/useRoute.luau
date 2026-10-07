--!strict
-- useRoute: the open screen's name (or nil), re-rendering when it changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Router = require(script.Parent.Parent.Router)

local function useRoute(): string?
	local screen, setScreen = React.useState(Router.current())

	React.useEffect(function()
		local connection = Router.onChanged(setScreen)
		return function()
			connection:Disconnect()
		end
	end, {})

	return screen
end

return useRoute
