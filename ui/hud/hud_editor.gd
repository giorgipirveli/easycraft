class_name HudEditor
extends Control
## MOVE BUTTONS (M5 Task 1, spec §15.1a): a picture of the HUD at the child's button size and hand, where JUMP, ATTACK,
## CROUCH and the stick follow a finger (two fingers move two). The other controls, the labels and the hotbar show as
## faint outlines. A place that covers something or leaves the screen is drawn crossed out while the finger is there
## (a shape, not only a colour), and on letting go the control goes back to where it was ("No room there"). DONE
## saves this size's moves in the profile (the right hand's frame; HudLayout checks them again on every screen),
## RESET puts all four back, Back closes without saving. A child or a grown-up may use it (no gate).

signal closed

const WORDS := {&"jump": "JUMP", &"attack": "ATTACK", &"crouch": "CROUCH", &"joystick": "MOVE"}
const BACKDROP := Color(0.03, 0.05, 0.1, 0.78)
const OUTLINE := Color(1, 1, 1, 0.28)
const PIECE := Color(0.08, 0.1, 0.16, 0.85)
const EDGE := Color(1, 1, 1, 0.95)
const NO_ROOM := "No room there: it went back."
## Every open editor (the sandbox's and the menu's Android Back ask them first: close_open).
const GROUP := &"hud_editor"

## The profile whose layout this edits (default: the player's; tests give a fresh one).
var profile: ProfileData
## Saves the profile after DONE (default: Profile.save() and Game.apply_settings(); tests set their own).
var saver := Callable()
var done_button: Button
var reset_button: Button
## True once a drop was refused (tests; the words show under the title).
var said_no_room := false

var _step: StringName = HudLayout.NORMAL
var _left := false
var _moves := {}          # spot -> Vector2, this size's moves (the right hand's frame)
var _fingers := {}        # touch index -> {"spot": StringName, "from": Vector2 (screen), "move": Vector2 (start)}
var _ghost := {}          # spot -> Rect2 where a finger holds it now (screen)
var _fits := {}           # spot -> bool: does the ghost's place fit
var _panel: Control
var _note: Label
var _closed := false


func _ready() -> void:
	add_to_group(GROUP)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP   # nothing behind hears a tap
	process_mode = Node.PROCESS_MODE_ALWAYS   # the pause menu opens it while the game is paused
	if profile == null:
		profile = Profile.data
	_step = StringName(str(profile.settings.get("button_size", "normal")))
	if not HudLayout.FACTORS.has(_step):
		_step = HudLayout.NORMAL
	_left = bool(profile.settings.get("left_handed", false))
	_moves = HudLayout.moves_for(profile.hud_moves, _step)
	_build_panel()
	_apply(_moves)
	_moves = _kept_moves()   # an old move that no longer fits here is dropped


func _build_panel() -> void:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	box.add_theme_stylebox_override("panel", UiKit.box(UiKit.DARK, 22, 16))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(ReadAloud.with_speaker(UiKit.title("Move the buttons", 36), v))
	var hint := Label.new()
	hint.text = "Drag JUMP, ATTACK, CROUCH and the stick."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	v.add_child(hint)
	_note = Label.new()
	_note.name = "NoRoom"
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_font_size_override("font_size", 22)
	_note.add_theme_color_override("font_color", Color("ffd23f"))
	v.add_child(_note)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	reset_button = UiKit.big_button("RESET", UiKit.BLUE, Vector2(200, 72))
	reset_button.name = "Reset"
	reset_button.pressed.connect(reset)
	done_button = UiKit.big_button("DONE", UiKit.GREEN, Vector2(200, 72))
	done_button.name = "Done"
	done_button.pressed.connect(done)
	row.add_child(reset_button)
	row.add_child(done_button)
	v.add_child(row)
	box.add_child(v)
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.offset_top = 12.0
	_panel = box


## Where `spot` shows now: under a finger, or on its (moved) place.
func piece_rect(spot: StringName) -> Rect2:
	if _ghost.has(spot):
		return _ghost[spot]
	return HudLayout.rect(spot, _screen())


func dragging(spot: StringName) -> bool:
	return _ghost.has(spot)


