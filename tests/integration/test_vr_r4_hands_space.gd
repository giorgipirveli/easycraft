extends GutTest
## VR P5's follow-up (a), owner #101/#110 (docs/devlog/parts/vr-perf.md "For the lead", docs/devlog/parts/vr-r4-hands.md):
## with the physics on its own thread (the Quest APK's lever `physics/3d/run_on_separate_thread.quest`) the engine reads
## the physics space only in the physics step ("Space state is inaccessible right now" anywhere else). BlockInteractor's
## and SecretTaps' ray queries all go through BlockInteractor.space_ray, and a tap that may read the space runs in the
## next physics tick then (BlockInteractor.in_space). Off that thread (phones, the web, the desktop) every tap runs at once,
## exactly as before.

class FloorWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 80 else BlockIds.AIR


const DT := 1.0 / 72.0

var p: Player
var interactor: BlockInteractor
var _settings := {}


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	var w := FloorWorld.new()
	autofree(w)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0.5, 80, 0.5)
	interactor = p.get_node("BlockInteractor") as BlockInteractor
	interactor.set_physics_process(false)   # the test runs the physics step itself
	interactor.set_process_unhandled_input(false)


func after_each() -> void:
	BlockInteractor.physics_thread = -1
	Vr.simulate(false)
	Vr.anchor(null)
	Input.flush_buffered_events()
	Profile.data.settings = _settings


func _vr_tap() -> void:
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	# the pointing hand points down at the floor a metre ahead
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis.looking_at(Vector3(0, -1, -1)), Vector3(0.2, 1.2, -0.3)))
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	Vr.step(DT)
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	Vr.step(DT)


func test_with_the_physics_on_its_own_thread_a_vr_tap_reads_the_space_only_in_the_physics_step() -> void:
	BlockInteractor.physics_thread = 1
	assert_false(interactor.space_readable(), "a test's frame is not the physics step")
	_vr_tap()
	assert_eq(interactor.unreadable_queries, 0, "no ray asked of a space the engine would refuse")
	assert_eq(interactor.space_reads, 0, "the tap waits for the physics step")
	assert_eq(interactor.waiting(), 1, "one tap waiting")
	interactor._physics_process(1.0 / 60.0)
	assert_gt(interactor.space_reads, 0, "in the physics step the tap ran and read the space")
	assert_eq(interactor.unreadable_queries, 0)
	assert_eq(interactor.waiting(), 0)


func test_off_that_thread_a_vr_tap_runs_at_once_as_before() -> void:
	BlockInteractor.physics_thread = 0
	assert_true(interactor.space_readable(), "the space can always be read on the main thread")
	_vr_tap()
	assert_gt(interactor.space_reads, 0, "the tap ran in the frame it was made")
	assert_eq(interactor.waiting(), 0, "nothing waits")
	assert_eq(interactor.unreadable_queries, 0)


func test_a_phone_tap_runs_at_once_and_the_project_setting_is_off_by_default() -> void:
	assert_false(BlockInteractor.physics_threaded(), "the project's own setting (phones, web, desktop): the main thread")
	var ok := interactor.place_at_screen(Vector2(640, 360))
	assert_gt(interactor.space_reads, 0, "a touch's tap reads the space at once")
	assert_eq(interactor.waiting(), 0)
	assert_false(ok and interactor.waiting() > 0)


func test_a_done_callback_hears_the_tap_at_once_or_in_the_step() -> void:
	var heard := {}
	BlockInteractor.physics_thread = 0
	assert_true(interactor.in_space(func() -> bool: return true, func(ok: bool) -> void: heard.now = ok))
	assert_true(heard.get("now", false), "at once on the main thread")
	BlockInteractor.physics_thread = 1
	assert_false(interactor.in_space(func() -> bool: return true, func(ok: bool) -> void: heard.later = ok),
		"not now: it waits")
	assert_false(heard.has("later"))
	interactor._physics_process(1.0 / 60.0)
	assert_true(heard.get("later", false), "heard in the physics step")


func test_keys_and_buttons_wait_for_the_physics_step_too() -> void:
	BlockInteractor.physics_thread = 1
	interactor.crosshair_mode = true
	var e := InputEventAction.new()
	e.action = &"place"
	e.pressed = true
	interactor._unhandled_input(e)
	assert_eq(interactor.space_reads, 0, "a key's place waits")
	assert_eq(interactor.unreadable_queries, 0)
	interactor._physics_process(1.0 / 60.0)
	assert_gt(interactor.space_reads, 0, "and runs in the physics step")
	assert_eq(interactor.unreadable_queries, 0)


func test_secret_taps_ask_through_the_same_gate() -> void:
	BlockInteractor.physics_thread = 0
	var before := interactor.space_reads
	SecretTaps.tap(interactor, Vector2(640, 360))
	assert_eq(interactor.space_reads, before + 1, "SecretTaps' one ray counted by the interactor's gate")
