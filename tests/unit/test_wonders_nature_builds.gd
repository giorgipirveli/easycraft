extends GutTest
## Owner #78 (spec §24), the third tour: what is built at each of the Seven Natural Wonders (WonderBuildsNature) and a
## child's safe adventures there, walked cell by cell on the real ground (tests/fakes/wonder_walker.gd: standing needs two
## free cells over a solid one, a step up is one block, a fall a few blocks at most): down the Grand Canyon's trail to
## the river and into the granary, out on its glass walk; along the reef's jetty and down the glass tube into the
## underwater room; round the bay and up the steps to the Sugarloaf's lookout; from Everest's base camp up to the South
## Col and the summit; into the snowy valley's cabin and onto its deck; up Parícutin's stair to the rim, down into the
## crater and out again; along the rainforest path facing Victoria Falls and down to its pool.

const Walker := preload("res://tests/fakes/wonder_walker.gd")
const Y := WonderTour.BASE_Y
const G := preload("res://world/wonders/nature_ground.gd")
const B := preload("res://world/wonders/wonder_builds_nature.gd")

var shape: WondersShape
var walker: Walker


func before_all() -> void:
	shape = WondersShape.new(31)
	walker = Walker.new(shape)


func _b(id: StringName, x: int, y: int, z: int) -> int:
	return walker.block(Walker.at(id, x, y, z))


func _gate(id: StringName) -> Vector3i:
	var g := WonderTour.gate(id)
	return Vector3i(g.x, Y, g.y)


## A child walks from wonder `id`'s gate to the frame box lo..hi (feet cells), within its reach and a margin.
func _reaches(id: StringName, lo: Vector3i, hi: Vector3i, margin: int = 16) -> bool:
	var g := WonderTour.gate(id)
	var within := Walker.around(id, margin).merge(Rect2i(g - Vector2i(margin, margin), Vector2i.ONE * (2 * margin + 1)))
	return walker.walks(_gate(id), Walker.inside(Walker.at(id, lo.x, lo.y, lo.z), Walker.at(id, hi.x, hi.y, hi.z)),
		within, 1, 400000)


# --- The Grand Canyon ---

func test_the_canyon_has_a_lookout_a_glass_walk_and_a_granary() -> void:
	var top := G.PLATEAU_TOP - Y
	var rim := G.canyon_rim_west(0)
	assert_eq(_b(&"grand_canyon", 0, top, rim), BlockIds.KAIBAB_LIMESTONE, "the lookout's low wall on the rim")
	var grim := G.canyon_rim_west((B.GLASS_X.x + B.GLASS_X.y) / 2)
	for d in range(2, B.GLASS_OUT):
		var x := (B.GLASS_X.x + B.GLASS_X.y) / 2
		assert_eq(_b(&"grand_canyon", x, top - 1, grim + d), BlockIds.GLASS, "the glass walk's floor at %d" % d)
		assert_true(Walker.is_free(_b(&"grand_canyon", x, top - 2, grim + d)), "nothing under it but the canyon")
	var g := B.GRANARY
	var feet := B.trail_feet(B.GRANARY_DOOR_Z)
	assert_eq(_b(&"grand_canyon", g.end.x, feet + 2, g.position.y - 1), BlockIds.COCONINO_SANDSTONE, "its stone front")
	assert_eq(_b(&"grand_canyon", g.end.x, feet, B.GRANARY_DOOR_Z), BlockIds.AIR, "its door from the trail")


func test_a_child_walks_down_the_canyons_trail_to_the_river_out_on_the_glass_and_into_the_granary() -> void:
	var top := G.PLATEAU_TOP - Y
	var x := (B.GLASS_X.x + B.GLASS_X.y) / 2
	var grim := G.canyon_rim_west(x)
	assert_true(_reaches(&"grand_canyon", Vector3i(x, top, grim + B.GLASS_OUT - 2), Vector3i(x, top, grim + B.GLASS_OUT - 1)),
		"up the plateau and out on the glass walk")
	var bank := G.TRAIL_END
	assert_true(_reaches(&"grand_canyon", Vector3i(G.TRAIL_X - 1, 5 - Y, bank), Vector3i(G.TRAIL_X + 1, 5 - Y, bank)),
		"down the trail to the river's bank")
	var g := B.GRANARY
	var feet := B.trail_feet(B.GRANARY_DOOR_Z)
	assert_true(_reaches(&"grand_canyon", Vector3i(g.position.x, feet, g.position.y), Vector3i(g.end.x - 1, feet, g.end.y - 1)),
		"into the granary beside the trail")


# --- The Great Barrier Reef ---

