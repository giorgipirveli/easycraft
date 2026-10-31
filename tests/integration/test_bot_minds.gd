extends GutTest
## Bot friends with minds (M2 Task 18, owner feedback #24, spec §12.17): they learn their child's
## style — builders build with the child's favourite blocks and keep to designs the child keeps,
## explorers learn whether the child follows ores, animals or secrets, the follow distance adapts,
## fighters guard the side monsters come from — and remember it all in the world save. Task 15's
## rules stay: labelled bots, fixed lines, never the player's things.

## Stone below GROUND, air above; edits are recorded (and announced like the real world).
class FlatWorld:
	extends WorldService
	const GROUND := 10
	var cells := {}
	var edits: Array = []

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.STONE if pos.y < GROUND else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		edits.append([pos, id])
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func box_reader(_origin: Vector3i, _size: Vector3i) -> Callable:
		return get_block

	func copy_box(origin: Vector3i, size: Vector3i) -> VoxelBuffer:
		var buf := VoxelBuffer.new()
		buf.create(size.x, size.y, size.z)
		for z in size.z:
			for x in size.x:
				for y in size.y:
					buf.set_voxel(get_block(origin + Vector3i(x, y, z)), x, y, z, VoxelBuffer.CHANNEL_TYPE)
		return buf

	func spawn_column() -> Vector2i:
		return Vector2i.ZERO

	func surface_height(_x: int, _z: int) -> int:
		return GROUND - 1

	func find_standing_y(_x: int, _z: int) -> int:
		return GROUND

	func is_area_ready(_center: Vector3) -> bool:
		return true


class FakeMonster:
	extends Node3D

	func take_hit(_damage: int, _from: Vector3, _knockback: Vector3) -> void:
		pass


const STEP := 1.0 / 60.0
const G := FlatWorld.GROUND

var world: FlatWorld
var leader: Player
var director: BotDirector
var lines: Array[Dictionary] = []
var _session_world: WorldService
var _mode: StringName
var _names: Dictionary
var _book: MindBook


func before_each() -> void:
	_session_world = Session.world
	_mode = Game.mode
	_names = Session.chat_names.duplicate()
	_book = MindBook.current
	MindBook.current = MindBook.new()
	Game.mode = ModeRules.SANDBOX
	world = FlatWorld.new()
	autofree(world)
	Session.register_world(world)
	lines.clear()
	Session.chat_received.connect(_on_chat)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = Vector3(0, G - 0.5, 0)


func after_each() -> void:
	Session.chat_received.disconnect(_on_chat)
	Session.world = _session_world
	Game.mode = _mode
	Session.chat_names = _names
	MindBook.current = _book
	Session.survivor_reset()


func _on_chat(from: String, text: String, kind: StringName) -> void:
	lines.append({"from": from, "text": text, "kind": kind})


func _bot(personality: StringName) -> BotFriend:
	leader = load("res://entities/player/player.tscn").instantiate()
	leader.name = str(multiplayer.get_unique_id())
	leader.world = world
	add_child_autofree(leader)
	leader.set_physics_process(false)
	leader.viewer.free()
	leader._spawned = true
	leader.global_position = Vector3(0.5, G, 0.5)
	Session.chat_names[leader.peer_id] = "Tina"
	var container := Node3D.new()
	add_child_autofree(container)
	var combat := CombatDirector.new()
	combat.name = "Combat"
	add_child_autofree(combat)
	combat.block_at = world.get_block
	director = BotDirector.new()
	director.container = container
	director.world = world
	director.spawn = func(data: Dictionary) -> Node:
		var b := BotFriend.new()
		b.setup(data)
		b.world = world
		b.combat = combat
		container.add_child(b)
		return b
	add_child_autofree(director)
	await get_tree().physics_frame
	return director.add(personality)


func _steps(b: BotFriend, n: int) -> void:
	for i in n:
		if is_instance_valid(b):
			b._physics_process(STEP)


func _decisions(b: BotFriend, n: int) -> void:
	_steps(b, ceili(BotRules.AI_INTERVAL * 60.0) * n + 1)


func _dog(id: String, pos: Vector3) -> Animal:
	var a := Animal.new()
	a.setup({"species": &"dog", "id": id, "pos": pos})
	a.world = world
	add_child_autofree(a)
	return a


# --- Builders ---

