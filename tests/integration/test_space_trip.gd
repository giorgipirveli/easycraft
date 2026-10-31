extends GutTest
## Owner feedback #55 (spec §21), the whole trip with the real parts: a child flying over Green Meadows goes up past the
## space line (the real Player's own position), "Where shall we land?" opens, the Moon card lands them there
## (SpaceTrip's saves, as the sandbox writes them), the Moon's gravity lets a real player fall slowly, flying up on the
## Moon offers HOME, and home (owner #39's way home) lands them on the column they took off from. The saves round-trip
## through the disk. Survivor: the bag goes to the Moon and comes back. Slots are per process (parallel suites).

const KEY := "Mia"
const GROUND := 40

var HOME_SLOT := "test_space_home_%d" % OS.get_process_id()
var MOON_SLOT := "test_space_moon_%d" % OS.get_process_id()


## Flat ground (grass on top at y 39) everywhere.
class FlatWorld:
	extends WorldService

	func get_block(p: Vector3i) -> int:
		return BlockIds.GRASS if p.y < GROUND else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return GROUND

	func is_area_ready(_center: Vector3) -> bool:
		return true

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func spawn_column() -> Vector2i:
		return Vector2i(3, 5)


var _world: FlatWorld
var _player: Player
var _panel_ui: Control


func before_each() -> void:
	WorldSaves.delete(HOME_SLOT)
	WorldSaves.delete(MOON_SLOT)
	SpaceDirector.landing = 0


func after_each() -> void:
	LabRules.world_gravity = 1.0
	get_tree().paused = false
	UniverseRegistry.reset()


func after_all() -> void:
	WorldSaves.delete(HOME_SLOT)
	WorldSaves.delete(MOON_SLOT)


func _setup_world() -> void:
	_world = FlatWorld.new()
	add_child_autofree(_world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 10, 400)
	shape.shape = box
	shape.position = Vector3(0, GROUND - 5, 0)
	ground.add_child(shape)
	_world.add_child(ground)
	_player = load("res://entities/player/player.tscn").instantiate()
	_player.name = str(multiplayer.get_unique_id())
	_player.world = _world
	add_child_autofree(_player)


func _director(here: int, home: int, travel: Callable, go_home: Callable) -> SpaceDirector:
	var d := SpaceDirector.new()
	d.player_position = func() -> Vector3: return Player.position_or_none(_player)
	d.mode = func() -> StringName: return ModeRules.SANDBOX
	d.here = here
	d.home = home
	d.available = func() -> Array[int]: return [16] as Array[int]
	d.travel = travel
	d.go_home = go_home
	add_child_autofree(d)
	_panel_ui = Control.new()
	add_child_autofree(_panel_ui)
	d.setup_panel(_panel_ui)
	d.set_process(false)
	return d


## The flyer's own body goes up (as FLY does) and the director looks.
func _fly_to(d: SpaceDirector, y: float) -> void:
	_player.global_position.y = y
	d.tick(SpaceDirector.CHECK_EVERY + 0.01)


func _hotbar() -> Array[int]:
	return WorldMeta.new().hotbar