func test_the_reef_has_a_jetty_a_glass_tube_and_a_dry_room_under_the_water() -> void:
	var deck := B.DECK - Y
	for z in range(B.JETTY_FROM, B.JETTY_TO + 1, 3):
		assert_eq(_b(&"barrier_reef", 0, deck, z), BlockIds.PLANKS, "the jetty's planks at %d" % z)
	var r := B.ROOM
	var floor_y := B.ROOM_FLOOR - Y
	var mid := Vector3i((r.position.x + r.end.x - 1) / 2, floor_y + 1, (r.position.y + r.end.y - 1) / 2)
	assert_eq(_b(&"barrier_reef", mid.x, mid.y, mid.z), BlockIds.AIR, "the room is dry")
	assert_eq(_b(&"barrier_reef", mid.x, floor_y, mid.z), BlockIds.GLASS, "a glass floor")
	assert_eq(_b(&"barrier_reef", mid.x, floor_y + 4, mid.z), BlockIds.GLASS, "a glass roof ...")
	assert_lt(B.ROOM_FLOOR + 4, G.SEA - 1, "... under the water")
	assert_eq(_b(&"barrier_reef", r.end.x, floor_y + 2, mid.z), BlockIds.GLASS, "glass walls: the corals at its windows")
	var c := B.CANNON
	assert_eq(_b(&"barrier_reef", c.x, floor_y, c.z), BlockIds.DEEPSTONE, "Endeavour's cannon on the reef")


func test_a_child_walks_along_the_jetty_to_the_cay_and_down_into_the_underwater_room() -> void:
	var cay := G.CAY_TOP - Y
	assert_true(_reaches(&"barrier_reef", Vector3i(-1, cay, -3), Vector3i(1, cay, 3)), "along the jetty to the coral cay")
	var r := B.ROOM
	var feet := B.ROOM_FLOOR - Y + 1
	assert_true(_reaches(&"barrier_reef", Vector3i(r.position.x, feet, r.position.y), Vector3i(r.end.x - 1, feet, r.end.y - 1)),
		"down the glass tube into the room on the reef")


# --- The Harbour of Rio de Janeiro ---

func test_a_child_walks_round_the_bay_and_up_the_steps_to_the_sugarloafs_lookout() -> void:
	var sl := G.SUGARLOAF
	var feet := G.SEA + G.SUGARLOAF_TOP - Y
	assert_eq(_b(&"rio_harbour", int(sl.x), feet - 1, int(sl.y)), BlockIds.PAVING, "the lookout's floor")
	assert_eq(_b(&"rio_harbour", int(sl.x), feet, int(sl.y) - 4), BlockIds.WHITE_BRICK, "its low wall")
	assert_true(_reaches(&"rio_harbour", Vector3i(-28, -1, -12), Vector3i(-12, 0, -24), 20), "to the promenade on the shore")
	assert_true(_reaches(&"rio_harbour", Vector3i(int(sl.x) - 1, feet, int(sl.y) - 1),
		Vector3i(int(sl.x) + 1, feet, int(sl.y) + 1), 24), "up the steps over Urca to the Sugarloaf's top")
	var promenade := 0
	for fx in range(-30, 1):
		for fz in range(-30, 1):
			promenade += 1 if _b(&"rio_harbour", fx, -1, fz) == BlockIds.PAVING else 0
	assert_gt(promenade, 40, "a paved promenade along the bay (%d)" % promenade)


# --- Mount Everest ---

func test_everest_has_base_camp_camp_iv_the_stairs_and_flags_on_the_summit() -> void:
	var tents := 0
	for t: Vector3i in B.CAMP_TENTS:
		tents += 1 if _b(&"everest", t.x, 0, t.y) == t.z else 0
	assert_eq(tents, B.CAMP_TENTS.size(), "base camp's tents")
	assert_eq(_b(&"everest", 20, 3, B.FLAGS_Z), BlockIds.PRAYER_FLAGS, "prayer flags over base camp")
	var col := B.COL_TENTS[0]
	assert_eq(_b(&"everest", col.x, G.COL_TOP, col.y), col.z, "Camp IV's tents on the South Col")
	var top := G.EVEREST_TOP
	assert_eq(_b(&"everest", -2, top + 1, 0), BlockIds.PRAYER_FLAGS, "prayer flags on the summit")
	assert_eq(_b(&"everest", -1, top - 1, 1), BlockIds.SEA_FOSSIL, "the summit's rock: a sea fossil")
	assert_eq(_b(&"everest", G.STAIR1_X, 10 - 1, G.ROUTE_FOOT + 10), BlockIds.PACKED_SNOW, "stair 1's packed snow")


func test_a_child_climbs_from_base_camp_to_the_south_col_and_the_summit() -> void:
	var col := G.COL_TOP
	assert_true(_reaches(&"everest", Vector3i(G.COL_X, col, -1), Vector3i(G.COL_X + 2, col, 1), 8),
		"up stair 1 to the South Col")
	assert_true(_reaches(&"everest", Vector3i(-1, G.EVEREST_TOP, -1), Vector3i(1, G.EVEREST_TOP, 1), 8),
		"along the ridge to the top of the world")


# --- The Northern Lights ---

