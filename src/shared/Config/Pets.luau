--!strict
-- Pet definitions (TDD B3 PetDef), islands 1–2 from the GDD A12a rosters.
-- Stat fields (energyMult, coinMult) and asset names join when PetService
-- is built; eggs only need each pet's rarity.

local Rarities = require(script.Parent.Rarities)

export type PetDef = {
	id: string,
	name: string,
	rarity: Rarities.Rarity,
	island: string,
}

local list: { PetDef } = {
	-- Island 1: Ninja village
	{ id = "kohai", name = "Kōhai", rarity = "Common", island = "NinjaVillage" },
	{ id = "hana_tetsu", name = "Hana Tetsu", rarity = "Uncommon", island = "NinjaVillage" },
	{ id = "elder_kurogane", name = "Elder Kurogane", rarity = "Rare", island = "NinjaVillage" },
	{ id = "kaeru_jin", name = "Kaeru Jin", rarity = "Epic", island = "NinjaVillage" },
	{ id = "utsushi", name = "Utsushi", rarity = "Legendary", island = "NinjaVillage" },
	{ id = "karasu_ren", name = "Karasu Ren", rarity = "Mythical", island = "NinjaVillage" },
	{ id = "kurai", name = "Kurai", rarity = "Secret", island = "NinjaVillage" },

	-- Island 2: Cursed-spirit city
	{ id = "haiiro_wisp", name = "Haiiro Wisp", rarity = "Common", island = "CursedCity" },
	{ id = "mokuren", name = "Mokuren", rarity = "Uncommon", island = "CursedCity" },
	{ id = "kazan", name = "Kazan", rarity = "Rare", island = "CursedCity" },
	{ id = "nuiko", name = "Nuiko", rarity = "Epic", island = "CursedCity" },
	{ id = "kizuna", name = "Kizuna", rarity = "Legendary", island = "CursedCity" },
	{ id = "henko", name = "Henkō", rarity = "Mythical", island = "CursedCity" },
	{ id = "mumei", name = "Mumei", rarity = "Secret", island = "CursedCity" },
}

-- Pets by id.
local Pets: { [string]: PetDef } = {}
for _, pet in list do
	Pets[pet.id] = table.freeze(pet)
end

return table.freeze(Pets)
