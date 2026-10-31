extends GutTest
## Universe 6, the Glow Caves (owner #122): where the Cave Wonders stand and what the generator builds for them
## (GlowWonders). One wonder in each 128 x 128 area that has room for it, its kind in turn (KINDS[(ax + 2 az) mod 5]: the
## nine areas round any spot hold all five, so every kind is near the spawn, and they come back mixed further out), on
## open dry floor under a ceiling high enough for it, never in a shaft, a lake or the spawn clearing, inside its area,
## and never under a secret. Their structures: the grotto's dark floor and listening stone; the drip stone's stalactite
## over a stump and the pillar with its pearls (the steps grow later); the echo fork's mound with three tunnels, the long
## one plugged before a pocket of pearls; the rain carver's granite wall with a limestone door, a basin of rainwater and a
## pocket of pearls behind; the blind fish lake's pool with a pearl on its bottom, a lamp stone and a ripple stone.

const SEED := 20261017
const W := preload("res://core/rules/glow_wonder_rules.gd")

var _shape: GlowShape
var _wonders: GlowWonders
var _all: Array = []


func before_all() -> void:
	_shape = GlowShape.new(SEED)
	_wonders = GlowWonders.new(SEED, _shape)
	for az in range(-4, 4):
		for ax in range(-4, 4):
			var w := _wonders.wonder_in_area(Vector2i(ax, az))
			if not w.is_empty():
				_all.append(w)


func _of(kind: StringName) -> Array:
	return _all.filter(func(w: Dictionary) -> bool: return w.kind == kind)


func test_most_areas_hold_a_wonder_of_their_kind_in_turn() -> void:
	assert_gt(_all.size(), 40, "%d of 64 areas" % _all.size())
	for w: Dictionary in _all:
		var a: Vector2i = w.area
		assert_eq(w.kind, W.KINDS[posmod(a.x + 2 * a.y, W.KINDS.size())], "%s in its turn" % w.id)
	for kind: StringName in W.KINDS:
		assert_gt(_of(kind).size(), 4, "%s: several" % kind)
	var again := GlowWonders.new(SEED, GlowShape.new(SEED))
	assert_eq(again.wonder_in_area(Vector2i(1, -2)), _wonders.wonder_in_area(Vector2i(1, -2)), "the same every time")


func test_every_kind_is_near_the_spawn() -> void:
	var sp := _shape.spawn_column()
	var kinds := {}
	for w: Dictionary in _wonders.wonders_near(Vector3(sp.x, 0, sp.y), 200.0):
		kinds[w.kind] = true
	for kind: StringName in W.KINDS:
		assert_true(kinds.has(kind), "%s within 200 blocks of the spawn: %s" % [kind, kinds.keys()])


func test_wonders_fit_their_caves() -> void:
	var sp := _shape.spawn_column()
	for w: Dictionary in _all:
		var a0: Vector2i = (w.area as Vector2i) * SecretRules.AREA
		var lo: Vector3i = w.lo
		var hi: Vector3i = w.hi
		assert_true(lo.x >= a0.x and lo.z >= a0.y and hi.x <= a0.x + SecretRules.AREA and hi.z <= a0.y + SecretRules.AREA,
			"%s inside its area" % w.id)
		assert_gt(Vector2(w.anchor.x - sp.x, w.anchor.z - sp.y).length(), SecretRules.SPAWN_CLEARING, "%s off the spawn" % w.id)
		for b: Array in w.boxes:   # each box over open, dry floor and under its columns' ceiling
			var blo: Vector3i = b[0]
			var bhi: Vector3i = b[1]
			for z in range(blo.z, bhi.z, 2):
				for x in range(blo.x, bhi.x, 2):
					var c := _shape.column(x, z)
					if c.x == c.y or _shape.in_shaft(x, z) or c.x <= GlowShape.LAKE_LEVEL + 1 or bhi.y > c.y:
						assert_true(false, "%s does not fit at %d,%d (%s, top %d)" % [w.id, x, z, c, bhi.y])
						return
	assert_true(_all.size() > 0)


func test_no_secret_lies_on_a_wonder() -> void:
	var rules := GlowSecretRules.new(SEED, _shape)
	for w: Dictionary in _all:
		for s: Dictionary in rules.secrets_in_area(w.area):
			var overlap: bool = s.lo.x < w.hi.x and w.lo.x < s.hi.x and s.lo.z < w.hi.z and w.lo.z < s.hi.z
			assert_false(overlap, "%s on %s" % [s.id, w.id])


func test_the_grotto_is_dark_round_its_listening_stone() -> void:
	for w: Dictionary in _of(W.GROTTO):
		var c: Vector3i = w.anchor
		assert_eq(_wonders.block_at(c), BlockIds.FLOWSTONE, "its listening stone")
		assert_eq(_wonders.block_at(c + Vector3i(2, -1, 0)), BlockIds.CAVE_STONE, "a dark floor (no moss) for the worms")
		assert_gt(int(w.ceiling), c.y + 5, "a ceiling for the worms over it")


