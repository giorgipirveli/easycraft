extends GutTest
## M3 Task 7 (spec §14.4, §3a, §16 "friends racing your course"): Game Blocks in a world. A runner's own
## game watches its feet (CourseDirector.watch) and tells the host what they touch; the host times everyone
## with its own clock (CourseDirector): START arms a runner's clock and stepping off starts it; a checkpoint
## is where a fall comes back (the runner's own game moves them); coins count for the course only, never
## Survivor gold; FINISH gives the time and a medal by the builder's goals (the first run sets them), and a
## guest's finish counts only when they passed START and are on the FINISH as far as the host can tell.
## The best run is recorded at 10 Hz (3 minutes at most) for bot friends; everything is saved.

const S := Vector3i(0, 9, 0)            # START under the player's feet
const CHECK := Vector3i(8, 9, 0)
const COIN_A := Vector3i(4, 10, 0)
const COIN_B := Vector3i(5, 10, 0)
const F := Vector3i(16, 9, 0)
const ON_START := Vector3(0.5, 10.0, 0.5)


class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

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


class FakePeer:
	extends MultiplayerPeerExtension
	var id := 1
	var server := true
	var _target := 0

	func _get_unique_id() -> int:
		return id

	func _is_server() -> bool:
		return server

	func _get_connection_status() -> MultiplayerPeer.ConnectionStatus:
		return MultiplayerPeer.CONNECTION_CONNECTED

	func _put_packet_script(_buffer: PackedByteArray) -> Error:
		return OK

	func _get_packet_script() -> PackedByteArray:
		return PackedByteArray()

	func _get_available_packet_count() -> int:
		return 0

	func _get_max_packet_size() -> int:
		return 1 << 20

	func _set_target_peer(peer: int) -> void:
		_target = peer

	func _get_packet_peer() -> int:
		return 1

	func _get_packet_mode() -> MultiplayerPeer.TransferMode:
		return MultiplayerPeer.TRANSFER_MODE_RELIABLE

	func _get_packet_channel() -> int:
		return 0

	func _set_transfer_channel(_channel: int) -> void:
		pass

	func _get_transfer_channel() -> int:
		return 0

	func _set_transfer_mode(_mode: MultiplayerPeer.TransferMode) -> void:
		pass

	func _get_transfer_mode() -> MultiplayerPeer.TransferMode:
		return MultiplayerPeer.TRANSFER_MODE_RELIABLE

	func _poll() -> void:
		pass

	func _close() -> void:
		pass

	func _disconnect_peer(_peer: int, _force: bool) -> void:
		pass


var world: EditWorld
var me: Player
var courses: CourseDirector
var clock := [0]
var states: Array = []
var infos: Array = []
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	world = EditWorld.new()
	add_child_autofree(world)
	for c: Vector3i in [S, CHECK, F]:
		world.cells[c] = [BlockIds.START, BlockIds.CHECKPOINT, BlockIds.FINISH][[S, CHECK, F].find(c)]
	world.cells[COIN_A] = BlockIds.COIN
	world.cells[COIN_B] = BlockIds.COIN
	Session.register_world(world)
	clock[0] = 0
	Session.smart_now_ms = func() -> int: return clock[0]
	states = []
	infos = []
	Session.course_state_received.connect(_on_state)
	Session.course_info_received.connect(_on_info)
	me = _player(multiplayer.get_unique_id(), ON_START)
	courses = _director({})


func after_each() -> void:
	Session.course_state_received.disconnect(_on_state)
	Session.course_info_received.disconnect(_on_info)
	Game.mode = _mode_before
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Session.register_world(null)
	Session.survivor_reset()
	Session.smart_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_state(state: Dictionary) -> void:
	states.append(state)


func _on_info(info: Dictionary) -> void:
	infos.append(info)


func _director(saved: Dictionary) -> CourseDirector:
	var d := CourseDirector.new()
	d.name = "Courses"
	d.now_ms = func() -> int: return clock[0]
	add_child_autofree(d)
	d.set_process(false)
	d.set_physics_process(false)
	d.start(saved)
	return d


