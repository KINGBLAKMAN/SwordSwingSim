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

-- Color of each enemy difficulty label (GDD A9).
UI.TIER_COLORS = {
	["Very Easy"] = Color3.fromRGB(180, 184, 196),
	Easy = Color3.fromRGB(96, 214, 108),
	Medium = Color3.fromRGB(70, 150, 255),
	Hard = Color3.fromRGB(176, 92, 255),
	["Very Hard"] = Color3.fromRGB(255, 196, 40),
	Boss = Color3.fromRGB(255, 72, 120),
} :: { [string]: Color3 }

-- The name, difficulty and HP bar floating over each enemy.
UI.ENEMY_BILLBOARD = {
	SIZE = Vector2.new(170, 50),
	-- Studs above the top of the enemy.
	HEIGHT_ABOVE = 1.5,
	-- Hidden beyond this many studs from the camera.
	MAX_DISTANCE = 140,
	HP_FILL = Color3.fromRGB(232, 64, 72),
}

-- The ring under the enemy the player is attacking.
UI.TARGET_RING = {
	-- Studs wider than the enemy.
	PADDING = 2,
	THICKNESS = 0.2,
	COLOR = Color3.fromRGB(255, 220, 60),
	TRANSPARENCY = 0.35,
}

-- Floating damage numbers (TDD B8: pooled, about 40 on screen at most).
UI.DAMAGE_NUMBERS = {
	MAX_ON_SCREEN = 40,
	SECONDS = 0.8,
	-- Studs the number rises while it fades.
	RISE = 3,
	-- Random sideways spread, in studs, so stacked hits don't overlap.
	SPREAD = 1.5,
	SIZE = Vector2.new(120, 40),
	COLOR = Color3.fromRGB(255, 255, 255),
	CRIT_COLOR = Color3.fromRGB(255, 196, 40),
	TEXT_SIZE = 26,
	CRIT_TEXT_SIZE = 34,
}

-- Boss HP bar along the bottom of the screen.
UI.BOSS_BAR = {
	SIZE = Vector2.new(420, 30),
	-- Pixels up from the bottom of the safe area, clear of the thumbstick.
	BOTTOM_OFFSET = 70,
}

-- Short "+1 Scroll Token" toasts when something drops (GDD A9).
UI.DROP_TOASTS = {
	SECONDS = 2.5,
	-- Older toasts drop off once this many are showing.
	MAX_SHOWN = 5,
	SIZE = Vector2.new(240, 26),
	-- Pixels up from the bottom of the safe area, above the boss bar.
	BOTTOM_OFFSET = 110,
}

-- The big banner for a rare drop (Config/Drops.RARE_CHANCE or less).
UI.RARE_BANNER = {
	SECONDS = 4,
	SIZE = Vector2.new(460, 64),
	-- Share of the screen height from the top to the banner's middle.
	Y = 0.28,
	COLOR = Color3.fromRGB(255, 196, 40),
}

-- The panel listing an enemy's drops, shown while one is hovered or tapped.
UI.ENEMY_INFO = {
	WIDTH = 260,
	ROW_HEIGHT = 20,
	-- Pixels from the top of the safe area, under the level bar.
	TOP_OFFSET = 72,
}

-- The odds board floating over each egg (GDD A6).
UI.EGG_BILLBOARD = {
	SIZE = Vector2.new(230, 236),
	-- Studs above the egg stand's middle.
	HEIGHT_ABOVE = 7,
	MAX_DISTANCE = 70,
	ROW_HEIGHT = 18,
}

-- The hatch animation (GDD A6): the egg shakes, harder for rarer pets,
-- then cracks and shows the pet.
UI.HATCH = {
	EGG_SIZE = Vector2.new(160, 200),
	EGG_COLOR = Color3.fromRGB(245, 235, 210),
	SHAKE_SECONDS = 1.6,
	-- Seconds per side-to-side swing while shaking.
	SHAKE_SWING_SECONDS = 0.08,
	-- Degrees the egg tilts each way, by the rarest pet in the hatch.
	SHAKE_DEGREES = {
		Common = 6,
		Uncommon = 8,
		Rare = 11,
		Epic = 15,
		Legendary = 20,
		Mythical = 26,
		Secret = 32,
	} :: { [string]: number },
	CRACK_SECONDS = 0.35,
	REVEAL_SECONDS = 1.4,
	-- The results grid closes itself after this long if not tapped.
	RESULTS_SECONDS = 6,
}

