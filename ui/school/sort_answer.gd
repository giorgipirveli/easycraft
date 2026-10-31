class_name SortAnswer
extends VBoxContainer
## The research's "sort into groups" (docs/design/school-curriculum-research.md §5.3; living or not, source or not): each
## thing is a big button; a tap puts it in the next group (its name and colour show on it), and round again. CHECK when
## every thing is sorted; a miss clears the groups.

signal changed

const ITEM := Vector2(560, 56)
const PLAIN := Color(0.2, 0.24, 0.36)
## The groups' colours on the items (never red or green: those mean wrong and right).
const COLORS: Array[Color] = [Color("3a7be8"), Color("f08a1c"), Color("9b59d0")]

var items: Array = []
var groups: Array = []
var buttons: Array[Button] = []
var picked: Array[int] = []
var _locked := false


func _init(ex: Dictionary) -> void:
	items = ex.get("items", [])
	groups = ex.get("groups", [])
	add_theme_constant_override("separation", 6)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# The groups as a line that wraps within the items' width (long names never push the panel wider)
	var legend := SchoolUi.words("Tap to sort:  " + "  ·  ".join(PackedStringArray(groups.map(
		func(g: Variant) -> String: return str(g)))), 18, ITEM.x)
	add_child(legend)
	for i in items.size():
		picked.append(-1)
		var b := UiKit.big_button("", Color(), ITEM)   # not the School's 64 px minimum: six rows and the legend fit
		b.focus_mode = Control.FOCUS_NONE
		b.name = "Item%d" % i
		b.add_theme_font_size_override("font_size", 20)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # a long thing and its group take two lines, never more width
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, UiKit.box(PLAIN, 14, 6))   # slim margins: two lines fit its height
		b.pressed.connect(tap.bind(i))
		buttons.append(b)
		add_child(b)
	_relabel()


## A tap on thing i: the next group (after the last, the first again).
func tap(i: int) -> void:
	if _locked or i < 0 or i >= items.size():
		return
	picked[i] = (picked[i] + 1) % groups.size()
	_relabel()
	changed.emit()


func response() -> Variant:
	return picked.duplicate()


func is_ready() -> bool:
	return not picked.has(-1)


func mark_wrong() -> void:
	for i in picked.size():
		picked[i] = -1
	_relabel()


func mark_right() -> void:
	for b in buttons:
		b.add_theme_stylebox_override("disabled", UiKit.box(UiKit.GREEN))


func lock() -> void:
	_locked = true
	for b in buttons:
		b.disabled = true


func show_answer(answer: Variant) -> void:
	for i in mini(picked.size(), (answer as Array).size()):
		picked[i] = int(answer[i])
	_relabel()
	mark_right()


func _relabel() -> void:
	for i in buttons.size():
		var words := ExerciseCheck.item_text(items[i])
		var g := picked[i]
		if g < 0:
			buttons[i].text = "   %s" % words
			buttons[i].add_theme_stylebox_override("normal", UiKit.box(PLAIN, 14, 6))
		else:
			buttons[i].text = "   %s   →   %s" % [words, groups[g]]
			buttons[i].add_theme_stylebox_override("normal", UiKit.box(COLORS[g % COLORS.size()], 14, 6))
