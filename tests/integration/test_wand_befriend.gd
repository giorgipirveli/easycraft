extends GutTest
## Befriending on the child's own game (M3 Task 20b, spec §14.21): a tap on a monster holding the Magic Wand asks
## the host to befriend it (Session.befriend_requested); a tap on a boss says bosses are too big to be friends; with
## anything else in the hand a tap on a monster does what it always did.

var _player: Player
var _interactor: BlockInteractor
var _asked: Array = []


func before_each() -> void:
	_asked.clear()
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	_player = load("res://entities/player/player.tscn").instantiate()
	_player.name = str(multiplayer.get_unique_id())
	_player.world = world
	add_child_autofree(_player)
	_player.viewer.free()
	_player.set_physics_process(false)
	_player.rig.process_mode = Node.PROCESS_MODE_DISABLED   # the test aims the camera
	_player._spawned = true
	_interactor = _player.get_node("BlockInteractor")
	Session.befriend_requested.connect(_on_asked)


func after_each() -> void:
	Session.befriend_requested.disconnect(_on_asked)


func after_all() -> void:
	Audio.stop_all()


func _on_asked(peer: int, monster_name: String) -> void:
	_asked.append([peer, monster_name])


func _monster() -> Monster:
	var m := Monster.new()
	m.setup({"kind": MonsterRules.SLIME, "level": 1, "id": "calm1", "pos": Vector3(0.5, 30, 0.5), "yaw": 0.0, "wild": true,
		"universe": 1})
	m.block_at = func(_p: Vector3i) -> int: return BlockIds.AIR
	add_child_autofree(m)
	m.set_physics_process(false)
	return m


func _look_at(target: Vector3) -> Vector2:
	_player.global_position = Vector3(0.5, 30, -2.5)
	_player.camera().look_at_from_position(_player.eye_position(), target)
	return _interactor.get_viewport().get_visible_rect().size * 0.5


func _hold(item: int) -> void:
	_interactor.hotbar[0] = item
	_interactor.select_slot(0)


func test_the_wand_on_a_monster_asks_the_host_to_befriend_it() -> void:
	var m := _monster()
	_hold(ItemIds.WAND)
	await get_tree().physics_frame
	assert_true(_interactor.place_at_screen(_look_at(m.global_position + Vector3(0, 0.3, 0))))
	assert_eq(_asked, [[multiplayer.get_unique_id(), "calm1"]])


func test_a_sword_on_a_monster_never_befriends() -> void:
	var m := _monster()
	_hold(ItemIds.SWORD)
	await get_tree().physics_frame
	_interactor.place_at_screen(_look_at(m.global_position + Vector3(0, 0.3, 0)))
	assert_eq(_asked, [])


func test_a_buddy_in_front_of_a_monster_is_the_wands_tap() -> void:
	var m := _monster()
	var b := Buddy.new()
	b.setup({"flat": Buddy.pack({Vector3i.ZERO: BlockIds.PLANKS, Vector3i(0, 1, 0): BlockIds.PLANKS}), "name": "Bobble",
		"owner": multiplayer.get_unique_id(), "pos": Vector3(0.5, 30, -1.0), "yaw": 0.0, "id": "Buddy1"})
	add_child_autofree(b)
	b.set_physics_process(false)
	_hold(ItemIds.WAND)
	var slept: Array = []
	var hear := func(_peer: int, buddy_name: String) -> void: slept.append(buddy_name)
	Session.sleep_requested.connect(hear)
	await get_tree().physics_frame
	_interactor.place_at_screen(_look_at(m.global_position + Vector3(0, 0.3, 0)))
	Session.sleep_requested.disconnect(hear)
	assert_eq(_asked, [], "the buddy in front, not the monster behind it")
	assert_eq(slept, ["Buddy1"], "the wand on a buddy puts it to sleep, as always")


func test_the_wand_on_a_boss_says_it_is_too_big() -> void:
	var boss := StoneGolem.new()
	boss.setup({"id": "golem1", "pos": Vector3(0.5, 30, 1.5), "yaw": 0.0, "max_hp": 20, "tired": false, "boss": "golem",
		"center": Vector3(0.5, 30, 1.5)})
	add_child_autofree(boss)
	boss.set_physics_process(false)
	_hold(ItemIds.WAND)
	await get_tree().physics_frame
	var said: Array = []
	var hear := func(t: String) -> void: said.append(t)
	Session.magic_feedback.connect(hear)
	assert_true(_interactor.place_at_screen(_look_at(boss.hit_center())))
	Session.magic_feedback.disconnect(hear)
	assert_eq(_asked, [], "never a boss")
	assert_has(said, BefriendRules.message(BefriendRules.BOSS))
