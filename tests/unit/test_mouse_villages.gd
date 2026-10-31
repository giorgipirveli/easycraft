extends GutTest
## M3 Task 21c: the Tiny world (spec §3a Size Magic "tiny-only secrets", §16 "a Tiny-only mouse village"). Mouse
## holes — 1-block openings at the foot of a hill, or between the roots of a big old tree on a grassy knoll — lead
## into a mouse village: a little room under the ground where a mouse family lives with a tiny treasure. Only a tiny
## player fits through the door. They are placed like secrets (the seed and the area alone, every box inside its
## area: chunks meet without seams), after the secrets and the wild meadows' places, so those never move, and they
## never touch a secret, a place, a river or the spawn's surroundings.

const SEED := 12345
const RINGS := 6   # areas -6..6 each way


func _all(rules: SecretRules) -> Array:
	var out: Array = []
	for az in range(-RINGS, RINGS + 1):
		for ax in range(-RINGS, RINGS + 1):
			out.append_array(rules.tiny_in_area(Vector2i(ax, az)))
	return out


static func _cell(rules: SecretRules, shape: MeadowsShape, p: Vector3i) -> int:
	var s := rules.block_at(p)
	if s >= 0:
		return s
	return shape.column_block(p.y, shape.height_at(p.x, p.z))


## Can a body `clearance` blocks tall walk from `from` to `to` on the level y0 (a solid floor under it, room over it)?
static func _walks(rules: SecretRules, shape: MeadowsShape, from: Vector3i, to: Vector3i, clearance: int, lo: Vector3i,
		hi: Vector3i) -> bool:
	var y0 := from.y
	var seen := {Vector2i(from.x, from.z): true}
	var queue: Array[Vector2i] = [Vector2i(from.x, from.z)]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		if c == Vector2i(to.x, to.z):
			return true
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if seen.has(n) or n.x < lo.x - 2 or n.y < lo.z - 2 or n.x >= hi.x + 2 or n.y >= hi.z + 2:
				continue
			if not BlockIds.is_solid(_cell(rules, shape, Vector3i(n.x, y0 - 1, n.y))):
				continue
			var free := true
			for k in clearance:
				if BlockIds.is_solid(_cell(rules, shape, Vector3i(n.x, y0 + k, n.y))):
					free = false
			if free:
				seen[n] = true
				queue.append(n)
	return false


func test_villages_are_found_in_every_universe_but_the_sky() -> void:
	var shapes := {"meadows": MeadowsShape.new(SEED), "wild meadows": MeadowsBiomeShape.new(SEED),
		"desert": DesertShape.new(SEED), "frost": FrostShape.new(SEED), "candy": CandyShape.new(SEED)}
	for n: String in shapes:
		var got := _all(SecretRules.new(SEED, shapes[n]))
		gut.p("%s: %d mouse villages in %d areas" % [n, got.size(), (2 * RINGS + 1) * (2 * RINGS + 1)])
		assert_gte(got.size(), 8, "%s has mouse villages" % n)
	assert_eq(_all(DragonSecretRules.new(SEED)).size(), 0, "the Dragon Realm's islands float over nothing: no mice there")


## Worked out again from nothing (not from the cache every MouseVillages of a world shares), a world's villages are
## the same.
func test_the_same_world_always_has_the_same_villages() -> void:
	var a := _all(SecretRules.new(SEED))
	assert_gt(a.size(), 0)
	var fresh := SecretRules.new(SEED)
	for s: Dictionary in a:
		var again: Array = fresh.tiny._place(s.area)
		assert_eq(again.size(), 1, s.id)
		if again.size() == 1:
			assert_eq(again[0].id, s.id)
			assert_eq(again[0].boxes, s.boxes, s.id)
	assert_ne(_all(SecretRules.new(SEED + 1)).map(func(s: Dictionary) -> String: return s.id),
		a.map(func(s: Dictionary) -> String: return s.id), "another seed, other villages")


func test_ids_kind_and_finding_one_again() -> void:
	var rules := SecretRules.new(SEED)
	var all := _all(rules)
	assert_gt(all.size(), 0)
	for s: Dictionary in all:
		assert_eq(s.kind, MouseVillages.KIND)
		assert_true(s.tiny, "a tiny-only secret")
		var parts := (s.id as String).split("_")
		assert_eq(parts.size(), 4, s.id)
		assert_eq(parts[0], "mice")
		assert_gte(int(parts[3]), MouseVillages.FIRST_ATTEMPT, "never an id a secret of the area has")
		assert_eq(rules.find(s.id).get("id", ""), s.id)
	assert_true(SecretRules.is_kind(MouseVillages.KIND), "the Secret Book knows it")
	assert_eq(String(MouseVillages.KIND).find("_"), -1)


