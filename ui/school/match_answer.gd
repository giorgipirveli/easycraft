class_name MatchAnswer
extends HBoxContainer
## The research's "match pairs" (docs/design/school-curriculum-research.md §5.3; word and meaning, instrument and family):
## the things on the left, their partners on the right in their own order. Tap one on the left, then its partner on the
## right: both show the same number and colour. A tap on a paired one on the left unpairs it. CHECK when every thing
## on the left has a partner; a miss clears the pairs.

signal changed

const ITEM := Vector2(260, 62)   # two columns beside the prompt (ExercisePanel.SIZE)
const COLORS: Array[Color] = [Color("3a7be8"), Color("f08a1c"), Color("9b59d0"), Color("16a3b8"), Color("d9437a")]

var items: Array = []
var matches: Array = []
var left: Array[Button] = []
var right: Array[Button] = []
var pairs: Array[int] = []        # each left item's partner on the right (-1: none yet)
var chosen := -1                  # the left item waiting for its partner
var _locked := false


func _init(ex: Dictionary) -> void:
	items = ex.get("items", [])
	matches = ex.get("matches", [])
	add_theme_constant_override("separation", 24)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var lc := VBoxContainer.new()
	lc.add_theme_constant_override("separation", 8)
	var rc := VBoxContainer.new()
	rc.add_theme_constant_override("separation", 8)
	add_child(lc)
	add_child(rc)
	for i in items.size():
		pairs.append(-1)
		var b := SchoolUi.button("", Color(), ITEM)
		b.name = "Left%d" % i
		b.add_theme_font_size_override("font_size", 21)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(tap_left.bind(i))
		left.append(b)
		lc.add_child(b)
	for j in matches.size():
		var b := SchoolUi.button("", Color(), ITEM)
		b.name = "Right%d" % j
		b.add_theme_font_size_override("font_size", 21)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(tap_right.bind(j))
		right.append(b)
		rc.add_child(b)
	_relabel()


## A tap on the left: choose it (or, when it has a partner, unpair it).
func tap_left(i: int) -> void:
	if _locked or i < 0 or i >= items.size():
		return
	if pairs[i] >= 0:
		pairs[i] = -1
		chosen = -1
	else:
		chosen = -1 if chosen == i else i
	_relabel()
	changed.emit()


## A tap on the right: the chosen left thing's partner (taken from another pair if it had one).
func tap_right(j: int) -> void:
	if _locked or chosen < 0 or j < 0 or j >= matches.size():
		return
	var had := pairs.find(j)
	if had >= 0:
		pairs[had] = -1
	pairs[chosen] = j
	chosen = -1
	_relabel()
	changed.emit()


func response() -> Variant:
	return pairs.duplicate()


func is_ready() -> bool:
	return not pairs.has(-1)


func mark_wrong() -> void:
	for i in pairs.size():
		pairs[i] = -1
	chosen = -1
	_relabel()


func mark_right() -> void:
	for b in left + right:
		b.add_theme_stylebox_override("disabled", UiKit.box(UiKit.GREEN))


func lock() -> void:
	_locked = true
	for b in left + right:
		b.disabled = true


func show_answer(answer: Variant) -> void:
	for i in mini(pairs.size(), (answer as Array).size()):
		pairs[i] = int(answer[i])
	chosen = -1
	_relabel()
	mark_right()


func _relabel() -> void:
	for i in left.size():
		var n := _number(i)
		left[i].text = ("%d.  " % n if n > 0 else "") + ExerciseCheck.item_text(items[i])
		_colour(left[i], COLORS[(n - 1) % COLORS.size()] if n > 0 else (Color("ffe14d") if chosen == i else Color()))
	for j in right.size():
		var i := pairs.find(j)
		var n := _number(i) if i >= 0 else 0
		right[j].text = ("%d.  " % n if n > 0 else "") + ExerciseCheck.item_text(matches[j])
		_colour(right[j], COLORS[(n - 1) % COLORS.size()] if n > 0 else Color())


## Pair numbers count the pairs from the top of the left side: 1, 2, 3 …
func _number(i: int) -> int:
	if i < 0 or pairs[i] < 0:
		return 0
	var n := 0
	for k in i + 1:
		if pairs[k] >= 0:
			n += 1
	return n


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
