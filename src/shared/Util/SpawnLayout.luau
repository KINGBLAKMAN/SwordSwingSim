--!strict
-- SpawnLayout: spreads a zone's spawn points evenly round a circle. Pure,
-- so Lune tests can check it; WorldService turns the offsets into parts.

export type Offset = { x: number, z: number }

local SpawnLayout = {}

-- `count` offsets from the zone's center, `radius` studs out, evenly
-- spaced. One point (or radius 0) sits on the center.
function SpawnLayout.ring(count: number, radius: number): { Offset }
	local offsets: { Offset } = {}
	if count == 1 or radius == 0 then
		for _ = 1, count do
			table.insert(offsets, { x = 0, z = 0 })
		end
		return offsets
	end
	for index = 1, count do
		local angle = (index - 1) / count * 2 * math.pi
		table.insert(offsets, { x = math.cos(angle) * radius, z = math.sin(angle) * radius })
	end
	return offsets
end

return SpawnLayout
