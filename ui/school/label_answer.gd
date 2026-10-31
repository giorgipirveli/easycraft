class_name LabelAnswer
extends VBoxContainer
## The research's "label the diagram" (docs/design/school-curriculum-research.md §5.3; the parts of a plant, the
## digestive system, a volcano, the continents): the exercise's picture with numbered pins on it, the labels under it.
## Tap a label, then its pin: both show the pin's number and colour. A tap on a placed label takes it off; a tap on a
## pin with no label chosen does nothing. CHECK when every label is on a pin; a miss clears them all.

signal changed

const PIN := 52.0                 # a pin's size: big enough for a finger (ExerciseCheck.PIN_GAP keeps them apart)
const LABEL := Vector2(168, 64)   # three labels to a row under the picture (ExerciseCheck.MAX_LABEL letters)
const COLORS: Array[Color] = [Color("3a7be8"), Color("f08a1c"), Color("9b59d0"), Color("16a3b8"), Color("d9437a")]

var texts: Array = []
var picture: SchoolPicture
var pins: Array[Button] = []
var labels: Array[Button] = []
var placed: Array[int] = []       # each label's pin (-1: not placed yet)
var leaders: Array = []           # [pin centre, part] for each pin that points at a part (a spot of four numbers)
var chosen := -1                  # the label waiting for its pin
var _locked := false


func _init(ex: Dictionary) -> void:
	texts = ex.get("labels", [])
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var board := Control.new()
	board.name = "Board"
	board.custom_minimum_size = ExerciseCheck.LABEL_BOX
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture = SchoolPicture.new(ex.get("picture", {}), ExerciseCheck.LABEL_BOX)
	picture.size = ExerciseCheck.LABEL_BOX
	board.add_child(picture)
	var spots: Array = ex.get("spots", [])
	for sp: Array in spots:
		if sp.size() == 4:
			leaders.append([Vector2(float(sp[0]), float(sp[1])) * ExerciseCheck.LABEL_BOX,
				Vector2(float(sp[2]), float(sp[3])) * ExerciseCheck.LABEL_BOX])
	var lines := Control.new()
	lines.name = "Leaders"
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.size = ExerciseCheck.LABEL_BOX
	lines.draw.connect(func() -> void:
		for l: Array in leaders:
			lines.draw_line(l[0], l[1], SchoolUi.INK, 3.0, true)
			lines.draw_circle(l[1], 5.0, SchoolUi.INK))
	board.add_child(lines)
	for j in spots.size():
		var pin := Button.new()
		pin.name = "Pin%d" % j
		pin.text = str(j + 1)
		pin.focus_mode = Control.FOCUS_NONE
		pin.custom_minimum_size = Vector2(PIN, PIN)
		pin.size = Vector2(PIN, PIN)
		var at := Vector2(float(spots[j][0]), float(spots[j][1])) * ExerciseCheck.LABEL_BOX
		pin.position = (at - pin.size / 2.0).clamp(Vector2.ZERO, ExerciseCheck.LABEL_BOX - pin.size)
		pin.add_theme_font_size_override("font_size", 26)
		pin.pressed.connect(tap_pin.bind(j))
		pins.append(pin)
		board.add_child(pin)
	add_child(board)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for i in texts.size():
		placed.append(-1)
		var b := SchoolUi.button("", Color(), LABEL)
		b.name = "Label%d" % i
		b.add_theme_font_size_override("font_size", 19)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(tap_label.bind(i))
		labels.append(b)
		grid.add_child(b)
	add_child(grid)
	_relabel()


## A tap on a label: choose it (or, when it is on a pin, take it off).
func tap_label(i: int) -> void:
	if _locked or i < 0 or i >= texts.size():
		return
	if placed[i] >= 0:
		placed[i] = -1
		chosen = -1
	else:
		chosen = -1 if chosen == i else i
	_relabel()
	changed.emit()


## A tap on a pin: the chosen label goes there (taking the place of a label already on it).
func tap_pin(j: int) -> void:
	if _locked or chosen < 0 or j < 0 or j >= pins.size():
		return
	var had := placed.find(j)
	if had >= 0:
		placed[had] = -1
	placed[chosen] = j
	chosen = -1
	_relabel()
	changed.emit()


func response() -> Variant:
	return placed.duplicate()


func is_ready() -> bool:
	return not placed.has(-1)


func mark_wrong() -> void:
	for i in placed.size():
		placed[i] = -1
	chosen = -1
	_relabel()


func mark_right() -> void:
	for b in labels:
		b.add_theme_stylebox_override("disabled", UiKit.box(UiKit.GREEN))


func lock() -> void:
	_locked = true
	for b in labels + pins:
		b.disabled = true


func show_answer(answer: Variant) -> void:
	for i in mini(placed.size(), (answer as Array).size()):
		placed[i] = int(answer[i])
	chosen = -1
	_relabel()
	mark_right()


func _relabel() -> void:
	for i in labels.size():
		var j := placed[i]
		labels[i].text = ("%d.  " % (j + 1) if j >= 0 else "") + ExerciseCheck.item_text(texts[i])
		_colour(labels[i], COLORS[j % COLORS.size()] if j >= 0 else (Color("ffe14d") if chosen == i else Color()))
	for j in pins.size():
		var filled := placed.has(j)
		var look := StyleBoxFlat.new()
		look.set_corner_radius_all(int(PIN / 2.0))
		look.set_border_width_all(4)
		look.border_color = Color.WHITE if filled else SchoolUi.INK
		look.bg_color = COLORS[j % COLORS.size()] if filled else Color("fff8d6")
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			pins[j].add_theme_stylebox_override(state, look)
		var ink := Color.WHITE if filled else SchoolUi.INK
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			pins[j].add_theme_color_override(state, ink)


func _colour(b: Button, c: Color) -> void:
	if c == Color():
		b.remove_theme_stylebox_override("normal")
	else:
		b.add_theme_stylebox_override("normal", UiKit.box(c))
	if c.get_luminance() > 0.6:   # the chosen one's yellow: dark words
		for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(state, Color(0.12, 0.12, 0.18))
	else:
		for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.remove_theme_color_override(state)
