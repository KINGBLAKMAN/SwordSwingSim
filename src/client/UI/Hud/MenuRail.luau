--!strict
-- MenuRail: the grid of menu buttons on the left edge. Each one opens or
-- closes a screen through the Router. Buttons come from Config/UI.MENU.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local Button = require(script.Parent.Parent.Components.Button)
local Router = require(script.Parent.Parent.Router)
local useRoute = require(script.Parent.Parent.Hooks.useRoute)

local e = React.createElement

local function MenuRail(props: { layoutOrder: number? })
	local openScreen = useRoute()
	local isStudio = RunService:IsStudio()
	local buttonSize = UI.HUD.MENU_BUTTON_SIZE

	local children: { [string]: any } = {
		Grid = e("UIGridLayout", {
			CellSize = UDim2.fromOffset(buttonSize, buttonSize),
			CellPadding = UDim2.fromOffset(UI.GAP, UI.GAP),
			FillDirection = Enum.FillDirection.Horizontal,
			FillDirectionMaxCells = UI.HUD.MENU_COLUMNS,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for order, entry in UI.MENU do
		if entry.studioOnly and not isStudio then
			continue
		end
		children[entry.screen] = e(Button, {
			text = entry.label,
			icon = entry.icon,
			textSize = UI.TEXT_SIZE.small,
			-- The open screen's button is highlighted.
			color = if openScreen == entry.screen
				then UI.COLORS.secondary
				else UI.COLORS.panelLight,
			layoutOrder = order,
			onActivated = function()
				Router.toggle(entry.screen)
			end,
		})
	end

	return e("Frame", {
		LayoutOrder = props.layoutOrder,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		-- A gamepad's selection moves between these buttons as one group.
		SelectionGroup = true,
	}, children)
end

return MenuRail
