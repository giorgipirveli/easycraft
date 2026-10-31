extends GutTest
## Owner #122 (docs/design/learning-is-play.md §4; spec §22.0): a unit is played in the play arena, flat or in VR. The
## hook comes first (a problem in the place), then the try before any words, the coach's one line after it, the rest of
## the round, and the world task at the end. A miss: the world reacts and the hint; the second: the coach's ghost does
## one step in the game; the third: the worked answer. ExerciseCheck judges every answer; only right the first try with
## no help counts. I NEED A BREAK holds everything; STOP FOR NOW ends calmly; the screen it came from hides while the
## place shows and comes back after.

const UNIT := "g4.maths.big_numbers"
const CONTENT := {"id": UNIT, "lesson": [
		{"text": "Quick memory: what is 3 × 4?"},
		{"text": "A digit's place tells what it is worth."},
		{"text": "We read big numbers in groups of three."},
		{"text": "Try it in the world: build a tower of 347 blocks. Next: tables."}],
	"exercises": [
		{"type": "truefalse", "prompt": "In 347, the 4 is worth 40.", "answer": true, "hint": "Tens place.", "level": 1},
		{"type": "sort", "prompt": "More than 100 or not?", "hint": "Hundreds.", "groups": ["more", "not more"],
			"items": ["347", "99", "120"], "answer": [0, 1, 0], "level": 2},
		{"type": "number", "prompt": "300 + 40 + 7 = ?", "answer": "347", "hint": "Put the parts together.", "level": 2},
		{"type": "choice", "prompt": "Which is 3,000 + 20 + 5?", "choices": ["3,025", "3,205", "325"], "answer": 0,
			"hint": "No hundreds.", "level": 3}]}
const LIMIT := 4.0

var host: PlayHost
var layer: CanvasLayer
var screen: Control
var outcomes: Array = []
var stops: Array = []
var golds := 0


func before_each() -> void:
	outcomes.clear()
	stops.clear()
	golds = 0
	Profile.data.settings.reduce_motion = true
	layer = CanvasLayer.new()
	add_child_autofree(layer)
	screen = Control.new()
	layer.add_child(screen)


func after_each() -> void:
	if is_instance_valid(host) and not host.closed:
		host.close()
	Vr.simulate(false)
	Profile.data.settings.reduce_motion = false
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(seed: int = 7) -> PlayHost:
	host = PlayHost.new()
	host.setup(UNIT, CONTENT.duplicate(true), seed, 0, {"title": "Big numbers", "goals": ["Read big numbers"]})
	host.first_try_gold = func() -> int:
		golds += 1
		return 5
	host.finished.connect(func(o: Dictionary) -> void: outcomes.append(o))
	host.stopped.connect(func(o: Dictionary) -> void: stops.append(o))
	host.open(screen)
	await wait_process_frames(3)
	return host


func _skip_hook() -> void:
	host.end_hook()
	await wait_process_frames(1)


## Plays the current challenge right by the coach's own steps, as taps on the screen (flat).
func _play_right() -> void:
	var st := host.station()
	for i in 200:
		var steps := st.ghost()
		if steps.is_empty():
			break
		for t in steps:
			host.finger_down(host.screen_of(t))
			host.finger_up(host.screen_of(t))
	if not st.answers_by_acting():
		host.hud.go_button.pressed.emit()
	await wait_process_frames(1)


## A wrong answer to the current challenge, through the station.
func _play_wrong() -> void:
	var st := host.station()
	match st.mechanic:
		"test":
			st.tap("gate_%d" % (1 - PlayChoose.right_option(st.ex)))
		"choose":
			var r := PlayChoose.right_option(st.ex)
			var w := (r + 1) % PlayChoose.options(st.ex).size()
			if (st as ChooseStation).costume == PlayChoose.PATH:
				st.tap("sign_%d" % w)
			else:
				st.tap("thing_%d" % w)
				st.tap("buddy")
		"sort":
			for i in (st.ex.items as Array).size():
				st.tap("thing_%d" % i)
				st.tap("bin_0")
			host.check()
		"make":
			st.tap("src_0")
			host.check()
	await wait_process_frames(1)


