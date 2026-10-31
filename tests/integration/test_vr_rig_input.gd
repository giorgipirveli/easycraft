extends GutTest
## Owner #101 (VR on the Meta Quest): the Touch controllers as one game pad (VrInput), with Vr.simulate's fake
## controllers. Every control the game knows plays its action through the input map's one table (GamepadRules.BINDINGS
## via QUEST_BUTTONS); the walking stick walks; the turning stick snap-turns 45° once per push (smooth only when asked)
## and never looks round; the pointing trigger is TAP (place) and HOLD (break, with the break ring) on the laser's target,
## never in a paused game; the hands swap for a left-handed child; a place, a break and a snap turn buzz; the end of the
## session lets go of everything.

class FloorWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 80 else BlockIds.AIR


## Stands in for the BlockInteractor (VrInput.target): counts the trigger's places and breaks.
class Taps:
	extends RefCounted
	var placed := 0
	var broken := 0
	var progress := -1.0

	func place_crosshair() -> bool:
		placed += 1
		return true

	func break_crosshair() -> bool:
		broken += 1
		return true

	func show_break_progress(_hit: Variant, p: float) -> void:
		progress = p

	func ray_at(_pos: Vector2) -> BlockHit:
		return BlockHit.new(Vector3i(0, 79, -2), Vector3i(0, 80, -2), 2.0)


const DT := 1.0 / 72.0

var p: Player
var taps: Taps
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
	p.get_node("BlockInteractor").set_process_unhandled_input(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0.5, 80, 0.5)
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	taps = Taps.new()
	Vr.input.target = taps


func after_each() -> void:
	get_tree().paused = false
	Vr.simulate(false)
	Vr.anchor(null)
	Input.flush_buffered_events()
	Profile.data.settings = _settings


## One frame of the controllers, and the game's input caught up.
func _step(n: int = 1) -> void:
	for i in n:
		Vr.input.step(DT, p)
	Input.flush_buffered_events()


