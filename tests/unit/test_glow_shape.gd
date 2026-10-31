extends GutTest
## Universe 6, the Glow Caves (spec §5.1): GlowShape, the caves' pure terrain rules. A 2.5-D layered cave: every column
## has a cavern floor (height_at: where every spawner finds its ground), a domed ceiling over it and a meadow roof on
## top (the way in and out). Big halls with high ceilings, wide passages through the rock walls between them, lakes
## where the floor dips under the water line, daylight shafts with a spiral ramp up to the roof, the home hall round
## the spawn, and the glow that always shows the way.

const SEED := 20261017

var s: GlowShape


func before_all() -> void:
	s = GlowShape.new(SEED)


func test_it_is_a_meadows_shape_and_the_same_for_a_seed() -> void:
	assert_true(s is MeadowsShape, "every system types it MeadowsShape")
	var again := GlowShape.new(SEED)
	var other := GlowShape.new(SEED + 1)
	var differs := 0
	for i in 40:
		var x := i * 37 - 700
		var z := i * 53 - 900
		assert_eq(again.column(x, z), s.column(x, z), "the same seed, the same caves")
		if other.column(x, z) != s.column(x, z):
			differs += 1
	assert_gt(differs, 20, "another seed, other caves")


## (floor, ceiling, roof): floor <= ceiling <= roof; a wall is solid rock (floor == ceiling); a shaft is open to the sky.
func test_every_column_is_floor_ceiling_and_roof() -> void:
	var walls := 0
	var open := 0
	for z in range(-400, 400, 7):
		for x in range(-400, 400, 7):
			var c := s.column(x, z)
			assert_true(c.x <= c.y and c.y <= c.z, "%d,%d: %s" % [x, z, c])
			assert_between(c.z, GlowShape.ROOF_MID - 6, GlowShape.ROOF_MID + 6, "the roof's meadow")
			if c.x == c.y:
				walls += 1
				assert_eq(s.height_at(x, z), GlowShape.NO_GROUND, "a wall has no ground: no spawner stands in rock")
			else:
				open += 1
				assert_true(c.y == c.z or c.z - c.y >= GlowShape.ROOF_ROCK, "rock over a hall's ceiling, or a shaft")
	var share := float(walls) / (walls + open)
	assert_between(share, 0.04, 0.3, "walls between the halls, not a maze: %.2f" % share)


## The home hall round the spawn: open, high, dry, never a lake or a wall.
func test_the_home_hall_is_big_open_high_and_dry() -> void:
	var home := s.home
	assert_lte(Vector2(home).length(), GlowShape.HOME_OFFSET * 1.5, "near the origin")
	for z in range(-GlowShape.HOME_OPEN, GlowShape.HOME_OPEN + 1, 3):
		for x in range(-GlowShape.HOME_OPEN, GlowShape.HOME_OPEN + 1, 3):
			if Vector2(x, z).length() > GlowShape.HOME_OPEN:
				continue
			var c := s.column(home.x + x, home.y + z)
			if s.in_shaft(home.x + x, home.y + z):
				continue
			assert_gt(c.y, c.x, "open at %d,%d" % [x, z])
			assert_gt(c.x, MeadowsShape.SEA_LEVEL + 1, "dry land at %d,%d" % [x, z])
	var mid := s.column(home.x, home.y)
	assert_gte(mid.y - mid.x, 16, "a high domed roof over the middle")


func test_the_spawn_is_flat_open_and_clear() -> void:
	var sp := s.spawn_column()
	var h := s.height_at(sp.x, sp.y)
	assert_gt(h, MeadowsShape.SEA_LEVEL + 1)
	for dz in range(-6, 7, 3):
		for dx in range(-6, 7, 3):
			assert_lte(absi(s.height_at(sp.x + dx, sp.y + dz) - h), 2, "flat round the spawn")
	for dz in range(-3, 4):
		for dx in range(-3, 4):
			assert_eq(s.plant_at(sp.x + dx, sp.y + dz), GlowShape.NO_PLANT, "nothing grows on the spawn")
			assert_false(s.in_shaft(sp.x + dx, sp.y + dz))
	var c := s.column(sp.x, sp.y)
	assert_gte(c.y - c.x, 10, "room over the spawn")


