extends GutTest
## Owner feedback #45b (spec §14.18): places to find in the wild meadows (MeadowsPlaces): windmills, villages,
## lookout towers, lighthouses, ships at a pier, castle ruins, towns. At most one per 256 x 256 region, from the
## seed alone; rarer farther from the spawn; never within 60 blocks of the spawn, never on a secret's ground, never
## cutting into water or cliffs; every one can be walked into and every stair climbed.

const SEED := 12345
const R := 12                     # regions -R..R-1 on both axes (about 6 km across)

var shape: MeadowsBiomeShape
var rules: SecretRules
var places: MeadowsPlaces
var _all: Array = []


func before_all() -> void:
	shape = MeadowsBiomeShape.new(SEED)
	rules = SecretRules.new(SEED, shape)
	places = MeadowsPlaces.new(SEED, shape, rules)
	for rz in range(-R, R):
		for rx in range(-R, R):
			_all.append_array(places.places_in_region(Vector2i(rx, rz)))
	var kinds := {}
	for p: Dictionary in _all:
		kinds[p.kind] = int(kinds.get(p.kind, 0)) + 1
	gut.p("%d places in %d regions: %s" % [_all.size(), 4 * R * R, kinds])


func _of(kind: StringName) -> Array:
	return _all.filter(func(p: Dictionary) -> bool: return p.kind == kind)


func _spawn_distance(p: Dictionary) -> float:
	var a: Vector3i = p.anchor
	return Vector2(a.x, a.z).distance_to(Vector2(places.spawn))


# --- The rules of placement ---

func test_the_same_world_always_has_the_same_places() -> void:
	var again := MeadowsPlaces.new(SEED, MeadowsBiomeShape.new(SEED))
	for rz in range(-3, 3):
		for rx in range(-3, 3):
			var a: Array = places.places_in_region(Vector2i(rx, rz))
			var b: Array = again.places_in_region(Vector2i(rx, rz))
			assert_eq(a.size(), b.size())
			for i in mini(a.size(), b.size()):
				assert_eq(a[i].id, b[i].id)
				assert_eq(a[i].boxes, b[i].boxes)
				assert_eq(a[i].name, b[i].name)


func test_every_kind_is_somewhere() -> void:
	for kind: StringName in MeadowsPlaces.KINDS:
		assert_gt(_of(kind).size(), 0, "a %s within 3 km" % kind)


func test_ids_names_and_lookups() -> void:
	for p: Dictionary in _all:
		assert_true(MeadowsPlaces.is_place_id(p.id), p.id)
		assert_eq(p.id.validate_node_name(), p.id)
		assert_ne(String(p.name), "", p.id)
		assert_eq(places.find(p.id).get("anchor"), p.anchor, p.id)
		assert_eq(MeadowsPlaces.region_of(p.anchor.x, p.anchor.z), p.region)
	assert_false(MeadowsPlaces.is_place_id("treasure_1_2_0"))
	assert_false(MeadowsPlaces.is_place_id("village_x_2"))
	assert_eq(places.find("village_999_999"), {})
	var some: Dictionary = _all[0]
	var near := places.places_near(Vector3(some.anchor), 5.0)
	assert_true(near.any(func(p: Dictionary) -> bool: return p.id == some.id))
	assert_eq(places.nearest(Vector3(some.anchor)).get("id"), some.id)


func test_they_stay_inside_their_region_and_one_per_region() -> void:
	var seen := {}
	for p: Dictionary in _all:
		var r0: Vector2i = p.region * MeadowsPlaces.REGION
		assert_true(p.lo.x >= r0.x and p.lo.z >= r0.y and p.hi.x <= r0.x + MeadowsPlaces.REGION \
			and p.hi.z <= r0.y + MeadowsPlaces.REGION, p.id)
		assert_false(seen.has(p.region), "one place in region %s" % p.region)
		seen[p.region] = true


func test_never_near_the_spawn() -> void:
	var sp := places.spawn
	for p: Dictionary in _all:
		var dx := maxi(maxi(p.lo.x - sp.x, sp.x - (p.hi.x - 1)), 0)
		var dz := maxi(maxi(p.lo.z - sp.y, sp.y - (p.hi.z - 1)), 0)
		assert_gte(Vector2(dx, dz).length(), MeadowsPlaces.CLEAR_OF_SPAWN, p.id)
	assert_gte(MeadowsPlaces.CLEAR_OF_SPAWN, TreasurePlaces.CLEAR_OF_SPAWN, "at least the treasure pack's clear zone")


