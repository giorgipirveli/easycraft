extends GutTest
## Owner #78 (spec §24), the third tour: world 41's terrain as the game streams it (WondersGenerator, chunk by chunk) in
## the nature region: the builds and secrets exactly as WonderBuilds and WondersSecretRules say, the canyon's rock
## layers and its river, the falls' river, curtain, pool and spray, the reef's coral under the water, the cornfield, the
## frozen lake, Everest's snow, no cave anywhere under the region, the Nature Trail's dirt.

const Y := WonderTour.BASE_Y
const SEED := 20261001
const G := preload("res://world/wonders/nature_ground.gd")

var gen: WondersGenerator
var rules: WondersSecretRules
var _chunks := {}


func before_all() -> void:
	gen = WondersGenerator.new()
	gen.world_seed = SEED
	rules = WondersSecretRules.new(SEED, gen.wonders_shape())


## The block the generator writes at world cell p (its chunk generated once).
func _block(p: Vector3i) -> int:
	var origin := Vector3i(floori(p.x / 16.0), floori(p.y / 16.0), floori(p.z / 16.0)) * 16
	var buf: VoxelBuffer = _chunks.get(origin)
	if buf == null:
		buf = VoxelBuffer.new()
		buf.create(16, 16, 16)
		gen._generate_block(buf, origin, 0)
		_chunks[origin] = buf
	var l := p - origin
	return buf.get_voxel(l.x, l.y, l.z, VoxelBuffer.CHANNEL_TYPE)


func _at(id: StringName, x: int, y: int, z: int) -> Vector3i:
	var q := WonderTour.to_world(id, Vector2i(x, z))
	return Vector3i(q.x, Y + y, q.y)


func test_each_natural_wonders_builds_and_secret_are_in_their_chunks() -> void:
	for id: StringName in WonderFacts.tour_ids(&"nature"):
		var checked := 0
		for box: Array in WonderBuilds.boxes(id):
			var lo: Vector3i = box[0]
			var hi: Vector3i = box[1]
			for p: Vector3i in [lo, hi - Vector3i.ONE, (lo + hi) / 2]:
				var want := rules.block_at(p)
				if want < 0:
					want = WonderBuilds.block_at(p)
				if want < 0:
					continue
				checked += 1
				assert_eq(_block(p), want, "%s at %s" % [id, p])
		assert_gt(checked, 10, "%s checked" % id)
		var s := rules.secret_of(id)
		if s.has("fake_wall"):
			for c: Vector3i in s.fake_wall:
				assert_eq(_block(c), rules.block_at(c), "%s's fake door at %s" % [id, c])


func test_the_canyons_walls_show_their_layers_and_its_river_runs_in_its_bottom() -> void:
	var mid := roundi(G.canyon_middle(0))
	var bottom := _at(&"grand_canyon", 0, G.RIVER_BED - Y, mid)
	assert_eq(_block(bottom), BlockIds.WATER, "the Colorado River")
	assert_eq(_block(bottom + Vector3i.DOWN), BlockIds.VISHNU_SCHIST, "on the oldest rock")
	var seen := {}
	for d in range(0, 30):
		var c := _at(&"grand_canyon", 0, 0, mid - d)
		var h := gen.wonders_shape().height_at(c.x, c.z)
		seen[_block(Vector3i(c.x, h - 1, c.z))] = true
	for layer: int in [BlockIds.VISHNU_SCHIST, BlockIds.CANYON_SHALE, BlockIds.REDWALL_LIMESTONE, BlockIds.SUPAI_REDBED,
			BlockIds.COCONINO_SANDSTONE]:
		assert_true(seen.has(layer), "%s shows on the walls" % BlockIds.display_name(layer))
	var rim := _at(&"grand_canyon", 0, G.PLATEAU_TOP - Y - 1, -G.PLATEAU_FLAT.y)
	assert_eq(_block(rim), BlockIds.GRASS, "grass on the plateau")
	assert_eq(_block(rim + Vector3i(0, -3, 0)), BlockIds.KAIBAB_LIMESTONE, "over the Kaibab limestone")


