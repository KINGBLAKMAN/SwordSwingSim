--!strict
-- DropToasts: a short "+1 Scroll Token" line for each thing that drops,
-- and a big banner for rare drops (GDD A9).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DropTables = require(ReplicatedStorage.Shared.Util.DropTables)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local OddsCalculator = require(ReplicatedStorage.Shared.Util.OddsCalculator)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local DropController = require(script.Parent.Parent.Parent.Controllers.DropController)

local e = React.createElement

type Toast = { key: number, text: string }

local TOASTS = UI.DROP_TOASTS
local BANNER = UI.RARE_BANNER

local function toastText(drop: DropTables.Drop): string
	return `+{Format.number(drop.amount)} {DropTables.itemName(drop.kind, drop.item)}`
end

type LabelProps = {
	text: string,
	color: Color3,
	size: UDim2,
	textSize: number,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
}

local function textLabel(props: LabelProps)
	return e("TextLabel", {
		Text = props.text,
		Font = UI.FONT,
		TextSize = props.textSize,
		TextColor3 = props.color,
		TextStrokeTransparency = 0,
		BackgroundTransparency = 1,
		Size = props.size,
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
	})
end

local function DropToasts()
	local toasts: { Toast }, setToasts = React.useState({} :: { Toast })
	local banner: string?, setBanner = React.useState(nil :: string?)
	local nextKey = React.useRef(0)

	React.useEffect(function()
		local connection = DropController.onDropped(function(_enemyId, drops)
			for _, drop in drops do
				nextKey.current += 1
				local key = nextKey.current
				setToasts(function(current: { Toast })
					local updated = table.clone(current)
					table.insert(updated, { key = key, text = toastText(drop) })
					while #updated > TOASTS.MAX_SHOWN do
						table.remove(updated, 1)
					end
					return updated
				end)
				task.delay(TOASTS.SECONDS, function()
					setToasts(function(current: { Toast })
						local kept = {}
						for _, toast in current do
							if toast.key ~= key then
								table.insert(kept, toast)
							end
						end
						return kept
					end)
				end)

				if DropTables.isRare(drop.chance) then
					local name = DropTables.itemName(drop.kind, drop.item)
					local text = `RARE DROP! {name} ({OddsCalculator.formatPercent(drop.chance)})`
					setBanner(text)
					task.delay(BANNER.SECONDS, function()
						setBanner(function(current: string?)
							return if current == text then nil else current
						end)
					end)
				end
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	local toastChildren: { [string]: any } = {
		List = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for index, toast in toasts do
		toastChildren[`Toast{toast.key}`] = textLabel({
			text = toast.text,
			color = UI.COLORS.text,
			size = UDim2.fromOffset(TOASTS.SIZE.X, TOASTS.SIZE.Y),
			textSize = UI.TEXT_SIZE.body,
			layoutOrder = index,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Toasts = e("Frame", {
			Size = UDim2.fromOffset(TOASTS.SIZE.X, TOASTS.SIZE.Y * TOASTS.MAX_SHOWN),
			Position = UDim2.new(0.5, 0, 1, -TOASTS.BOTTOM_OFFSET),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
		}, toastChildren),
		Banner = banner and textLabel({
			text = banner,
			color = BANNER.COLOR,
			size = UDim2.fromOffset(BANNER.SIZE.X, BANNER.SIZE.Y),
			textSize = UI.TEXT_SIZE.title,
			position = UDim2.fromScale(0.5, BANNER.Y),
			anchorPoint = Vector2.new(0.5, 0.5),
		}),
	})
end

return DropToasts
