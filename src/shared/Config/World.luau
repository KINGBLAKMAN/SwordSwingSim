--!strict
-- Placeholder island layout (GDD A12): where each island sits and where its
-- enemies stand. WorldService builds a flat block-out from this when the
-- place has no real map for an island yet (Workspace.Islands.<island id>).
--
-- A real map replaces it by having the same shape: a model named after the
-- island id with a SpawnLocation named Spawn and an EnemySpawns folder of
-- parts, each with an Enemy attribute naming the enemy id that stands there,
-- and a part named EggStand with an Egg attribute naming the island's egg.

export type Zone = {
	enemy: string,
	-- Middle of the zone, relative to the island's origin.
	center: Vector3,
	-- Studs from the middle to the ring of spawn points (0 for a single point).
	radius: number,
	-- Spawn points in the ring. Usually the tier's maxAlive.
	count: number,
}

export type IslandLayout = {
	origin: Vector3,
	groundSize: Vector3,
	groundColor: Color3,
	-- Where players appear, relative to the origin.
	spawn: Vector3,
	-- Where the island's egg stands, relative to the origin.
	egg: Vector3,
	zones: { Zone },
}

local World = {
	ISLANDS = {
		-- The ground's top sits a little above y = 0 so it doesn't flicker
		-- against a default Baseplate.
		NinjaVillage = {
			origin = Vector3.new(0, 0.2, 0),
			groundSize = Vector3.new(260, 2, 260),
			groundColor = Color3.fromRGB(110, 150, 90),
			spawn = Vector3.new(0, 0, 100),
			egg = Vector3.new(30, 0, 95),
			zones = {
				{ enemy = "kohai", center = Vector3.new(0, 0, 45), radius = 22, count = 10 },
				{
					enemy = "elder_kurogane",
					center = Vector3.new(-60, 0, -30),
					radius = 18,
					count = 6,
				},
				{ enemy = "karasu_ren", center = Vector3.new(55, 0, -70), radius = 0, count = 1 },
			},
		},
	} :: { [string]: IslandLayout },
}

return table.freeze(World)
