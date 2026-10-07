--!strict
-- CurrencyBar: the currency chips in the HUD's top-left corner (GDD A5).
-- Which currencies show, and in what order, comes from Config/UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Util.Format)
local ProfileTypes = require(ReplicatedStorage.Shared.Data.ProfileTypes)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local CurrencyChip = require(script.Parent.Parent.Components.CurrencyChip)
local useProfile = require(script.Parent.Parent.Hooks.useProfile)

local e = React.createElement

type Currencies = typeof(({} :: ProfileTypes.Profile).currencies)

local function selectCurrencies(profile: ProfileTypes.Profile): Currencies
	return profile.currencies
end

-- Gems are a plain number; the other HUD currencies are BigNums.
local function formatAmount(currencies: Currencies, field: UI.CurrencyKey): string
	if field == "gems" then
		return Format.number(currencies.gems)
	end
	return Format.big(currencies[field])
end

local function CurrencyBar(props: { layoutOrder: number? })
	local currencies = useProfile(selectCurrencies)

	local children: { [string]: any } = {
		List = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, UI.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for order, currency in UI.HUD_CURRENCIES do
		children[currency.field] = e(CurrencyChip, {
			label = currency.label,
			amount = if currencies then formatAmount(currencies, currency.field) else "…",
			icon = currency.icon,
			color = currency.color,
			layoutOrder = order,
		})
	end

	return e("Frame", {
		LayoutOrder = props.layoutOrder,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
	}, children)
end

return CurrencyBar