## The secrets never move for a place: a place gives way to every secret (and the treasure pack's places).
func test_never_on_a_secrets_ground() -> void:
	var checked := 0
	for p: Dictionary in _all:
		var a0 := SecretRules.area_of(p.lo.x - MeadowsPlaces.GAP, p.lo.z - MeadowsPlaces.GAP)
		var a1 := SecretRules.area_of(p.hi.x + MeadowsPlaces.GAP, p.hi.z + MeadowsPlaces.GAP)
		for az in range(a0.y, a1.y + 1):
			for ax in range(a0.x, a1.x + 1):
				for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
					checked += 1
					var apart: bool = p.hi.x + MeadowsPlaces.GAP <= s.lo.x or s.hi.x + MeadowsPlaces.GAP <= p.lo.x \
						or p.hi.z + MeadowsPlaces.GAP <= s.lo.z or s.hi.z + MeadowsPlaces.GAP <= p.lo.z \
						or p.hi.y + MeadowsPlaces.GAP <= s.lo.y or s.hi.y + MeadowsPlaces.GAP <= p.lo.y
					assert_true(apart, "%s and %s share ground" % [p.id, s.id])
	assert_gt(checked, 50)
	# and the M2 secrets and the treasure pack's stay where they were for this terrain
	var alone := SecretRules.new(SEED, MeadowsBiomeShape.new(SEED))
	for az in range(-2, 2):
		for ax in range(-2, 2):
			var before: Array = alone.secrets_in_area(Vector2i(ax, az))
			var now: Array = rules.secrets_in_area(Vector2i(ax, az))
			assert_eq(now.size(), before.size())
			for i in mini(now.size(), before.size()):
				assert_eq(now[i].id, before[i].id)
				assert_eq(now[i].boxes, before[i].boxes)


# --- Rarer farther away ---

func test_every_places_rarity_against_the_distance() -> void:
	for p: Dictionary in _all:
		assert_gte(_spawn_distance(p), float(MeadowsPlaces.RARITY[p.kind].from), "%s is %.0f blocks out" % [p.id, _spawn_distance(p)])
	assert_eq(MeadowsPlaces.kinds_at(100.0), [MeadowsPlaces.WINDMILL] as Array[StringName], "by the spawn: windmills only")
	assert_true(MeadowsPlaces.kinds_at(5000.0).has(MeadowsPlaces.TOWN))
	assert_gt(MeadowsPlaces.chance_at(3000.0), MeadowsPlaces.chance_at(300.0), "more places farther out")
	var near := {"n": 0, "rare": 0}
	var far := {"n": 0, "rare": 0}
	for p: Dictionary in _all:
		var bucket := near if _spawn_distance(p) < 1200.0 else far
		bucket.n += 1
		if p.kind in [MeadowsPlaces.SHIP, MeadowsPlaces.CASTLE, MeadowsPlaces.TOWN]:
			bucket.rare += 1
	gut.p("rare places: %d of %d near, %d of %d far" % [near.rare, near.n, far.rare, far.n])
	assert_gt(far.rare / float(maxi(far.n, 1)), near.rare / float(maxi(near.n, 1)), "rarer kinds farther away")
	var regions_near := 0
	var with_near := 0
	var regions_far := 0
	var with_far := 0
	for rz in range(-R, R):
		for rx in range(-R, R):
			var mid := Vector2((rx + 0.5) * MeadowsPlaces.REGION, (rz + 0.5) * MeadowsPlaces.REGION)
			var has := not places.places_in_region(Vector2i(rx, rz)).is_empty()
			if mid.distance_to(Vector2(places.spawn)) < 1200.0:
				regions_near += 1
				with_near += 1 if has else 0
			else:
				regions_far += 1
				with_far += 1 if has else 0
	assert_gt(with_far / float(regions_far), with_near / float(regions_near), "a place in more regions farther out")


# --- Built right ---

## A village's houses, farm and plaza stand on dry, gentle ground: every column under them is dry land off the
## rivers, and the floor is within SLOPE of the ground (no cliff cut, no hill buried).
func test_villages_never_cut_into_water_or_cliffs() -> void:
	var villages := _of(MeadowsPlaces.VILLAGE) + _of(MeadowsPlaces.TOWN)
	assert_gt(villages.size(), 2)
	for v: Dictionary in villages:
		var houses: Array = v.houses
		assert_gte(houses.size(), 3, v.id)
		for h: Array in houses:
			var lo: Vector3i = h[0]
			var hi: Vector3i = h[1]
			var floor_y: int = h[2]
			for z in range(lo.z, hi.z):
				for x in range(lo.x, hi.x):
					var c := shape.column(x, z)
					assert_gt(c.x, MeadowsShape.SEA_LEVEL + 1, "%s: dry at %d %d" % [v.id, x, z])
					assert_eq(c.z & MeadowsBiomeShape.F_RIVER, 0, "%s: no river at %d %d" % [v.id, x, z])
					assert_lte(absi(c.x - floor_y), MeadowsPlaces.SLOPE + 1, "%s: gentle at %d %d" % [v.id, x, z])
		assert_between((v.villagers as Array).size(), 2, 16, v.id)