## While a finger holds `spot`: does the place under it fit?
func fits_now(spot: StringName) -> bool:
	return bool(_fits.get(spot, true))


## Every control back to its own place at this size (saved with DONE).
func reset() -> void:
	_fingers.clear()
	_ghost.clear()
	_moves = {}
	_note.text = ""
	_apply(_moves)


## Saves this size's moves in the profile and closes.
func done() -> void:
	var saved := {}
	for spot: StringName in _moves:
		var d: Vector2 = _moves[spot]
		if d != Vector2.ZERO:
			saved[String(spot)] = [d.x, d.y]
	var all := profile.hud_moves.duplicate(true)
	if saved.is_empty():
		all.erase(String(_step))
	else:
		all[String(_step)] = saved
	profile.hud_moves = all
	if saver.is_valid():
		saver.call()
	else:
		Profile.save()
		Game.apply_settings()
	_close()


## Closes without saving (Back, or the settings page that opened it went away).
func cancel() -> void:
	_close()


func _close() -> void:
	if _closed:
		return
	_closed = true
	HudLayout.configure_from(Profile.data, _screen())   # the HUD's own layout again
	closed.emit()
	queue_free()


## Closes every open editor without saving; true when there was one (closed now, or earlier this frame: it goes at the
## frame's end). The sandbox's and the menu's Android Back ask this first, so a Back over MOVE BUTTONS closes only it
## (M5 Task 6 review: it closed the pause menu under it, or took the menu back to its first screen).
static func close_open() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var was := false
	if tree == null:
		return false
	for n in tree.get_nodes_in_group(GROUP):
		if n is HudEditor:
			(n as HudEditor)._close()
			was = true
	return was


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):   # Escape on a desktop: nothing saved
		get_viewport().set_input_as_handled()
		_close()


