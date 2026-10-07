--!strict
-- Placeholder enemy looks by tier: a colored block until the real rigs come
-- from Blender (GDD A24, E-part). Bigger tiers get bigger blocks.

local Enemies = require(script.Parent.Enemies)

export type Look = { bodySize: Vector3, bodyColor: Color3 }

local EnemyLooks: { [Enemies.Tier]: Look } = {
	["Very Easy"] = { bodySize = Vector3.new(3, 5, 2), bodyColor = Color3.fromRGB(150, 160, 175) },
	Easy = { bodySize = Vector3.new(3.5, 5.5, 2.5), bodyColor = Color3.fromRGB(90, 190, 110) },
	Medium = { bodySize = Vector3.new(4, 7, 3), bodyColor = Color3.fromRGB(70, 130, 230) },
	Hard = { bodySize = Vector3.new(5, 8, 4), bodyColor = Color3.fromRGB(160, 90, 230) },
	["Very Hard"] = { bodySize = Vector3.new(6, 9, 4), bodyColor = Color3.fromRGB(240, 180, 40) },
	Boss = { bodySize = Vector3.new(10, 14, 8), bodyColor = Color3.fromRGB(230, 60, 100) },
}

return table.freeze(EnemyLooks)