## Every step on the dry cave floor is one block at most: a child walks it all without a jump.
func test_every_dry_step_is_one_block() -> void:
	var worst := 0
	for z in range(-300, 300):
		for x in range(-300, 300, 2):
			var a := s.column(x, z)
			var b := s.column(x + 1, z)
			if a.x == a.y or b.x == b.y or s.in_shaft(x, z) or s.in_shaft(x + 1, z):
				continue
			if a.x <= GlowShape.LAKE_LEVEL or b.x <= GlowShape.LAKE_LEVEL:
				continue
			worst = maxi(worst, absi(a.x - b.x))
	assert_lte(worst, 1, "the floor's steps")


## The halls are big, high and connected: most open floor is reached from the spawn on foot (steps of one block, no
## swimming needed through the passages), and many columns have a ceiling 12 or more blocks up.
func test_halls_are_high_and_the_passages_connect_them() -> void:
	var sp := s.spawn_column()
	var r := 120
	var seen := {}
	var queue: Array[Vector2i] = [sp]
	seen[sp] = true
	var high := 0
	while not queue.is_empty():
		var p: Vector2i = queue.pop_back()
		var c := s.column(p.x, p.y)
		if c.y - c.x >= 12:
			high += 1
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q := p + d
			if seen.has(q) or absi(q.x - sp.x) > r or absi(q.y - sp.y) > r:
				continue
			var n := s.column(q.x, q.y)
			if n.x == n.y or absi(s.height_at(q.x, q.y) - s.height_at(p.x, p.y)) > 1:
				continue
			if n.y - maxi(n.x, GlowShape.LAKE_LEVEL) < 3:
				continue
			seen[q] = true
			queue.append(q)
	var total := 0
	for z in range(sp.y - r, sp.y + r + 1, 4):
		for x in range(sp.x - r, sp.x + r + 1, 4):
			var c := s.column(x, z)
			if c.x != c.y:
				total += 1
	var reached := 0
	for z in range(sp.y - r, sp.y + r + 1, 4):
		for x in range(sp.x - r, sp.x + r + 1, 4):
			if seen.has(Vector2i(x, z)):
				reached += 1
	assert_gt(float(reached) / total, 0.6, "most of the caves are reached on foot: %d of %d" % [reached, total])
	assert_gt(float(high) / seen.size(), 0.35, "big halls with high ceilings")


## Underground lakes: the floor dips under the water line; their water's top is LAKE_LEVEL; deep enough for fish.
func test_lakes_lie_under_the_water_line() -> void:
	var lake := 0
	var deep := 0
	for z in range(-500, 500, 5):
		for x in range(-500, 500, 5):
			var c := s.column(x, z)
			if c.x == c.y or s.in_shaft(x, z):
				continue
			if c.x < GlowShape.LAKE_LEVEL:
				lake += 1
				assert_eq(s.height_at(x, z), c.x, "a lake's bed is its ground")
				assert_eq(s.water_top(x, z), GlowShape.LAKE_LEVEL)
				if c.x <= MeadowsShape.SEA_LEVEL - 2:
					deep += 1
	assert_gt(lake, 100, "lakes")
	assert_gt(deep, 40, "some deep enough to swim and for fish")


## Daylight shafts: open to the sky; a spiral ramp up their wall climbs to the roof one block a step: the way out.
func test_a_shaft_near_home_has_a_ramp_up_to_the_roof() -> void:
	var shaft := s.home_shaft()
	assert_lte(Vector2(shaft - s.home).length(), GlowShape.HOME_OPEN + GlowShape.SHAFT_R, "a shaft near home")
	assert_true(s.in_shaft(shaft.x, shaft.y))
	var top := s.column(shaft.x, shaft.y)
	assert_eq(top.y, top.z, "open to the sky")
	# walk from the hall floor next to the ramp's foot (its east side) up the ramp, one block a step, until a step
	# of the ramp is one block or less under the roof's meadow: the way out
	var start := shaft + Vector2i(GlowShape.SHAFT_R + 1, 0)
	assert_false(s.in_shaft(start.x, start.y))
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var out := false
	while not queue.is_empty() and not out:
		var p: Vector2i = queue.pop_front()
		var hp := s.walk_top(p.x, p.y)
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q := p + d
			if seen.has(q) or not s.in_shaft(q.x, q.y):
				continue
			var hq := s.walk_top(q.x, q.y)
			if hq - hp > 1:
				continue
			seen[q] = true
			queue.append(q)
			if hq >= s.column(q.x, q.y).z - 1:
				out = true
	assert_true(out, "the ramp reaches the meadow on the roof")


