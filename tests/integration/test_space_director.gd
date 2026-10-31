extends GutTest
## Owner feedback #55 (spec §21.1): the space line on this game. The director watches where this game's player is:
## on the way up the sky turns to space (the climb) and "Keep flying up!" is said once; crossing the line (y 200) opens
## the picker, once, until the child comes back under REARM_Y; Monster Wave (no flying) never opens it. The picker's
## choices go to the sandbox: land on a planet (a refusal is said on the panel), HOME from a space world, STAY HERE.

var _feet := Vector3.INF
var _mode: StringName = ModeRules.SANDBOX
var _climbs: Array[float] = []
var _toasts: Array[String] = []
var _trips: Array[int] = []
var _homes := 0
var _stays := 0
var _refuse := ""
var _warmed := 0


func before_each() -> void:
	_warmed = 0
	_feet = Vector3.INF
	_mode = ModeRules.SANDBOX
	_climbs.clear()
	_toasts.clear()
	_trips.clear()
	_homes = 0
	_stays = 0
	_refuse = ""


func after_each() -> void:
	get_tree().paused = false


func _director(here: int = 1, home: int = 1) -> SpaceDirector:
	var d := SpaceDirector.new()
	d.player_position = func() -> Vector3: return _feet
	d.mode = func() -> StringName: return _mode
	d.here = here
	d.home = home
	d.available = func() -> Array[int]: return [16, 17, 18] as Array[int]
	d.travel = func(u: int) -> String:
		_trips.append(u)
		return _refuse
	d.go_home = func() -> String:
		_homes += 1
		return _refuse
	d.stay = func() -> void: _stays += 1
	d.toast = func(t: String) -> void: _toasts.append(t)
	d.sky_climb = func(c: float) -> void: _climbs.append(c)
	d.may_hold = func() -> bool: return false
	d.warm = func() -> void: _warmed += 1
	add_child_autofree(d)
	var ui := Control.new()
	add_child_autofree(ui)
	d.setup_panel(ui)
	d.set_process(false)
	return d


func _at(d: SpaceDirector, y: float) -> void:
	_feet = Vector3(5.5, y, -3.5)
	d.tick(SpaceDirector.CHECK_EVERY + 0.01)


func test_on_the_ground_nothing_happens() -> void:
	var d := _director()
	_at(d, 40.0)
	assert_false(d.panel.visible)
	assert_true(_climbs.is_empty(), "the sky is left alone")
	assert_true(_toasts.is_empty())


func test_the_sky_turns_to_space_on_the_way_up_and_back() -> void:
	var d := _director()
	_at(d, 170.0)
	assert_eq(_climbs.size(), 1)
	assert_almost_eq(_climbs[0], 0.25, 0.001)
	_at(d, 170.2)
	assert_eq(_climbs.size(), 1, "a tiny change does not re-light the sky")
	_at(d, 190.0)
	assert_almost_eq(_climbs.back(), 0.75, 0.001)
	_at(d, 60.0)
	assert_eq(_climbs.back(), 0.0, "back down: the sky of home")


func test_keep_flying_up_is_said_once_per_climb() -> void:
	var d := _director()
	_at(d, 181.0)
	_at(d, 183.0)
	assert_eq(_toasts, [SpaceRules.HINT_WORDS] as Array[String])
	_at(d, 100.0)
	_at(d, 182.0)
	assert_eq(_toasts.size(), 2, "again after landing")


func test_crossing_the_line_opens_the_picker_once() -> void:
	var d := _director()
	_at(d, 199.0)
	assert_false(d.panel.visible)
	_at(d, 200.5)
	assert_true(d.panel.visible)
	assert_eq(d.panel.bodies.size(), StarMap.bodies().size(), "the Star Map")
	d.panel.close()
	_at(d, 205.0)
	assert_false(d.panel.visible, "not again while still up there")
	_at(d, 192.0)
	_at(d, 201.0)
	assert_false(d.panel.visible, "hovering at the line")
	_at(d, 185.0)
	_at(d, 201.0)
	assert_true(d.panel.visible, "down under the re-arm line and up again")


func test_monster_wave_never_goes_to_space() -> void:
	_mode = ModeRules.WAVE
	var d := _director()
	_at(d, 250.0)
	assert_false(d.panel.visible)
	assert_true(_climbs.is_empty())


func test_no_player_no_space() -> void:
	var d := _director()
	_feet = Vector3.INF
	d.tick(1.0)
	assert_false(d.panel.visible)


func test_a_card_lands_there_or_says_why_not() -> void:
	var d := _director()
	_at(d, 201.0)
	_refuse = SpaceRules.message("friends")
	d.panel.body_for(&"moon").pressed.emit()
	d.panel.action_button.pressed.emit()
	assert_eq(_trips, [16] as Array[int])
	assert_true(d.panel.visible)
	assert_eq(d.panel.hint(), _refuse)
	_refuse = ""
	d.panel.body_for(&"boing").pressed.emit()
	d.panel.action_button.pressed.emit()
	assert_eq(_trips, [16, 17] as Array[int])
	assert_false(d.panel.visible, "on the way: the picker goes")


func test_home_from_the_moon() -> void:
	var d := _director(16, 2)
	_at(d, 201.0)
	d.panel.body_for(&"sandstorm_desert").pressed.emit()
	assert_eq(d.panel.action_button.text, "HOME", "the Sandstorm Desert, where the trip started")
	d.panel.action_button.pressed.emit()
	assert_eq(_homes, 1)
	assert_false(d.panel.visible)


func test_stay_here() -> void:
	var d := _director()
	_at(d, 201.0)
	d.panel.stay_button.pressed.emit()
	assert_eq(_stays, 1)
	assert_false(d.panel.visible)


func test_played_alone_the_picker_holds_the_game() -> void:
	var d := _director()
	d.may_hold = func() -> bool: return true
	_at(d, 201.0)
	assert_true(get_tree().paused)
	d.panel.close()
	assert_false(get_tree().paused)


## M7 (the browser's freezes): the picker's cards read the space worlds' files, loaded the first time it opened (a
## second frozen in a phone's browser). They load in the background from the start of the climb, once per world.
func test_the_climb_warms_the_space_worlds_once() -> void:
	var d := _director()
	_at(d, 150.0)
	assert_eq(_warmed, 0, "under the climb")
	_at(d, 161.0)
	assert_eq(_warmed, 1, "the sky starts to darken: their files load in the background")
	_at(d, 185.0)
	_at(d, 150.0)
	_at(d, 170.0)
	assert_eq(_warmed, 1, "once")


func test_monster_wave_warms_nothing() -> void:
	var d := _director()
	_mode = ModeRules.WAVE
	_at(d, 170.0)
	assert_eq(_warmed, 0)


func test_the_landing_is_handed_to_the_next_world_once() -> void:
	SpaceDirector.landing = 16
	assert_true(SpaceDirector.take_landing(16))
	assert_false(SpaceDirector.take_landing(16), "said once")
	SpaceDirector.landing = 17
	assert_false(SpaceDirector.take_landing(16), "another world's landing")
	assert_eq(SpaceDirector.landing, 0)