func _next() -> void:
	host.hud.next_button.pressed.emit()
	await wait_process_frames(1)
	if is_instance_valid(host) and not host.closed and host.loop.phase == PlayLoop.WHY:
		host.hud.play_on_button.pressed.emit()
		await wait_process_frames(1)


func test_the_place_opens_with_its_hook_and_hides_the_screen() -> void:
	await _open()
	assert_false(layer.visible, "the screen it came from hides")
	assert_eq(host.arena.global_position, PlayHost.ROOM_ORIGIN)
	assert_eq(host.get_viewport().get_camera_3d(), host.camera, "the place's own camera")
	assert_eq(host.loop.phase, PlayLoop.HOOK)
	assert_eq(host.hud.say_label.text, host.loop.hook_line, "a problem appears in the place first")
	assert_not_null(host.station(), "the try is already there to act on")
	await _skip_hook()
	assert_eq(host.loop.phase, PlayLoop.TRY)
	assert_eq(host.hud.say_label.text, str(host.loop.current().prompt), "then the challenge's own words")


func test_acting_on_the_place_ends_the_hook_at_once() -> void:
	await _open()
	var st := host.station()
	var t := st.ghost()[0]
	host.finger_down(host.screen_of(t))
	host.finger_up(host.screen_of(t))
	await wait_process_frames(1)
	assert_ne(host.loop.phase, PlayLoop.HOOK, "play first: the try starts with the first act")


func test_a_whole_unit_plays_through_the_loop_and_counts_like_a_round() -> void:
	await _open()
	await _skip_hook()
	await _play_right()
	assert_true(host.loop.answered, "the try was answered by acting")
	assert_true(host.hud.next_button.visible)
	host.hud.next_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(host.loop.phase, PlayLoop.WHY, "see why, after the try")
	assert_true(host.hud.why_card.visible)
	assert_string_contains(ReadAloud.words_of(host.hud.why_card), host.loop.see_why())
	host.hud.play_on_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(host.loop.phase, PlayLoop.PLAY)
	for i in 5:
		await _play_right()
		await _next()
	assert_eq(outcomes.size(), 1, "the round finished")
	assert_eq(int(outcomes[0].right_first), 6)
	assert_eq(int(outcomes[0].total), 6)
	assert_eq(str(outcomes[0].world_task), "Build a tower of 347 blocks.")
	assert_eq(golds, 6, "a few gold for each answer right the first time (EarnRules)")
	assert_true(not is_instance_valid(host) or host.closed, "the place has closed")
	assert_true(layer.visible, "the screen comes back")


func test_misses_not_yet_then_the_ghost_then_the_worked_answer() -> void:
	await _open()
	await _skip_hook()
	await _play_wrong()
	assert_eq(host.loop.tries, 1)
	assert_string_contains(host.hud.feedback.text, str(host.loop.current().hint), "not yet: the hint")
	assert_false(host.hud.next_button.visible)
	await _play_wrong()
	assert_eq(host.loop.tries, 2)
	assert_true(host.ghost_busy(), "shown, not told: the ghost does one step")
	await wait_until(func() -> bool: return not host.ghost_busy(), LIMIT, "the ghost's step is done")
	await _play_wrong()
	assert_true(host.loop.answered, "the third miss: the worked answer")
	assert_true(ExerciseCheck.is_right(host.station().ex, host.station().response()), "the place shows it")
	assert_true(host.hud.next_button.visible)
	assert_eq(host.loop.right_first, 0)
	assert_eq(golds, 0)


func test_show_me_does_one_step_and_the_challenge_no_longer_counts() -> void:
	await _open()
	await _skip_hook()
	host.hud.show_me_button.pressed.emit()
	assert_true(host.ghost_busy())
	await wait_until(func() -> bool: return not host.ghost_busy(), LIMIT, "the ghost's step")
	await _play_right()
	assert_true(host.loop.answered)
	assert_eq(host.loop.right_first, 0, "SHOW ME is help")


func test_a_break_holds_everything_and_stop_ends_calmly() -> void:
	await _open()
	await _skip_hook()
	host.hud.break_button.pressed.emit()
	assert_true(host.paused)
	var before: Variant = host.station().response()
	var t := host.station().ghost()[0]
	host.finger_down(host.screen_of(t))
	host.finger_up(host.screen_of(t))
	assert_eq(host.station().response(), before, "while on a break a tap does nothing")
	assert_eq(host.station().carried, "")
	host.hud.stop_button.pressed.emit()
	await wait_process_frames(1)
	assert_eq(stops.size(), 1)
	assert_eq(outcomes.size(), 0, "a stopped round records nothing")
	assert_true(layer.visible)


