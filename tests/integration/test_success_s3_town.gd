extends GutTest
## Owner #115 (S3): the Market Square beside a home world's Life Town (LifeTownDirector's MarketPlazaPlacer). A saved
## town with its Market Square stands both at once; the host checks the Market Square's ground, clears the trees in its
## places' way and the save keeps it with the town; a child's build moves it; a guest stands it at once. Walking up to
## the bakery opens Life on My Business's shop, to the stalls on the Market Square; walking up to one never opens another.

const SEED := 4242


class FlatWorld:
	extends Node
	const GROUND := 70
	var cells := {}
	var writes := 0

	func get_block(p: Vector3i) -> int:
		if cells.has(p):
			return int(cells[p])
		return BlockIds.GRASS if p.y < GROUND else BlockIds.AIR

	func box_reader(_origin: Vector3i, _size: Vector3i) -> Callable:
		return get_block

	func is_editable(_p: Vector3i) -> bool:
		return true

	func set_blocks(changes: Array) -> Array:
		writes += changes.size()
		for c: Array in changes:
			cells[c[0]] = int(c[1])
		return []


var world: FlatWorld
var feet := Vector3.INF
var profile: ProfileData
var saved: Array = []


func before_each() -> void:
	world = FlatWorld.new()
	add_child_autofree(world)
	feet = Vector3.INF
	profile = ProfileData.new()
	saved = []


func after_each() -> void:
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _flat(_x: int, _z: int) -> int:
	return FlatWorld.GROUND


func _yes(_x: int, _z: int) -> bool:
	return true


func _no(_x: int, _z: int) -> bool:
	return false


func _town() -> Dictionary:
	return LifeTown.pick(Vector2i.ZERO, SEED, _flat, _yes, _no)


func _market(town: Dictionary) -> Dictionary:
	return MarketPlaza.pick(Vector2i.ZERO, SEED, _flat, _yes, _no, town)


func _director(saved_site: Array, on_market: Callable = Callable()) -> LifeTownDirector:
	var d := LifeTownDirector.new()
	if on_market.is_valid():
		d.market_ready.connect(on_market)
	d.search_later = false
	d.world = world
	d.ground = _flat
	d.profile = profile
	d.save_profile = func() -> void: pass
	d.player_position = func() -> Vector3: return feet
	d.site_placed.connect(func(s: Array) -> void: saved = s)
	add_child_autofree(d)
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	d.setup(null, saved_site, [], [], layer)
	return d


func test_a_saved_town_and_its_market_square_stand_at_once() -> void:
	var town := _town()
	var both := town.duplicate()
	both.market = _market(town)
	var d := _director(LifeTown.to_save(both))
	assert_not_null(d.market_square)
	assert_true(d.market_square.stood)
	assert_eq(d.market_square.buildings.signs.size(), MarketPlaza.SPOTS.size(), "a sign over both places")
	assert_eq(d.saved_site(), LifeTown.to_save(both), "the save keeps both")


func test_the_host_checks_its_ground_clears_its_trees_and_the_save_keeps_it() -> void:
	var town := _town()
	var market := _market(town)
	var spot := MarketPlaza.to_world(market, Vector2i(-5, -1))
	world.cells[Vector3i(spot.x, FlatWorld.GROUND, spot.y)] = BlockIds.LOG   # a tree in the bakery's way
	var d := _director(LifeTown.to_save(town))
	assert_true(d.stood, "the town stands")
	assert_false(d.market_square.stood, "no generator in this test: no search")
	d.market_square.site = market   # the flat world's own place
	for i in 20:
		await wait_process_frames(1)
		if d.market_square.stood:
			break
	assert_true(d.market_square.stood, "it stands")
	assert_eq(world.get_block(Vector3i(spot.x, FlatWorld.GROUND, spot.y)), BlockIds.AIR, "the tree in its way cleared")
	assert_eq(saved.size(), 8, "the save keeps the town and its Market Square")
	assert_eq(LifeTown.from_save(saved).market, market)


## S3's follow-up (the lead, 2026-10-17): MY MAP marks the Market Square (scenes/sandbox.gd), so the director says
## when its site is known: a saved one at once, a searched one when it stands.
func test_the_director_says_when_the_market_squares_site_is_known() -> void:
	var town := _town()
	var both := town.duplicate()
	both.market = _market(town)
	var heard := [0]
	var d := _director(LifeTown.to_save(both), func() -> void: heard[0] += 1)
	assert_eq(heard[0], 1, "a saved one at once")
	assert_eq(d.site.market, both.market)
	var market := _market(town)
	heard[0] = 0
	var d2 := _director(LifeTown.to_save(town), func() -> void: heard[0] += 1)
	assert_eq(heard[0], 0, "none yet: no search here")
	d2.market_square.site = market
	for i in 20:
		await wait_process_frames(1)
		if d2.market_square.stood:
			break
	assert_eq(heard[0], 1, "a searched one when it stands")


func test_a_childs_build_moves_it() -> void:
	var town := _town()
	var market := _market(town)
	var corner := MarketPlaza.to_world(market, Vector2i(0, 0))
	world.cells[Vector3i(corner.x, FlatWorld.GROUND + 1, corner.y)] = BlockIds.PLANKS
	var d := _director(LifeTown.to_save(town))
	d.market_square.site = market
	d.market_square._place_step()
	assert_false(d.market_square.stood, "never over a child's build")
	assert_eq(world.get_block(Vector3i(corner.x, FlatWorld.GROUND + 1, corner.y)), BlockIds.PLANKS, "the build untouched")


func test_a_guest_stands_it_at_once() -> void:
	var town := _town()
	var placer := MarketPlazaPlacer.new()
	placer.host = false
	placer.search_later = false
	add_child_autofree(placer)
	placer.setup(null, town, {}, [], [], _flat)
	placer._on_found(_market(town))
	assert_true(placer.stood)
	assert_eq(world.writes, 0, "a guest never edits the world")


func test_walking_up_to_the_bakery_and_the_stalls_opens_each_one() -> void:
	profile.life.track = "middle"
	var town := _town()
	var both := town.duplicate()
	both.market = _market(town)
	var d := _director(LifeTown.to_save(both))
	for id: String in MarketPlaza.SPOTS:
		feet = MarketPlaza.door_position(both.market, id, _flat)
		await wait_until(func() -> bool: return d.panel.visible and d.panel.experience == str(MarketPlaza.SPOTS[id].experience),
			2.0, id + ": the panel opens")
		assert_eq(d.panel.experience, str(MarketPlaza.SPOTS[id].experience), id)
		await wait_process_frames(2)
		assert_eq(d.panel.screen.page, LifeScreen.UNIT)
		assert_eq(d.panel.screen.unit_id, LifeCatalog.experience_unit(str(MarketPlaza.SPOTS[id].experience), "middle"))
		feet = MarketPlaza.door_position(both.market, id, _flat) + Vector3(60, 0, 60)
		await wait_until(func() -> bool: return not d.panel.visible, 2.0, "walking away closes it")
	feet = LifeTown.door_position(town, "kitchen", _flat)
	await wait_until(func() -> bool: return d.panel.visible, 2.0, "the town's places still open")
	assert_eq(d.panel.experience, "kitchen")