func test_fly_up_from_the_meadows_land_on_the_moon_and_come_home() -> void:
	_setup_world()
	_player.spawn_at(Vector3(10.7, GROUND, -3.2))
	await wait_until(func() -> bool: return _player.is_spawned(), 3.0, "spawned")
	_player.set_physics_mode(PhysicsMode.Mode.FLY)
	var home := WorldMeta.new_random()
	home.mode = ModeRules.SANDBOX
	home.universe = 1
	home.physics_mode = PhysicsMode.Mode.FLY
	var trips: Array[int] = []
	var up := _director(1, 1, func(u: int) -> String:
		trips.append(u)
		SpaceTrip.arrival(home, u, ModeRules.SANDBOX, MOON_SLOT, KEY, [], _hotbar(), 2)
		SpaceRules.take_off(home, _player.global_position)
		WorldSaves.save_meta(HOME_SLOT, home)
		return "", func() -> String: return "")
	# Up through the sky: it turns to space, then the picker.
	for y: float in [80.0, 150.0, 181.0, 195.0]:
		_fly_to(up, y)
	assert_false(up.panel.visible, "not yet")
	_fly_to(up, 201.0)
	assert_true(up.panel.visible, "Where shall we land?")
	var moon_body := up.panel.body_for(&"moon")
	assert_not_null(moon_body)
	moon_body.pressed.emit()
	assert_eq(up.panel.card_title(), "The Moon")
	up.panel.action_button.pressed.emit()
	assert_eq(trips, [16] as Array[int])
	assert_false(up.panel.visible, "on the way")
	# The saves, read back from the disk.
	var moon := WorldSaves.load_meta(MOON_SLOT)
	assert_eq(moon.universe, 16, "a Moon world")
	assert_eq(moon.mode, ModeRules.SANDBOX)
	assert_eq(moon.space_home, 1, "it remembers home")
	assert_eq(moon.arrival_gate, 1, "the portal home is built by the landing pad (owner #39)")
	assert_false(moon.has_player_pos(), "on the landing pad (the spawn)")
	assert_eq(moon.selected_slot, 2, "the hotbar came along")
	var left := WorldSaves.load_meta(HOME_SLOT)
	assert_eq(left.space_return, [10, -4], "home remembers where the child took off")
	assert_eq(left.physics_mode, PhysicsMode.Mode.NORMAL, "and lands them walking")
	# On the Moon: its gravity; a real player falls slowly.
	LabRules.world_gravity = UniverseRegistry.gravity(moon.universe)
	_player.set_physics_mode(PhysicsMode.Mode.NORMAL)
	_player.global_position = Vector3(3.5, GROUND + 8.0, 5.5)
	_player.velocity = Vector3.ZERO
	await wait_physics_frames(12)
	var moon_fall := -_player.velocity.y
	LabRules.world_gravity = 1.0
	_player.global_position = Vector3(3.5, GROUND + 8.0, 5.5)
	_player.velocity = Vector3.ZERO
	await wait_physics_frames(12)
	var home_fall := -_player.velocity.y
	assert_gt(moon_fall, 0.0, "it still falls")
	assert_almost_eq(moon_fall / home_fall, 0.35, 0.08, "at the Moon's gravity (%.2f vs %.2f m/s)" % [moon_fall, home_fall])
	# Home: fly up on the Moon, HOME first, the way home owner #39 built.
	var homes := [0]
	var down := _director(16, moon.space_home, func(_u: int) -> String: return "", func() -> String:
		homes[0] += 1
		var back := UniverseRules.sandbox_arrival_meta(WorldSaves.load_meta(HOME_SLOT), 1, 16)
		WorldSaves.save_meta(HOME_SLOT, back)
		return "")
	_player.set_physics_mode(PhysicsMode.Mode.FLY)
	_fly_to(down, 120.0)
	_fly_to(down, 202.0)
	assert_true(down.panel.visible)
	down.panel.body_for(&"green_meadows").pressed.emit()
	assert_eq(down.panel.action_button.text, "HOME", "Green Meadows, where the trip started")
	down.panel.action_button.pressed.emit()
	assert_eq(homes[0], 1)
	var arrived := WorldSaves.load_meta(HOME_SLOT)
	assert_eq(arrived.arrival_gate, 0, "no portal back is built at home (the Moon has no crystal)")
	var col := SpaceRules.landing_spot(arrived)
	assert_eq(col, [10, -4], "home lands on the take-off column")
	# ... where a player spawned on that column stands on the ground.
	_player.set_physics_mode(PhysicsMode.Mode.NORMAL)
	_player.spawn_on_surface(int(col[0]), int(col[1]))
	await wait_until(func() -> bool: return _player.is_spawned(), 3.0, "spawned at home")
	assert_eq(Vector2i(floori(_player.global_position.x), floori(_player.global_position.z)), Vector2i(10, -4))
	assert_almost_eq(_player.global_position.y, float(GROUND), 0.6, "on the ground, not in the sky")


func test_survivor_the_bag_goes_to_the_moon_and_comes_back() -> void:
	var home := WorldMeta.new_random()
	home.mode = ModeRules.SURVIVOR
	home.universe = 1
	home.difficulty = DifficultyRules.COZY
	var bag := Inventory.new()
	bag.add(ItemIds.SWORD_COSMIC, 1)
	bag.add(BlockIds.PLANKS, 30)
	var moon := SpaceTrip.arrival(home, 16, ModeRules.SURVIVOR, MOON_SLOT, KEY, bag.to_save(), _hotbar(), 0)
	assert_eq(moon.difficulty, DifficultyRules.COZY, "the difficulty of home")
	var on_moon := Inventory.from_save(WorldSaves.load_meta(MOON_SLOT).inventories.get(KEY, []))
	assert_eq(on_moon.count(ItemIds.SWORD_COSMIC), 1, "the bag came along")
	assert_eq(on_moon.count(BlockIds.PLANKS), 30)
	assert_eq(Inventory.from_save(home.inventories.get(KEY, [])).count(BlockIds.PLANKS), 0, "nothing copied")
	# Home again (the sandbox's _travel for Survivor): the bag goes back.
	WorldSaves.save_meta(HOME_SLOT, home)
	var back := UniverseRules.arrival_meta(WorldSaves.load_meta(HOME_SLOT), 1, DifficultyRules.COZY, KEY)
	UniverseRules.carry(moon, back, KEY, on_moon.to_save(), moon.hotbar, 0)
	assert_eq(Inventory.from_save(back.inventories[KEY]).count(ItemIds.SWORD_COSMIC), 1, "home with the cosmic sword")


func test_a_trip_from_the_moon_to_another_planet_keeps_the_way_home() -> void:
	var moon := WorldMeta.new_random()
	moon.universe = 16
	moon.space_home = 3
	var boing := SpaceTrip.arrival(moon, 17, ModeRules.SANDBOX, MOON_SLOT, KEY, [], _hotbar(), 0)
	assert_eq(boing.space_home, 3, "still Frostpeak's trip")
	SpaceRules.take_off(moon, Vector3(1, 205, 1))
	assert_eq(moon.space_return, [], "a space world never keeps a take-off column")

