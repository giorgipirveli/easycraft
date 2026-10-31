extends GutTest
## Owner #78 (spec §24), the third tour: the ground of world 41's nature region (NatureGround through WondersShape): the
## canyon carved into its plateau with its rock layers in order and a river in its bottom, Parícutin's cone and crater in
## its cornfield with the lava field behind, the snowy valley's frozen lake, Everest over Lhotse and the South Col, the
## falls' river, chasm and pool, the bay with the Sugarloaf, the reef's cay and shallow flat, the sea, the snow, the trees
## (pines in the snow, a rainforest facing the falls, never on a build). Everything stays inside the streamed height.

const Y := WonderTour.BASE_Y
const G := preload("res://world/wonders/nature_ground.gd")

var shape: WondersShape


func before_all() -> void:
	shape = WondersShape.new(777)


func _h(x: int, z: int) -> int:
	return shape.height_at(x, z)


## The world cell of wonder `id`'s frame (x, z).
func _w(id: StringName, x: int, z: int) -> Vector2i:
	return WonderTour.to_world(id, Vector2i(x, z))


func test_the_grounds_copies_of_the_wonders_places_match() -> void:
	assert_eq(G.CANYON_C, WonderTour.WONDERS[&"grand_canyon"].centre)
	assert_eq(WonderTour.WONDERS[&"grand_canyon"].face, WonderTour.W, "(the canyon's sums take it facing west)")
	assert_eq(G.PARICUTIN_C, WonderTour.WONDERS[&"paricutin"].centre)
	assert_eq(WonderTour.WONDERS[&"paricutin"].face, WonderTour.S)
	assert_eq(G.AURORA_C, WonderTour.WONDERS[&"northern_lights"].centre)
	assert_eq(WonderTour.WONDERS[&"northern_lights"].face, WonderTour.E)
	assert_eq(G.EVEREST_C, WonderTour.WONDERS[&"everest"].centre)
	assert_eq(WonderTour.WONDERS[&"everest"].face, WonderTour.E)
	assert_eq(G.FALLS_C, WonderTour.WONDERS[&"victoria_falls"].centre)
	assert_eq(WonderTour.WONDERS[&"victoria_falls"].face, WonderTour.N)
	assert_eq(G.RIO_C, WonderTour.WONDERS[&"rio_harbour"].centre)
	assert_eq(G.REEF_C, WonderTour.WONDERS[&"barrier_reef"].centre)
	for p: Vector2i in [_w(&"grand_canyon", 0, 7), _w(&"everest", 9, -9), _w(&"paricutin", 20, 0)]:
		var s := G.sample(p.x, p.y)
		var k := WonderTour.to_frame(&"grand_canyon", p)
		assert_eq(WonderTour.to_world(&"grand_canyon", k), p, "frames turn both ways")
		assert_gte(s.x, 0)


func test_the_grand_canyon_is_carved_into_its_plateau_with_its_layers_in_order() -> void:
	var rim := _w(&"grand_canyon", 0, -G.PLATEAU_FLAT.y)
	assert_eq(_h(rim.x, rim.y), G.PLATEAU_TOP, "the plateau's flat top")
	var mid := G.canyon_middle(0)
	var bottom := _w(&"grand_canyon", 0, roundi(mid))
	assert_eq(_h(bottom.x, bottom.y), G.RIVER_BED, "the Colorado River in its bottom")
	assert_eq(G.sample(bottom.x, bottom.y).y, G.CANYON)
	assert_gte(G.PLATEAU_TOP - G.RIVER_BED, 40, "about 40 blocks deep")
	var heights: Array[int] = []
	for d in range(0, 30):   # walking out from the river the ground only rises
		var p := _w(&"grand_canyon", 0, roundi(mid) - d)
		heights.append(_h(p.x, p.y))
	for i in heights.size() - 1:
		assert_gte(heights[i + 1], heights[i], "the walls step up from the river (%s)" % [heights])
	var layers := [BlockIds.VISHNU_SCHIST, BlockIds.CANYON_SHALE, BlockIds.REDWALL_LIMESTONE, BlockIds.SUPAI_REDBED,
		BlockIds.COCONINO_SANDSTONE, BlockIds.KAIBAB_LIMESTONE]
	var seen: Array = []
	for y in range(G.RIVER_BED, G.PLATEAU_TOP):
		var s := G.stratum(y)
		if seen.is_empty() or seen[-1] != s:
			seen.append(s)
	assert_eq(seen, layers, "the oldest rock at the bottom, the Kaibab at the rim")
	var far := _w(&"grand_canyon", 0, G.CANYON_HALF.y + 6)
	assert_eq(_h(far.x, far.y), Y, "the plateau's slope back down to the park")
	for b: Vector3 in G.BUTTES:   # buttes: towers of the same layers, worn free of the walls
		var bp := _w(&"grand_canyon", int(b.x), roundi(G.canyon_middle(int(b.x)) + b.y))
		assert_eq(_h(bp.x, bp.y), 41, "a butte stands in the canyon at frame x %d" % b.x)
		assert_gt(absf(b.y) - b.z, 3.5, "clear of the river")


