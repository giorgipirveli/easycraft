class_name KeysCard
extends PanelContainer
## Owner #84: the PC's KEYS card (KeysRules): two columns of key caps and what they do, CLOSE (or Esc, or F1 again).
## Owner #90: with a game controller used last it is the CONTROLLER card (GamepadRules.CARD_LINES): the pad's own words
## for its buttons (PlayStation or Xbox, by the pad's name), the face buttons drawn (PadGlyph); show_for switches it as
## the child switches hands. It frees the mouse while it shows and emits `closed`.

signal closed

const CAP := Vector2(180, 42)
const PAD_CAP := Vector2(230, 42)
const WORDS_W := 330.0
const PAD_WORDS_W := 300.0

var close_button: Button
## &"" the keys; else the pad's family (GamepadRules.PLAYSTATION, XBOX or GENERIC).
var family: StringName = &""
var _body: VBoxContainer


func _init(pad_family: StringName = &"") -> void:
	name = "KeysCard"
	add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.13, 0.22, 0.96), 22, 26))
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	family = pad_family
	_build()


func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	visible = false
	closed.emit()


## The keys (&"") or a pad's family: the card shows what the child's hands hold now.
func show_for(pad_family: StringName) -> void:
	if pad_family == family:
		return
	family = pad_family
	_build()
	reset_size()


func _build() -> void:
	if _body:
		remove_child(_body)
		_body.queue_free()
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 14 if family == &"" else 10)
	add_child(_body)
	var title := UiKit.title(_title(), 40 if family == &"" else 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(title)
	var halves := HBoxContainer.new()
	halves.add_theme_constant_override("separation", 36 if family == &"" else 28)
	_body.add_child(halves)
	var lines: Array = KeysRules.LINES if family == &"" else GamepadRules.CARD_LINES
	var per_half := ceili(lines.size() / 2.0)
	for h in 2:
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 8 if family == &"" else 6)
		halves.add_child(grid)
		for line: Array in lines.slice(h * per_half, (h + 1) * per_half):
			grid.add_child(_cap(line[0]))
			var words := Label.new()
			words.text = str(line[1])
			words.custom_minimum_size.x = WORDS_W if family == &"" else PAD_WORDS_W
			words.add_theme_font_size_override("font_size", 22 if family == &"" else 21)
			words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			grid.add_child(words)
	close_button = UiKit.big_button("CLOSE", UiKit.GREEN, Vector2(240, 72 if family == &"" else 64))
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(close)
	_body.add_child(close_button)


func _title() -> String:
	match family:
		&"":
			return "KEYS"
		GamepadRules.PLAYSTATION:
			return "PLAYSTATION CONTROLLER"
		GamepadRules.XBOX:
			return "XBOX CONTROLLER"
	return "CONTROLLER"


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if visible and k != null and k.pressed and not k.echo and k.keycode in [KEY_ESCAPE, KEY_F1]:
		close()
		get_viewport().set_input_as_handled()


## One line's cap: the keys (KeysRules.line_keys), or the pad's words with its face button drawn beside them.
func _cap(actions: Array) -> Control:
	var l := Label.new()
	l.text = KeysRules.line_keys(actions) if family == &"" else GamepadRules.line_words(actions, family)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 22 if family == &"" else 20)
	l.add_theme_color_override("font_color", SchoolUi.INK)
	var box := UiKit.box(Color("f4efe1"), 10, 6)
	var face := _face_button(actions)
	if face < 0:
		l.custom_minimum_size = CAP if family == &"" else PAD_CAP
		l.add_theme_stylebox_override("normal", box)
		return l
	var cap := PanelContainer.new()
	cap.custom_minimum_size = PAD_CAP
	cap.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	cap.add_child(row)
	row.add_child(PadGlyph.new(face, family))
	row.add_child(l)
	return cap


## The face button (Cross / A, Circle / B, Square / X, Triangle / Y) a pad line is, -1 for any other.
static func _face_button(actions: Array) -> int:
	if actions.size() != 1:
		return -1
	var specs := GamepadRules.specs_for(actions[0])
	if specs.size() != 1 or not (specs[0] as Dictionary).has("button"):
		return -1
	var b: int = specs[0].button
	return b if b in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y] else -1
