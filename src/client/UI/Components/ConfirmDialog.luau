--!strict
-- ConfirmDialog: "Are you sure?" before anything that can't be undone,
-- like deleting pets (TDD B9). Dims everything behind it and blocks taps
-- there; tapping the dimmed area counts as Cancel.
--
-- Render it as the last child of a full-screen frame so it covers the rest.
-- It only asks; the caller sends the intent to the server in onConfirm.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Shared.Config.UI)
local Button = require(script.Parent.Button)

local e = React.createElement

export type Props = {
	title: string,
	message: string,
	confirmText: string?,
	cancelText: string?,
	-- Colors the confirm button red, for things like deleting.
	danger: boolean?,
	onConfirm: () -> (),
	onCancel: () -> (),
}

-- Draws above anything else in the same parent.
local DIALOG_Z_INDEX = 100

local function ConfirmDialog(props: Props)
	local dialogSize = UI.DIALOG_SIZE
	local buttonWidth = (dialogSize.X - UI.GAP * 6) / 2

	return e("TextButton", {
		-- The backdrop is a button so taps can't fall through to the HUD.
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		-- Frees the mouse on PC while the dialog is up.
		Modal = true,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UI.COLORS.backdrop,
		BackgroundTransparency = UI.BACKDROP_TRANSPARENCY,
		ZIndex = DIALOG_Z_INDEX,
		[React.Event.Activated] = props.onCancel,
	}, {
		Panel = e("Frame", {
			Size = UDim2.fromOffset(dialogSize.X, dialogSize.Y),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = UI.COLORS.panel,
			-- Gamepad selection stays inside the dialog.
			SelectionGroup = true,
			-- Taps on the panel itself shouldn't cancel.
			Active = true,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, UI.CORNER_RADIUS) }),
			Stroke = e("UIStroke", { Color = UI.COLORS.stroke, Thickness = UI.STROKE_THICKNESS }),
			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, UI.GAP * 2),
				PaddingBottom = UDim.new(0, UI.GAP * 2),
				PaddingLeft = UDim.new(0, UI.GAP * 2),
				PaddingRight = UDim.new(0, UI.GAP * 2),
			}),
			Title = e("TextLabel", {
				Text = props.title,
				Font = UI.FONT,
				TextSize = UI.TEXT_SIZE.title,
				TextColor3 = UI.COLORS.text,
				TextStrokeTransparency = 0,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, UI.TEXT_SIZE.title),
			}),
			Message = e("TextLabel", {
				Text = props.message,
				Font = UI.FONT,
				TextSize = UI.TEXT_SIZE.body,
				TextColor3 = UI.COLORS.textMuted,
				TextWrapped = true,
				BackgroundTransparency = 1,
				-- Between the title and the buttons.
				Size = UDim2.new(1, 0, 1, -(UI.TEXT_SIZE.title + UI.MIN_TOUCH_TARGET + UI.GAP * 2)),
				Position = UDim2.fromOffset(0, UI.TEXT_SIZE.title + UI.GAP),
			}),
			Cancel = e(Button, {
				text = props.cancelText or "Cancel",
				color = UI.COLORS.panelLight,
				size = UDim2.fromOffset(buttonWidth, UI.MIN_TOUCH_TARGET),
				position = UDim2.fromScale(0, 1),
				anchorPoint = Vector2.new(0, 1),
				onActivated = props.onCancel,
			}),
			Confirm = e(Button, {
				text = props.confirmText or "Confirm",
				color = if props.danger then UI.COLORS.danger else UI.COLORS.primary,
				size = UDim2.fromOffset(buttonWidth, UI.MIN_TOUCH_TARGET),
				position = UDim2.fromScale(1, 1),
				anchorPoint = Vector2.new(1, 1),
				onActivated = props.onConfirm,
			}),
		}),
	})
end

return ConfirmDialog