func test_a_builder_friend_builds_with_the_childs_blocks() -> void:
	var b := await _bot(BotRules.BUILDER)
	for i in 4:
		world.set_block(Vector3i(3 + i, G, 0), BlockIds.SAND)       # the child's sandy wall...
	for i in 3:
		world.set_block(Vector3i(3 + i, G + 1, 0), BlockIds.DIRT)   # ... topped with dirt (no design has either)
	assert_eq(b.style.favourite_blocks(), [BlockIds.SAND, BlockIds.DIRT] as Array[int])
	assert_gt(b.style.shape().y, 0.5, "the child builds wide")
	world.edits.clear()
	b._build_t = 0.0
	for i in 600:
		_steps(b, 1)
		if not world.edits.is_empty():
			break
	assert_gt(world.edits.size(), 1, "a build")
	var own := 0
	for e: Array in world.edits:
		assert_true(e[1] in [BlockIds.SAND, BlockIds.DIRT, BlockIds.LIGHT, BlockIds.LEAVES], "the child's blocks: %s" % [e])
		if e[1] in [BlockIds.SAND, BlockIds.DIRT]:
			own += 1
	assert_gt(own, 0)


func _build_now(b: BotFriend) -> Array[Vector3i]:
	world.edits.clear()
	b._build_t = 0.0
	for i in 900:
		_steps(b, 1)
		if not world.edits.is_empty():
			break
	var cells: Array[Vector3i] = []
	for e: Array in world.edits:
		cells.append(e[0])
	return cells


func test_a_builder_learns_from_builds_the_child_keeps_or_breaks() -> void:
	var b := await _bot(BotRules.BUILDER)
	world.set_block(Vector3i(3, G, 0), BlockIds.BRICK)
	var cells := _build_now(b)
	assert_false(cells.is_empty())
	var design := b._build_action
	var before := BotSpecies.design_odds(b.mind, b.style, 5)[design]
	world.set_block(cells[0], BlockIds.AIR)                        # the child breaks it
	assert_lt(BotSpecies.design_odds(b.mind, b.style, 5)[design], before, "that design comes less often")
	assert_true(b._build_cells.is_empty(), "one lesson per build")
	# The next build stays: a kept build brings its design back more often.
	world.set_block(Vector3i(3, G + 1, 0), BlockIds.BRICK)
	cells = _build_now(b)
	assert_false(cells.is_empty())
	design = b._build_action
	before = BotSpecies.design_odds(b.mind, b.style, 5)[design]
	b.mind.tick(BotFriend.KEPT_AFTER + 1.0)
	_decisions(b, 2)
	assert_gt(BotSpecies.design_odds(b.mind, b.style, 5)[design], before, "kept: more like it")


# --- Explorers ---

func _find(e: BotFriend) -> void:
	e._clear_sight()
	e._scan_t = 0.0
	_decisions(e, 2)


func test_an_explorer_learns_what_the_child_follows() -> void:
	var e := await _bot(BotRules.EXPLORER)
	for round in 4:
		var gold := Vector3i(3 - round, G - 1, 2)
		world.cells[gold] = BlockIds.GOLD
		_find(e)
		assert_eq(e._find_kind, BotSpecies.FIND_ORE, "round %d: shows the gold" % round)
		e.mind.tick(BotFriend.FIND_WAIT + 1.0)                    # the child walks on
		_decisions(e, 1)
		assert_eq(e._find_kind, &"", "that find is over")
		var dog := _dog("d%d" % round, e.global_position + Vector3(3, 0, -1))
		_find(e)
		assert_eq(e._find_kind, BotSpecies.FIND_ANIMAL, "round %d: shows the dog" % round)
		dog.owner_peer = leader.peer_id                            # the child tames it
		_decisions(e, 1)
		dog.free()
	var both := BotSpecies.find_mask([BotSpecies.FIND_ORE, BotSpecies.FIND_ANIMAL])
	assert_gt(BotSpecies.find_odds(e.mind, both)[BotSpecies.index(BotSpecies.FIND_ANIMAL)], 0.75)
	world.cells[Vector3i(4, G - 1, -2)] = BlockIds.GOLD
	_dog("last", e.global_position + Vector3(-3, 0, 1))
	_find(e)
	assert_eq(e._find_kind, BotSpecies.FIND_ANIMAL, "with gold and a dog around, it shows the dog")
	assert_eq(e._sight_kind, &"animal")


func test_an_explorer_counts_a_mined_ore_and_a_visited_secret() -> void:
	var e := await _bot(BotRules.EXPLORER)
	var gold := Vector3i(3, G - 1, 2)
	world.cells[gold] = BlockIds.GOLD
	_find(e)
	var lessons := e.mind.lessons
	world.set_block(gold, BlockIds.AIR)                           # mined
	_decisions(e, 1)
	assert_eq(e.mind.lessons, lessons + 1)
	assert_eq(e._find_kind, &"")
	e._clear_sight()                                              # done pointing at the gold
	assert_true(e.notice(leader.global_position + Vector3(6, 0, 0), "A secret!"))
	assert_eq(e._find_kind, BotSpecies.FIND_SECRET)
	leader.global_position += Vector3(5, 0, 0)                    # the child goes to look
	await get_tree().physics_frame
	_decisions(e, 1)
	assert_eq(e.mind.lessons, lessons + 2)


