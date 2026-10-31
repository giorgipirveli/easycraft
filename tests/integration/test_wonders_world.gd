extends GutTest
## Owner #78 (spec §24): world 41's terrain as the game streams it (WondersGenerator, chunk by chunk): the wonders built
## into their chunks exactly as WonderBuilds says, the secrets carved after them, no cave under the tour, Giza's sand,
## the sea to the north-east with its island, the landing square's paving, wild flowers and trees in the park, and the
## trip's saves: landing there from the Star Map writes its own slot, remembers home and builds the portal home.

const Y := WonderTour.BASE_Y
const SEED := 20260930

var gen: WondersGenerator
var rules: WondersSecretRules
var SLOT := "test_wonders_%d" % OS.get_process_id()


func before_all() -> void:
	gen = WondersGenerator.new()
	gen.world_seed = SEED
	rules = WondersSecretRules.new(SEED, gen.wonders_shape())


func after_all() -> void:
	WorldSaves.delete(SLOT)


func _chunk(origin: Vector3i) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	gen._generate_block(buf, origin, 0)
	return buf


func _at(buf: VoxelBuffer, origin: Vector3i, p: Vector3i) -> int:
	var l := p - origin
	return buf.get_voxel(l.x, l.y, l.z, VoxelBuffer.CHANNEL_TYPE)


## Every cell of the chunks round point `p` is what the tour and its secrets put there.
func _matches(center: Vector3i) -> int:
	var checked := 0
	var o0 := Vector3i(floori(center.x / 16.0), floori(center.y / 16.0), floori(center.z / 16.0)) * 16
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
					assert_eq(_at(buf, origin, p), want, "at %s" % p)
					if _at(buf, origin, p) != want:
						return checked
	return checked


func test_the_wonders_are_built_into_their_chunks() -> void:
	for id in WonderTour.ids():
		if WonderFacts.tour_of(id) == &"nature":
			continue   # nature's wonders are the ground's, their builds round them (test_wonders_nature_world)
		var c := WonderTour.centre(id)
		var n := _matches(Vector3i(c.floor()) + Vector3i(0, 4, 0))
		assert_gt(n, 100, "%s's blocks in its chunks (%d)" % [id, n])


func test_the_secrets_are_carved_after_the_wonders() -> void:
	var s := rules.secret_of(&"pyramid")
	var fake: Vector3i = s.fake_wall[0]
	var o := Vector3i(floori(fake.x / 16.0), floori(fake.y / 16.0), floori(fake.z / 16.0)) * 16
	assert_eq(_at(_chunk(o), o, fake), BlockIds.FAKE_LIMESTONE, "the hidden room's fake block in the gallery wall")
	var room: Vector3i = s.inside[0]
	var ro := Vector3i(floori(room.x / 16.0), floori(room.y / 16.0), floori(room.z / 16.0)) * 16
	assert_eq(_at(_chunk(ro), ro, room), BlockIds.AIR, "the hidden room inside the pyramid's stone")


func test_no_cave_opens_under_the_tour() -> void:
	for origin: Vector3i in [Vector3i(0, -32, 0), Vector3i(-16, 0, 96), Vector3i(-96, -16, -64), Vector3i(96, 0, 64)]:
		var buf := _chunk(origin)
		var air := 0
		for y in 16:
			for z in 16:
				for x in 16:
					if buf.get_voxel(x, y, z, VoxelBuffer.CHANNEL_TYPE) == BlockIds.AIR:
						air += 1
		assert_eq(air, 0, "solid rock under the tour at %s" % origin)


func test_the_ground_sand_sea_island_and_square() -> void:
	var o := Vector3i(0, 16, 0)
	var buf := _chunk(o)
	assert_eq(_at(buf, o, Vector3i(0, Y - 1, 0)), BlockIds.PAVING, "the landing square")
	assert_eq(_at(buf, o, Vector3i(3, Y - 2, 12)), BlockIds.DIRT, "grass land under the park")
	var g := WonderTour.to_world(&"pyramid", Vector2i(-12, -28))
	var go := Vector3i(floori(g.x / 16.0) * 16, 16, floori(g.y / 16.0) * 16)
	assert_eq(_at(_chunk(go), go, Vector3i(g.x, Y - 1, g.y)), BlockIds.SAND, "Giza's sand")
	var sea := Vector3i(144, 16, -96)
	var sb := _chunk(sea)
	assert_eq(_at(sb, sea, Vector3i(150, MeadowsShape.SEA_LEVEL - 1, -90)), BlockIds.WATER, "the sea")
	assert_eq(_at(sb, sea, Vector3i(150, WonderTour.SEA_FLOOR - 1, -90)), BlockIds.SAND, "its sandy floor")
	var i := WonderTour.ISLAND + Vector2i(-9, 6)
	var io := Vector3i(floori(i.x / 16.0) * 16, 16, floori(i.y / 16.0) * 16)
	assert_eq(_at(_chunk(io), io, Vector3i(i.x, Y - 1, i.y)), BlockIds.SAND, "the island's top")


func test_the_park_has_wild_flowers_and_trees_of_their_place() -> void:
	var flowers := 0
	var olive := 0
	for ox in range(-176, -80, 16):
		for oz in range(-16, 16, 16):
			var o := Vector3i(ox, Y, oz)
			var buf := _chunk(o)
			for z in 16:
				for x in 16:
					if buf.get_voxel(x, 0, z, VoxelBuffer.CHANNEL_TYPE) == BlockIds.FLOWERS:
						flowers += 1
					for y in range(0, 8):
						if buf.get_voxel(x, y, z, VoxelBuffer.CHANNEL_TYPE) == BlockIds.OLIVE_LEAVES:
							olive += 1
	assert_gt(flowers, 0, "wild flowers in the grass")
	assert_gt(olive, 0, "olive trees to the west")


func test_landing_there_writes_its_own_save_with_the_way_home() -> void:
	var home := WorldMeta.new_random()
	home.universe = 3
	var hotbar: Array[int] = [BlockIds.STONE, 0, 0, 0, 0, 0, 0, 0, 0]
	var m := SpaceTrip.arrival(home, EarthRules.WONDERS, ModeRules.SANDBOX, SLOT, "Mia", [], hotbar, 0)
	assert_eq(m.universe, 41)
	var back := WorldSaves.load_meta(SLOT)
	assert_eq(back.universe, 41, "the number is saved")
	assert_eq(back.space_home, 3, "home is Frostpeak")
	assert_eq(back.arrival_gate, 3, "the portal home stands by the landing spot")
	assert_eq(SpaceRules.home_for(back.universe, back.space_home), 3)
