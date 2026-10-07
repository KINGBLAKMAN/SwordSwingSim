--!strict
-- Swords (GDD A8). Only the names exist for now, so drops can be stored;
-- multipliers and the weapon screen come with WeaponService in Phase 2.

export type WeaponDef = { id: string, name: string, island: string }

local list: { WeaponDef } = {
	{ id = "crowfeather_tachi", name = "Crowfeather Tachi", island = "NinjaVillage" },
}

-- Weapons by id.
local Weapons: { [string]: WeaponDef } = {}
for _, def in list do
	Weapons[def.id] = table.freeze(def)
end

return table.freeze(Weapons)
