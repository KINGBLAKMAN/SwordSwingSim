--!strict
-- useInspectedEnemy: the enemy being hovered or tapped (CombatController),
-- re-rendering when it changes. nil when there isn't one.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local CombatController = require(script.Parent.Parent.Parent.Controllers.CombatController)

local function useInspectedEnemy(): Model?
	local inspected, setInspected = React.useState(CombatController.inspected)

	React.useEffect(function()
		local connection = CombatController.onInspectedChanged(setInspected)
		setInspected(CombatController.inspected())
		return function()
			connection:Disconnect()
		end
	end, {})

	return inspected
end

return useInspectedEnemy