func test_the_drip_stone_and_its_ledge() -> void:
	for w: Dictionary in _of(W.DRIP):
		var tip: Vector3i = w.tip
		var land: Vector3i = w.land
		assert_eq(_wonders.block_at(tip), BlockIds.STALACTITE, "the drop's stalactite")
		assert_eq(Vector2i(tip.x, tip.z), Vector2i(land.x, land.z), "right over the stone it lands on")
		assert_gt(tip.y, land.y + 2)
		assert_eq(_wonders.block_at(land + Vector3i.DOWN), BlockIds.FLOWSTONE, "the stump the drops land on")
		var steps: Array = w.steps
		assert_between(steps.size(), 3, W.STEPS)
		for i in steps.size():
			for cell: Vector3i in steps[i]:
				assert_eq(_wonders.block_at(cell), -1, "step %d grows later (nothing built there now)" % i)
		assert_eq(_wonders.block_at(w.pearls), BlockIds.CAVE_PEARL, "pearls up on the ledge")


func test_the_echo_fork_has_three_tunnels_and_one_goes_through() -> void:
	for w: Dictionary in _of(W.ECHO):
		var lengths: Array = w.lengths
		assert_eq(lengths.size(), 3)
		assert_eq(int(w.long), W.longest(lengths))
		for i in 3:
			var mouth: Vector3i = (w.mouths as Array)[i]
			assert_eq(_wonders.block_at(mouth), BlockIds.AIR, "tunnel %d is open at its mouth" % i)
			assert_eq(_wonders.block_at((w.markers as Array)[i]), BlockIds.SELENITE, "a crystal to tap over it")
		for p: Vector3i in w.plug:
			assert_eq(_wonders.block_at(p), BlockIds.CAVE_STONE, "the long tunnel is closed before its pocket")
		assert_eq(_wonders.block_at(w.pearls), BlockIds.CAVE_PEARL, "pearls in the pocket")
		assert_eq(_wonders.block_at(w.roost), BlockIds.FLOWSTONE, "the bat roost's stone")
		var d: Vector3i = w.dir
		for i in 3:   # three tunnel mouths, never a face: their floors glow, their crystals stand on the ground in front
			var mouth: Vector3i = (w.mouths as Array)[i]
			assert_eq(_wonders.block_at(mouth + Vector3i.DOWN), BlockIds.GLOW_MOSS, "a glowing floor shows the way in")
			var marker: Vector3i = (w.markers as Array)[i]
			assert_eq(marker.y, mouth.y, "the crystal stands on the floor ...")
			assert_eq(marker - mouth, -d, "... in front of its mouth")
			assert_true(BlockIds.is_solid(_wonders.block_at(marker + Vector3i.DOWN)), "... on solid ground")
		_assert_rounded(w)


## A mound is no box: its top corners are cut (air there, or nothing built).
func _assert_rounded(w: Dictionary) -> void:
	var lo: Vector3i = w.lo
	var hi: Vector3i = w.hi
	var top := hi.y - 1
	for corner: Vector3i in [Vector3i(lo.x, top, lo.z), Vector3i(hi.x - 1, top, lo.z), Vector3i(lo.x, top, hi.z - 1),
			Vector3i(hi.x - 1, top, hi.z - 1)]:
		assert_true(_wonders.block_at(corner) in [-1, BlockIds.AIR], "%s: no square corner at %s" % [w.id, corner])


func test_the_rain_carver_wall_is_granite_with_a_limestone_door() -> void:
	for w: Dictionary in _of(W.RAIN):
		for p: Vector3i in w.limestone:
			assert_eq(_wonders.block_at(p), BlockIds.LIMESTONE, "a pale limestone door: rainwater opens it")
		for p: Vector3i in w.granite:
			assert_eq(_wonders.block_at(p), BlockIds.GRANITE, "granite: it never does")
		assert_eq(_wonders.block_at(w.basin), BlockIds.WATER, "a basin of rainwater")
		assert_eq(_wonders.block_at(w.pearls), BlockIds.CAVE_PEARL, "pearls behind the wall")
		_assert_rounded(w)


func test_the_blind_fish_lake() -> void:
	for w: Dictionary in _of(W.LAKE):
		assert_eq(_wonders.block_at(w.pearl), BlockIds.CAVE_PEARL, "a pearl on the bottom")
		assert_eq(_wonders.block_at(w.pearl + Vector3i.UP), BlockIds.WATER, "under the water")
		assert_eq(_wonders.block_at(w.lamp), BlockIds.SPORE_LAMP, "a lamp stone")
		assert_eq(_wonders.block_at(w.ripple), BlockIds.FLOWSTONE, "a ripple stone at the water's edge")


## The generator builds them (the reference block, wonders included).
func test_the_generator_writes_the_wonders() -> void:
	var gen := GlowGenerator.new()
	gen.world_seed = SEED
	var w: Dictionary = _of(W.RAIN)[0]
	var door: Vector3i = (w.limestone as Array)[0]
	assert_eq(gen.reference_block(door.x, door.y, door.z), BlockIds.LIMESTONE)
	var granite: Vector3i = (w.granite as Array)[0]
	assert_eq(gen.reference_block(granite.x, granite.y, granite.z), BlockIds.GRANITE)
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	var origin := Vector3i(floori(granite.x / 16.0), floori(granite.y / 16.0), floori(granite.z / 16.0)) * 16
	gen._generate_block(buf, origin, 0)
	var l := granite - origin
	assert_eq(buf.get_voxel(l.x, l.y, l.z, VoxelBuffer.CHANNEL_TYPE), BlockIds.GRANITE, "in the chunk too")