func test_every_door_opens_on_ground_you_can_stand_on() -> void:
	var doors := 0
	for p: Dictionary in _all:
		for d: Array in p.get("doors", []):
			var door: Vector3i = d[0]
			var front: Vector3i = d[1]
			doors += 1
			assert_true(_walkable(door), "%s: its door %s is open" % [p.id, door])
			assert_true(_walkable(door + Vector3i.UP), "%s: two blocks high" % p.id)
			assert_true(_walkable(front) and _walkable(front + Vector3i.UP), "%s: room in front of the door %s" % [p.id, front])
			assert_true(_solid(front + Vector3i.DOWN), "%s: ground in front of the door %s" % [p.id, front])
	assert_gt(doors, 20)


## Every step of a tower's or a lighthouse's stair is one block above the one before, next to it, with room over
## it, and the last one leads onto the top.
func test_every_stair_can_be_climbed() -> void:
	var climbed := 0
	for p: Dictionary in _of(MeadowsPlaces.TOWER) + _of(MeadowsPlaces.LIGHTHOUSE):
		var steps: Array = p.stairs
		assert_gt(steps.size(), 10, p.id)
		var door: Vector3i = p.doors[0][0]
		assert_eq((steps[0] as Vector3i).y, door.y, "%s: the first step is at the door's floor" % p.id)
		for i in steps.size():
			var st: Vector3i = steps[i]
			assert_true(_solid(st), "%s: step %d is there" % [p.id, i])
			assert_true(_walkable(st + Vector3i.UP) and _walkable(st + Vector3i.UP * 2), "%s: room over step %d" % [p.id, i])
			if i > 0:
				var prev: Vector3i = steps[i - 1]
				assert_eq(st.y, prev.y + 1, "%s: step %d climbs one" % [p.id, i])
				assert_lte(absi(st.x - prev.x) + absi(st.z - prev.z), 2, "%s: step %d is next to the one before" % [p.id, i])
		var last: Vector3i = steps[steps.size() - 1]
		var top: Vector3i = p.top
		assert_true(_walkable(top), "%s: the top is open" % p.id)
		assert_eq(top.y, last.y + 2, "%s: one step from the last step up onto the top" % p.id)
		climbed += 1
	assert_gt(climbed, 1)


func test_a_ship_floats_in_deep_water_and_its_pier_reaches_the_shore() -> void:
	var ships := _of(MeadowsPlaces.SHIP)
	assert_gt(ships.size(), 0)
	for p: Dictionary in ships:
		var pier: Array = p.pier
		var land: Vector3i = pier[1]
		var c := shape.column(land.x, land.z)
		assert_gt(c.x, MeadowsShape.SEA_LEVEL + 1, "%s: the pier ends on land" % p.id)
		var deck: Vector3i = p.anchor
		assert_true(_solid(deck + Vector3i.DOWN), "%s: a deck to stand on" % p.id)
		assert_eq(places.block_at(deck + Vector3i.DOWN * 3), BlockIds.AIR, "%s: dry inside the hull" % p.id)


func test_a_lighthouse_stands_by_the_sea_with_its_lamp_lit() -> void:
	for p: Dictionary in _of(MeadowsPlaces.LIGHTHOUSE):
		var boxes: Array = p.boxes
		assert_true(boxes.any(func(b: Array) -> bool: return b[2] == BlockIds.GOLD_LAMP), p.id)
		var a: Vector3i = p.anchor
		var sea := 0
		for d in range(5, 21):
			for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if shape.height_at(a.x + dir.x * d, a.z + dir.y * d) < MeadowsShape.SEA_LEVEL:
					sea += 1
		assert_gt(sea, 0, "%s: the sea is near" % p.id)


func _block(p: Vector3i) -> int:
	var id := places.block_at(p)
	if id >= 0:
		return id
	return shape.block_in_column(p.y, shape.column(p.x, p.z), MeadowsShape.WORLD_BOTTOM)


func _walkable(p: Vector3i) -> bool:
	var id := _block(p)
	return id == BlockIds.AIR or not BlockIds.is_solid(id)


func _solid(p: Vector3i) -> bool:
	return BlockIds.is_solid(_block(p))