func test_the_trail_goes_down_the_gully_a_block_a_step_to_the_river() -> void:
	var prev := -1
	for fz in range(-G.CANYON_HALF.y - 4, G.TRAIL_END + 1):
		var p := _w(&"grand_canyon", G.TRAIL_X, fz)
		var h := _h(p.x, p.y)
		if prev >= 0:
			assert_lte(absi(h - prev), 1, "a block a step at frame z %d" % fz)
		prev = h
		for side: int in [-1, 1]:
			var q := _w(&"grand_canyon", G.TRAIL_X + side, fz)
			assert_eq(_h(q.x, q.y), h, "3 wide at frame z %d" % fz)
	assert_eq(prev, 5, "it ends on the river's bank")
	var top := _w(&"grand_canyon", G.TRAIL_X, G.TRAIL_TOP)
	assert_eq(_h(top.x, top.y), Y, "it starts level with the park")


func test_paricutin_is_a_cone_with_a_crater_in_its_cornfield_and_a_lava_field_behind() -> void:
	var c := G.PARICUTIN_C
	assert_eq(_h(c.x, c.y), Y + G.CRATER_FLOOR, "the crater's floor")
	var rim := _w(&"paricutin", 0, -8)
	assert_eq(_h(rim.x, rim.y), Y + G.CONE_TOP, "the rim")
	var slope := _w(&"paricutin", 0, -25)
	assert_between(_h(slope.x, slope.y), Y + 5, Y + G.CONE_TOP - 5, "its slope")
	assert_eq(G.sample(slope.x, slope.y).y, G.CINDER, "of cinders")
	var field := _w(&"paricutin", 25, -38)
	assert_eq(G.sample(field.x, field.y).y, G.FARM, "a cornfield round its foot")
	var corn := 0
	for x in range(c.x - 50, c.x + 50):
		corn += 1 if G.corn_at(x, c.y + 45) or G.corn_at(x, c.y - 45) else 0
	assert_gt(corn, 20, "rows of corn (%d)" % corn)
	for fz in range(-54, -35):
		var t := _w(&"paricutin", 0, fz)
		assert_false(G.corn_at(t.x, t.y), "the farm track to the stair is clear")
	var lava := _w(&"paricutin", 8, 56)
	assert_eq(G.sample(lava.x, lava.y).y, G.LAVA, "the lava field behind it")
	assert_between(_h(lava.x, lava.y), Y + 2, Y + 3, "a little higher than the fields")
	assert_lt(lava.y, c.y, "(behind it is to the north)")


func test_the_northern_lights_valley_is_snowy_with_a_frozen_lake_and_a_mound() -> void:
	var lake := _w(&"northern_lights", int(G.LAKE.x), int(G.LAKE.y))
	assert_eq(G.sample(lake.x, lake.y), Vector2i(Y, G.LAKE_ICE), "the frozen lake")
	var snow := _w(&"northern_lights", -20, -30)
	assert_eq(G.sample(snow.x, snow.y), Vector2i(Y, G.SNOW), "snow all round")
	var mound := _w(&"northern_lights", int(G.MOUND.x), int(G.MOUND.y))
	assert_eq(_h(mound.x, mound.y), Y + G.MOUND_TOP, "the snow mound")