func test_inside_their_area_and_clear_of_the_spawn() -> void:
	var rules := SecretRules.new(SEED)
	for s: Dictionary in _all(rules):
		var base: Vector2i = (s.area as Vector2i) * SecretRules.AREA
		assert_true(s.lo.x >= base.x and s.lo.z >= base.y and s.hi.x <= base.x + SecretRules.AREA
			and s.hi.z <= base.y + SecretRules.AREA, "%s stays in its area" % s.id)
		var dx := maxi(maxi(s.lo.x - rules.spawn.x, rules.spawn.x - (s.hi.x - 1)), 0)
		var dz := maxi(maxi(s.lo.z - rules.spawn.y, rules.spawn.y - (s.hi.z - 1)), 0)
		assert_gte(Vector2(dx, dz).length(), MouseVillages.CLEAR_OF_SPAWN, s.id)


static func _apart(a: Dictionary, b: Dictionary, gap: int) -> bool:
	var alo: Vector3i = a.lo
	var ahi: Vector3i = a.hi
	var blo: Vector3i = b.lo
	var bhi: Vector3i = b.hi
	return not (alo.x - gap < bhi.x and blo.x < ahi.x + gap and alo.z - gap < bhi.z and blo.z < ahi.z + gap)


func test_never_on_a_secret_and_the_secrets_never_move() -> void:
	var rules := SecretRules.new(SEED)
	var without := SecretRules.new(SEED, null, true, false)
	assert_null(without.tiny)
	for s: Dictionary in _all(rules):
		for o: Dictionary in rules.secrets_in_area(s.area):
			assert_true(_apart(s, o, MouseVillages.GAP), "%s keeps off %s" % [s.id, o.id])
	for az in range(-3, 4):
		for ax in range(-3, 4):
			var a := Vector2i(ax, az)
			assert_eq(rules.secrets_in_area(a).map(func(s: Dictionary) -> String: return s.id),
				without.secrets_in_area(a).map(func(s: Dictionary) -> String: return s.id), "the area's secrets are the same")


## The wild meadows' villages, windmills, towers and their paths: never under a mouse village, and none moves for one.
func test_never_on_a_place_and_the_places_never_move() -> void:
	var shape := MeadowsBiomeShape.new(SEED)
	var rules := SecretRules.new(SEED, shape)
	var places := MeadowsPlaces.new(SEED, shape, rules)
	var alone := MeadowsPlaces.new(SEED, shape, SecretRules.new(SEED, shape, true, false))
	var near_places := 0
	for s: Dictionary in _all(rules):
		var region := MeadowsPlaces.region_of(s.lo.x, s.lo.z)
		for p: Dictionary in places.places_in_region(region):
			near_places += 1
			assert_true(_apart(s, p, MouseVillages.GAP), "%s keeps off %s" % [s.id, p.id])
	gut.p("places in the villages' regions: %d" % near_places)
	for rz in range(-3, 4):
		for rx in range(-3, 4):
			var r := Vector2i(rx, rz)
			assert_eq(places.places_in_region(r).map(func(p: Dictionary) -> String: return p.id),
				alone.places_in_region(r).map(func(p: Dictionary) -> String: return p.id), "region %s's places" % r)


## Never in a normal-size child's way: the knoll's sides and back go up and down one block at a time (a child walks
## over it), and the doorstep in front of the door is level, open to the sky.
func test_a_normal_size_child_walks_over_a_knoll() -> void:
	var shape := MeadowsShape.new(SEED)
	var rules := SecretRules.new(SEED, shape)
	var checked := 0
	for s: Dictionary in _all(rules):
		if checked >= 8:
			continue
		checked += 1
		var dir: Vector3i = s.dir
		var side := Vector3i(-dir.z, 0, dir.x)
		var door: Vector3i = s.door
		var f := door.y
		var tops := {}
		for along in range(1, MouseVillages.SHELL_ALONG.y + MouseVillages.MOUND_REACH + 2):
			for across in range(-MouseVillages.SHELL_ACROSS - MouseVillages.MOUND_REACH - 1, MouseVillages.SHELL_ACROSS + MouseVillages.MOUND_REACH + 2):
				var c := door + dir * along + side * across
				tops[Vector2i(along, across)] = _surface(rules, shape, c.x, c.z, f + 12)
		for k: Vector2i in tops:
			for n: Vector2i in [k + Vector2i(1, 0), k + Vector2i(0, 1)]:
				if tops.has(n) and absi(int(tops[k]) - int(tops[n])) > 1:
					var c := door + dir * k.x + side * k.y
					var natural := absi(shape.height_at(c.x, c.z) - shape.height_at((door + dir * n.x + side * n.y).x,
						(door + dir * n.x + side * n.y).z)) > 1
					assert_true(natural, "%s: a step of %d at %s (the land itself is steeper there)" % [s.id,
						absi(int(tops[k]) - int(tops[n])), k])
		for along in range(1, MouseVillages.DOORSTEP + 1):
			for across in range(-1, 2):
				var c := door - dir * along + side * across
				assert_eq(_surface(rules, shape, c.x, c.z, f + 12), f, "%s: the doorstep is level" % s.id)
	assert_gt(checked, 2)


