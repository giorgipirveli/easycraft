extends GutTest
## Cosmos: Venus's cloud city (world 24, spec §21b.2): its terrain as pure rules (SpaceShape with planet VENUS; the city
## in VenusTerrain). About 50 km up, round platforms float over the yellow clouds, every deck and bridge at one height
## (so every walk is level: gravity 0.9 climbs one block, and there is never a step), each deck over a silvery float
## hull; the landing deck round the pad, the city's ring (the airship dock, the aliens' camp, the show deck, the cloud
## homes, the sky garden, the west lookout, the orchard), an outer ring, isles far out, bridges between them all, lamp
## posts, gardens, the city's built parts and its sights. The clouds far below are never reached: the lift line lies high
## over them.

const SEED := 12345
const SEEDS: Array[int] = [12345, 77, 777, 42]


func _venus(seed: int = SEED) -> SpaceShape:
	return SpaceShape.new(seed, SpaceShape.VENUS)


func test_venus_is_a_space_planet_with_its_city() -> void:
	assert_has(SpaceShape.PLANETS, SpaceShape.VENUS)
	var s := _venus()
	assert_eq(s.planet, SpaceShape.VENUS)
	assert_not_null(s.venus, "Venus's city")
	assert_null(s.mercury)
	assert_null(s.titan)
	assert_null(SpaceShape.new(SEED, SpaceShape.MERCURY).venus, "Mercury has none")
	var jump := Player.JUMP_VELOCITY * Player.JUMP_VELOCITY / (2.0 * Player.GRAVITY * 0.9)
	assert_gt(jump, 1.3, "a jump at 0.9 gravity climbs a block (%.2f)" % jump)


func test_the_landing_deck_round_the_pad() -> void:
	for seed in SEEDS:
		var s := _venus(seed)
		var sp := s.spawn_column()
		assert_eq(sp, s.venus.spawn())
		assert_eq(s.height_at(sp.x, sp.y), VenusTerrain.DECK_Y, "the pad is on a deck")
		assert_eq(s.block_at(sp.x, VenusTerrain.DECK_Y - 1, sp.y), BlockIds.LANDING_PAD)
		assert_eq(s.block_at(sp.x, VenusTerrain.DECK_Y, sp.y), BlockIds.AIR)
		for d: Vector2i in [Vector2i(19, 0), Vector2i(-19, 0), Vector2i(0, 19), Vector2i(0, -19), Vector2i(13, 13)]:
			assert_eq(s.height_at(sp.x + d.x, sp.y + d.y), VenusTerrain.DECK_Y, "a wide landing deck (%s)" % d)
		assert_false(s.is_river(sp.x + 12, sp.y), "Tilly's ring is dry land")


func test_the_citys_ring_round_the_landing_deck() -> void:
	for seed in SEEDS:
		var v := _venus(seed).venus
		var sp := v.spawn()
		var dock := v.centre(VenusTerrain.DOCK)
		assert_eq(dock.x, sp.x, "the dock straight north (or south) of the pad")
		assert_eq(signi(dock.y - sp.y), v.north().y, "toward north(): %s" % v.north())
		assert_between(Vector2(dock - sp).length(), 40.0, 50.0)
		var lookout := v.centre(VenusTerrain.LOOKOUT)
		assert_eq(lookout.y, sp.y, "the lookout due west")
		assert_lt(lookout.x, sp.x - 40)
		for role: StringName in [VenusTerrain.CAMP, VenusTerrain.SHOW, VenusTerrain.HOMES, VenusTerrain.GARDEN_DECK,
				VenusTerrain.ORCHARD]:
			var d := Vector2(v.centre(role) - sp).length()
			assert_between(d, 38.0, 52.0, "%s a short walk from the pad" % role)
		var all: Array = v.platforms()
		for i in all.size():
			for j in range(i + 1, all.size()):
				var a: Array = all[i]
				var b: Array = all[j]
				var gap: float = Vector2(a[1] - b[1], a[2] - b[2]).length() - a[3] - b[3]
				assert_gt(gap, 4.0, "%s and %s never touch (%.1f)" % [a[0], b[0], gap])