func test_everest_rises_over_lhotse_and_the_south_col_with_its_route() -> void:
	var top := _h(G.EVEREST_C.x, G.EVEREST_C.y)
	assert_eq(top, Y + G.EVEREST_TOP, "the summit")
	assert_lt(top + 4, 128, "inside the streamed height from its foot (a view of 128 streams y 0 to 127)")
	var lhotse := _w(&"everest", G.LHOTSE.x, G.LHOTSE.y)
	assert_eq(_h(lhotse.x, lhotse.y), Y + G.LHOTSE_TOP, "Lhotse, lower")
	var col := _w(&"everest", G.COL_X + 3, 0)
	assert_eq(_h(col.x, col.y), Y + G.COL_TOP, "the South Col between them")
	for fz in range(G.ROUTE_FOOT, 1):   # stair 1, from base camp up to the col
		var p := _w(&"everest", G.STAIR1_X, fz)
		assert_eq(_h(p.x, p.y), Y + fz - G.ROUTE_FOOT, "stair 1 at frame z %d" % fz)
	for fx in range(0, G.COL_X):   # stair 2, along the ridge to the summit
		var p := _w(&"everest", fx, 0)
		assert_eq(_h(p.x, p.y), Y + G.EVEREST_TOP - fx, "stair 2 at frame x %d" % fx)
	var camp := _w(&"everest", G.STAIR1_X, -70)
	assert_eq(G.sample(camp.x, camp.y), Vector2i(Y, G.SNOW), "base camp on flat snow")
	var everywhere := 0
	for x in range(-60, 100, 3):
		for z in range(400, 560, 3):
			everywhere = maxi(everywhere, _h(x, z))
	assert_lte(everywhere, top, "Everest is the highest ground round it")


func test_victoria_falls_drops_from_its_river_into_a_narrow_chasm() -> void:
	var f := G.FALLS_C
	assert_eq(G.sample(f.x, f.y), Vector2i(G.POOL_BED, G.CHASM), "the chasm's pool")
	var river := _w(&"victoria_falls", -10, 20)
	assert_eq(G.sample(river.x, river.y), Vector2i(G.RIVER_BED_Y, G.RIVER), "the Zambezi above the falls")
	var lip := _w(&"victoria_falls", 0, -6)
	assert_eq(_h(lip.x, lip.y), Y, "the rainforest's lip facing the falls")
	assert_gte(Y - G.POOL_TOP, 24, "a long drop")
	var island := _w(&"victoria_falls", 7, 6)
	assert_eq(_h(island.x, island.y), Y + 1, "Livingstone Island over the river")
	var gorge := _w(&"victoria_falls", -41, 20)
	assert_eq(G.sample(gorge.x, gorge.y).y, G.CHASM, "the zigzag gorge")
	assert_lt(G.coast(f.x, f.y + 100), -10.0, "the falls are inland")


func test_the_harbour_of_rio_has_its_bay_the_sugarloaf_and_the_steps_up() -> void:
	var b := G.RIO_C
	assert_eq(G.sample(b.x, b.y), Vector2i(G.BAY_FLOOR, G.SEA_FLOOR), "the bay's water")
	var sl := _w(&"rio_harbour", int(G.SUGARLOAF.x), int(G.SUGARLOAF.y))
	assert_eq(_h(sl.x, sl.y), G.SEA + G.SUGARLOAF_TOP, "the Sugarloaf's top")
	var urca := _w(&"rio_harbour", int(G.URCA.x), int(G.URCA.y))
	assert_eq(_h(urca.x, urca.y), G.SEA + G.URCA_TOP, "Urca, lower")
	var prev := -1
	for fx in range(G.STEPS_FROM, G.STEPS_TO + 1):
		var p := _w(&"rio_harbour", fx, G.STEPS_Z)
		var h := _h(p.x, p.y)
		if prev >= 0:
			assert_eq(h - prev, 1, "a step a block at frame x %d" % fx)
		prev = h
	var foot := _w(&"rio_harbour", G.STEPS_FROM - 1, G.STEPS_Z)
	assert_lte(absi(_h(foot.x, foot.y) - G.STEPS_FOOT), 1, "the steps start from the beach")
	var out := _w(&"rio_harbour", 22, 6)
	assert_lt(_h(out.x, out.y), G.SEA, "the bay opens to the sea")


