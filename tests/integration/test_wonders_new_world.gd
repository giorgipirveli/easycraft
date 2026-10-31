extends GutTest
## Owner #78 (spec §24), the second tour: world 41's terrain as the game streams it (WondersGenerator, chunk by chunk)
## round the New Seven Wonders: each wonder built into its chunks exactly as WonderBuilds says and its secret carved
## after it, no cave under the region, Petra's sand, Corcovado's grass, the Wonders Road's paving and speed pads.

const Y := WonderTour.BASE_Y
const SEED := 20260930

var gen: WondersGenerator
var rules: WondersSecretRules


func before_all() -> void:
	gen = WondersGenerator.new()
	gen.world_seed = SEED
	rules = WondersSecretRules.new(SEED, gen.wonders_shape())


func _chunk(origin: Vector3i) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	gen._generate_block(buf, origin, 0)
	return buf


func _origin(p: Vector3i) -> Vector3i:
	return Vector3i(floori(p.x / 16.0), floori(p.y / 16.0), floori(p.z / 16.0)) * 16


func _at(buf: VoxelBuffer, origin: Vector3i, p: Vector3i) -> int:
	var l := p - origin
	return buf.get_voxel(l.x, l.y, l.z, VoxelBuffer.CHANNEL_TYPE)


## Every cell the tours or their secrets put in the two chunks at `center` is there.
func _matches(center: Vector3i) -> int:
	var checked := 0
	var o0 := _origin(center)
	for dy: int in [0, 16]:
		var origin := o0 + Vector3i(0, dy, 0)
		var buf := _chunk(origin)
		for y in 16:
			for z in 16:
				for x in 16:
					var p := origin + Vector3i(x, y, z)
					var want := rules.block_at(p)
					if want < 0:
						want = WonderBuilds.block_at(p)
					if want < 0:
						continue
					checked += 1
					if _at(buf, origin, p) != want:
						assert_eq(_at(buf, origin, p), want, "at %s" % p)
						return checked
	return checked


func test_the_new_seven_are_built_into_their_chunks() -> void:
	for id: StringName in WonderFacts.tour_ids(&"new"):
		var c := WonderTour.centre(id)
		var n := _matches(Vector3i(c.floor()) + Vector3i(0, 4, 0))
		assert_gt(n, 100, "%s's blocks in its chunks (%d)" % [id, n])


func test_their_secrets_are_carved_after_them() -> void:
	for id: StringName in [&"great_wall", &"colosseum", &"chichen_itza", &"machu_picchu", &"christ_redeemer"]:
		var s := rules.secret_of(id)
		var fake: Vector3i = s.fake_wall[0]
		var o := _origin(fake)
		assert_true(SecretRules.is_fake_wall(_at(_chunk(o), o, fake)), "%s's fake door" % id)
		var room: Vector3i = s.inside[0]
		var ro := _origin(room)
		assert_eq(_at(_chunk(ro), ro, room), BlockIds.AIR, "%s's hidden room" % id)


func test_no_cave_opens_under_the_second_tour() -> void:
	for origin: Vector3i in [Vector3i(-352, -32, 0), Vector3i(-464, 0, -64), Vector3i(-336, 0, 96), Vector3i(-256, -16, 48)]:
		var buf := _chunk(origin)
		var air := 0
		for y in 16:
			for z in 16:
				for x in 16:
					if buf.get_voxel(x, y, z, VoxelBuffer.CHANNEL_TYPE) == BlockIds.AIR:
						air += 1
		assert_eq(air, 0, "solid rock under the tour at %s" % origin)


func test_the_road_the_square_petras_sand_and_corcovados_grass() -> void:
	var sq := WonderTour.NEW_SQUARE
	var so := _origin(Vector3i(sq.x, Y - 1, sq.y))
	assert_eq(_at(_chunk(so), so, Vector3i(sq.x, Y - 1, sq.y)), BlockIds.PAVING, "the New Seven's square")
	var pad := Vector3i(WonderTour.road_pads()[3], Y - 1, 0)
	var po := _origin(pad)
	var pb := _chunk(po)
	assert_eq(_at(pb, po, pad), BlockIds.SPEED_PAD, "a speed pad across the Wonders Road")
	assert_eq(_at(pb, po, pad + Vector3i(4, 0, 0)), WonderTour.ROAD_BLOCK, "the road's sand")
	var sand := WonderTour.to_world(&"petra", Vector2i(-12, -30))
	var s := Vector3i(sand.x, Y - 1, sand.y)
	var sao := _origin(s)
	assert_eq(_at(_chunk(sao), sao, s), BlockIds.SAND, "Petra's desert")
	var c: Vector2i = WonderTour.WONDERS[&"christ_redeemer"].centre
	var slope := Vector2i(c.x + 30, c.y)
	var h := gen.wonders_shape().height_at(slope.x, slope.y)
	assert_gt(h, Y + 8, "Corcovado rises")
	var top := Vector3i(slope.x, h - 1, slope.y)
	var to := _origin(top)
	assert_eq(_at(_chunk(to), to, top), BlockIds.GRASS, "green on its slopes")