## Every deck and bridge is at one height: from the pad a child walks to every platform of the ring and the outer ring
## without a single step.
func test_every_platform_is_joined_by_bridges_at_one_height() -> void:
	var s := _venus()
	var v := s.venus
	var sp := v.spawn()
	var r := 130
	var seen := {sp: true}
	var todo: Array[Vector2i] = [sp]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for n: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q := c + n
			if seen.has(q) or absi(q.x - sp.x) > r or absi(q.y - sp.y) > r:
				continue
			if s.height_at(q.x, q.y) != VenusTerrain.DECK_Y:
				continue
			seen[q] = true
			todo.append(q)
	for p: Array in v.platforms():
		assert_true(seen.has(Vector2i(p[1], p[2])), "%s at (%d, %d) is a walk from the pad" % [p[0], p[1], p[2]])
	assert_gte(v.bridges().size(), 7 + 6 + 16, "the radials, the promenade, the outer ring's (and to the isles)")


func test_decks_over_float_hulls_over_the_yellow_clouds() -> void:
	var s := _venus()
	var v := s.venus
	var seen := {}
	for i in 3000:
		var x := (i * 37) % 700 - 300
		var z := (i * 53) % 700 - 300
		var c := v.column(x, z)
		seen[c[0]] = int(seen.get(c[0], 0)) + 1
		var cloud := c[3]
		assert_between(cloud, VenusTerrain.CLOUD_LOW, VenusTerrain.CLOUD_HIGH - 1, "the clouds' top (%d, %d)" % [x, z])
		assert_eq(s.block_at(x, cloud - 1, z), BlockIds.VENUS_CLOUD, "yellow cloud tops")
		assert_eq(s.block_at(x, cloud - 5, z), BlockIds.DEEP_CLOUD, "deeper clouds under them")
		assert_eq(s.block_at(x, -20, z), BlockIds.DEEP_CLOUD, "clouds all the way down")
		assert_eq(s.block_at(x, MeadowsShape.WORLD_BOTTOM, z), BlockIds.BEDROCK)
		assert_eq(s.block_at(x, cloud, z), BlockIds.AIR, "air over the clouds")
		if c[0] == VenusTerrain.CLOUD:
			assert_eq(s.height_at(x, z), cloud)
			assert_true(s.is_river(x, z), "no dry land for a spawner over the clouds")
			continue
		assert_eq(s.height_at(x, z), VenusTerrain.DECK_Y, "every deck and bridge at one height")
		assert_eq(s.block_at(x, VenusTerrain.DECK_Y, z), BlockIds.AIR)
		assert_eq(s.block_at(x, c[2] - 1, z), BlockIds.AIR, "air under the hull or the bridge")
		assert_gt(c[2] - 1, VenusTerrain.LIFT_Y, "every hull floats over the lift line")
		if c[0] == VenusTerrain.BRIDGE:
			assert_eq(s.block_at(x, VenusTerrain.DECK_Y - 1, z), BlockIds.SKY_BRIDGE, "honey planks")
			assert_true(s.is_river(x, z), "spawners keep off the bridges")
		elif not s.pad_at(x, z):
			var top := {VenusTerrain.DECK: BlockIds.CLOUD_DECK, VenusTerrain.GARDEN: BlockIds.SKY_TURF,
				VenusTerrain.RIM: BlockIds.SKY_FRAME}
			assert_eq(s.block_at(x, VenusTerrain.DECK_Y - 1, z), top[c[0]], "(%d, %d)" % [x, z])
			assert_eq(s.block_at(x, VenusTerrain.DECK_Y - 2, z), BlockIds.FLOAT_HULL, "a float hull under the deck")
			assert_eq(s.block_at(x, c[2], z), BlockIds.FLOAT_HULL, "the hull's lowest block")
			assert_false(s.is_river(x, z), "a deck is dry land")
	assert_gt(int(seen.get(VenusTerrain.CLOUD, 0)), 1500, "mostly open sky over the clouds")
	for k in [VenusTerrain.DECK, VenusTerrain.GARDEN, VenusTerrain.RIM, VenusTerrain.BRIDGE]:
		assert_gt(int(seen.get(k, 0)), 5, "some %d" % k)


## The hulls are round underneath: thin at the rim, deepest in the middle.
func test_a_hull_is_deepest_in_its_middle() -> void:
	var v := _venus().venus
	var g := v.centre(VenusTerrain.GARDEN_DECK)
	var r := int(v.platform(VenusTerrain.GARDEN_DECK)[3])
	var middle := v.column(g.x, g.y)[2]
	var rim := v.column(g.x + r, g.y)[2]
	assert_eq(rim, VenusTerrain.DECK_Y - 1 - VenusTerrain.HULL_EDGE, "HULL_EDGE thick at the rim")
	assert_lt(middle, rim - 8, "much deeper in the middle (%d vs %d)" % [middle, rim])