func test_the_reef_has_a_coral_cay_in_a_shallow_flat_with_coral_heads() -> void:
	var k := G.REEF_C
	assert_eq(G.sample(k.x, k.y), Vector2i(G.CAY_TOP, G.BEACH), "the cay over the water")
	var flat := _w(&"barrier_reef", 12, 8)
	assert_eq(G.sample(flat.x, flat.y), Vector2i(G.REEF_FLOOR, G.REEF), "the reef flat")
	assert_gte(G.SEA - G.REEF_FLOOR, 5, "deep enough to swim over")
	var heads := 0
	for x in range(k.x - 24, k.x + 25):
		for z in range(k.y - 24, k.y + 25):
			var c := G.coral_at(x, z)
			if not c.is_empty():
				heads += 1
				assert_lte(G.REEF_FLOOR + int(c[1]), G.SEA - 2, "under water")
	assert_gt(heads, 80, "coral heads all over the flat (%d)" % heads)
	var deep := Vector2i(k.x + 40, k.y + 30)
	assert_eq(_h(deep.x, deep.y), G.SEA_DEEP, "the sea round it")


func test_the_sea_is_south_east_and_the_square_is_dry() -> void:
	var s := WonderTour.NATURE_SQUARE
	assert_eq(_h(s.x, s.y), Y)
	assert_lt(G.coast(s.x, s.y), -50.0)
	assert_eq(_h(330, 560), G.SEA_DEEP, "the sea")
	assert_true(G.snowy(40, 330), "snow in the west")
	assert_false(G.snowy(200, 400), "grass in the east")


func test_trees_pines_in_the_snow_a_rainforest_by_the_falls_never_on_a_build() -> void:
	var pines := 0
	var oaks := 0
	for x in range(0, 80, 2):
		for z in range(300, 400, 2):
			if shape.tree_at(x, z):
				if shape.tree_kind(x, z) == &"pine":
					pines += 1
				else:
					oaks += 1
	assert_gt(pines, 15, "pines in the snowy valley (%d)" % pines)
	assert_eq(oaks, 0, "only pines in the snow")
	var forest := 0
	for x in range(G.FALLS_C.x - 30, G.FALLS_C.x + 30):
		for z in range(G.FALLS_C.y - 30, G.FALLS_C.y - 10):
			forest += 1 if shape.tree_at(x, z) else 0
	assert_gt(forest, 40, "a rainforest facing the falls (%d)" % forest)
	for id: StringName in WonderBuildsNature.CLEAR:
		for r: Rect2i in WonderBuildsNature.CLEAR[id]:
			for fx in range(r.position.x, r.end.x):
				for fz in range(r.position.y, r.end.y):
					var p := WonderTour.to_world(id, Vector2i(fx, fz))
					assert_false(shape.tree_at(p.x, p.y), "no tree on %s's builds at %s" % [id, p])
	for id: StringName in WonderFacts.tour_ids(&"nature"):
		for box: Array in WonderBuilds.boxes(id):
			var lo: Vector3i = box[0]
			var hi: Vector3i = box[1]
			if box[2] == BlockIds.AIR or hi.y <= shape.height_at(lo.x, lo.z):
				continue
			for x in range(lo.x - 1, hi.x + 1, 2):
				for z in range(lo.z - 1, hi.z + 1, 2):
					assert_false(shape.tree_at(x, z), "no tree in %s's build at (%d, %d)" % [id, x, z])