func test_the_hud_shows_the_station_s_test_and_its_words() -> void:
	await _open(3)
	await _skip_hook()
	while host.station().mechanic != "make" and host.loop.index < 5:
		await _play_right()
		await _next()
	if host.station().mechanic == "make":
		assert_eq(host.hud.go_button.text, host.station().go_words())
		host.station().tap("src_1")
		await wait_process_frames(1)
		assert_string_contains(host.hud.readout.text, "Made:")


# --- VR (a simulated headset) -------------------------------------------------------------------------------------

func _vr_open() -> void:
	Vr.simulate(true)
	await wait_process_frames(2)
	await _open()
	await wait_physics_frames(2)
	await wait_process_frames(2)


func _hand_at(side: StringName, world: Vector3) -> void:
	Vr.sim_hand(side, Transform3D(Basis(), Vr.rig.global_transform.affine_inverse() * world))


func test_vr_the_child_stands_at_the_station() -> void:
	await _vr_open()
	assert_true(host.vr)
	assert_eq(Vr.anchor_node(), host.stand)
	assert_eq(host.hud.tap_area.mouse_filter, Control.MOUSE_FILTER_IGNORE, "no flat tap area in VR")


func test_vr_the_hands_carry_a_thing_to_its_place() -> void:
	await _vr_open()
	await _skip_hook()
	var ex := {"type": "sort", "prompt": "More than 100 or not?", "hint": "Hundreds.", "groups": ["more", "not more"],
		"items": ["347", "99"], "answer": [0, 1], "level": 2}
	host.show_exercise(ex)
	await wait_process_frames(2)
	var st := host.station()
	_hand_at(VrRules.RIGHT, host.arena.target_position("thing_0"))
	await wait_process_frames(2)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	await wait_until(func() -> bool: return st.carried == "thing_0", LIMIT, "the hand picks it up")
	var bin := host.arena.target_position("bin_0")
	_hand_at(VrRules.RIGHT, bin)
	await wait_process_frames(3)
	assert_lt(st.carried_node().global_position.distance_to(bin), 0.25, "it follows the hand")
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
	await wait_until(func() -> bool: return st.carried == "", LIMIT, "let go over the bin")
	assert_eq((st as SortStation).placing.at[0], 0, "it is in the bin")


## Life's way for a child who doesn't know what to touch yet: after IDLE_HINT seconds without an act, the things to act
## with glow for a moment (never the answer: every one of them; and it is no help: the challenge still counts).
func test_a_child_who_waits_sees_what_can_be_touched() -> void:
	await _open()
	await _skip_hook()
	host.set_process(false)
	assert_eq(host.arena.glowing(), [] as Array[String])
	for i in 12:
		host._process(1.0)
	var lit := host.arena.glowing()
	assert_gt(lit.size(), 1, "the things to act with glow: %s" % [lit])
	assert_false(lit.has(PlayStation.GO), "the test is not one of them")
	assert_false(host.loop.helped, "no help: it still counts")
	for i in 4:
		host._process(1.0)
	assert_eq(host.arena.glowing(), [] as Array[String], "for a moment only")



## Shown, not told, for a choice: the ghost shows the right crate and where it goes; the crate itself keeps glowing (the
## child gives it), and nothing is given for them.
func test_after_the_ghost_shows_a_choice_the_right_thing_keeps_glowing() -> void:
	await _open()
	await _skip_hook()
	var ex := {"type": "choice", "prompt": "Which is 3,000 + 20 + 5?", "choices": ["3,025", "3,205", "325"], "answer": 1,
		"hint": "No hundreds."}
	host.content.play = {"params": {"costume": "give"}}
	host.show_exercise(ex)
	await wait_process_frames(1)
	host.set_process(false)
	host.show_me()
	for i in 4:
		host._process(PlayHost.GHOST_TAP)
	assert_false(host.ghost_busy())
	assert_eq(host.arena.glowing(), ["thing_1"] as Array[String], "the right crate glows")
	assert_false(host.loop.answered, "the child gives it")
