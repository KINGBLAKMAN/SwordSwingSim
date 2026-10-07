--!strict
-- UIController: mounts the React UI (TDD B9) into the player's PlayerGui.
-- The UI only shows data and sends intent; it never changes the profile
-- itself (see DataController).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local App = require(script.Parent.Parent.UI.App)
local EggBillboards = require(script.Parent.Parent.UI.EggBillboards)

local UIController = {}

function UIController.start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- React needs a container to own; the portal puts the ScreenGui it
	-- renders into PlayerGui, where Roblox draws it. The key names it.
	-- Egg boards are BillboardGuis, which only take taps from PlayerGui.
	local root = ReactRoblox.createRoot(Instance.new("Folder"))
	root:render(ReactRoblox.createPortal({
		App = React.createElement(App),
		EggBoards = React.createElement(EggBillboards),
	}, playerGui))
end

return UIController