-- Short server messages ("Not enough Coins.") near the top of the screen.
UI.NOTICES = {
	SECONDS = 3,
	SIZE = Vector2.new(420, 32),
	-- Share of the screen height from the top.
	Y = 0.2,
	COLOR = Color3.fromRGB(255, 120, 120),
}

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
	CURRENCY_CHIP_SIZE = Vector2.new(140, 28),
	LEVEL_BAR_SIZE = Vector2.new(260, 26),
	TIMER_CHIP_SIZE = Vector2.new(110, 30),
	-- Menu buttons sit in a grid this many columns wide, under the currencies.
	MENU_BUTTON_SIZE = 48,
	MENU_COLUMNS = 2,
	-- The Click! button sits on the right, above the mobile jump button
	-- (which Roblox puts in the bottom-right corner).
	CLICK_BUTTON_SIZE = 120,
	CLICK_BUTTON_Y = 0.45,
	-- The Auto toggle under the Click! button.
	AUTO_BUTTON_SIZE = Vector2.new(110, 44),
	-- How much the Click! button shrinks on a tap, and for how long.
	CLICK_PRESS_SCALE = 0.9,
	CLICK_PRESS_SECONDS = 0.06,
}

-- The active quest under the menu, on the left (GDD A13).
UI.QUEST_TRACKER = {
	WIDTH = 200,
	TITLE_HEIGHT = 20,
	BAR_HEIGHT = 22,
}

UI.QUESTS_SCREEN = {
	ROW_HEIGHT = 56,
}

UI.PETS_SCREEN = {
	-- Share of the panel's width the detail column on the right takes.
	DETAIL_WIDTH = 0.36,
	ROW_HEIGHT = 22,
}

UI.SCREEN_SIZE = Vector2.new(520, 320)
UI.DIALOG_SIZE = Vector2.new(340, 190)
UI.ITEM_CARD_SIZE = Vector2.new(96, 116)

-- Currencies shown on the HUD, top to bottom. `field` is the key in
-- profile.currencies; `icon` is a key in Config/Assets (text shows until
-- the icon is uploaded).
export type CurrencyKey = "energy" | "coins" | "embers" | "gems"
UI.HUD_CURRENCIES = {
	{
		field = "energy",
		label = "Energy",
		icon = "ui.icon.energy",
		color = Color3.fromRGB(110, 200, 255),
	},
	{
		field = "coins",
		label = "Coins",
		icon = "ui.icon.coins",
		color = Color3.fromRGB(255, 206, 60),
	},
	{
		field = "embers",
		label = "Embers",
		icon = "ui.icon.embers",
		color = Color3.fromRGB(255, 120, 48),
	},
	{
		field = "gems",
		label = "Gems",
		icon = "ui.icon.gems",
		color = Color3.fromRGB(120, 255, 200),
	},
} :: { { field: CurrencyKey, label: string, icon: string, color: Color3 } }

-- Buttons on the menu rail, top to bottom. `screen` is a name from
-- client/UI/Screens. `studioOnly` buttons are hidden in live games.
UI.MENU = {
	{ screen = "Pets", label = "Pets", icon = "ui.icon.pets" },
	{ screen = "Weapons", label = "Swords", icon = "ui.icon.weapons" },
	{ screen = "Quests", label = "Quests", icon = "ui.icon.quests" },
	{ screen = "Islands", label = "Islands", icon = "ui.icon.islands" },
	{ screen = "Store", label = "Store", icon = "ui.icon.store" },
	{ screen = "Settings", label = "Settings", icon = "ui.icon.settings" },
	{ screen = "Gallery", label = "Kit", icon = "ui.icon.gallery", studioOnly = true },
} :: { { screen: string, label: string, icon: string, studioOnly: boolean? } }

return table.freeze(UI)
