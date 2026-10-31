class_name OrderAnswer
extends VBoxContainer
## Owner #68 (spec §22.1): put things in order by tapping them first to last; each tapped one shows its place ("1.").
## A tap on the last one placed takes it back; CLEAR starts again (a miss clears it by itself).

signal changed

const ITEM := Vector2(540, 56)
const PLAIN := Color(0.2, 0.24, 0.36)

var items: Array = []
var buttons: Array[Button] = []
var order: Array[int] = []
var clear_button: Button
var _locked := false


func _init(ex: Dictionary) -> void:
	items = ex.get("items", [])
	add_theme_constant_override("separation", 6)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for i in items.size():
		# Not the School's 64 px minimum: six rows fit; long words wrap to two lines within the width
		var b := UiKit.big_button(ExerciseCheck.item_text(items[i]), Color(), ITEM)
		b.focus_mode = Control.FOCUS_NONE
		b.name = "Item%d" % i
		b.add_theme_font_size_override("font_size", 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, UiKit.box(PLAIN, 14, 6))
		b.pressed.connect(tap.bind(i))
		buttons.append(b)
		add_child(b)
	clear_button = SchoolUi.button("CLEAR", UiKit.BLUE, Vector2(200, 64))
	clear_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	clear_button.pressed.connect(clear)
	add_child(clear_button)


func tap(i: int) -> void:
	if _locked or i < 0 or i >= items.size():
		return
	if order.has(i):
		if order.back() == i:
			order.pop_back()   # the last one placed goes back
	else:
		order.append(i)
	_relabel()
	changed.emit()


func clear() -> void:
	if _locked:
		return
	order.clear()
	_relabel()
	changed.emit()


func response() -> Variant:
	return order.duplicate()


func is_ready() -> bool:
	return order.size() == items.size()


func mark_wrong() -> void:
	clear()


func mark_right() -> void:
	for b in buttons:
		b.add_theme_stylebox_override("disabled", UiKit.box(UiKit.GREEN, 14, 6))


func lock() -> void:
	_locked = true
	for b in buttons:
		b.disabled = true
	clear_button.disabled = true


func show_answer(answer: Variant) -> void:
	order.clear()
	for i: Variant in answer:
		order.append(int(i))
	_relabel()
	mark_right()


func _relabel() -> void:
	for i in buttons.size():
		var place := order.find(i)
		var words := ExerciseCheck.item_text(items[i])
		buttons[i].text = "%d.   %s" % [place + 1, words] if place >= 0 else "      %s" % words
