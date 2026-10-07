--!strict
-- usePlayerAttribute: reads an attribute on the local player and
-- re-renders when the server changes it (EquipSlots, DropBoost...).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local function usePlayerAttribute(name: string): any
	local player = Players.LocalPlayer
	local value, setValue = React.useState(function()
		return player:GetAttribute(name)
	end)

	React.useEffect(function()
		local connection = player:GetAttributeChangedSignal(name):Connect(function()
			setValue(player:GetAttribute(name))
		end)
		setValue(player:GetAttribute(name))
		return function()
			connection:Disconnect()
		end
	end, { name })

	return value
end

return usePlayerAttribute
