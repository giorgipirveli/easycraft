extends GutTest
## The new animals move the way they should (owner feedback #41, spec §14.19), on the host's real Animal code with
## a flat stand-in world: a goat jumps up a 2-block step a sheep can't, a duck floats on the water's top where a
## sheep would sink, a deer runs from a child walking up while a sheep stays, a hedgehog curls up instead of
## running, a penguin belly-slides on ice faster than it waddles on snow, a squirrel runs up a tree trunk, an owl
## sleeps by day and wakes at night, and a turtle's egg on the sand hatches into a baby when a child comes.

## Stone below GROUND, air above, plus the cells a test sets.
class FlatWorld:
	extends WorldService
	const GROUND := 10
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.STONE if pos.y < GROUND else BlockIds.AIR)

	func copy_box(origin: Vector3i, size: Vector3i) -> VoxelBuffer:
		var buf := VoxelBuffer.new()
		buf.create(size.x, size.y, size.z)
		for z in size.z:
			for x in size.x:
				for y in size.y:
					buf.set_voxel(get_block(origin + Vector3i(x, y, z)), x, y, z, VoxelBuffer.CHANNEL_TYPE)
		return buf

	func is_area_ready(_center: Vector3) -> bool:
		return true


const STEP := 1.0 / 60.0
const G := FlatWorld.GROUND

var world: FlatWorld
var _time := DayCycle.NOON
var _book: MindBook
var _source: Callable


func before_each() -> void:
	_book = MindBook.current
	MindBook.current = MindBook.new()
	_source = Animal.time_source
	Animal.time_source = func() -> float: return _time
	_time = DayCycle.NOON
	world = FlatWorld.new()
	autofree(world)
	_box(Vector3(0, G - 0.5, 0), Vector3(200, 1, 200))   # the ground


func after_each() -> void:
	MindBook.current = _book
	Animal.time_source = _source


## A static box (the physics of blocks the stand-in world names).
func _box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = center