func _player(peer: int, feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.global_position = feet
	p._spawned = true
	return p


func _at(t: int, id: int, cell: Vector3i, left: bool = false) -> bool:
	clock[0] = t
	me.global_position = CourseRules.top_of(cell) if id != BlockIds.COIN else Vector3(cell) + Vector3(0.5, 0.0, 0.5)
	return Session.request_smart_touch(id, cell, left)


func _last() -> Dictionary:
	return states.back() if not states.is_empty() else {}


## START at t0, off it at t_go.
func _start(t0: int = 0, t_go: int = 1000) -> void:
	_at(t0, BlockIds.START, S)
	_at(t_go, BlockIds.START, S, true)


# --- Timing ---

func test_start_arms_the_clock_and_stepping_off_starts_it() -> void:
	assert_true(_at(0, BlockIds.START, S))
	assert_true(_last().on and _last().armed, "on START: the clock shows 0.0")
	assert_eq(int(_last().elapsed), 0)
	_at(2000, BlockIds.START, S, true)
	assert_true(_last().on)
	assert_false(_last().armed, "stepped off: running")
	clock[0] = 5000
	assert_eq(courses.elapsed_of(me.peer_id), 3000)


func test_finish_shows_the_time_and_a_medal_by_the_goals() -> void:
	_start(0, 1000)
	_at(41000, BlockIds.FINISH, F)
	var done := _last()
	assert_false(done.on)
	assert_eq(done.event, "finish")
	assert_eq(int(done.ms), 40000)
	assert_eq(done.medal, String(CourseRules.GOLD), "the first run sets the goals: gold")
	assert_eq(courses.book.goals(S), [40000, 52000, 64000])
	_start(50000, 50000)
	_at(100000, BlockIds.FINISH, F)
	assert_eq(_last().medal, String(CourseRules.SILVER), "50 s against 40 / 52 / 64")


## M3 Task 12 meets Task 7 (the lead's merge): a finished race counts on the runner's own progress.
func test_a_finished_race_counts_for_the_runner() -> void:
	var data := ProgressData.new()
	Progress.begin(data)
	_start(0, 1000)
	_at(41000, BlockIds.FINISH, F)
	Progress.end()
	assert_eq(data.count(&"race_finished"), 1, "the runner's game counted the race")


## Owner #45a: the medal counts too ("Win a gold medal" on the board), and the race still counts once.
func test_a_finished_race_counts_its_medal() -> void:
	var data := ProgressData.new()
	Progress.begin(data)
	_start(0, 1000)
	_at(41000, BlockIds.FINISH, F)
	_start(50000, 50000)
	_at(100000, BlockIds.FINISH, F)
	Progress.end()
	assert_eq(data.count(&"race_finished"), 2)
	assert_eq(data.count(&"race_finished/gold"), 1, "the first run: gold")
	assert_eq(data.count(&"race_finished/silver"), 1)


func test_touching_start_again_starts_over() -> void:
	_start(0, 1000)
	_at(9000, BlockIds.START, S)
	_at(9500, BlockIds.START, S, true)
	_at(19500, BlockIds.FINISH, F)
	assert_eq(int(_last().ms), 10000)


func test_a_finish_without_a_start_is_nothing() -> void:
	_at(5000, BlockIds.FINISH, F)
	assert_eq(states.size(), 0, "never passed START")
	assert_eq(courses.book.starts().size(), 0)


func test_a_guests_finish_is_checked_by_the_host() -> void:
	var peer := FakePeer.new()
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(5)
	var guest := _player(5, ON_START)
	assert_true(Session.host_smart_touch(5, BlockIds.START, S, false))
	clock[0] = 1000
	assert_true(Session.host_smart_touch(5, BlockIds.START, S, true))
	clock[0] = 9000
	guest.global_position = ON_START        # the host sees the guest far from the FINISH
	assert_false(Session.host_smart_touch(5, BlockIds.FINISH, F, false), "a guest the host sees far away can't finish")
	assert_true(courses.is_running(5))
	guest.global_position = CourseRules.top_of(F)
	assert_true(Session.host_smart_touch(5, BlockIds.FINISH, F, false))
	assert_false(courses.is_running(5), "finished: timed by the host")
	assert_eq(courses.book.best(S), 8000)
	var other := _player(6, CourseRules.top_of(F))
	peer.peer_connected.emit(6)
	assert_true(Session.host_smart_touch(6, BlockIds.FINISH, F, false))
	assert_eq(courses.book.best(S), 8000, "a guest who never passed START finishes nothing")
	other.queue_free()


# --- Checkpoints and falls ---

func test_a_checkpoint_is_where_a_fall_comes_back() -> void:
	courses.setup_local(me)
	_start(0, 1000)
	assert_eq(_last().spot, CourseRules.top_of(S), "before any checkpoint a fall comes back to START")
	_at(3000, BlockIds.CHECKPOINT, CHECK)
	assert_eq(_last().spot, CourseRules.top_of(CHECK))
	assert_eq(_last().event, "checkpoint")
	me.global_position = CourseRules.top_of(CHECK) + Vector3(2, -12.5, 0)   # fell off the course
	courses.watch()
	assert_eq(me.global_position, CourseRules.top_of(CHECK), "back on the checkpoint")
	assert_true(courses.is_racing(), "still racing")


func test_falling_into_water_comes_back_too() -> void:
	courses.setup_local(me)
	_start(0, 1000)
	me.global_position = Vector3(3.5, 10.0, 0.5)
	me.water_state = SwimRules.State.SWIMMING
	courses.watch()
	assert_eq(me.global_position, CourseRules.top_of(S))
	me.water_state = SwimRules.State.DRY


func test_nobody_is_moved_when_not_racing() -> void:
	courses.setup_local(me)
	me.global_position = Vector3(3.5, -30.0, 0.5)
	courses.watch()
	assert_eq(me.global_position, Vector3(3.5, -30.0, 0.5))


# --- Coins ---

func test_coins_count_once_per_run_and_never_pay_gold() -> void:
	Game.mode = ModeRules.SURVIVOR
	var gold_before := Session.gold_of(me.peer_id)
	_start(0, 1000)
	_at(2000, BlockIds.COIN, COIN_A)
	_at(2100, BlockIds.COIN, COIN_A)
	_at(2200, BlockIds.COIN, COIN_B)
	assert_eq(int(_last().coins), 2, "each coin once")
	_at(9000, BlockIds.FINISH, F)
	assert_eq(int(_last().coins), 2, "the finish shows the course's coins")
	assert_eq(Session.gold_of(me.peer_id), gold_before, "never Survivor gold: courses can't farm gold")


func test_coins_before_a_run_count_nothing() -> void:
	_at(500, BlockIds.COIN, COIN_A)
	assert_eq(states.size(), 0)


# --- The best run, recorded ---

func test_the_best_run_is_recorded_at_10_hz_for_bots() -> void:
	_start(0, 1000)
	for i in 50:                              # 5 s of running, sampled by the host's tick
		clock[0] = 1000 + i * 100
		me.global_position = Vector3(0.5 + i * 0.3, 10.0, 0.5)
		courses.tick(0.1)
	_at(6000, BlockIds.FINISH, F)
	var ghost := courses.book.ghost(S)
	assert_not_null(ghost)
	assert_between(ghost.size(), 48, 52, "10 samples a second")
	assert_almost_eq(ghost.sample_at(2.0).x, 0.5 + 20 * 0.3, 0.35)


func test_a_run_over_3_minutes_keeps_no_recording() -> void:
	_start(0, 1000)
	for i in RecordedRun.MAX_SAMPLES + 20:
		clock[0] = 1000 + i * 100
		courses.tick(0.1)
	_at(1000 + (RecordedRun.MAX_SAMPLES + 20) * 100, BlockIds.FINISH, F)
	assert_true(courses.book.best(S) > 0, "the time still counts")
	assert_null(courses.book.ghost(S), "but a bot can't race a run cut short")


# --- The goals panel ---

func test_tapping_finish_shows_its_course_and_the_builder_sets_the_goals() -> void:
	_start(0, 1000)
	_at(31000, BlockIds.FINISH, F)
	Session.request_course_info(F)
	assert_eq(infos.size(), 1)
	assert_eq(infos[0].goals, [30000, 39000, 48000])
	assert_eq(int(infos[0].best), 30000)
	Session.request_course_goals(F, [25000, 35000, 45000])
	assert_eq(courses.book.goals(S), [25000, 35000, 45000])
	assert_eq(infos.back().goals, [25000, 35000, 45000], "the panel hears the new goals")


func test_a_course_nobody_finished_yet_says_so() -> void:
	me.global_position = CourseRules.top_of(F) + Vector3(-2, 0, 0)
	Session.request_course_info(F)
	assert_eq(infos.size(), 1)
	assert_true(infos[0].none, "race it once first")


# --- Stopping, saving ---

func test_a_knocked_out_runner_stops() -> void:
	_start(0, 1000)
	me.knocked_out = true
	courses.tick(0.2)
	assert_false(courses.is_running(me.peer_id))
	assert_eq(_last().event, "stop")
	me.knocked_out = false


func test_courses_are_saved_and_loaded() -> void:
	_start(0, 1000)
	for i in 20:
		clock[0] = 1000 + i * 100
		courses.tick(0.1)
	_at(3000, BlockIds.FINISH, F)
	var again := _director({"courses": courses.to_save()})
	assert_eq(again.book.best(S), 2000)
	assert_not_null(again.book.ghost(S))


# --- The runner's own game watches its feet ---

func test_the_players_own_game_reports_start_and_stepping_off() -> void:
	courses.setup_local(me)
	me.global_position = ON_START
	courses.watch()
	assert_true(_last().armed, "standing on START")
	clock[0] = 800
	me.global_position = Vector3(2.5, 10.0, 0.5)        # stepped onto the grass
	courses.watch()
	assert_false(_last().armed, "off START: the clock runs")
	me.global_position = Vector3(4.5, 10.3, 0.5)        # through the coin (feet in its cell)
	courses.watch()
	assert_eq(int(_last().coins), 1)
	clock[0] = 7800
	me.global_position = CourseRules.top_of(F)
	courses.watch()
	assert_eq(_last().event, "finish")
	assert_eq(int(_last().ms), 7000)