## The warm breeze's line (the descriptor's void line) lies far over every cloud and far under every deck.
func test_the_lift_line_between_the_clouds_and_the_city() -> void:
	assert_gt(VenusTerrain.LIFT_Y, float(VenusTerrain.CLOUD_HIGH) + 8.0, "a child never touches the clouds")
	assert_lt(VenusTerrain.LIFT_Y, float(VenusTerrain.DECK_Y) - 16.0, "a real fall first, then the breeze")
	assert_gt(VenusTerrain.DECK_Y, MeadowsShape.SEA_LEVEL + 40)
	assert_lt(VenusTerrain.DECK_Y + 20, SpaceGenerator.SKY_TOP, "the city far under the sky's limit")


## The generator's fast path (a chunk column's columns at once) is column(), everywhere.
func test_the_fast_columns_are_column() -> void:
	var s := _venus()
	var v := s.venus
	var spots: Array[Vector2i] = [v.spawn(), v.centre(VenusTerrain.DOCK), v.centre(VenusTerrain.HOMES),
		Vector2i(v.bridges()[0][0], v.bridges()[0][1]), Vector2i(333, -517), Vector2i(-250, 260)]
	for c in spots:
		var x0 := c.x - 20
		var z0 := c.y - 20
		var cols := v.columns(x0, z0, 40, 40)
		var grounds := s.grounds(x0, z0, 40, 40)
		for z in 40:
			for x in 40:
				var one := v.column(x0 + x, z0 + z)
				var i := x + z * 40
				assert_eq(int(cols[0][i]), one[1], "top at (%d, %d)" % [x0 + x, z0 + z])
				assert_eq(int(cols[1][i]), one[0], "kind at (%d, %d)" % [x0 + x, z0 + z])
				assert_eq(int(cols[2][i]), one[2])
				assert_eq(int(cols[3][i]), one[3])
				assert_eq(grounds[i], s.ground_at(x0 + x, z0 + z))
				if int(cols[0][i]) != one[1]:
					return


func test_lamps_on_rims_and_bridges_flowers_and_trees_in_the_gardens() -> void:
	for seed: int in [SEED, 77]:
		_features_of(seed)


func _features_of(seed: int) -> void:
	var s := _venus(seed)
	var v := s.venus
	var sp := v.spawn()
	var count := {}
	for z in range(sp.y - 130, sp.y + 130):
		for x in range(sp.x - 130, sp.x + 130):
			var f := v.feature_at(x, z)
			if f == VenusTerrain.NO_FEATURE:
				continue
			var k := v.kind_at(x, z)
			count[f] = int(count.get(f, 0)) + 1
			if f == VenusTerrain.LAMP:
				assert_true(k == VenusTerrain.RIM or k == VenusTerrain.BRIDGE, "a lamp on a rim or a bridge (%d, %d)" % [x, z])
			else:
				assert_eq(k, VenusTerrain.GARDEN, "plants grow in the gardens (%d, %d)" % [x, z])
			var p := v.platform_at(x, z)
			if not p.is_empty():
				assert_false(p[0] in [VenusTerrain.CAMP, VenusTerrain.SHOW, VenusTerrain.DOCK],
					"the camp, the show deck and the dock stay clear (%s)" % p[0])
			if s.tree_at(x, z):
				assert_gt(Vector2(x - sp.x, z - sp.y).length(), float(SpaceShape.BLEND_RADIUS), "none by the pad")
	assert_gt(int(count.get(VenusTerrain.LAMP, 0)), 40, "lamps light the city")
	assert_gt(int(count.get(VenusTerrain.FLOWER, 0)), 30, "flowers in the gardens")
	assert_gt(int(count.get(VenusTerrain.TREE, 0)), 4, "little trees from Earth")
	var fast := v.features(sp.x - 40, sp.y - 40, 80, 80, SpaceShape.BLEND_RADIUS)
	var n := 0
	for z in range(sp.y - 40, sp.y + 40):
		for x in range(sp.x - 40, sp.x + 40):
			if s.tree_at(x, z):
				assert_eq(fast[n * 3], x)
				assert_eq(fast[n * 3 + 1], z)
				assert_eq(fast[n * 3 + 2], v.feature_at(x, z))
				n += 1
	assert_eq(fast.size(), n * 3, "the fast features are tree_at's")


