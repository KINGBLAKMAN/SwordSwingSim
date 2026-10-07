--!strict
-- Hud: everything on screen during play (TDD B9, GDD C2). Layout, for a
-- phone held sideways:
--
--   currencies (top-left)   level bar + boosts (top-center)
--   menu grid under them                     Click! + Auto toggle (right)
--                  boss HP bar (bottom-center, only vs a boss)
--
-- The bottom corners stay clear for Roblox's thumbstick and jump button.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local AutoClickToggle = require(script.AutoClickToggle)
local BoostChips = require(script.BoostChips)
local BossBar = require(script.BossBar)
local ClickButton = require(script.ClickButton)
local CurrencyBar = require(script.CurrencyBar)
local LevelBar = require(script.LevelBar)
local MenuRail = require(script.MenuRail)

local e = React.createElement

local function Hud()
	local padding = UDim.new(0, UI.EDGE_PADDING)

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Padding = e("UIPadding", {
			PaddingTop = padding,
			PaddingBottom = padding,
			PaddingLeft = padding,
			PaddingRight = padding,
		}),
		-- One column, so the menu can never overlap the currencies.
		Left = e("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
		}, {
			List = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, UI.GAP * 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Currencies = e(CurrencyBar, { layoutOrder = 1 }),
			Menu = e(MenuRail, { layoutOrder = 2 }),
		}),
		Top = e("Frame", {
			Position = UDim2.fromScale(0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
		}, {
			List = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, UI.GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Level = e(LevelBar, { layoutOrder = 1 }),
			Boosts = e(BoostChips, { layoutOrder = 2 }),
		}),
		Boss = e(BossBar),
		Right = e("Frame", {
			Position = UDim2.fromScale(1, UI.HUD.CLICK_BUTTON_Y),
			AnchorPoint = Vector2.new(1, 0.5),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
		}, {
			List = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, UI.GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Click = e(ClickButton, { layoutOrder = 1 }),
			Auto = e(AutoClickToggle, { layoutOrder = 2 }),
		}),
	})
end

return Hud
