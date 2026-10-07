--!strict
-- Asset registry (TDD B15): maps logical names like "pet.ember_fox.model"
-- to asset IDs. Code looks assets up here and never hardcodes an
-- rbxassetid. Filled in as art is uploaded.

local Assets: { [string]: string } = {}

return table.freeze(Assets)
