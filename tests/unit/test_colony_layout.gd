extends GutTest
## Colonies under domes (owner #77, spec §21c.2): where the colony stands on the Moon and Mars and what it is built of
## (ColonyLayout, pure). A short walk from the landing pad and seen from it, on flattened ground: the Great Dome (round
## glass, 21 across: grass, a greenhouse garden in rows under pink grow lamps, a pond, fruit trees, flowers, a warm light
## at its top), five smaller domes joined by glass tunnels (homes under a shield of printed regolith with beds and a
## table, a lab with Lab Benches, the water plant melting ice into tanks, the oxygen maker, the control room with screens
## and a big map), the airlock (two doors in a row, open), and outside the solar panel field, the big rocket on its own
## pad, the rover garage with a rover and the ice mine (Mars: toward an ice cap; the Moon: a crater). Every doorway is
## open: a child walks from the airlock into every part.

const SEEDS: Array[int] = [12345, 77, 20260930, 4242, 99, 1, 31337, 555]


func _layout(planet: StringName, seed: int = 12345) -> ColonyLayout:
	return SpaceShape.new(seed, planet).colony


func test_the_moon_and_mars_have_a_colony_the_others_none() -> void:
	for seed in SEEDS:
		assert_not_null(_layout(SpaceShape.MOON, seed), "the Moon %d" % seed)
		assert_not_null(_layout(SpaceShape.MARS, seed), "Mars %d" % seed)
	for p: StringName in [SpaceShape.BOING, SpaceShape.RAINBOW, SpaceShape.EUROPA, SpaceShape.IO, SpaceShape.TITAN,
			SpaceShape.MERCURY]:
		assert_null(SpaceShape.new(12345, p).colony, str(p))


## A short walk from the landing pad, facing it: the airlock's door looks at the pad and the path runs toward it.
func test_a_short_walk_from_the_landing_pad() -> void:
	for planet: StringName in ColonyRules.PLANETS:
		for seed in SEEDS:
			var s := SpaceShape.new(seed, planet)
			var c := s.colony
			var pad := Vector2(s.spawn_column())
			assert_almost_eq(Vector2(c.centre).distance_to(pad), float(ColonyLayout.DISTANCE), 1.0, "%s %d" % [planet, seed])
			var door := Vector2(c.entrance())
			assert_lt(door.distance_to(pad), 32.0, "the airlock's door a short walk from the pad (%s %d)" % [planet, seed])
			assert_gt(door.distance_to(pad), float(SpaceShape.BLEND_RADIUS), "clear of the pad, the lander and the portal")
			assert_lt(door.distance_to(pad), Vector2(c.centre).distance_to(pad), "the door faces the pad")


## Seen from the pad: the big rocket stands 30 blocks tall over the flat ground, the Great Dome 10.
func test_seen_from_the_pad() -> void:
	var c := _layout(SpaceShape.MARS)
	assert_eq(c.top(), c.ground + ColonyLayout.ROCKET_TOP + 1)
	var k := c.world(ColonyLayout.ROCKET.x, ColonyLayout.ROCKET.y)
	assert_eq(c.block_at(Vector3i(k.x, c.ground + 15, k.y)), BlockIds.ROCKET_HULL, "the rocket's body")
	assert_eq(c.block_at(Vector3i(k.x, c.ground + ColonyLayout.ROCKET_TOP, k.y)), BlockIds.COLONY_LIGHT, "a light on its tip")
	var g := c.world(0, 0)
	assert_eq(c.block_at(Vector3i(g.x, c.ground + ColonyLayout.GREAT_R, g.y)), BlockIds.DOME_GLASS, "the dome's top")