func test_the_walking_stick_walks() -> void:
	Vr.sim_input(VrRules.LEFT, &"primary", Vector2(0.0, 1.0))   # pushed away from the child
	_step()
	assert_almost_eq(Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back"), Vector2(0, -1), Vector2(0.01, 0.01),
		"forward, as a pad's left stick")
	Vr.sim_input(VrRules.LEFT, &"primary", Vector2.ZERO)
	_step()
	assert_eq(Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back"), Vector2.ZERO, "let go: still")


func test_every_button_plays_its_action() -> void:
	var cases := [[VrRules.RIGHT, &"ax_button", &"jump"], [VrRules.RIGHT, &"by_button", &"crouch"],
		[VrRules.LEFT, &"ax_button", &"more"], [VrRules.LEFT, &"by_button", &"blocks"],
		[VrRules.LEFT, &"menu_button", &"pause"], [VrRules.LEFT, &"grip_click", &"hotbar_prev"],
		[VrRules.RIGHT, &"grip_click", &"hotbar_next"], [VrRules.LEFT, &"primary_click", &"size_mode"],
		[VrRules.RIGHT, &"primary_click", &"physics_mode"]]
	for c: Array in cases:
		Vr.sim_input(c[0], c[1], true)
		_step()
		assert_true(Input.is_action_pressed(c[2]), "%s %s: %s" % c)
		Vr.sim_input(c[0], c[1], false)
		_step()
		assert_false(Input.is_action_pressed(c[2]), "%s let go" % c[2])


func test_the_other_trigger_attacks() -> void:
	Vr.sim_input(VrRules.LEFT, &"trigger", 0.9)
	_step()
	assert_true(Input.is_action_pressed(&"attack"))
	Vr.sim_input(VrRules.LEFT, &"trigger", 0.0)
	_step()
	assert_false(Input.is_action_pressed(&"attack"))


func test_b_flies_down_while_flying() -> void:
	p.physics_mode = PhysicsMode.Mode.FLY
	Vr.sim_input(VrRules.RIGHT, &"by_button", true)
	_step()
	assert_true(Input.is_action_pressed(&"fly_down"), "down, as the D-pad's")
	assert_false(Input.is_action_pressed(&"crouch"))
	p.physics_mode = PhysicsMode.Mode.NORMAL   # landed while holding: its release still lets go of what it pressed
	Vr.sim_input(VrRules.RIGHT, &"by_button", false)
	_step()
	assert_false(Input.is_action_pressed(&"fly_down"))


func test_the_turning_stick_snaps_45_degrees_once_per_push_and_never_looks() -> void:
	_step()
	var yaw := VrRules.yaw_of(Vr.head_transform().basis)
	var buzzes := Vr.haptics
	Vr.sim_input(VrRules.RIGHT, &"primary", Vector2(1.0, 0.0))
	_step(3)
	assert_almost_eq(angle_difference(yaw, VrRules.yaw_of(Vr.head_transform().basis)), -deg_to_rad(45.0), 0.001,
		"one step to the right, held or not")
	assert_eq(Vr.haptics, buzzes + 1, "a tick in the hand")
	assert_false(Input.is_action_pressed(&"look_right"), "the pad's look never reaches the VR view")
	Vr.sim_input(VrRules.RIGHT, &"primary", Vector2.ZERO)
	_step()
	Vr.sim_input(VrRules.RIGHT, &"primary", Vector2(-1.0, 0.0))
	_step()
	assert_almost_eq(angle_difference(yaw, VrRules.yaw_of(Vr.head_transform().basis)), 0.0, 0.001, "and back")


func test_smooth_turning_turns_while_held_when_asked() -> void:
	Profile.data.settings[VrRules.TURN] = "smooth"
	_step()
	var yaw := VrRules.yaw_of(Vr.head_transform().basis)
	Vr.sim_input(VrRules.RIGHT, &"primary", Vector2(1.0, 0.0))
	_step(36)   # half a second
	assert_almost_eq(angle_difference(yaw, VrRules.yaw_of(Vr.head_transform().basis)),
		-deg_to_rad(VrRules.SMOOTH_TURN_DEGREES) * 0.5, 0.01)


func test_the_trigger_taps_to_place_and_holds_to_break() -> void:
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	_step()
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	_step()
	assert_eq(taps.placed, 1, "a quick squeeze places (and opens, talks, uses)")
	assert_eq(taps.broken, 0)
	var buzzes := Vr.haptics
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	_step(5)
	assert_gt(taps.progress, 0.0, "the break ring fills while it is held")
	_step(int(TouchClassifier.HOLD_TIME / DT) + 2)
	assert_eq(taps.broken, 1, "held 0.25 s: the block breaks")
	assert_eq(Vr.haptics, buzzes + 1, "with a buzz")
	_step(30)
	assert_eq(taps.broken, 1, "one block per hold, as a finger")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	_step()
	assert_eq(taps.placed, 1, "letting go after a hold places nothing")


func test_a_paused_game_takes_no_trigger() -> void:
	get_tree().paused = true
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	_step()
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	_step()
	assert_eq(taps.placed, 0, "behind the pause menu nothing is built")


func test_a_left_handed_child_swaps_the_hands() -> void:
	Profile.data.settings["left_handed"] = true
	Vr.sim_input(VrRules.LEFT, &"trigger", 1.0)
	_step()
	Vr.sim_input(VrRules.LEFT, &"trigger", 0.0)
	_step()
	assert_eq(taps.placed, 1, "the left trigger places")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.9)
	_step()
	assert_true(Input.is_action_pressed(&"attack"), "the right one attacks")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	Vr.sim_input(VrRules.RIGHT, &"primary", Vector2(0.0, 1.0))
	_step()
	assert_almost_eq(Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back"), Vector2(0, -1),
		Vector2(0.01, 0.01), "the right stick walks")


## The lead's frozen name (round 3): one reading of a press for both sides, VrRules.trigger_down's hysteresis per hand.
func test_a_triggers_press_is_on_at_0_6_and_off_under_0_35_per_hand() -> void:
	assert_false(Vr.trigger_pressed(VrRules.RIGHT))
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.7)
	_step()
	assert_true(Vr.trigger_pressed(VrRules.RIGHT), "squeezed past 0.6")
	assert_false(Vr.trigger_pressed(VrRules.LEFT), "the other hand is its own")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.5)
	_step()
	assert_true(Vr.trigger_pressed(VrRules.RIGHT), "still held at 0.5 (no flicker)")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.3)
	_step()
	assert_false(Vr.trigger_pressed(VrRules.RIGHT), "let go under 0.35")
	Vr.sim_input(VrRules.LEFT, &"trigger_click", true)
	Vr.sim_input(VrRules.LEFT, &"trigger", 0.0)
	_step()
	assert_false(Vr.trigger_pressed(VrRules.LEFT), "the analog value first (trigger, then trigger_click: VrInput's rule)")
	Vr.simulate(false)
	assert_false(Vr.trigger_pressed(VrRules.RIGHT), "off VR: never pressed")


func test_the_end_of_the_session_lets_go_of_everything() -> void:
	Vr.sim_input(VrRules.RIGHT, &"ax_button", true)
	Vr.sim_input(VrRules.LEFT, &"primary", Vector2(0.0, 1.0))
	_step()
	assert_true(Input.is_action_pressed(&"jump"))
	Vr.simulate(false)
	Input.flush_buffered_events()
	assert_false(Input.is_action_pressed(&"jump"), "nothing stays pressed in the game")
	assert_eq(Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back"), Vector2.ZERO)