func test_the_falls_pour_into_the_pool_and_their_spray_rises() -> void:
	var f := G.FALLS_C
	assert_eq(_block(Vector3i(f.x, G.POOL_BED, f.y)), BlockIds.WATER, "the pool")
	assert_eq(_block(Vector3i(f.x, G.POOL_BED - 1, f.y)), BlockIds.BLACK_LAVA, "the chasm of basalt")
	assert_eq(_block(_at(&"victoria_falls", -15, -10, G.CHASM_Z.y)), BlockIds.WATER, "the falling water")
	assert_eq(_block(_at(&"victoria_falls", -10, -1, 20)), BlockIds.WATER, "the river above the falls")
	assert_eq(_block(_at(&"victoria_falls", -10, -4, 20)), BlockIds.SAND, "on its bed")
	var spray := 0
	for x in range(f.x - 24, f.x + 25):
		for y in range(G.SPRAY_LOW, G.SPRAY_HIGH + 1):
			spray += 1 if _block(Vector3i(x, y, f.y)) == BlockIds.SPRAY else 0
	assert_gt(spray, 40, "the smoke that thunders: spray rising over the chasm (%d)" % spray)


func test_the_reefs_corals_grow_under_the_water() -> void:
	var k := G.REEF_C
	var corals := 0
	for x in range(k.x - 24, k.x + 25):
		var p := Vector3i(x, G.REEF_FLOOR, k.y + 14)
		var b := _block(p)
		if b in [BlockIds.BRAIN_CORAL, BlockIds.STAGHORN_CORAL, BlockIds.SEA_FAN]:
			corals += 1
			assert_eq(_block(Vector3i(x, G.SEA - 1, p.z)), BlockIds.WATER, "water over the coral")
	assert_gt(corals, 4, "coral heads on the reef flat (%d)" % corals)
	assert_eq(_block(Vector3i(k.x, G.CAY_TOP - 1, k.y)), BlockIds.SAND, "the sandy cay")


func test_the_cornfield_the_frozen_lake_everests_snow_and_the_lava() -> void:
	var p := G.PARICUTIN_C
	var corn := 0
	for x in range(p.x - 30, p.x + 30):
		corn += 1 if _block(Vector3i(x, Y, p.y + 46)) == BlockIds.CORN else 0
	assert_gt(corn, 10, "corn round Parícutin (%d)" % corn)
	assert_eq(_block(Vector3i(p.x, Y + G.CRATER_FLOOR - 1, p.y)), BlockIds.HOT_LAVA, "the crater's lava")
	assert_eq(_block(_at(&"paricutin", 0, G.CONE_TOP - 1, -8)), BlockIds.CINDER, "a cone of cinders")
	var lake := _at(&"northern_lights", int(G.LAKE.x), -1, int(G.LAKE.y))
	assert_eq(_block(lake), BlockIds.ICE, "the frozen lake")
	assert_eq(_block(lake + Vector3i.DOWN), BlockIds.WATER, "water under its ice")
	var e := G.EVEREST_C
	var snow := 0
	for dz in range(-12, 13, 3):
		var x := e.x + 8
		var h := gen.wonders_shape().height_at(x, e.y + dz)
		if h - Y >= G.SNOW_LINE:
			snow += 1 if _block(Vector3i(x, h - 1, e.y + dz)) in [BlockIds.SNOW, BlockIds.PACKED_SNOW] else 0
	assert_gt(snow, 2, "snow on Everest's top (%d)" % snow)


func test_no_cave_under_the_region_and_the_nature_trails_dirt() -> void:
	var shape := gen.wonders_shape()
	for c: Vector2i in [Vector2i(165, 410), Vector2i(60, 300), Vector2i(250, 560), Vector2i(-30, 450)]:
		var h := shape.height_at(c.x, c.y)
		for y in range(maxi(h - 30, -40), h - 4, 3):
			assert_ne(_block(Vector3i(c.x, y, c.y)), BlockIds.AIR, "no cave under %s at y %d" % [c, y])
	var trail := WonderTour.trail()
	var cells := WonderTour.line_cells(trail[0], trail[1])
	for i in range(0, cells.size(), 40):
		var c: Vector2i = cells[i]
		assert_has([BlockIds.DIRT, BlockIds.SPEED_PAD], _block(Vector3i(c.x, Y - 1, c.y)), "the trail at %s" % c)
