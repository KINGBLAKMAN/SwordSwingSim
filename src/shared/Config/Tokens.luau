--!strict
-- Island tokens (GDD A5, A12a). Enemies drop them; later systems spend them
-- (trait rerolls, crafting). Counts live in profile.currencies.tokens.

export type TokenDef = { id: string, name: string, island: string }

local list: { TokenDef } = {
	{ id = "scroll_token", name = "Scroll Token", island = "NinjaVillage" },
	{ id = "mask_token", name = "Mask Token", island = "NinjaVillage" },
}

-- Tokens by id.
local Tokens: { [string]: TokenDef } = {}
for _, def in list do
	Tokens[def.id] = table.freeze(def)
end

return table.freeze(Tokens)
