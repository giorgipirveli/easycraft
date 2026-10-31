extends GutTest
## Deferred M1 minor: the HUD pauses with the game, so a finger lifted while the pause menu is open
## never reaches the touch controls. Pausing lets go of every touch: nothing stays held after RESUME,
## and the next finger works. The HUD lives in its own 1280x720 SubViewport, and touches are pushed
## into it the way the engine delivers them (paused controls never hear them).

const SCREEN := Vector2i(1280, 720)
const STICK := Vector2(200, 560)     # inside the joystick's bottom-left area

var view: SubViewport
var hud: Hud


func before_each() -> void:
	view = SubViewport.new()
	view.size = SCREEN
	add_child_autofree(view)
	hud = Hud.new()
	view.add_child(hud)


func after_each() -> void:
	get_tree().paused = false
	for a: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right", &"jump", &"fly_down"]:
		Input.action_release(a)


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = index
	t.position = pos
	t.pressed = pressed
	view.push_input(t, true)


func _drag(index: int, pos: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = index
	d.position = pos
	view.push_input(d, true)


func test_a_finger_lifted_while_paused_lets_go_of_the_joystick() -> void:
	_touch(0, STICK, true)
	_drag(0, STICK + Vector2(0, -120))
	assert_true(Input.is_action_pressed(&"move_forward"), "the stick walks forward")
	get_tree().paused = true
	_touch(0, STICK + Vector2(0, -120), false)     # lifted during the pause menu: nobody hears it
	get_tree().paused = false
	assert_false(Input.is_action_pressed(&"move_forward"), "no walking on by itself after RESUME")
	_touch(1, STICK, true)
	_drag(1, STICK + Vector2(0, 120))
	assert_true(Input.is_action_pressed(&"move_back"), "the next finger steers again")


func test_a_finger_lifted_while_paused_lets_go_of_jump() -> void:
	var at := hud.jump_button.get_global_rect().get_center()
	_touch(2, at, true)
	assert_true(Input.is_action_pressed(&"jump"), "JUMP holds the jump action")
	get_tree().paused = true
	_touch(2, at, false)
	get_tree().paused = false
	assert_false(Input.is_action_pressed(&"jump"), "JUMP is not held after RESUME")
	assert_false(hud.jump_button.is_down())
	_touch(3, at, true)
	assert_true(hud.jump_button.is_down(), "and the next press works")


## The look area needs a spawned player to take touches, so the finger is handed to its classifier.
func test_pausing_forgets_a_finger_on_the_look_area() -> void:
	hud.look_area._classifier.down(4, Vector2(640, 300), 0.0)
	get_tree().paused = true
	get_tree().paused = false
	assert_false(hud.look_area._classifier.owns(4), "no late HOLD breaks a block after RESUME")
