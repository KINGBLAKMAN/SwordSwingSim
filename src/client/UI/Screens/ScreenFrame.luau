--!strict
-- ScreenFrame: the shared look of a full screen (Pets, Store...): a dimmed
-- backdrop, a panel with a title and a close button, and the screen's own
-- content below the title. Tapping the backdrop closes the screen too.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local Button = require(script.Parent.Parent.Components.Button)
local Router = require(script.Parent.Parent.Router)

local e = React.createElement

export type Props = {
	title: string,
	children: any?,
}

-- The panel fills this share of a small screen and stops at
-- Config/UI.SCREEN_SIZE on bigger ones.
local SMALL_SCREEN_FILL = 0.92

local function ScreenFrame(props: Props)
	local titleHeight = UI.MIN_TOUCH_TARGET
	local padding = UDim.new(0, UI.GAP * 2)

	return e("TextButton", {
		-- The backdrop is a button so taps can't fall through to the HUD.
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UI.COLORS.backdrop,
		BackgroundTransparency = UI.BACKDROP_TRANSPARENCY,
		[React.Event.Activated] = function()
			Router.close()
		end,
	}, {
		Panel = e("Frame", {
			Size = UDim2.fromScale(SMALL_SCREEN_FILL, SMALL_SCREEN_FILL),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = UI.COLORS.panel,
			-- Taps on the panel itself shouldn't close the screen.
			Active = true,
			SelectionGroup = true,
		}, {
			MaxSize = e("UISizeConstraint", { MaxSize = UI.SCREEN_SIZE }),
			Corner = e("UICorner", { CornerRadius = UDim.new(0, UI.CORNER_RADIUS) }),
			Stroke = e("UIStroke", { Color = UI.COLORS.stroke, Thickness = UI.STROKE_THICKNESS }),
			Padding = e("UIPadding", {
				PaddingTop = padding,
				PaddingBottom = padding,
				PaddingLeft = padding,
				PaddingRight = padding,
			}),
			Title = e("TextLabel", {
				Text = props.title,
				Font = UI.FONT,
				TextSize = UI.TEXT_SIZE.title,
				TextColor3 = UI.COLORS.text,
				TextStrokeTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -titleHeight, 0, titleHeight),
			}),
			Close = e(Button, {
				text = "X",
				color = UI.COLORS.danger,
				size = UDim2.fromOffset(titleHeight, titleHeight),
				position = UDim2.fromScale(1, 0),
				anchorPoint = Vector2.new(1, 0),
				onActivated = function()
					Router.close()
				end,
			}),
			Content = e("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, -(titleHeight + UI.GAP)),
				Position = UDim2.fromOffset(0, titleHeight + UI.GAP),
			}, props.children),
		}),
	})
end

return ScreenFrame