## The colony stands on flattened ground at the landing pad's height; the ground blends back into the planet's own.
func test_the_ground_is_flat_under_it_and_blends_back() -> void:
	for planet: StringName in ColonyRules.PLANETS:
		for seed in [12345, 77, 4242]:
			var s := SpaceShape.new(seed, planet)
			var c := s.colony
			var g := s.height_at(s.spawn_column().x, s.spawn_column().y)
			assert_eq(c.ground, g, "at the landing pad's height")
			var worst := 0
			var bumps := 0
			for dz in range(-ColonyLayout.R_FLAT - ColonyLayout.BLEND - 2, ColonyLayout.R_FLAT + ColonyLayout.BLEND + 3, 2):
				for dx in range(-ColonyLayout.R_FLAT - ColonyLayout.BLEND - 2, ColonyLayout.R_FLAT + ColonyLayout.BLEND + 3):
					var x := c.centre.x + dx
					var z := c.centre.y + dz
					var d := Vector2(dx, dz).length()
					if d <= ColonyLayout.R_FLAT:
						if s.height_at(x, z) != g:
							bumps += 1
					else:
						worst = maxi(worst, absi(s.height_at(x, z) - s.height_at(x + 1, z)))
			assert_eq(bumps, 0, "flat under the colony (%s %d)" % [planet, seed])
			assert_lte(worst, 4, "every step a jump at %s's gravity (%s %d: %d)" % [planet, planet, seed, worst])


func test_the_great_dome_is_round_glass_21_across() -> void:
	var c := _layout(SpaceShape.MOON)
	var y := c.ground
	assert_eq(ColonyLayout.GREAT_R * 2 + 1, 21)
	for side: int in [-1, 1]:
		var edge := c.world(3, 10 * side)
		var out := c.world(3, 11 * side)
		assert_eq(c.block_at(Vector3i(edge.x, y, edge.y)), BlockIds.COLONY_PANEL, "a white base ring")
		assert_eq(c.block_at(Vector3i(out.x, y, out.y)), -1, "outside the dome")
	var glass := c.world(7, 7)
	assert_eq(c.block_at(Vector3i(glass.x, y + 2, glass.y)), BlockIds.DOME_GLASS, "glass above the base")
	var inside := c.world(6, 6)
	assert_eq(c.block_at(Vector3i(inside.x, y + 2, inside.y)), BlockIds.AIR, "room inside")
	var apex := c.world(0, 0)
	assert_eq(c.block_at(Vector3i(apex.x, y + 9, apex.y)), BlockIds.COLONY_LIGHT, "a warm light under its top")
	assert_eq(c.block_at(Vector3i(apex.x, y - 1, apex.y)), BlockIds.GRASS, "green grass inside")


func test_the_great_dome_has_a_garden_a_pond_trees_and_flowers() -> void:
	var c := _layout(SpaceShape.MARS)
	var seen := _count_in(c, Vector2i(0, 0), ColonyLayout.GREAT_R, -3, ColonyLayout.GREAT_R)
	for id: int in [BlockIds.GREENHOUSE_SOIL, BlockIds.WHEAT, BlockIds.BUSH, BlockIds.PUMPKIN, BlockIds.GROW_LAMP,
			BlockIds.WATER, BlockIds.LOG, BlockIds.FRUIT_LEAVES, BlockIds.FLOWERS, BlockIds.COLONY_LIGHT]:
		assert_gt(int(seen.get(id, 0)), 0, "%s under the Great Dome" % BlockIds.display_name(id))
	assert_gte(int(seen.get(BlockIds.GREENHOUSE_SOIL, 0)), 18, "garden beds in rows")
	assert_gte(int(seen.get(BlockIds.GROW_LAMP, 0)), 12, "a grow lamp over every row")
	assert_gte(int(seen.get(BlockIds.WATER, 0)), 90, "a pond three deep: fish swim in it without bumping its walls")