## The first empty height over the solid ground of a column (the knoll's tree left out: you walk under it).
static func _surface(rules: SecretRules, shape: MeadowsShape, x: int, z: int, from: int) -> int:
	for y in range(from, from - 40, -1):
		var id := _cell(rules, shape, Vector3i(x, y, z))
		if BlockIds.is_solid(id) and not id in [BlockIds.LOG, BlockIds.LEAVES]:
			return y + 1
	return from - 40


## The door is one block high: a tiny child walks from outside through it into the room; a normal-size child (two
## blocks tall) can't, from anywhere around. Everything on the way is level (a tiny child can't climb a block).
func test_only_a_tiny_player_fits_through_the_door() -> void:
	var tiny := SizeMagic.clearance_blocks(SizeMagic.Mode.TINY)
	var normal := SizeMagic.clearance_blocks(SizeMagic.Mode.NORMAL)
	assert_eq(tiny, 1)
	assert_eq(normal, 2)
	for shape: MeadowsShape in [MeadowsShape.new(SEED), FrostShape.new(SEED)]:
		var rules := SecretRules.new(SEED, shape)
		var checked := 0
		for s: Dictionary in _all(rules):
			if checked >= 6:
				break
			checked += 1
			var visit: Vector3i = s.visit
			var door: Vector3i = s.door
			var anchor: Vector3i = s.anchor
			assert_eq(visit.y, anchor.y, "%s: the way in is level" % s.id)
			assert_eq(door.y, anchor.y, s.id)
			assert_false(BlockIds.is_solid(_cell(rules, shape, door)), "%s: the door is open" % s.id)
			assert_true(BlockIds.is_solid(_cell(rules, shape, door + Vector3i.UP)), "%s: and one block high" % s.id)
			assert_true(_walks(rules, shape, visit, anchor, tiny, s.lo, s.hi), "%s: a tiny child walks in" % s.id)
			assert_false(_walks(rules, shape, visit, anchor, normal, s.lo, s.hi), "%s: a normal child never fits" % s.id)
		assert_gt(checked, 2)


## The room is closed all round but for its door, under a roof with ground over it: a child walking over the hill
## or the knoll never falls in or sees into it.
func test_the_room_is_closed_and_covered() -> void:
	var shape := MeadowsShape.new(SEED)
	var rules := SecretRules.new(SEED, shape)
	for s: Dictionary in _all(rules):
		var inside: Array = s.room
		var lo: Vector3i = inside[0]
		var hi: Vector3i = inside[1]
		for x in range(lo.x, hi.x):
			for z in range(lo.z, hi.z):
				for y in [hi.y, hi.y + 1]:
					assert_true(BlockIds.is_solid(_cell(rules, shape, Vector3i(x, y, z))), "%s: covered at %d,%d,%d" % [s.id, x, y, z])
				assert_true(BlockIds.is_solid(_cell(rules, shape, Vector3i(x, lo.y - 1, z))), "%s: a floor" % s.id)
		var openings := 0
		for x in range(lo.x - 1, hi.x + 1):
			for z in range(lo.z - 1, hi.z + 1):
				if x >= lo.x and x < hi.x and z >= lo.z and z < hi.z:
					continue
				for y in range(lo.y, hi.y):
					if not BlockIds.is_solid(_cell(rules, shape, Vector3i(x, y, z))):
						openings += 1
		assert_eq(openings, 1, "%s: one way in (the tunnel)" % s.id)