## Android's Back is a notification every node gets, not ui_cancel (M5 Task 6 review): nothing saved.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_inside_tree():
		_close()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_press(t.index, t.position)
		elif _fingers.has(t.index):
			_lift(t.index, t.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if _fingers.has(d.index):
			_follow(d.index, d.position)
			get_viewport().set_input_as_handled()


func _press(index: int, at: Vector2) -> void:
	if _panel.get_global_rect().has_point(at):
		return   # DONE and RESET are buttons
	for spot: StringName in [&"jump", &"attack", &"crouch", &"joystick"]:   # buttons over the stick's big area
		if _ghost.has(spot) or not _hit(spot, at):
			continue
		_fingers[index] = {"spot": spot, "from": at, "move": _moves.get(spot, Vector2.ZERO)}
		_ghost[spot] = piece_rect(spot)
		_fits[spot] = true
		get_viewport().set_input_as_handled()
		queue_redraw()
		return


func _hit(spot: StringName, at: Vector2) -> bool:
	var r := piece_rect(spot)
	if spot == &"joystick":
		return r.has_point(at)
	return at.distance_to(r.get_center()) <= r.size.x * 0.55


func _follow(index: int, at: Vector2) -> void:
	var f: Dictionary = _fingers[index]
	var spot: StringName = f.spot
	var home := HudLayout.rect(spot, _screen())
	var by := at - (f.from as Vector2)
	_ghost[spot] = Rect2(home.position + by, home.size)
	_fits[spot] = _fits_with(spot, _move_for(f, by))
	queue_redraw()


func _lift(index: int, at: Vector2) -> void:
	var f: Dictionary = _fingers[index]
	_fingers.erase(index)
	var spot: StringName = f.spot
	_ghost.erase(spot)
	_fits.erase(spot)
	var move := _move_for(f, at - (f.from as Vector2))
	var tried := _moves.duplicate()
	tried[spot] = move
	if _fits_with(spot, move):
		_moves = tried
		_note.text = ""
	else:
		said_no_room = true
		_note.text = NO_ROOM
	_apply(_moves)


## A finger's drag `by` (on the screen) as `spot`'s move (the right hand's frame: the left hand's x is mirrored).
func _move_for(f: Dictionary, by: Vector2) -> Vector2:
	return (f.move as Vector2) + Vector2(-by.x if _left else by.x, by.y)


## True when every move fits with `spot` at `move` (HudLayout.configure rejects none); the layout is put back after.
func _fits_with(spot: StringName, move: Vector2) -> bool:
	var tried := _moves.duplicate()
	tried[spot] = move
	HudLayout.configure(_step, _left, tried, _screen())
	var ok := HudLayout.rejected.is_empty()
	_apply(_moves)
	return ok


func _apply(moves: Dictionary) -> void:
	HudLayout.configure(_step, _left, moves, _screen())
	queue_redraw()


## The moves HudLayout kept (the ones it rejected are dropped).
func _kept_moves() -> Dictionary:
	var out := {}
	for spot: StringName in _moves:
		if not HudLayout.rejected.has(spot):
			out[spot] = _moves[spot]
	return out


func _screen() -> Vector2:
	return get_viewport_rect().size


func _draw() -> void:
	var screen := _screen()
	draw_rect(Rect2(Vector2.ZERO, screen), BACKDROP)
	var outline := StyleBoxFlat.new()
	outline.draw_center = false
	outline.border_color = OUTLINE
	outline.set_border_width_all(2)
	outline.set_corner_radius_all(12)
	for spot: StringName in HudLayout.SPOTS:
		if HudLayout.MOVABLE.has(spot) or HudLayout.OVERLAYS.has(spot):
			continue
		var r := HudLayout.rect(spot, screen, HudLayout.spot_own_size(spot))
		if r.size != Vector2.ZERO:
			draw_style_box(outline, r)
	for spot: StringName in HudLayout.MOVABLE:
		_draw_piece(spot, piece_rect(spot), fits_now(spot))


func _draw_piece(spot: StringName, r: Rect2, ok: bool) -> void:
	var font := get_theme_default_font()
	var alpha := 1.0 if ok else 0.55
	if spot == &"joystick":
		var area := StyleBoxFlat.new()
		area.draw_center = false
		area.border_color = Color(EDGE, 0.6 * alpha)
		area.set_border_width_all(3)
		area.set_corner_radius_all(20)
		draw_style_box(area, r)
		var c := r.get_center()
		var radius := HudLayout.STICK * HudLayout.factor() * 0.5
		draw_circle(c, radius, Color(PIECE, PIECE.a * alpha))
		draw_arc(c, radius, 0.0, TAU, 48, Color(EDGE, alpha), 3.0, true)
		draw_circle(c, HudLayout.STICK_TIP * HudLayout.factor() * 0.5, Color(1, 1, 1, 0.5 * alpha))
		_word(font, WORDS[spot], Vector2(r.position.x, c.y + radius + 30), r.size.x, alpha)
	else:
		var c := r.get_center()
		var radius := r.size.x * 0.5
		draw_circle(c, radius, Color(PIECE, PIECE.a * alpha))
		draw_arc(c, radius - 1.5, 0.0, TAU, 48, Color(EDGE, alpha), 3.0, true)
		var side := r.size.y * 0.46
		HudIcons.draw(self, spot, Rect2(Vector2(c.x - side * 0.5, r.position.y + r.size.y * 0.15), Vector2(side, side)))
		_word(font, WORDS[spot], Vector2(r.position.x, r.position.y + r.size.y * 0.8), r.size.x, alpha)
	if not ok:   # no room: crossed out (a shape, never only a colour)
		var k := r.grow(-r.size.x * 0.18)
		draw_line(k.position, k.end, Color(1, 0.35, 0.3, 0.95), 8.0, true)
		draw_line(Vector2(k.end.x, k.position.y), Vector2(k.position.x, k.end.y), Color(1, 0.35, 0.3, 0.95), 8.0, true)


func _word(font: Font, text: String, base: Vector2, width: float, alpha: float) -> void:
	var fs := 24
	draw_string_outline(font, base, text, HORIZONTAL_ALIGNMENT_CENTER, width, fs, 5, Color(0, 0, 0, 0.75 * alpha))
	draw_string(font, base, text, HORIZONTAL_ALIGNMENT_CENTER, width, fs, Color(1, 1, 1, alpha))