func test_the_smaller_domes_and_what_is_in_them() -> void:
	for planet: StringName in ColonyRules.PLANETS:
		var c := _layout(planet)
		var homes := _count_in(c, ColonyLayout.DOMES[ColonyRules.HOMES], ColonyLayout.SMALL_R, -1, ColonyLayout.SMALL_R)
		assert_eq(int(homes.get(BlockIds.BED, 0)), 3, "beds in the homes")
		assert_gt(int(homes.get(BlockIds.COLONY_TABLE, 0)), 0, "a table")
		assert_gt(int(homes.get(BlockIds.PRINTED_REGOLITH, 0)), 30, "a shield of printed regolith")
		assert_gt(int(homes.get(BlockIds.DOME_GLASS, 0)), 2, "with windows")
		var lab := _count_in(c, ColonyLayout.DOMES[ColonyRules.LAB], ColonyLayout.SMALL_R, -1, ColonyLayout.SMALL_R)
		assert_eq(int(lab.get(BlockIds.LAB_BENCH, 0)), 2, "Lab Benches: the Science Lab works there")
		assert_gt(int(lab.get(ColonyRules.block(planet, "rock"), 0)), 0, "a rock sample")
		var water := _count_in(c, ColonyLayout.DOMES[ColonyRules.WATER], ColonyLayout.SMALL_R, -1, ColonyLayout.SMALL_R)
		assert_gt(int(water.get(BlockIds.ICE_MELTER, 0)), 0, "ice melts ...")
		assert_gt(int(water.get(ColonyRules.block(planet, "ice"), 0)), 0, "... the planet's ice ...")
		assert_gt(int(water.get(BlockIds.WATER_TANK, 0)), 0, "... into tanks")
		var oxygen := _count_in(c, ColonyLayout.DOMES[ColonyRules.OXYGEN], ColonyLayout.SMALL_R, -1, ColonyLayout.SMALL_R)
		assert_gt(int(oxygen.get(BlockIds.OXYGEN_MAKER, 0)), 0, "the oxygen maker")
		var control := _count_in(c, ColonyLayout.DOMES[ColonyRules.CONTROL], ColonyLayout.SMALL_R, -1, ColonyLayout.SMALL_R)
		assert_gt(int(control.get(BlockIds.CONTROL_SCREEN, 0)), 0, "screens")
		assert_eq(int(control.get(BlockIds.COLONY_MAP, 0)), 6, "a big map (3 x 2)")
		for part: StringName in ColonyLayout.DOMES:
			var here := _count_in(c, ColonyLayout.DOMES[part], ColonyLayout.SMALL_R, -1, ColonyLayout.SMALL_R)
			assert_gt(int(here.get(BlockIds.COLONY_LIGHT, 0)), 0, "%s is always lit" % part)


func test_the_airlock_is_two_doors_in_a_row_open() -> void:
	var c := _layout(SpaceShape.MOON)
	for a: int in ColonyLayout.DOORS:
		var wall := c.world(a, 2)
		var roof := c.world(a, 0)
		assert_eq(c.block_at(Vector3i(wall.x, c.ground + 1, wall.y)), BlockIds.AIRLOCK_FRAME, "a door's frame at %d" % a)
		assert_eq(c.block_at(Vector3i(roof.x, c.ground + 3, roof.y)), BlockIds.AIRLOCK_FRAME)
		assert_eq(c.block_at(Vector3i(roof.x, c.ground, roof.y)), BlockIds.AIR, "open (pretend)")
		assert_eq(c.block_at(Vector3i(roof.x, c.ground + 1, roof.y)), BlockIds.AIR)


## Friendly (spec §21c.2): every doorway is open. A child walks (one-block steps, two blocks of room) from the airlock's
## door into the Great Dome and through the glass tunnels into every smaller dome, and around to the outside parts.
func test_a_child_walks_into_every_part() -> void:
	for planet: StringName in ColonyRules.PLANETS:
		for seed in [12345, 77]:
			var s := SpaceShape.new(seed, planet)
			var c := s.colony
			var reach := _walk(s, c, c.entrance())
			for part: StringName in ColonyRules.PARTS:
				var at: Vector2i = c.part_centre(part)
				assert_true(reach.has(at), "%s: a child walks to %s (%s)" % [planet, part, at])


