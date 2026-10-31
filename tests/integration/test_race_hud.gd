extends GutTest
## M3 Task 7: the race clock and a course's goals panel on the HUD. The clock is a label (never a button)
## top-centre, below the wave line and the boss bar and never over them, with a clock picture, the time and
## the course's coins; at FINISH a medal picture and the time, then it hides; while it shows the toasts step
## down under it. A tap on FINISH (not racing) opens the course's picture panel: gold, silver and bronze times
## with big - and + buttons that ask the host; closes on X.

const SCREENS: Array[Vector2i] = [Vector2i(2400, 1080), Vector2i(1334, 750)]
const S := Vector3i(0, 9, 0)
const F := Vector3i(6, 9, 0)

var _window_size: Vector2i
var clock := [0]


class AirWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.AIR)


func before_all() -> void:
	_window_size = get_window().size


func after_all() -> void:
	get_window().size = _window_size


func after_each() -> void:
	Session.register_world(null)
	Session.smart_reset()


func _hud(screen: Vector2i) -> Hud:
	get_window().size = screen
	var w := AirWorld.new()
	w.cells[S] = BlockIds.START
	w.cells[F] = BlockIds.FINISH
	autofree(w)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = CourseRules.top_of(F) + Vector3(-2, 0, 0)
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(p, "Kid", true, true)
	hud.add_health_controls()
	hud.add_secret_controls(null)
	await wait_process_frames(3)
	return hud


func _courses(hud: Hud) -> CourseDirector:
	Session.register_world(hud.player.world)
	clock[0] = 0
	Session.smart_now_ms = func() -> int: return clock[0]
	var d := CourseDirector.new()
	d.name = "Courses"
	d.now_ms = func() -> int: return clock[0]
	add_child_autofree(d)
	d.set_process(false)
	d.set_physics_process(false)
	d.start({})
	d.setup_local(hud.player)
	hud.setup_races(d)
	return d


func test_the_clock_sits_under_the_wave_and_boss_lines_and_the_toasts_under_it() -> void:
	for screen in SCREENS:
		var hud := await _hud(screen)
		hud.show_race_state({"on": true, "armed": false, "elapsed": 12300, "coins": 12, "event": "go"})
		hud.toast("Checkpoint!")
		await wait_process_frames(2)
		var view := Rect2(Vector2.ZERO, hud.get_viewport_rect().size)
		var clock_rect := hud.race_clock.get_global_rect()
		assert_true(hud.race_clock.is_visible_in_tree())
		assert_true(view.encloses(clock_rect), "%s: on the screen (%s)" % [screen, clock_rect])
		for line: Control in [hud.wave_line, hud.boss_bar]:
			var r := line.get_global_rect()
			assert_false(clock_rect.intersects(r), "%s: never over the %s" % [screen, line.get_class()])
			assert_gte(clock_rect.position.y, r.end.y, "%s: below it" % screen)
		assert_lt(absf(clock_rect.get_center().x - view.size.x * 0.5), 80.0, "%s: top-centre" % screen)
		var toast_rect := (hud._toast_panel as Control).get_global_rect()
		assert_gte(toast_rect.position.y, clock_rect.end.y, "%s: the toast steps down under the clock" % screen)
		for c in hud.race_clock.find_children("*", "", true, false):
			assert_false(c is BaseButton or c is TouchButton, "a label, never a button")
		assert_eq(hud.race_clock.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		hud.show_race_state({"on": false, "event": "stop"})
		await wait_process_frames(1)
		assert_false(hud.race_clock.visible)
		assert_eq((hud._toast_panel as Control).offset_top, 96.0, "the toasts are back")
		hud.queue_free()
		await wait_process_frames(1)


func test_the_clock_shows_the_time_and_coins_and_a_medal_at_the_finish() -> void:
	var hud := await _hud(SCREENS[0])
	hud.race_clock.clock_ms = func() -> int: return 42350
	hud.show_race_state({"on": true, "armed": false, "elapsed": 42000, "coins": 3, "event": "go"})
	hud.race_clock._process(0.016)
	assert_eq(hud.race_clock.time_label.text, "0:42.3")
	assert_eq(hud.race_clock.coins_label.text, "3")
	assert_eq(hud.race_clock.picture.kind, &"clock")
	hud.show_race_state({"on": false, "event": "finish", "ms": 40000, "medal": "silver", "best": true, "coins": 5})
	assert_true(hud.race_clock.visible)
	assert_eq(hud.race_clock.picture.kind, CourseRules.SILVER, "the medal's picture")
	assert_true(hud.race_clock.picture.best, "sparkles on a new best")
	assert_eq(hud.race_clock.time_label.text, "0:40.0")
	assert_eq(hud.race_clock.coins_label.text, "5")
	hud.race_clock._process(RaceClock.RESULT_SECONDS + 0.1)
	assert_false(hud.race_clock.visible, "then it goes away by itself")
	hud.show_race_state({"on": false, "event": "finish", "ms": 90000, "medal": "", "coins": 0})
	assert_eq(hud.race_clock.picture.kind, &"star", "no medal: a star, finished all the same")


func test_a_tap_on_finish_opens_its_goals_panel_and_the_buttons_ask_the_host() -> void:
	var hud := await _hud(SCREENS[0])
	var d := await _courses(hud)
	d.book.finished(S, F, 30000, "Kid", null)
	hud.interactor.course_tapped.emit(F)
	assert_true(hud.course_panel.visible, "the course's panel")
	assert_eq(hud.course_panel.goals_ms(), [30000, 39000, 48000])
	for b in hud.course_panel.step_buttons():
		assert_gte(b.get_combined_minimum_size().y, 84.0, "big - and + buttons")
	assert_eq(hud.course_panel.step_buttons().size(), 6, "- and + for each medal")
	(hud.course_panel.find_child("GoldFaster", true, false) as Button).pressed.emit()
	assert_eq(d.book.goals(S), [29000, 39000, 48000], "the host changed the gold time")
	assert_eq(hud.course_panel.goals_ms(), [29000, 39000, 48000])
	(hud.course_panel.find_child("BronzeSlower", true, false) as Button).pressed.emit()
	assert_eq(d.book.goals(S), [29000, 39000, 49000])
	hud.course_panel.close_button.pressed.emit()
	assert_false(hud.course_panel.visible)


func test_a_course_nobody_finished_says_race_it_first() -> void:
	var hud := await _hud(SCREENS[0])
	await _courses(hud)
	hud.interactor.course_tapped.emit(F)
	assert_false(hud.course_panel.visible)
	assert_eq(hud._toast_label.text, Hud.RACE_IT_FIRST)


func test_no_panel_while_racing() -> void:
	var hud := await _hud(SCREENS[0])
	var d := await _courses(hud)
	d.book.finished(S, F, 30000, "Kid", null)
	hud.show_race_state({"on": true, "armed": false, "elapsed": 0, "coins": 0, "event": "go"})
	hud.interactor.course_tapped.emit(F)
	assert_false(hud.course_panel.visible, "a runner's tap on FINISH is running, not building")