func test_the_valley_has_a_lit_path_a_cabin_and_a_deck_by_the_frozen_lake() -> void:
	for z: int in B.LANTERN_ZS:
		assert_eq(_b(&"northern_lights", 2, 2, z), BlockIds.ICE_LANTERN, "an ice lantern on the path at %d" % z)
	var d := B.DECK_RECT
	assert_eq(_b(&"northern_lights", 0, 0, d.position.y + 1), BlockIds.PLANKS, "the viewing deck")
	var lake := Walker.at(&"northern_lights", int(G.LAKE.x), -1, int(G.LAKE.y))
	assert_lt(Vector2(lake.x, lake.z).distance_to(Vector2(Walker.at(&"northern_lights", 0, 0, d.end.y).x,
		Walker.at(&"northern_lights", 0, 0, d.end.y).z)), 20.0, "by the frozen lake")
	var c := B.CABIN
	assert_eq(_b(&"northern_lights", c.position.x, 1, c.position.y), BlockIds.LOG, "a log cabin")
	assert_true(_reaches(&"northern_lights", Vector3i(-1, 1, d.position.y + 1), Vector3i(1, 1, d.position.y + 2)),
		"along the path onto the deck")
	assert_true(_reaches(&"northern_lights", Vector3i(c.position.x + 1, 0, c.position.y + 1),
		Vector3i(c.end.x - 2, 0, c.end.y - 2)), "into the cabin")


# --- Parícutin ---

func test_paricutins_crater_glows_behind_a_ring_of_rock_and_the_church_tower_stands_in_the_lava() -> void:
	var floor_y := G.CRATER_FLOOR
	assert_eq(_b(&"paricutin", 0, floor_y - 1, 0), BlockIds.HOT_LAVA, "glowing lava in the crater (it never hurts)")
	assert_eq(_b(&"paricutin", -4, floor_y, 0), BlockIds.BLACK_LAVA, "behind a ring of rock")
	var t := B.TOWER
	assert_eq(_b(&"paricutin", t.x, 6, t.y), BlockIds.WALL_BRICK, "the church tower ...")
	var lava := WonderTour.to_world(&"paricutin", Vector2i(t.x, t.y - 1))
	assert_lte(shape.height_at(lava.x, lava.y) - Y, 3, "... rising out of the lava field")
	assert_eq(_b(&"paricutin", t.x + 1, B.TOWER_TOP - 3, t.y), BlockIds.AIR, "its belfry")


func test_a_child_climbs_parícutin_walks_round_its_rim_goes_into_the_crater_and_out() -> void:
	var rim := G.CONE_TOP
	assert_true(_reaches(&"paricutin", Vector3i(-1, rim, -8), Vector3i(1, rim, -8)), "up the stair to the rim")
	assert_true(_reaches(&"paricutin", Vector3i(-1, rim, 7), Vector3i(1, rim, 8)), "round the rim to its far side")
	var x0 := B.CRATER_STAIR_X.x
	assert_true(_reaches(&"paricutin", Vector3i(x0, G.CRATER_FLOOR, -4), Vector3i(x0 + 2, G.CRATER_FLOOR, -4)),
		"down the crater's stair to its floor")
	var inside := Walker.at(&"paricutin", x0 + 1, G.CRATER_FLOOR, -4)
	assert_true(walker.walks(inside, Walker.inside(Walker.at(&"paricutin", -1, rim, -8), Walker.at(&"paricutin", 1, rim, -8)),
		Walker.around(&"paricutin")), "and out again")


# --- Victoria Falls ---

func test_the_falls_pour_from_the_river_into_the_chasm() -> void:
	var lip := G.RIVER_TOP - 1 - Y
	var pool := G.POOL_TOP - Y
	for c: Vector2i in B.CURTAINS:
		for y in range(pool, lip + 1, 4):
			assert_eq(_b(&"victoria_falls", c.x, y, G.CHASM_Z.y), BlockIds.WATER, "the falling water at %d, %d" % [c.x, y])
	assert_eq(_b(&"victoria_falls", 7, -10, G.CHASM_Z.y), BlockIds.BLACK_LAVA, "Livingstone Island's rock face")
	assert_eq(_b(&"victoria_falls", 0, -1, B.PATH_Z.x), BlockIds.DIRT, "the rainforest path")


func test_a_child_walks_to_the_lip_facing_the_falls_and_down_to_the_pool() -> void:
	assert_true(_reaches(&"victoria_falls", Vector3i(-5, 0, B.PATH_Z.x), Vector3i(5, 0, B.PATH_Z.y)),
		"through the rainforest to the path facing the falls")
	var s := B.STAIR_DOWN
	var feet := G.POOL_TOP - Y
	assert_true(_reaches(&"victoria_falls", Vector3i(s.y, feet, G.CHASM_Z.x), Vector3i(s.y, feet, -1)),
		"down the stair to the pool (the Boiling Pot)")
