extends GutTest
## M4 ghost races (spec §17.5, research T2): racing a friend's ghost on a course. A see-through runner in the
## friend's look waits on START while this player is near; this player's run starts as in M3 Task 7 (stepping
## off START, timed by the host) and the ghost runs its path at its own pace; at FINISH the race clock shows the
## medal against the ghost's time and a kind line. Fair: the ghost never blocks and can't be touched (no
## collision of any kind), it is not a player, and it lives on this game only.

const S := Vector3i(0, 9, 0)
const F := Vector3i(8, 9, 0)
const ON_START := Vector3(0.5, 10.0, 0.5)


class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		cells[pos] = id

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func surface_height(_x: int, _z: int) -> int:
		return 9


var world: EditWorld
var me: Player
var courses: CourseDirector
var races: GhostRaces
var clock := [0]
var shown: Array = []
var noted: Array = []
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	world = EditWorld.new()
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
	me.global_position = ON_START
	me._spawned = true
	courses = CourseDirector.new()
	courses.name = "Courses"
	courses.now_ms = func() -> int: return clock[0]
	add_child_autofree(courses)
	courses.set_process(false)
	courses.set_physics_process(false)
	courses.start({})
	courses.setup_local(me)
	shown = []
	noted = []
	courses.state_changed.connect(func(s: Dictionary) -> void: shown.append(s))
	races = GhostRaces.new()
	races.name = "GhostRaces"
	add_child_autofree(races)
	races.set_process(false)
	races.result_noted = func(key: String, ms: int) -> bool:
		noted.append([key, ms])
		return true
	races.setup(courses, me)


func after_each() -> void:
	Game.mode = _mode_before
	Session.register_world(null)
	Session.smart_reset()


func after_all() -> void:
	Audio.stop_all()


## A friend's 10 s ghost from START's top to FINISH's top (8 blocks along +x), in their look.
func _ghost(ms: int = 10000, owner := "Mia_2") -> RaceGhost:
	var g := RaceGhost.new()
	g.start = Vector3i(0, 0, 0)
	g.finish = Vector3i(8, 0, 0)
	g.ms = ms
	var n := RaceGhost.sample_count(ms)
	for i in n:
		g.points.append((Vector3(8, 0, 0) * i / float(n - 1) * 10.0).round() / 10.0)
	var look := AvatarLook.new()
	look.hat = &"crown"
	g.look = look.to_code()
	g.owner = owner
	g.owner_id = "u-mia"
	return g


func _at(t: int, id: int, cell: Vector3i, left: bool = false) -> void:
	clock[0] = t
	me.global_position = CourseRules.top_of(cell)
	Session.request_smart_touch(id, cell, left)