# --- Space and guarding ---

func test_the_follow_distance_adapts_when_the_child_keeps_walking_away() -> void:
	var b := await _bot(BotRules.FIGHTER)
	for round in 3:
		await _come_back(b)                                        # the friend comes and stands by
		leader.velocity = Vector3(-6, 0, 0)                        # and the child walks off at once
		for i in 50:
			leader.global_position += Vector3(-0.1, 0, 0)
			_steps(b, 1)
		leader.velocity = Vector3.ZERO
		await get_tree().physics_frame
		b.mind.tick(BotFriend.SPACE_GAP)
	assert_gte(b.style.space, 2.0, "more space: %s" % b.style.space)
	await _come_back(b)
	assert_gte(_flat(b.global_position, leader.global_position), BotRules.FOLLOW_NEAR + b.style.space - 0.5,
		"it stops further away now")
	var around := leader.global_position
	var spot := b._mind_spaced(around + Vector3(BotRules.WANDER_MIN, 0, 0), around)
	assert_almost_eq(_flat(spot, around), BotRules.WANDER_MIN + b.style.space, 0.01, "and wanders further out")


## The child goes on ahead; the friend follows until it stands by again.
func _come_back(b: BotFriend) -> void:
	leader.global_position += Vector3(-12, 0, 0)
	await get_tree().physics_frame                                 # players are looked up once a frame
	_steps(b, 12)
	for i in 400:
		_steps(b, 1)
		if b.behaviour != BotRules.FOLLOW:
			return


func _flat(a: Vector3, c: Vector3) -> float:
	return Vector2(a.x - c.x, a.z - c.z).length()


func test_a_fighter_guards_the_side_monsters_come_from() -> void:
	var f := await _bot(BotRules.FIGHTER)
	for i in 3:
		var m := FakeMonster.new()
		m.add_to_group(&"monsters")
		add_child_autofree(m)
		m.global_position = leader.global_position + Vector3(9, 0, i - 1)
		await get_tree().physics_frame                             # monsters are looked up once a frame
		_decisions(f, 1)
		assert_eq(f.behaviour, BotRules.FIGHT)
		m.free()
		await get_tree().physics_frame
		_decisions(f, 1)
	var a := f.style.guard_angle()
	assert_false(is_nan(a), "it knows the side")
	assert_gt(cos(a), 0.9, "east, where they came from")
	for i in 20:
		# A wander spot rolled within 1.2 m of the friend ends in the same decision, and the next one would be
		# 2-6 s away: the wait is set to nothing each time, so a wander that lasts is always seen (a flake before).
		f._wander_t = 0.0
		_decisions(f, 1)
		if f.behaviour == BotRules.WANDER and f._wander_spot.is_finite():
			break
	assert_eq(f.behaviour, BotRules.WANDER)
	assert_gt(f._wander_spot.x, leader.global_position.x + 1.0, "stands guard on that side")


# --- Remembering ---

func test_friends_keep_what_they_learned_and_greet_the_child_by_name() -> void:
	var b := await _bot(BotRules.BUILDER)
	assert_true(b.mind.memory.knows("Tina"), "it knows its child")
	for i in 3:
		world.set_block(Vector3i(5, G + i, 4), BlockIds.BLUE)
	var saved := director.to_save()
	assert_true(saved[0].has("mind"))
	assert_lte(JSON.stringify(saved[0].mind).length(), 2048)
	var meta := WorldMeta.new_random()
	meta.bots = saved
	var back := WorldMeta.from_json(meta.to_json())
	b.free()
	lines.clear()
	director.restore(back.bots)
	var again := director.bots()[0]
	assert_eq(again.style.favourite_blocks(), [BlockIds.BLUE] as Array[int], "still knows the child's blocks")
	assert_eq(lines.size(), 1)
	assert_string_contains(lines[0].text, "Tina", "greets the child by name")
	assert_string_contains(lines[0].text, again.bot_name)
	assert_eq(lines[0].kind, &"bot")


func test_the_greeting_is_a_fixed_friendly_line() -> void:
	for p in BotRules.PERSONALITIES:
		var line := BotSpecies.greeting("Tina", "Pip", p)
		assert_string_contains(line, "Tina")
		assert_false(line.contains("?"), "never asks anything: %s" % line)
		for bad in ["miss", "come back", "lonely", "sad", "where were you"]:
			assert_false(line.to_lower().contains(bad), line)