## The green meadows' gentle land has grassy knolls with a big old tree (the door in its roots); the desert's mesas
## and Frostpeak's peaks have doors at the foot of their hills too.
func test_both_kinds_of_mouse_hole_and_a_marker_by_the_door() -> void:
	var variants := {}
	for shape: MeadowsShape in [MeadowsShape.new(SEED), DesertShape.new(SEED), FrostShape.new(SEED)]:
		for s: Dictionary in _all(SecretRules.new(SEED, shape)):
			variants[s.variant] = int(variants.get(s.variant, 0)) + 1
			assert_false((s.markers as Array).is_empty(), "%s: a pumpkin by the door" % s.id)
			for m: Vector3i in s.markers:
				assert_ne(Vector2i(m.x, m.z), Vector2i(s.visit.x, s.visit.z), "never on the way in")
				assert_ne(Vector2i(m.x, m.z), Vector2i(s.door.x, s.door.z))
	gut.p("variants: %s" % variants)
	assert_true(variants.has(MouseVillages.HILL), "at the foot of a hill")
	assert_true(variants.has(MouseVillages.KNOLL), "in an old tree's roots")
	for s: Dictionary in _all(SecretRules.new(SEED)):
		if s.variant == MouseVillages.KNOLL:
			var logs := 0
			for b: Array in s.boxes:
				logs += int(int(b[2]) == BlockIds.LOG)
			assert_gte(logs, 4, "the knoll's tree: its trunk and three roots round the door")
			break
	var marks := {"meadows": BlockIds.PUMPKIN, "desert": BlockIds.CACTUS, "frost": BlockIds.SNOWMAN_HEAD,
		"candy": BlockIds.JACK_O_LANTERN}
	var shapes := {"meadows": MeadowsShape.new(SEED), "desert": DesertShape.new(SEED), "frost": FrostShape.new(SEED),
		"candy": CandyShape.new(SEED)}
	for n: String in shapes:
		var rules := SecretRules.new(SEED, shapes[n])
		var found := false
		for s: Dictionary in _all(rules):
			for m: Vector3i in s.markers:
				found = found or rules.block_at(m) == int(marks[n])
		assert_true(found, "%s's mouse holes have a %s" % [n, BlockIds.display_name(marks[n])])


func test_the_tiny_treasure_and_the_mice_are_in_the_room() -> void:
	for s: Dictionary in _all(SecretRules.new(SEED)):
		var inside: Array = s.room
		assert_true(SecretRules._contains(inside[0], inside[1], s.chest), "%s: the chest is in the room" % s.id)
		assert_eq((s.chest as Vector3i).y, (s.anchor as Vector3i).y, "on its floor")
		assert_eq(s.chest_kind, MouseVillages.CHEST_KIND)
		assert_true(SecretRules._contains(inside[0], inside[1], s.anchor), "the mice's home is in the room")
		assert_true(is_finite(float(s.yaw)))


## Every block a village puts somewhere is in the generated chunks, whichever chunk it falls in (the old and the
## wild meadows' generators).
func test_villages_are_generated_without_seams() -> void:
	for gen: MeadowsGenerator in [MeadowsGenerator.new(), MeadowsBiomeGenerator.new()]:
		gen.world_seed = SEED
		var rules: SecretRules = gen._secrets
		var s: Dictionary = {}
		for v: Dictionary in _all(rules):
			if (v.lo as Vector3i) / 16 != ((v.hi as Vector3i) - Vector3i.ONE) / 16:
				s = v
				break
		assert_false(s.is_empty(), "a village that crosses chunk borders")
		if s.is_empty():
			continue
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		var c0 := Vector3i(floori(lo.x / 16.0), floori(lo.y / 16.0), floori(lo.z / 16.0))
		var c1 := Vector3i(floori((hi.x - 1) / 16.0), floori((hi.y - 1) / 16.0), floori((hi.z - 1) / 16.0))
		var checked := 0
		for cz in range(c0.z, c1.z + 1):
			for cy in range(c0.y, c1.y + 1):
				for cx in range(c0.x, c1.x + 1):
					var origin := Vector3i(cx, cy, cz) * 16
					var buf := VoxelBuffer.new()
					buf.create(16, 16, 16)
					gen._generate_block(buf, origin, 0)
					for b: Array in s.boxes:
						var a: Vector3i = (b[0] as Vector3i).max(origin)
						var e: Vector3i = (b[1] as Vector3i).min(origin + Vector3i(16, 16, 16))
						for x in range(a.x, e.x):
							for y in range(a.y, e.y):
								for z in range(a.z, e.z):
									var p := Vector3i(x, y, z)
									assert_eq(buf.get_voxel(p.x - origin.x, p.y - origin.y, p.z - origin.z, VoxelBuffer.CHANNEL_TYPE),
										rules.block_at(p), "%s at %s" % [s.id, p])
									checked += 1
		assert_gt(checked, 100)
