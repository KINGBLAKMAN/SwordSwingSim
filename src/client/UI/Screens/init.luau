--!strict
-- Screens: every full screen the Router can open, by name. Menu buttons in
-- Config/UI.MENU use these names. Swap a placeholder for the real screen
-- when its system is built.

local EggOddsScreen = require(script.EggOddsScreen)
local GalleryScreen = require(script.GalleryScreen)
local PetsScreen = require(script.PetsScreen)
local PlaceholderScreen = require(script.PlaceholderScreen)
local SettingsScreen = require(script.SettingsScreen)

local Screens: { [string]: () -> any } = {
	Pets = PetsScreen,
	Weapons = PlaceholderScreen.make("Swords"),
	Quests = PlaceholderScreen.make("Quests"),
	Store = PlaceholderScreen.make("Store"),
	Settings = SettingsScreen,
	-- Opened by an egg's Details button, not from the menu.
	EggOdds = EggOddsScreen,
	Gallery = GalleryScreen,
}

return table.freeze(Screens)
