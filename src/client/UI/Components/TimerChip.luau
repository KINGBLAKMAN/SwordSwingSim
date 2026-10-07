--!strict
-- TimerChip: a label and a countdown, like an active boost on the HUD
-- (GDD A14). Counts down once a second against the server's clock, because
-- `endsAt` comes from the server's os.time() and a player's own clock can
-- be wrong.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Util.Format)
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)

local e = React.createElement

export type Props = {
	label: string,
	-- Server time (os.time()) when the timer runs out.
	endsAt: number,
	color: Color3?,
	size: UDim2?,
	layoutOrder: number?,
}

local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

local function TimerChip(props: Props)
	local now, setNow = React.useState(serverNow)

	React.useEffect(function()
		local thread = task.spawn(function()
			while true do
				task.wait(1)
				setNow(serverNow())
			end
		end)
		return function()
			task.cancel(thread)
		end
	end, {})

	local chipSize = UI.HUD.TIMER_CHIP_SIZE

	return e("TextLabel", {
		Text = `{props.label} {Format.duration(props.endsAt - now)}`,
		Font = UI.FONT,
		TextSize = UI.TEXT_SIZE.small,
		TextColor3 = UI.COLORS.text,
		TextStrokeTransparency = 0,
		BackgroundColor3 = props.color or UI.COLORS.panel,
		BackgroundTransparency = 0.15,
		Size = props.size or UDim2.fromOffset(chipSize.X, chipSize.Y),
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = UI.COLORS.stroke,
			Thickness = UI.STROKE_THICKNESS,
		}),
	})
end

return TimerChip