func test_a_lamp_post_a_flower_and_a_little_tree() -> void:
	var y := VenusTerrain.DECK_Y
	var o := Vector3i(10, y, 20)
	assert_eq(VenusTerrain.feature_block(VenusTerrain.LAMP, 10, 20, y, o), BlockIds.SKY_FRAME)
	assert_eq(VenusTerrain.feature_block(VenusTerrain.LAMP, 10, 20, y, o + Vector3i(0, 2, 0)), BlockIds.CLOUD_LAMP)
	assert_eq(VenusTerrain.feature_block(VenusTerrain.LAMP, 10, 20, y, o + Vector3i(1, 0, 0)), -1)
	assert_eq(VenusTerrain.feature_block(VenusTerrain.FLOWER, 10, 20, y, o), BlockIds.FLOWERS)
	assert_eq(VenusTerrain.feature_block(VenusTerrain.TREE, 10, 20, y, o + Vector3i(0, 1, 0)), BlockIds.LOG)
	assert_eq(VenusTerrain.feature_block(VenusTerrain.TREE, 10, 20, y, o + Vector3i(1, 2, 1)), BlockIds.LEAVES)
	assert_eq(VenusTerrain.feature_block(VenusTerrain.TREE, 10, 20, y, o + Vector3i(0, 3, 0)), BlockIds.LEAVES)
	assert_eq(VenusTerrain.feature_block(VenusTerrain.TREE, 10, 20, y, o + Vector3i(1, 3, 1)), -1)


func test_the_citys_built_parts() -> void:
	for seed in SEEDS:
		var v := _venus(seed).venus
		var y := VenusTerrain.DECK_Y
		var sp := v.spawn()
		var out := -v.north()
		var scope := sp + out * VenusTerrain.SCOPE_OUT
		assert_eq(v.built_at(Vector3i(scope.x, y + 1, scope.y)), BlockIds.TELESCOPE, "the cloud scope by the pad")
		assert_eq(v.built_at(Vector3i(scope.x, y, scope.y)), BlockIds.SKY_FRAME, "on its stand")
		assert_eq(v.column(scope.x + out.x, scope.y + out.y)[0], VenusTerrain.RIM, "at the deck's rim, looking out")
		var dock := v.centre(VenusTerrain.DOCK)
		var mast := dock + v.north() * VenusTerrain.MAST_OUT + Vector2i(VenusTerrain.MAST_SIDE, 0)
		for up in range(1, VenusTerrain.MAST_H):
			assert_eq(v.built_at(Vector3i(mast.x, y + up, mast.y)), BlockIds.SKY_FRAME, "the mooring mast")
		assert_eq(v.built_at(Vector3i(mast.x, y + VenusTerrain.MAST_H, mast.y)), BlockIds.CLOUD_LAMP, "its lamp")
		var g := v.centre(VenusTerrain.GARDEN_DECK)
		assert_eq(v.built_at(Vector3i(g.x + 1, y - 1, g.y)), BlockIds.WATER, "the garden's pond")
		assert_eq(v.built_at(Vector3i(g.x, y + 1, g.y)), BlockIds.CLOUD_LAMP, "its lamp fountain")
		var hm := v.centre(VenusTerrain.HOMES)
		var homes := 0
		for c: Vector2i in [Vector2i(5, 5), Vector2i(-5, 5), Vector2i(5, -5), Vector2i(-5, -5)]:
			var h := hm + c
			assert_eq(v.built_at(Vector3i(h.x + 2, y + 2, h.y)), BlockIds.HOME_PANEL, "walls")
			assert_eq(v.built_at(Vector3i(h.x, y + 1, h.y)), BlockIds.AIR, "room inside")
			assert_eq(v.built_at(Vector3i(h.x, y + 3, h.y)), BlockIds.CLOUD_LAMP, "a lamp under its dome")
			assert_true(VenusTerrain.HOME_COLORS.has(v.built_at(Vector3i(h.x + 1, y + 4, h.y))), "a painted dome")
			var door := h + (Vector2i(-2, 0) if c.x > 0 else Vector2i(2, 0))
			assert_eq(v.built_at(Vector3i(door.x, y, door.y)), BlockIds.AIR, "a door toward the square")
			assert_eq(v.built_at(Vector3i(door.x, y + 1, door.y)), BlockIds.AIR)
			homes += 1
		assert_eq(homes, 4)
		var lk := v.centre(VenusTerrain.LOOKOUT)
		var tel := lk + Vector2i(-VenusTerrain.LOOKOUT_OUT, 0)
		assert_eq(v.built_at(Vector3i(tel.x - 1, y + 1, tel.y)), BlockIds.TELESCOPE, "the west lookout's telescope")
		assert_lt(v.built_top(), SpaceGenerator.SKY_TOP)


