extends GutTest
## M3 Task 7 (spec §14.4 "friends and bot friends can race it", §16 "friends racing your course"): a bot
## friend races the recorded best run of the course nearest its player as its own run, a little faster or
## slower (0.9-1.1): it waits by START, goes when a runner starts that course, follows the recording (no
## pathfinding, no physics) and finishes with confetti and its time. The FRIENDS page's RACE ME! asks for it.

const S := Vector3i(0, 9, 0)
const F := Vector3i(20, 9, 0)


class FlatWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.STONE if pos.y < 10 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func surface_height(_x: int, _z: int) -> int:
		return 9

	func find_standing_y(_x: int, _z: int) -> int:
		return 10

	func is_area_ready(_center: Vector3) -> bool:
		return true


var world: FlatWorld
var me: Player
var courses: CourseDirector
var clock := [0]
var _mode: StringName
var _style: String


func before_each() -> void:
	_mode = Game.mode
	Game.mode = ModeRules.SANDBOX
	_style = str(Profile.data.settings.style)
	Profile.data.settings.style = "blocky"
	world = FlatWorld.new()
	add_child_autofree(world)
	world.cells[S] = BlockIds.START
	world.cells[F] = BlockIds.FINISH
	Session.register_world(world)
	clock[0] = 0
	Session.smart_now_ms = func() -> int: return clock[0]
	me = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me._spawned = true
	me.global_position = CourseRules.top_of(S)
	courses = CourseDirector.new()
	courses.name = "Courses"
	courses.now_ms = func() -> int: return clock[0]
	add_child_autofree(courses)
	courses.set_process(false)
	courses.set_physics_process(false)
	courses.start({})


func after_each() -> void:
	Game.mode = _mode
	Profile.data.settings.style = _style
	Session.register_world(null)
	Session.smart_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _bot() -> BotFriend:
	var b := BotFriend.new()
	b.setup({"id": "Bot1", "name": "Pip", "personality": "builder", "look": 0, "pos": Vector3(3, 10, 3), "yaw": 0.0})
	b.world = world
	b.leader_peer = me.peer_id
	add_child_autofree(b)
	b.set_physics_process(false)
	return b


## The player runs the course in 10 s along a straight line, recorded by the host.
func _run_the_course() -> void:
	Session.request_smart_touch(BlockIds.START, S)
	clock[0] = 1000
	Session.request_smart_touch(BlockIds.START, S, true)
	for i in 101:
		clock[0] = 1000 + i * 100
		me.global_position = CourseRules.top_of(S) + Vector3(i * 0.2, 0, 0)
		courses.tick(0.1)
	me.global_position = CourseRules.top_of(F)
	clock[0] = 11000
	Session.request_smart_touch(BlockIds.FINISH, F)
	me.global_position = CourseRules.top_of(S)


func test_no_course_yet_no_race() -> void:
	var b := _bot()
	assert_eq(courses.race_bot(b), CourseDirector.NO_COURSE)
	assert_false(b.is_racing())


func test_a_bot_waits_by_start_and_goes_when_a_runner_starts() -> void:
	_run_the_course()
	var b := _bot()
	assert_eq(courses.race_bot(b), "", "it will race")
	assert_true(b.is_racing())
	assert_false(b.race_running(), "waiting by START")
	assert_lt(b.global_position.distance_to(CourseRules.top_of(S)), 2.0, "next to START")
	var waiting_at := b.global_position
	b._physics_process(0.5)
	assert_eq(b.global_position, waiting_at, "it waits")
	clock[0] = 20000
	Session.request_smart_touch(BlockIds.START, S)
	clock[0] = 20500
	Session.request_smart_touch(BlockIds.START, S, true)   # the child steps off START: go!
	assert_true(b.race_running())


func test_a_bot_replays_the_best_run_as_its_own_and_finishes() -> void:
	_run_the_course()
	var b := _bot()
	courses.race_bot(b)
	b.race_go()
	var halfway := false
	for i in 300:                              # 15 s: the 10 s run at 0.9 × takes 11.1 s
		b._physics_process(0.05)
		if not halfway and b.global_position.x > CourseRules.top_of(S).x + 9.0:
			halfway = true
			assert_almost_eq(b.global_position.y, 10.0, 0.01, "on the recorded way")
			assert_almost_eq(b.velocity.x, 2.0 * b._race_speed, 0.3, "at the run's speed")
		if not b.is_racing():
			break
	assert_true(halfway)
	assert_false(b.is_racing(), "finished")
	assert_almost_eq(b.global_position.x, CourseRules.top_of(S).x + 20.0, 0.3, "at the end of the recording")


func test_its_time_varies_a_little_around_the_best_run() -> void:
	_run_the_course()
	var times: Array[int] = []
	for i in 6:
		var b := _bot()
		b.name = "Bot%d" % i
		courses.race_bot(b)
		b.race_go()
		watch_signals(b)
		for k in 400:
			b._physics_process(0.05)
			if not b.is_racing():
				break
		var params: Array = get_signal_parameters(b, "race_done")
		assert_not_null(params, "it finished")
		times.append(params[1])
		b.queue_free()
	for t in times:
		assert_between(t, 9000, 11400, "the best run (10 s and the FINISH) at 0.9-1.1 × its speed")


func test_a_bot_waiting_too_long_says_another_time() -> void:
	_run_the_course()
	var b := _bot()
	courses.race_bot(b)
	for i in 70:
		b._physics_process(1.0)
	assert_false(b.is_racing(), "it gave up after a minute")


func test_race_me_in_the_friends_page() -> void:
	_run_the_course()
	var container := Node3D.new()
	add_child_autofree(container)
	var d := BotDirector.new()
	d.container = container
	d.world = world
	d.leader = func() -> Player: return me
	d.spawn = func(data: Dictionary) -> Node:
		var b := BotFriend.new()
		b.setup(data)
		b.world = world
		container.add_child(b)
		b.set_physics_process(false)
		return b
	d.race_with = courses.race_bot
	add_child_autofree(d)
	var bot := d.add(BotRules.BUILDER)
	var panel := FriendsPanel.new()
	panel.director = d
	add_child_autofree(panel)
	watch_signals(panel)
	var button := panel.find_child("Race%s" % bot.bot_name, true, false) as Button
	assert_not_null(button, "every friend's row has RACE ME!")
	assert_gte(button.get_combined_minimum_size().y, 72.0, "big enough for a thumb")
	button.pressed.emit()
	assert_signal_emitted(panel, "raced", "the menu closes: off to START")
	assert_true(bot.is_racing())


func test_race_me_with_no_course_says_why() -> void:
	var container := Node3D.new()
	add_child_autofree(container)
	var d := BotDirector.new()
	d.container = container
	d.world = world
	d.leader = func() -> Player: return me
	d.spawn = func(data: Dictionary) -> Node:
		var b := BotFriend.new()
		b.setup(data)
		b.world = world
		container.add_child(b)
		b.set_physics_process(false)
		return b
	d.race_with = courses.race_bot
	add_child_autofree(d)
	var bot := d.add(BotRules.EXPLORER)
	var panel := FriendsPanel.new()
	panel.director = d
	add_child_autofree(panel)
	watch_signals(panel)
	(panel.find_child("Race%s" % bot.bot_name, true, false) as Button).pressed.emit()
	assert_signal_not_emitted(panel, "raced")
	assert_true(panel.find_children("*", "Label", true, false).any(
		func(l: Node) -> bool: return (l as Label).text == CourseDirector.NO_COURSE), "the page says why")