func test_outside_the_solar_field_the_rocket_the_garage_and_the_mine() -> void:
	for planet: StringName in ColonyRules.PLANETS:
		var c := _layout(planet)
		var solar := _count_rect(c, Vector2i(-11, 26), Vector2i(11, 38), 0, 2)
		assert_gte(int(solar.get(BlockIds.SOLAR_PANEL, 0)), 60, "fields of solar panels")
		var rocket := _count_in(c, ColonyLayout.ROCKET, 5, -1, ColonyLayout.ROCKET_TOP)
		assert_gt(int(rocket.get(BlockIds.ROCKET_HULL, 0)), 300, "a tall silver rocket")
		assert_gt(int(rocket.get(BlockIds.ROCKET_ENGINE, 0)), 0, "with engines")
		assert_gt(int(rocket.get(BlockIds.PAD_CONCRETE, 0)), 60, "on its own pad")
		var garage := _count_rect(c, ColonyLayout.GARAGE_LO, ColonyLayout.GARAGE_HI, -1, 4)
		assert_eq(int(garage.get(BlockIds.ROVER_WHEEL, 0)), 4, "a rover in the garage")
		assert_gt(int(garage.get(BlockIds.COLONY_PANEL, 0)), 60)
		var mine := _count_in(c, ColonyLayout.MINE, ColonyLayout.MINE_R + 1, -8, 6)
		assert_gt(int(mine.get(ColonyRules.block(planet, "ice"), 0)), 60, "ice in the mine")
		var m := c.world(ColonyLayout.MINE.x, ColonyLayout.MINE.y)
		assert_eq(c.block_at(Vector3i(m.x, c.ground - 1, m.y)), BlockIds.AIR, "a pit dug into the ground")
		assert_eq(c.block_at(Vector3i(m.x, c.ground - 5, m.y)), ColonyRules.block(planet, "ice"), "ice on its floor")


## Mars: the ice mine faces an ice cap (the colony stands north or south of the pad, the mine on its far side).
func test_mars_digs_toward_an_ice_cap() -> void:
	for seed in SEEDS:
		var s := SpaceShape.new(seed, SpaceShape.MARS)
		var c := s.colony
		var m := c.world(ColonyLayout.MINE.x, ColonyLayout.MINE.y)
		assert_eq(c.dir.x, 0, "north or south of the pad (seed %d)" % seed)
		var toward_cap := signi(m.y - c.centre.y)
		assert_eq(toward_cap, signi(c.centre.y - s.spawn_column().y), "the mine on the far side, toward a cap (%d)" % seed)


func test_the_parts_where_a_child_stands() -> void:
	var c := _layout(SpaceShape.MARS)
	for part: StringName in ColonyRules.PARTS:
		var at: Vector2i = c.part_centre(part)
		assert_eq(c.part_at(at.x, at.y), part, str(part))
	var tunnel := c.world(0, -11)
	assert_eq(c.part_at(tunnel.x, tunnel.y), &"", "a tunnel is no part")
	var far := c.world(60, 60)
	assert_eq(c.part_at(far.x, far.y), &"")
	assert_true(c.in_great_dome(c.centre.x, c.centre.y))
	var lab := c.part_centre(ColonyRules.LAB)
	assert_false(c.in_great_dome(lab.x, lab.y))


## The Great Dome's animals: land animals on its grass, fish in its pond, all inside.
func test_the_animals_spots_are_inside_the_great_dome() -> void:
	var c := _layout(SpaceShape.MARS)
	var spots := c.animal_spots()
	var n := 0
	for e: Dictionary in ColonyRules.HERD:
		n += int(e.count)
	assert_eq(spots.size(), n)
	for s: Dictionary in spots:
		var p: Vector3 = s.pos
		assert_true(c.in_great_dome(floori(p.x), floori(p.z)), "%s at %s" % [s.species, p])
		var cell := Vector3i(p.floor())
		if s.species == &"fish":
			assert_eq(c.block_at(cell), BlockIds.WATER, "fish in the pond")
		else:
			assert_eq(c.block_at(cell + Vector3i.DOWN), BlockIds.GRASS, "%s on the grass" % s.species)
			assert_eq(c.block_at(cell), BlockIds.AIR)
			assert_eq(c.block_at(cell + Vector3i.UP), BlockIds.AIR)


