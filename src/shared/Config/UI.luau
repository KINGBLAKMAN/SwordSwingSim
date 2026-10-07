--!strict
-- UI look and layout (TDD B9). Every size here is in pixels at a UIScale of
-- 1; the UI scales up on bigger screens but never below 1 (see SCALE).

local Rarities = require(script.Parent.Rarities)

local UI = {}

-- Smallest size any tappable thing may have on screen. Apple and Google
-- both recommend about 44 points; Roblox's mobile viewport is in points.
UI.MIN_TOUCH_TARGET = 44

-- UIScale picks itself from the screen. REFERENCE_* is the smallest phone
-- we design for (iPhone SE, landscape): there the scale is exactly 1, so a
-- 44px button really is 44 points. Bigger screens scale up to MAX.
UI.SCALE = {
	REFERENCE_LONG_SIDE = 667,
	REFERENCE_SHORT_SIDE = 375,
	MIN = 1,
	MAX = 1.6,
}

UI.COLORS = {
	panel = Color3.fromRGB(28, 30, 48),
	panelLight = Color3.fromRGB(44, 47, 72),
	backdrop = Color3.fromRGB(0, 0, 0),
	text = Color3.fromRGB(255, 255, 255),
	textMuted = Color3.fromRGB(176, 182, 210),
	stroke = Color3.fromRGB(12, 12, 20),
	primary = Color3.fromRGB(255, 176, 32),
	secondary = Color3.fromRGB(70, 140, 255),
	danger = Color3.fromRGB(232, 64, 72),
	disabled = Color3.fromRGB(96, 98, 112),
	barFill = Color3.fromRGB(110, 220, 120),
	barBack = Color3.fromRGB(18, 20, 32),
}

-- Border and glow color for each rarity tier (GDD A6).
UI.RARITY_COLORS = {
	Common = Color3.fromRGB(180, 184, 196),
	Uncommon = Color3.fromRGB(96, 214, 108),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(176, 92, 255),
	Legendary = Color3.fromRGB(255, 196, 40),
	Mythical = Color3.fromRGB(255, 72, 120),
	Secret = Color3.fromRGB(40, 255, 230),
} :: { [Rarities.Rarity]: Color3 }

UI.FONT = Enum.Font.FredokaOne
UI.TEXT_SIZE = {
	small = 14,
	body = 18,
	title = 26,
	button = 20,
	click = 34,
}

UI.CORNER_RADIUS = 10
UI.STROKE_THICKNESS = 2
-- Gap between the HUD and the edges of the safe area.
UI.EDGE_PADDING = 8
-- Gap between items in a list or row.
UI.GAP = 6
-- How dark the backdrop behind dialogs and screens is (0 clear, 1 black).
UI.BACKDROP_TRANSPARENCY = 0.45

UI.HUD = {
	CURRENCY_CHIP_SIZE = Vector2.new(150, 34),
	LEVEL_BAR_SIZE = Vector2.new(260, 26),
	TIMER_CHIP_SIZE = Vector2.new(110, 30),
	MENU_BUTTON_SIZE = 56,
	-- The Click! button sits on the right, above the mobile jump button
	-- (which Roblox puts in the bottom-right corner).
	CLICK_BUTTON_SIZE = 120,
	CLICK_BUTTON_Y = 0.45,
	-- How much the Click! button shrinks on a tap, and for how long.
	CLICK_PRESS_SCALE = 0.9,
	CLICK_PRESS_SECONDS = 0.06,
}

UI.SCREEN_SIZE = Vector2.new(520, 320)
UI.DIALOG_SIZE = Vector2.new(340, 190)
UI.ITEM_CARD_SIZE = Vector2.new(96, 116)

-- Currencies shown on the HUD, top to bottom. `field` is the key in
-- profile.currencies; `icon` is a key in Config/Assets (text shows until
-- the icon is uploaded).
export type CurrencyKey = "energy" | "coins" | "embers" | "gems"
UI.HUD_CURRENCIES = {
	{ field = "energy", label = "Energy", icon = "ui.icon.energy", color = Color3.fromRGB(110, 200, 255) },
	{ field = "coins", label = "Coins", icon = "ui.icon.coins", color = Color3.fromRGB(255, 206, 60) },
	{ field = "embers", label = "Embers", icon = "ui.icon.embers", color = Color3.fromRGB(255, 120, 48) },
	{ field = "gems", label = "Gems", icon = "ui.icon.gems", color = Color3.fromRGB(120, 255, 200) },
} :: { { field: CurrencyKey, label: string, icon: string, color: Color3 } }

-- Buttons on the menu rail, top to bottom. `screen` is a name from
-- client/UI/Screens. `studioOnly` buttons are hidden in live games.
UI.MENU = {
	{ screen = "Pets", label = "Pets", icon = "ui.icon.pets" },
	{ screen = "Weapons", label = "Swords", icon = "ui.icon.weapons" },
	{ screen = "Quests", label = "Quests", icon = "ui.icon.quests" },
	{ screen = "Store", label = "Store", icon = "ui.icon.store" },
	{ screen = "Settings", label = "Settings", icon = "ui.icon.settings" },
	{ screen = "Gallery", label = "Kit", icon = "ui.icon.gallery", studioOnly = true },
} :: { { screen: string, label: string, icon: string, studioOnly: boolean? } }

return table.freeze(UI)