## The caves are never truly dark: in the home region most of the floor has its own glow within a few blocks.
func test_the_glow_shows_the_way() -> void:
	var sp := s.spawn_column()
	var lit := 0
	var n := 0
	for z in range(sp.y - 60, sp.y + 61, 4):
		for x in range(sp.x - 60, sp.x + 61, 4):
			var c := s.column(x, z)
			if c.x == c.y or s.in_shaft(x, z):
				continue
			n += 1
			if s.glow_near(x, z, 8):
				lit += 1
	assert_gt(float(lit) / n, 0.85, "glow within 8 blocks: %d of %d" % [lit, n])


## Plants fit their caves: a giant glowshroom's cap stays under the ceiling, a stalactite hangs from a ceiling,
## nothing grows in a lake's water or a shaft's open column.
func test_plants_fit_under_the_ceiling() -> void:
	var shrooms := 0
	var tites := 0
	for z in range(-300, 300):
		for x in range(-300, 300, 3):
			var p := s.plant_at(x, z)
			var c := s.column(x, z)
			if p != GlowShape.NO_PLANT:
				assert_gt(c.y, c.x, "on open floor")
				assert_gt(c.x, GlowShape.LAKE_LEVEL, "never in a lake")
				assert_false(s.in_shaft(x, z))
				if p == GlowShape.BLUE_GIANT or p == GlowShape.ROSE_GIANT:
					shrooms += 1
					assert_lt(c.x + s.plant_height(x, z) + 3, c.y, "the cap stays under the ceiling at %d,%d" % [x, z])
			var hang := s.hang_at(x, z)
			if hang > 0:
				tites += 1
				assert_gt(c.y, c.x)
				assert_lt(c.y, c.z, "under a ceiling, never in a shaft")
				assert_lt(c.y - hang, c.y)
				assert_gt(c.y - hang, maxi(c.x, GlowShape.LAKE_LEVEL) + 1, "never down to the floor")
	assert_gt(shrooms, 20, "giant glowshrooms")
	assert_gt(tites, 100, "stalactites")


## Selenite beams grow in crystal halls (the Cave of Crystals): a few big halls of them.
func test_crystal_halls_hold_selenite_beams() -> void:
	var beams := 0
	for z in range(-600, 600, 2):
		for x in range(-600, 600, 2):
			if s.plant_at(x, z) == GlowShape.BEAM:
				beams += 1
				assert_true(s.crystal_hall(x, z))
	assert_gt(beams, 10, "beams in crystal halls")


## The meadow on the roof is no bare lawn: flowers in patches (and a few alone), never over a daylight shaft.
func test_the_roof_meadow_has_flower_patches() -> void:
	var roofed := 0
	var flowers := 0
	var pairs := 0
	var both := 0
	for z in range(-300, 300, 3):
		for x in range(-300, 300, 3):
			if s.in_shaft(x, z):
				assert_false(s.flower_on_roof(x, z), "no flower over a shaft at %d,%d" % [x, z])
				continue
			roofed += 1
			if s.flower_on_roof(x, z):
				flowers += 1
				pairs += 1
				if s.flower_on_roof(x + 1, z) or s.flower_on_roof(x, z + 1):
					both += 1
	var share := float(flowers) / roofed
	assert_between(share, 0.03, 0.25, "flowers on %.1f%% of the roof" % (share * 100.0))
	assert_gt(float(both) / maxf(pairs, 1.0), share * 2.0, "they grow in patches")
