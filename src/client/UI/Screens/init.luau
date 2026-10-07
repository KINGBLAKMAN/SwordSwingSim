--!strict
-- Screens: every full screen the Router can open, by name. Menu buttons in
-- Config/UI.MENU use these names. Swap a placeholder for the real screen
-- when its system is built.

local GalleryScreen = require(script.GalleryScreen)
local PlaceholderScreen = require(script.PlaceholderScreen)

local Screens: { [string]: () -> any } = {
	Pets = PlaceholderScreen.make("Pets"),
	Weapons = PlaceholderScreen.make("Swords"),
	Quests = PlaceholderScreen.make("Quests"),
	Store = PlaceholderScreen.make("Store"),
	Settings = PlaceholderScreen.make("Settings"),
	Gallery = GalleryScreen,
}

return table.freeze(Screens)