func _player(peer: int, pos: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = pos
	return p


func _animal(species: StringName, id: String, pos: Vector3) -> Animal:
	var a := Animal.new()
	a.setup({"species": species, "id": id, "pos": pos, "yaw": 0.0, "owner": 0, "name": "", "sitting": false})
	a.world = world
	add_child_autofree(a)
	a.set_physics_process(false)
	return a


## An animal that walks `dir` and nothing else (its mind off), for the moves that don't depend on choices.
func _walker(species: StringName, id: String, pos: Vector3, dir: Vector3) -> Animal:
	var a := _animal(species, id, pos)
	a.mind = null
	a._think = 999.0
	a._dir = dir
	return a


func _run(animals: Array, seconds: float, keep_dir := Vector3.ZERO) -> void:
	for i in roundi(seconds / STEP):
		for a: Animal in animals:
			if is_instance_valid(a):
				if keep_dir != Vector3.ZERO:
					a._dir = keep_dir
				a._physics_process(STEP)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- A goat jumps up two blocks ---

func test_a_goat_climbs_a_two_block_step_a_sheep_does_not() -> void:
	_player(2, Vector3(0.5, G, 20.5))
	for x in range(4, 12):
		for z in range(-6, 7):
			for y in [G, G + 1]:
				world.cells[Vector3i(x, y, z)] = BlockIds.STONE
	_box(Vector3(8, G + 1, 0.5), Vector3(8, 2, 13))            # the step's physics: x 4..12, up to G + 2
	await get_tree().physics_frame
	var goat := _walker(&"goat", "g_test", Vector3(1.5, G, -2.5), Vector3.RIGHT)
	var sheep := _walker(&"sheep", "s_test", Vector3(1.5, G, 3.5), Vector3.RIGHT)
	_run([goat, sheep], 4.0, Vector3.RIGHT)
	assert_gt(goat.global_position.y, G + 1.9, "the goat is up on the step")
	assert_gt(goat.global_position.x, 4.2)
	assert_lt(sheep.global_position.y, G + 1.0, "the sheep is still below it")
	assert_lt(sheep.global_position.x, 4.0)


# --- A duck swims ---

func test_a_duck_floats_on_the_water_where_a_sheep_would_sink() -> void:
	_player(2, Vector3(0.5, G, 20.5))
	for x in range(-4, 5):
		for z in range(-4, 5):
			for y in range(G, G + 3):
				world.cells[Vector3i(x, y, z)] = BlockIds.WATER   # a pool 3 deep on the ground
	await get_tree().physics_frame
	var duck := _walker(&"duck", "d_test", Vector3(-1.5, G + 0.2, 0.5), Vector3.ZERO)
	var sheep := _walker(&"sheep", "s_test", Vector3(1.5, G + 0.2, 0.5), Vector3.ZERO)
	_run([duck, sheep], 3.0)
	var top := float(G + 3)
	assert_between(duck.global_position.y, top - 0.5, top, "the duck floats just under the water's top")
	assert_lt(sheep.global_position.y, G + 0.5, "a sheep in the water sinks to the bottom (it never walks in)")
	assert_true(AnimalRules.can_step(&"duck", Vector3i(0, G, 0), world.get_block), "a duck may paddle about")


# --- A deer is shy ---

func test_a_deer_runs_from_a_child_walking_up_a_sheep_stays() -> void:
	var deer := _animal(&"deer", "a3_3_0", Vector3(0.5, G, -4.5))
	var sheep := _animal(&"sheep", "a4_4_0", Vector3(0.5, G, 4.5))
	var kid_a := _player(2, Vector3(7.5, G, -4.5))
	var kid_b := _player(3, Vector3(7.5, G, 4.5))
	kid_a.velocity = Vector3(-2.0, 0, 0)   # both walk towards their animal, not rushing
	kid_b.velocity = Vector3(-2.0, 0, 0)
	await get_tree().physics_frame
	var deer_start := _flat(deer.global_position, kid_a.global_position)
	var sheep_start := _flat(sheep.global_position, kid_b.global_position)
	_run([deer, sheep], 2.0)
	assert_gt(_flat(deer.global_position, kid_a.global_position), deer_start + 5.0, "the deer ran off")
	assert_lt(_flat(sheep.global_position, kid_b.global_position), sheep_start + 3.9,
		"the sheep didn't run (at most a 2 s wander at its own pace)")


# --- A hedgehog curls up ---

func test_a_hedgehog_curls_up_instead_of_running_then_uncurls() -> void:
	var hog := _animal(&"hedgehog", "h_test", Vector3(0.5, G, 0.5))
	var kid := _player(2, Vector3(3.5, G, 0.5))
	kid.velocity = Vector3(-6.0, 0, 0)     # rushing at it
	await get_tree().physics_frame
	_run([hog], 0.4)
	assert_true(hog.curled_up(), "curled up")
	assert_true(hog.sitting, "a ball, low and still")
	var at := hog.global_position
	_run([hog], 1.5)
	assert_lt(_flat(hog.global_position, at), 0.3, "it doesn't run")
	kid.velocity = Vector3.ZERO
	kid.global_position = Vector3(20.5, G, 0.5)
	await get_tree().physics_frame
	_run([hog], AnimalRules.CURL_TIME + 0.5)
	assert_false(hog.curled_up(), "it uncurls after a while")
	assert_false(hog.sitting)


# --- A penguin belly-slides on ice ---

func test_a_penguin_slides_on_ice_faster_than_it_waddles_on_snow() -> void:
	_player(2, Vector3(0.5, G, 20.5))
	for x in range(-2, 40):
		for z in range(-3, 0):
			world.cells[Vector3i(x, G - 1, z)] = BlockIds.ICE
		for z in range(1, 4):
			world.cells[Vector3i(x, G - 1, z)] = BlockIds.SNOW
	await get_tree().physics_frame
	var on_ice := _walker(&"penguin", "p_ice", Vector3(0.5, G, -1.5), Vector3.RIGHT)
	var on_snow := _walker(&"penguin", "p_snow", Vector3(0.5, G, 2.5), Vector3.RIGHT)
	_run([on_ice, on_snow], 5.0, Vector3.RIGHT)
	var ice_went := on_ice.global_position.x - 0.5
	var snow_went := on_snow.global_position.x - 0.5
	assert_gt(ice_went, snow_went * 1.4, "sliding (%.1f m) beats waddling (%.1f m)" % [ice_went, snow_went])
	on_ice._moving = true
	on_snow._moving = true
	on_ice._look_under()
	on_snow._look_under()
	assert_true(on_ice.sliding(), "it lies on its belly on the ice")
	assert_false(on_snow.sliding(), "and walks on snow")


# --- A squirrel runs up a tree ---

func test_a_squirrel_runs_up_a_tree_trunk_a_rabbit_cannot() -> void:
	_player(2, Vector3(0.5, G, 20.5))
	for y in range(G, G + 6):
		world.cells[Vector3i(4, y, -2)] = BlockIds.LOG
		world.cells[Vector3i(4, y, 2)] = BlockIds.LOG
	_box(Vector3(4.5, G + 3, -1.5), Vector3(1, 6, 1))
	_box(Vector3(4.5, G + 3, 2.5), Vector3(1, 6, 1))
	await get_tree().physics_frame
	var squirrel := _walker(&"squirrel", "q_test", Vector3(2.5, G, -1.5), Vector3.RIGHT)
	var rabbit := _walker(&"rabbit", "r_test", Vector3(2.5, G, 2.5), Vector3.RIGHT)
	var top_s := 0.0
	var top_r := 0.0
	for i in 180:
		_run([squirrel, rabbit], STEP, Vector3.RIGHT)
		top_s = maxf(top_s, squirrel.global_position.y)
		top_r = maxf(top_r, rabbit.global_position.y)
	assert_gt(top_s, G + 2.5, "the squirrel ran up the trunk")
	assert_lt(top_r, G + 1.6, "a rabbit only hops against it")


# --- An owl is awake at night ---

func test_an_owl_sleeps_by_day_and_wakes_at_night() -> void:
	_player(2, Vector3(0.5, G, 14.5))
	for y in 4:
		world.cells[Vector3i(6, G + y, 0)] = BlockIds.LOG
	var owl := _animal(&"owl", "a9_9_0", Vector3(0.5, G, 0.5))
	await get_tree().physics_frame
	_time = DayCycle.NOON
	_run([owl], 25.0)
	assert_eq(owl.mind_action(), AnimalSpecies.SLEEP, "an owl sleeps by day")
	assert_true(owl.sitting)
	_time = 0.95   # night
	_run([owl], 2.0)
	assert_ne(owl.mind_action(), AnimalSpecies.SLEEP, "and is awake at night")
	assert_false(owl.sitting)


# --- A turtle's egg ---

func test_a_turtle_lays_an_egg_on_sand_that_hatches_when_a_child_comes() -> void:
	for x in range(-3, 4):
		for z in range(-3, 4):
			world.cells[Vector3i(x, G - 1, z)] = BlockIds.SAND
	var container := Node3D.new()
	add_child_autofree(container)
	var players: Array[Vector3] = [Vector3(20.5, G, 0.5)]
	var spawned: Array[Dictionary] = []
	var d := AnimalDirector.new()
	d.shape = MeadowsShape.new(12345)
	d.kinds = [&"turtle"] as Array[StringName]
	d.container = container
	d.player_positions = func() -> Array[Vector3]: return players
	d.is_ready = func(_p: Vector3) -> bool: return false   # no herds in this test
	d.block_at = world.get_block
	d.roll = func() -> float: return 0.0
	d.spawn = func(data: Dictionary) -> void:
		spawned.append(data)
		var baby := Animal.new()
		baby.setup(data)
		container.add_child(baby)
	add_child_autofree(d)
	d.set_process(false)
	var turtle := Animal.new()
	turtle.setup({"species": &"turtle", "id": "a1_1_0", "pos": Vector3(0.5, G, 0.5), "yaw": 0.0, "owner": 0})
	container.add_child(turtle)
	turtle.set_physics_process(false)
	var hatched: Array = []
	d.egg_hatched.connect(func(pos: Vector3, _by: Vector3) -> void: hatched.append(pos))
	for i in 10:
		d.tick()
	assert_false(turtle.egg_at.is_finite(), "not so soon")
	turtle.since_egg = AnimalRules.EGG_EVERY
	d.tick()
	assert_true(turtle.egg_at.is_finite(), "an egg on the sand")
	assert_eq(turtle.egg_at, Vector3(0.5, G, 0.5))
	turtle._pack_show(0.1)
	assert_not_null(turtle.get_node_or_null("Egg"), "every game shows it")
	d.tick()
	assert_eq(spawned.size(), 0, "nobody near: it waits")
	players[0] = Vector3(1.5, G, 1.0)   # a child finds it
	d.tick()
	assert_eq(spawned.size(), 1, "it hatched")
	assert_true(spawned[0].baby, "into a baby turtle")
	assert_eq(StringName(spawned[0].species), &"turtle")
	assert_eq(hatched.size(), 1, "the finder is told (a small secret)")
	assert_false(turtle.egg_at.is_finite(), "the egg is gone")
	var baby := container.get_child(container.get_child_count() - 1) as Animal
	assert_true(baby.baby)
	assert_lt(baby._size().y, float(AnimalRules.SPECIES[&"turtle"].size.y), "small")
	assert_gt(baby.voice(), VoiceRules.voice_pitch(baby.animal_id), "with a higher voice")


func test_a_turtle_on_grass_never_lays_and_pets_never_do() -> void:
	var container := Node3D.new()
	add_child_autofree(container)
	var d := AnimalDirector.new()
	d.shape = MeadowsShape.new(12345)
	d.container = container
	d.player_positions = func() -> Array[Vector3]: return [Vector3(20, G, 0)] as Array[Vector3]
	d.is_ready = func(_p: Vector3) -> bool: return false
	d.block_at = world.get_block
	d.roll = func() -> float: return 0.0
	d.spawn = func(_data: Dictionary) -> void: pass
	add_child_autofree(d)
	d.set_process(false)
	var turtle := Animal.new()
	turtle.setup({"species": &"turtle", "id": "a1_1_0", "pos": Vector3(0.5, G, 0.5), "yaw": 0.0, "owner": 0})
	container.add_child(turtle)
	turtle.set_physics_process(false)
	turtle.since_egg = AnimalRules.EGG_EVERY * 2.0
	d.tick()
	assert_false(turtle.egg_at.is_finite(), "stone under it: no egg")