func test_a_ghost_waits_on_start_in_the_friends_look_and_can_never_be_touched() -> void:
	races.link(S, _ghost(), Vector3i.ZERO, "s:h1")
	var r := races.runner_at(S)
	assert_not_null(r, "this player is near: the ghost waits")
	assert_eq(r.global_position, CourseRules.top_of(S), "on START's top")
	assert_eq(r.find_children("*", "CollisionObject3D", true, false).size(), 0, "never blocks, can't be hit")
	assert_eq(r.find_children("*", "CollisionShape3D", true, false).size(), 0)
	assert_false(r.is_in_group(&"players"), "not a player")
	assert_false((r as Node) is PhysicsBody3D, "no body")
	assert_eq(r.avatar.look().hat, &"crown", "the friend's look")
	var meshes := r.avatar.find_children("*", "MeshInstance3D", true, false)
	assert_gt(meshes.size(), 0)
	for m: MeshInstance3D in meshes:
		for i in m.mesh.get_surface_count():
			assert_true(GhostLook.is_see_through(m.get_active_material(i)), "translucent: %s" % m.name)
		assert_eq(m.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


func test_names_show_only_when_this_viewer_may_see_them() -> void:
	races.names_shown = func() -> bool: return false
	races.link(S, _ghost())
	assert_eq(races.runner_at(S).tag.text, "A friend's ghost", "no name for an under-13 viewer without consent")
	races.names_shown = func() -> bool: return true
	races.link(S, _ghost())
	assert_eq(races.runner_at(S).tag.text, "Mia_2's ghost")


func test_the_ghost_runs_when_this_players_run_starts_and_stops_with_it() -> void:
	races.link(S, _ghost(), Vector3i.ZERO, "s:h1")
	var r := races.runner_at(S)
	_at(0, BlockIds.START, S)
	assert_eq(races.racing, S)
	assert_false(r.running, "waits while the child stands on START")
	_at(1000, BlockIds.START, S, true)
	assert_true(r.running, "stepped off START: go!")
	r.step(5.0)
	assert_almost_eq(r.global_position.x, CourseRules.top_of(S).x + 4.0, 0.05, "halfway at half its time")
	assert_almost_eq(r.rotation.y, atan2(-1.0, 0.0), 0.01, "facing the way it goes (+x)")
	watch_signals(r)
	r.step(6.0)
	assert_signal_emitted(r, "arrived")
	assert_eq(r.global_position, CourseRules.top_of(F), "on FINISH's top at its time")
	assert_false(r.running)
	r.step(GhostRunner.WAIT_AFTER + 0.1)
	assert_eq(r.global_position, CourseRules.top_of(S), "back on START for the next race")


func test_at_finish_the_medal_is_against_the_ghosts_time() -> void:
	races.link(S, _ghost(10000), Vector3i.ZERO, "s:h1")
	_at(0, BlockIds.START, S)
	_at(1000, BlockIds.START, S, true)
	_at(9000, BlockIds.FINISH, F)                     # 8 s against the ghost's 10 s
	var done: Dictionary = shown.back()
	assert_eq(done.event, "finish")
	assert_eq(int(done.ms), 8000)
	assert_eq(done.medal, String(CourseRules.GOLD))
	assert_true(done.best, "the ghost is beaten: sparkles")
	assert_eq(done.ghost_line, "You beat a friend's ghost!  GOLD!")
	assert_eq(noted, [["s:h1", 8000]], "the child's best against it is kept")
	assert_eq(races.racing, CourseBook.NONE)
	# The course's own goals (8 s set by the first run) would say gold at 15 s... against the ghost it is bronze.
	_at(20000, BlockIds.START, S)
	_at(21000, BlockIds.START, S, true)
	_at(36000, BlockIds.FINISH, F)
	assert_eq(shown.back().medal, String(CourseRules.BRONZE), "15 s against 10 / 13 / 16")
	assert_eq(shown.back().ghost_line, "A friend's ghost got there first. Race again!  BRONZE!")


func test_a_run_without_a_ghost_keeps_the_courses_own_medal() -> void:
	races.link(Vector3i(50, 9, 50), _ghost())       # a ghost on another course
	_at(0, BlockIds.START, S)
	_at(1000, BlockIds.START, S, true)
	_at(9000, BlockIds.FINISH, F)
	assert_false(shown.back().has("ghost_line"))
	assert_eq(shown.back().medal, String(CourseRules.GOLD), "the first run sets the goals")
	assert_eq(noted, [])


func test_far_ghosts_go_and_come_back() -> void:
	races.link(S, _ghost())
	me.global_position = Vector3(200, 10, 0)
	races.look_around()
	await wait_process_frames(1)
	assert_null(races.runner_at(S), "far away: nothing runs")
	me.global_position = ON_START
	races.look_around()
	assert_not_null(races.runner_at(S))


func test_a_ghost_only_where_its_start_still_is() -> void:
	races.start_ok = func(cell: Vector3i) -> bool: return world.get_block(cell) == BlockIds.START
	races.link(S, _ghost())
	assert_not_null(races.runner_at(S))
	world.cells[S] = BlockIds.PLANKS
	races.look_around()
	await wait_process_frames(1)
	assert_null(races.runner_at(S), "the START was broken: its ghost waits nowhere")


func test_a_stamped_ghost_is_turned_like_its_stamp() -> void:
	var g := _ghost()
	races.link(S, g, Vector3i(1, 0, 0))                # a stamp facing +x: the build's +x points to +z... right
	var r := races.runner_at(S)
	r.go()
	r.step(10.0)
	var right := Vector3(-0, 0, 1)                     # Blueprints: right of +x forward is (0, 0, 1)
	assert_eq(r.global_position, CourseRules.top_of(S) + right * 8.0, "the path turned with the build")


func test_every_frame_is_cheap() -> void:
	races.link(S, _ghost(180000))
	var r := races.runner_at(S)
	r.go()
	var t0 := Time.get_ticks_usec()
	for i in 600:
		r.step(1.0 / 60.0)
	var per := (Time.get_ticks_usec() - t0) / 600.0
	gut.p("MEASURE ghost step %.1f us" % per)
	assert_lt(per, 500.0, "a ghost's frame is well under a millisecond")
