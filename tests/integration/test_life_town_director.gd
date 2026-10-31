extends GutTest
## Owner #112 (docs/design/life-skills.md §7, Life Town; Life L2): a home world's Life Town in the world. The host finds
## its site, checks its ground is the world's own (a child's build moves it), clears the trees in its places' way, stands
## the six places and asks the save to keep it; a saved one stands at once; a guest stands it from the seed. Walking up
## to a place opens Life on its Experience's unit (the track first, the very first time); walking away or BACK closes
## it; while a practice room shows, the avatar is held and kept safe and walking away never closes it.

const SEED := 4242


## A flat world: grass under GROUND, what was written, air above.
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
var held: Array = []
var safe := 0
var saved: Array = []


func before_each() -> void:
	world = FlatWorld.new()
	add_child_autofree(world)
	feet = Vector3.INF
	profile = ProfileData.new()
	held = []
	safe = 0
	saved = []


func after_each() -> void:
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _flat(_x: int, _z: int) -> int:
	return FlatWorld.GROUND


## A flat test world's shape stand-in: the real generator's search with flat, dry, treeless ground.
func _site() -> Dictionary:
	return LifeTown.pick(Vector2i.ZERO, SEED, _flat, func(_x: int, _z: int) -> bool: return true,
		func(_x: int, _z: int) -> bool: return false)


func _director(saved_site: Array, host := true) -> LifeTownDirector:
	var d := LifeTownDirector.new()
	d.search_later = false
	d.world = world
	d.host = host
	d.ground = _flat
	d.profile = profile
	d.save_profile = func() -> void: pass
	d.player_position = func() -> Vector3: return feet
	d.take_over = func(on: bool) -> void: held.append(on)
	d.keep_safe = func() -> void: safe += 1
	d.site_placed.connect(func(s: Array) -> void: saved = s)
	add_child_autofree(d)
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	d.setup(null, saved_site, [], [], layer)
	return d


func test_a_saved_town_stands_at_once_with_its_six_places() -> void:
	var d := _director(LifeTown.to_save(_site()))
	assert_true(d.stood)
	assert_not_null(d.buildings)
	assert_eq(d.buildings.signs.size(), LifeTown.SPOTS.size(), "a sign over every place")
	assert_eq(d.saved_site(), LifeTown.to_save(_site()))


func test_the_host_checks_the_ground_clears_the_trees_and_the_save_keeps_it() -> void:
	var site := _site()
	var spot := LifeTown.to_world(site, Vector2i(-9, -4))
	world.cells[Vector3i(spot.x, FlatWorld.GROUND, spot.y)] = BlockIds.LOG   # a tree in the practice house's way
	var d := LifeTownDirector.new()
	d.search_later = false
	d.world = world
	d.ground = _flat
	d.site_placed.connect(func(s: Array) -> void: saved = s)
	add_child_autofree(d)
	d.setup(null, [], [], [], self)
	d.site = site   # the flat world's own place (no generator here)
	d.stood = false
	for i in 20:
		await wait_process_frames(1)
		if d.stood:
			break
	assert_true(d.stood, "it stands")
	assert_eq(world.get_block(Vector3i(spot.x, FlatWorld.GROUND, spot.y)), BlockIds.AIR, "the tree in its way cleared")
	assert_eq(saved, LifeTown.to_save(site), "the save keeps it")


func test_a_childs_build_moves_it() -> void:
	var site := _site()
	var corner := LifeTown.to_world(site, Vector2i(0, 0))
	world.cells[Vector3i(corner.x, FlatWorld.GROUND + 1, corner.y)] = BlockIds.PLANKS
	var d := LifeTownDirector.new()
	d.search_later = false
	d.world = world
	d.ground = _flat
	add_child_autofree(d)
	d.setup(null, [], [], [], self)
	d.site = site
	d.stood = false
	d._shape = null
	d._place_step()   # the check finds the planks: another place (no generator in this test: none found)
	assert_false(d.stood, "never over a child's build")
	assert_eq(world.get_block(Vector3i(corner.x, FlatWorld.GROUND + 1, corner.y)), BlockIds.PLANKS, "the build untouched")


