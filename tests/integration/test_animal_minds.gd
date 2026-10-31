extends GutTest
## Animals with minds (M2 Task 18, owner feedback #24, spec §12.17): they act like real animals —
## run over to a child who fed them and keep away from one who hit them, herds follow a leader and
## sleep together at night by a tree, they go and look at something new, pets remember their owner
## by name — on the M1b rules (host only, near players only, decisions ten times a second).

## Stone below GROUND, air above, plus the cells a test sets (trees, new blocks).
class FlatWorld:
	extends WorldService
	const GROUND := 10
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.STONE if pos.y < GROUND else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		cells[pos] = id
		block_changed.emit(pos, old, id)

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
var _names: Dictionary


func before_each() -> void:
	_book = MindBook.current
	MindBook.current = MindBook.new()
	_source = Animal.time_source
	Animal.time_source = func() -> float: return _time
	_time = DayCycle.NOON
	_names = Session.chat_names.duplicate()
	world = FlatWorld.new()
	autofree(world)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = Vector3(0, G - 0.5, 0)


func after_each() -> void:
	MindBook.current = _book
	Animal.time_source = _source
	Session.chat_names = _names


## A player (peer `peer`, called `who`) standing still at `pos`.
func _player(peer: int, who: String, pos: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = pos
	Session.chat_names[peer] = who
	return p


func _animal(species: StringName, id: String, pos: Vector3, owner := 0) -> Animal:
	var a := Animal.new()
	a.setup({"species": species, "id": id, "pos": pos, "yaw": 0.0, "owner": owner,
		"name": "Biscuit" if owner != 0 else "", "sitting": false})
	a.world = world
	add_child_autofree(a)
	return a


func _run(animals: Array, seconds: float) -> void:
	for i in roundi(seconds / STEP):
		for a: Animal in animals:
			if is_instance_valid(a):
				a._physics_process(STEP)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- Affection and fear ---

func test_an_animal_fed_by_a_comes_to_a_and_keeps_away_from_b_who_hit_it() -> void:
	var ann := _player(2, "Ann", Vector3(12.5, G, 0.5))
	var bob := _player(3, "Bob", Vector3(-11.5, G, 0.5))
	var sheep := _animal(&"sheep", "s_test", Vector3(0.5, G, 0.5))
	await get_tree().physics_frame                    # players join the shared list between frames
	sheep.mind_fed(ann)
	assert_gt(sheep.mind.memory.like("Ann"), 0.3, "it likes the child who fed it")
	_run([sheep], 8.0)
	assert_lt(_flat(sheep.global_position, ann.global_position), 4.0, "ran over to Ann")
	# Bob comes over and hits it (a weapon pushes it away from him).
	bob.global_position = sheep.global_position + Vector3(-2.5, 0, 0)
	await get_tree().physics_frame
	sheep.knockback(Vector3(4, 0, 0))
	assert_gt(sheep.mind.memory.fear("Bob"), 0.5, "it knows who hit it")
	assert_eq(sheep.mind.memory.fear("Ann"), 0.0, "and it wasn't Ann")
	_run([sheep], 4.0)
	assert_gt(_flat(sheep.global_position, bob.global_position), 7.0, "keeps away from Bob")
	# Bob follows it: it keeps away again.
	bob.global_position = sheep.global_position + Vector3(-3.0, 0, 0.5)
	await get_tree().physics_frame
	_run([sheep], 4.0)
	assert_gt(_flat(sheep.global_position, bob.global_position), 6.0, "still keeps away")


func test_petting_is_liked_too_and_a_hit_makes_it_sweat() -> void:
	var ann := _player(2, "Ann", Vector3(3.5, G, 0.5))
	var pig := _animal(&"pig", "p_test", Vector3(0.5, G, 0.5))
	await get_tree().physics_frame
	pig.mind_petted(ann)
	assert_gt(pig.mind.memory.like("Ann"), 0.1)
	pig.knockback(Vector3(-4, 0, 0))
	assert_gt(pig.mind.memory.fear("Ann"), 0.3)
	assert_lt(pig.mind.memory.like("Ann"), 0.2, "a hit spoils the friendship a little")


# --- Herds ---

func test_a_herd_follows_its_leader() -> void:
	_player(2, "Ann", Vector3(0.5, G, 12.5))
	var leader := _animal(&"sheep", "a5_5_0", Vector3(0.5, G, 0.5))
	var a := _animal(&"sheep", "a5_5_1", Vector3(2.0, G, 1.5))
	var b := _animal(&"sheep", "a5_5_2", Vector3(-1.0, G, 1.5))
	await get_tree().physics_frame
	assert_same(a.herd_leader(), leader)
	assert_same(leader.herd_leader(), leader)
	leader.global_position = Vector3(16.5, G, 0.5)    # the leader wandered off
	_run([a, b], 12.0)
	for s in [a, b]:
		assert_lt(_flat(s.global_position, leader.global_position), 6.0, "%s went after the leader" % s.animal_id)


# --- Sleeping ---

func test_animals_sleep_together_at_night_by_a_tree_and_wake_in_the_morning() -> void:
	_player(2, "Ann", Vector3(0.5, G, 14.5))
	for y in 4:
		world.cells[Vector3i(6, G + y, 0)] = BlockIds.LOG          # a tree trunk
	var leader := _animal(&"cow", "a7_7_0", Vector3(0.5, G, 0.5))
	var other := _animal(&"cow", "a7_7_1", Vector3(-2.0, G, 2.0))
	await get_tree().physics_frame
	_time = 0.95                                                   # night
	_run([leader, other], 20.0)
	for c in [leader, other]:
		assert_eq(c.mind_action(), AnimalSpecies.SLEEP, "%s sleeps" % c.animal_id)
		assert_true(c.sitting, "lying down")
		assert_lt(_flat(c.global_position, Vector3(6.5, G, 0.5)), 3.5, "by the tree")
	assert_lt(_flat(leader.global_position, other.global_position), 3.5, "together")
	_time = DayCycle.NOON
	_run([leader, other], 2.0)
	for c in [leader, other]:
		assert_ne(c.mind_action(), AnimalSpecies.SLEEP, "awake in the morning")
		assert_false(c.sitting)


func test_a_sleeping_animal_that_is_hit_wakes_and_runs() -> void:
	var ann := _player(2, "Ann", Vector3(2.5, G, 0.5))
	var pig := _animal(&"pig", "a8_8_0", Vector3(0.5, G, 0.5))
	await get_tree().physics_frame
	_time = 0.95
	_run([pig], 12.0)
	assert_true(pig.sitting)
	ann.global_position = pig.global_position + Vector3(2, 0, 0)
	await get_tree().physics_frame
	pig.knockback(Vector3(-4, 0, 0))
	_run([pig], 0.5)
	assert_false(pig.sitting, "woke up")
	assert_eq(pig.mind_action(), AnimalSpecies.FLEE)


# --- Curiosity ---

func test_a_curious_animal_goes_to_look_at_a_new_block() -> void:
	_player(2, "Ann", Vector3(0.5, G, -12.5))
	var dog := _animal(&"dog", "c_test", Vector3(0.5, G, 0.5))
	await get_tree().physics_frame
	_run([dog], 0.5)
	dog.mind.set_drive(Mind.CURIOSITY, 0.9)
	world.set_block(Vector3i(8, G, 0), BlockIds.RED)             # a child built something new
	_run([dog], 6.0)
	assert_lt(_flat(dog.global_position, Vector3(8.5, G, 0.5)), 3.0, "went over to look")


# --- Pets and saving ---

func test_a_pet_remembers_its_owner_by_name_after_a_reload() -> void:
	var ann := _player(2, "Ann", Vector3(3.5, G, 0.5))
	var dog := _animal(&"dog", "d_test", Vector3(0.5, G, 0.5))
	await get_tree().physics_frame
	for t in 3:
		dog.pet_tap(ann.peer_id, float(t) * 0.5, 0)
		dog.mind_petted(ann)
	assert_true(dog.is_pet())
	var saved := dog.to_save()
	assert_true(saved.has("mind"))
	var back := _animal(&"dog", "d_test", Vector3(0.5, G, 0.5), ann.peer_id)
	back.mind_load(JSON.parse_string(JSON.stringify(saved)).mind)
	assert_gte(back.mind.memory.like("Ann"), MindMemory.OWNER_LIKE, "Biscuit still loves Ann")
	for i in 30:
		back.mind.memory.forget(100.0 * i, 100.0)
	assert_true(back.mind.memory.knows("Ann"), "and never forgets her")


func test_what_one_sheep_learns_every_sheep_of_the_world_knows() -> void:
	var ann := _player(2, "Ann", Vector3(3.5, G, 0.5))
	var a := _animal(&"sheep", "l_a", Vector3(0.5, G, 0.5))
	var b := _animal(&"sheep", "l_b", Vector3(-3.5, G, 0.5))
	await get_tree().physics_frame
	assert_same(a.mind.net, b.mind.net)
	_run([a], 0.3)
	a.mind_fed(ann)
	assert_false(MindBook.current.net_for(AnimalSpecies.table(&"sheep")).is_fresh())
	assert_true(MindBook.current.to_save().has("animal:sheep"), "saved with the world")


func test_the_animals_action_numbers_match_the_species_table() -> void:
	assert_eq([Animal._I_GRAZE, Animal._I_WANDER, Animal._I_HERD, Animal._I_APPROACH, Animal._I_FLEE, Animal._I_SLEEP,
		Animal._I_EXPLORE, Animal._I_WATCH], [AnimalSpecies.index(AnimalSpecies.GRAZE), AnimalSpecies.index(AnimalSpecies.WANDER),
		AnimalSpecies.index(AnimalSpecies.HERD), AnimalSpecies.index(AnimalSpecies.APPROACH), AnimalSpecies.index(AnimalSpecies.FLEE),
		AnimalSpecies.index(AnimalSpecies.SLEEP), AnimalSpecies.index(AnimalSpecies.EXPLORE), AnimalSpecies.index(AnimalSpecies.WATCH)])
	for i in AnimalSpecies.ACTIONS.size():
		assert_eq([Animal._GRAZE, Animal._WANDER, Animal._HERD, Animal._APPROACH, Animal._FLEE, Animal._SLEEP, Animal._EXPLORE,
			Animal._WATCH][i], 1 << i)


func test_fish_and_golden_animals_keep_their_old_ways() -> void:
	var fish := _animal(&"fish", "f_test", Vector3(0.5, G, 0.5))
	assert_null(fish.mind)
	var gold := Animal.new()
	gold.setup({"species": &"pig", "id": "g_test", "pos": Vector3(0.5, G, 0.5), "golden": true})
	add_child_autofree(gold)
	assert_null(gold.mind)


# --- Thought bubbles ---

func test_a_thought_is_synced_on_change_and_shown_over_its_head() -> void:
	var camera := Camera3D.new()
	add_child_autofree(camera)
	camera.current = true
	camera.global_position = Vector3(0, G + 2, 6)
	ThoughtBubble.shown = 0
	var ann := _player(2, "Ann", Vector3(3.5, G, 0.5))
	var pig := _animal(&"pig", "t_test", Vector3(0.5, G, 0.5))
	var cfg := (pig.get_node("Sync") as MultiplayerSynchronizer).replication_config
	assert_eq(cfg.property_get_replication_mode(NodePath(".:thought")), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	await get_tree().physics_frame
	pig.mind_fed(ann)
	_run([pig], 0.2)
	assert_eq(pig.thought, Thought.HEART, "a heart for the child who fed it")
	pig._process(STEP)
	var bubble := pig.get_node_or_null("Thought") as ThoughtBubble
	assert_not_null(bubble)
	assert_true(bubble.visible)
	_run([pig], ThoughtBubble.SHOW_TIME + 0.2)
	assert_eq(pig.thought, Thought.NONE, "and gone again")


func test_no_thoughts_when_nobody_is_near() -> void:
	_player(2, "Ann", Vector3(25.5, G, 0.5))
	var pig := _animal(&"pig", "n_test", Vector3(0.5, G, 0.5))
	await get_tree().physics_frame
	pig.mind.show_thought(Thought.HEART)
	_run([pig], 0.5)
	assert_eq(pig.thought, Thought.NONE)