## The generator's fast writer and the reference agree box by box (later boxes win).
func test_the_writer_equals_the_reference() -> void:
	var c := _layout(SpaceShape.MOON)
	for part: StringName in [ColonyRules.DOME, ColonyRules.HOMES, ColonyRules.ROCKET, ColonyRules.MINE]:
		var at: Vector2i = c.part_centre(part)
		for dy: int in [-16, 0, 16]:
			var origin := Vector3i(floori(at.x / 16.0), floori((c.ground + dy) / 16.0), floori(at.y / 16.0)) * 16
			var buf := VoxelBuffer.new()
			buf.create(16, 16, 16)
			buf.fill(250, VoxelBuffer.CHANNEL_TYPE)
			c.write(buf, origin)
			var bad := 0
			for z in 16:
				for x in 16:
					for y in 16:
						var want := c.block_at(origin + Vector3i(x, y, z))
						var got := buf.get_voxel(x, y, z, VoxelBuffer.CHANNEL_TYPE)
						if got != (250 if want < 0 else want):
							bad += 1
			assert_eq(bad, 0, "%s chunk %s" % [part, origin])


# --- helpers ---

## {block id: count} of the colony's own blocks in a disc round local centre `at` of radius r, dy0..dy1.
func _count_in(c: ColonyLayout, at: Vector2i, r: int, dy0: int, dy1: int) -> Dictionary:
	var out := {}
	for db in range(-r, r + 1):
		for da in range(-r, r + 1):
			if da * da + db * db > (r + 0.5) * (r + 0.5):
				continue
			var w := c.world(at.x + da, at.y + db)
			for dy in range(dy0, dy1 + 1):
				var id := c.block_at(Vector3i(w.x, c.ground + dy, w.y))
				if id > 0:
					out[id] = int(out.get(id, 0)) + 1
	return out


func _count_rect(c: ColonyLayout, lo: Vector2i, hi: Vector2i, dy0: int, dy1: int) -> Dictionary:
	var out := {}
	for b in range(lo.y, hi.y + 1):
		for a in range(lo.x, hi.x + 1):
			var w := c.world(a, b)
			for dy in range(dy0, dy1 + 1):
				var id := c.block_at(Vector3i(w.x, c.ground + dy, w.y))
				if id > 0:
					out[id] = int(out.get(id, 0)) + 1
	return out


## The columns a child reaches walking from `start` (world): feet on a solid block, two blocks of room, steps of one.
func _walk(s: SpaceShape, c: ColonyLayout, start: Vector2i) -> Dictionary:
	var feet := func(x: int, z: int) -> int:   # the lowest standing y in the column round the ground (-999: none)
		for y in range(c.ground - 6, c.ground + 3):
			if _solid(s, c, x, y - 1, z) and not _solid(s, c, x, y, z) and not _solid(s, c, x, y + 1, z):
				return y
		return -999
	var seen := {start: int(feet.call(start.x, start.y))}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		var y: int = seen[p]
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := p + d
			if seen.has(n) or Vector2(n - c.centre).length() > ColonyLayout.R_FLAT:
				continue
			var ny: int = feet.call(n.x, n.y)
			if ny == -999 or absi(ny - y) > 1:
				continue
			if ny > y and _solid(s, c, p.x, y + 2, p.y):
				continue   # no head room to step up
			seen[n] = ny
			queue.append(n)
	return seen


func _solid(s: SpaceShape, c: ColonyLayout, x: int, y: int, z: int) -> bool:
	var id := c.block_at(Vector3i(x, y, z))
	if id < 0:
		id = s.block_at(x, y, z)
	return BlockIds.is_solid(id)