func test_walking_up_to_the_kitchen_opens_life_on_the_kitchen() -> void:
	profile.life.track = "middle"
	var site := _site()
	var d := _director(LifeTown.to_save(site))
	feet = LifeTown.door_position(site, "kitchen", _flat)
	await wait_until(func() -> bool: return d.panel.visible, 2.0, "the panel opens")
	assert_true(d.panel.visible)
	assert_eq(d.panel.experience, "kitchen")
	await wait_process_frames(2)
	assert_eq(d.panel.screen.page, LifeScreen.UNIT)
	assert_eq(d.panel.screen.unit_id, "life.home.cook_safely", "the Kitchen on the child's own track")
	feet = LifeTown.door_position(site, "kitchen", _flat) + Vector3(40, 0, 40)
	await wait_until(func() -> bool: return not d.panel.visible, 2.0, "walking away closes it")
	assert_false(d.panel.visible)


func test_the_very_first_time_the_track_comes_first_then_the_unit() -> void:
	var site := _site()
	var d := _director(LifeTown.to_save(site))
	feet = LifeTown.door_position(site, "street", _flat)
	await wait_until(func() -> bool: return d.panel.visible, 2.0, "the panel opens")
	await wait_process_frames(2)
	assert_eq(d.panel.screen.page, LifeScreen.TRACK, "which one are you?")
	d.panel.screen._pick_track("little")
	assert_eq(d.panel.screen.unit_id, "life.around.cross_the_road", "Safe Streets on the Little track")


func test_back_closes_it_until_the_child_walks_away_and_back() -> void:
	profile.life.track = "big"
	var site := _site()
	var d := _director(LifeTown.to_save(site))
	feet = LifeTown.door_position(site, "bench", _flat)
	await wait_until(func() -> bool: return d.panel.visible, 2.0, "open")
	assert_true(d.close_if_open(), "Android Back closes it")
	assert_false(d.panel.visible)
	await wait_seconds(0.3)
	assert_false(d.panel.visible, "it stays closed while the child stands there")
	feet += Vector3(40, 0, 40)
	await wait_seconds(0.3)
	feet -= Vector3(40, 0, 40)
	await wait_until(func() -> bool: return d.panel.visible, 2.0, "walking back opens it again")
	assert_true(d.panel.visible)


## A BACK holds for the place it was pressed at: walking straight on to the next place opens that one.
func test_back_at_one_place_never_holds_the_next() -> void:
	profile.life.track = "middle"
	var site := _site()
	var d := _director(LifeTown.to_save(site))
	feet = LifeTown.door_position(site, "bench", _flat)
	await wait_until(func() -> bool: return d.panel.visible, 2.0, "the bench")
	d.close_if_open()
	feet = LifeTown.door_position(site, "kitchen", _flat)
	await wait_until(func() -> bool: return d.panel.visible, 2.0, "the kitchen")
	assert_true(d.panel.visible)
	assert_eq(d.panel.experience, "kitchen")


func test_a_practice_room_holds_the_avatar_and_keeps_it_safe() -> void:
	profile.life.track = "little"
	profile.life.set_skill("calm_corner.little", {"b": 1, "q": 4})   # the before-check done: straight into the room
	var site := _site()
	var d := _director(LifeTown.to_save(site))
	feet = LifeTown.door_position(site, "bench", _flat)
	await wait_until(func() -> bool: return d.panel.visible, 2.0, "open")
	d.panel.screen.start_experience("calm_corner", "little", false)
	await wait_until(func() -> bool: return d.panel.room_open(), 2.0, "the room")
	await wait_until(func() -> bool: return held == [true], 2.0, "held still")
	await wait_until(func() -> bool: return safe > 0, 2.0, "kept safe")
	assert_eq(held, [true], "the avatar is held while practising")
	feet += Vector3(40, 0, 40)
	await wait_seconds(0.3)
	assert_true(d.panel.room_open(), "walking away never closes a practice room")
	assert_true(d.close_if_open(), "Back belongs to the room (its own card)")
	assert_true(d.panel.room_open())
	d.panel.screen.host.stop_for_now()
	await wait_until(func() -> bool: return held == [true, false], 2.0, "let go")
	assert_eq(held, [true, false], "free again after the room")