func test_the_sights_where_a_child_learns_a_fact() -> void:
	var s := _venus()
	var v := s.venus
	var sp := v.spawn()
	var list := s.sights()
	var ids: Array = list.map(func(e: Dictionary) -> StringName: return e.id)
	assert_eq(ids, [&"scope", &"dock", &"garden", &"homes", &"lookout"])
	for e: Dictionary in list:
		var at: Vector3 = e.pos
		assert_eq(int(at.y), VenusTerrain.DECK_Y, "%s on a deck" % e.id)
		assert_eq(s.sight_at(floori(at.x), floori(at.z)), e.id, "standing there finds %s" % e.id)
		var d := Vector2(at.x - sp.x, at.z - sp.y).length()
		if e.id == &"scope":
			assert_between(d, 12.0, 20.0, "the cloud scope by the pad (%.0f)" % d)
		else:
			assert_between(d, 30.0, 60.0, "%s a short walk from the pad (%.0f)" % [e.id, d])
	var west: Vector3 = list[4].pos
	assert_lt(west.x, sp.x - 40.0, "the west lookout is west")
	assert_eq(s.sight_at(sp.x, sp.y), &"", "the pad itself is no sight")


func test_isles_far_out_joined_by_bridges() -> void:
	var s := _venus()
	var v := s.venus
	var sp := v.spawn()
	var isles := 0
	for cz in range(-6, 7):
		for cx in range(-6, 7):
			var i := v.isle(Vector2i(cx, cz))
			if i.is_empty():
				continue
			isles += 1
			var d := Vector2(i[1] - sp.x, i[2] - sp.y).length()
			assert_gt(d, VenusTerrain.ISLE_FROM - 0.5, "no isle near the city's rings")
			assert_eq(s.height_at(i[1], i[2]), VenusTerrain.DECK_Y)
			var east := v.isle(Vector2i(cx + 1, cz))
			if not east.is_empty():
				var mid := Vector2i(roundi((i[1] + east[1]) / 2.0), roundi((i[2] + east[2]) / 2.0))
				assert_eq(s.height_at(mid.x, mid.y), VenusTerrain.DECK_Y, "a bridge to the isle east")
	assert_gt(isles, 40, "isles far out")


func test_the_camp_and_show_decks() -> void:
	var v := _venus().venus
	var camp := v.centre(VenusTerrain.CAMP)
	var show := v.centre(VenusTerrain.SHOW)
	assert_true(v.camp_spot(camp.x, camp.y))
	assert_false(v.camp_spot(show.x, show.y))
	assert_true(v.show_spot(show.x, show.y))
	assert_false(v.show_spot(camp.x, camp.y))


func test_the_same_seed_is_the_same_city() -> void:
	var a := _venus()
	var b := _venus()
	assert_eq(a.spawn_column(), b.spawn_column())
	for i in 60:
		assert_eq(a.height_at(i * 13 - 300, -i * 7 + 200), b.height_at(i * 13 - 300, -i * 7 + 200))
	var flips := {}
	for seed in range(1, 40):
		flips[SpaceShape.new(seed, SpaceShape.VENUS).venus.flip] = true
	assert_eq(flips.size(), 2, "some cities mirrored north-south")


## The Shorts Theater stands on the show deck (never on the homes', the gardens' or the aliens' camp's), Tilly's stall on
## the landing deck, the Monster Totem on it too: every spawner keeps to the platforms.
func test_the_theater_tilly_and_the_totem_stand_on_decks() -> void:
	for seed in SEEDS:
		var s := _venus(seed)
		var v := s.venus
		var site := TheaterSite.pick_for(s)
		assert_false(site.is_empty(), "seed %d: the Theater has a place" % seed)
		var c: Vector3i = site.pos
		for d: Vector2i in [Vector2i.ZERO, Vector2i(4, 4), Vector2i(-4, 4), Vector2i(4, -4), Vector2i(-4, -4)]:
			assert_true(v.show_spot(c.x + d.x, c.z + d.y), "seed %d: on the show deck (%s)" % [seed, c])
		assert_eq(c.y, VenusTerrain.DECK_Y)
		var stall := TraderRules.stall_for_world(seed, s, s.spawn_column())
		var at: Vector3 = stall.pos
		assert_eq(v.platform_at(floori(at.x), floori(at.z))[0], VenusTerrain.LANDING, "seed %d: Tilly on the landing deck" % seed)
		var totem := WaveRules.totem_for_world(seed, s, s.spawn_column(), at)
		var t: Vector3 = totem.pos
		assert_false(v.platform_at(floori(t.x), floori(t.z)).is_empty(), "seed %d: the Totem on a deck (%s)" % [seed, t])
		assert_false(s.is_river(floori(t.x), floori(t.z)))
