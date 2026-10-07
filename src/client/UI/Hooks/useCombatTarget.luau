--!strict
-- useCombatTarget: the enemy the player is attacking (CombatController),
-- re-rendering when it changes. nil when there's no target.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local CombatController = require(script.Parent.Parent.Parent.Controllers.CombatController)

local function useCombatTarget(): Model?
	local target, setTarget = React.useState(CombatController.target)

	React.useEffect(function()
		local connection = CombatController.onTargetChanged(setTarget)
		-- The target may have changed between the first render and now.
		setTarget(CombatController.target())
		return function()
			connection:Disconnect()
		end
	end, {})

	return target
end

return useCombatTarget
