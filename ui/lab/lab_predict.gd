class_name LabPredict
extends GridContainer
## Spec §23.1, step 1: the guess. A "choice" prediction is big buttons (a tap picks one, teal; another tap picks another:
## nothing is ever greyed out or marked); a "sort" prediction is a card per thing with its picture (a tap puts it in
## the next group: its name and colour show on it, and round again). The School's exercise forms (ExerciseCheck), but
## a guess is never checked here: the Lab keeps it and compares it with what happened, kindly, at step 3.

signal changed

const CHOICE := Vector2(420, 96)
const CARD := Vector2(262, 132)
## The groups' colours (the School's SortAnswer's: never red or green, which mean wrong and right).
const COLORS: Array[Color] = [Color("3a7be8"), Color("f08a1c")]
const PICKED := Color("139e9b")

var ex: Dictionary
var sort := false
var buttons: Array[Button] = []
var chosen := -1
var picked: Array[int] = []
var _group_labels: Array[Label] = []


## `p`: the prediction as a School exercise (LabExperiments.predict_of); `things`: the scene's things (a sort's cards).
func _init(p: Dictionary = {}, things: Array = []) -> void:
	ex = p
	name = "Predict"
	sort = str(p.get("type", "")) == "sort"
	add_theme_constant_override("h_separation", 14)
	add_theme_constant_override("v_separation", 12)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if sort:
		columns = 4
		var items: Array = p.get("items", [])
		for i in items.size():
			picked.append(-1)
			var b := _card(str(items[i]), str((things[i] as Dictionary).get("thing", "")) if i < things.size() else "")
			b.pressed.connect(tap.bind(i))
			buttons.append(b)
			add_child(b)
	else:
		columns = 2
		var choices: Array = p.get("choices", [])
		for i in choices.size():
			var b := SchoolUi.button(ExerciseCheck.item_text(choices[i]), Color(0.2, 0.24, 0.36), CHOICE)
			b.name = "Choice%d" % i
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.add_theme_font_size_override("font_size", 28)
			b.pressed.connect(choose.bind(i))
			buttons.append(b)
			add_child(b)
	_show()


func _card(words: String, thing: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD
	b.focus_mode = Control.FOCUS_NONE
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8
	h.add_theme_constant_override("separation", 6)
	var pic := LabThings.Picture.new(thing, 80.0)
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(pic)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var n := Label.new()
	n.text = words
	n.add_theme_font_size_override("font_size", 22)
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.custom_minimum_size.x = CARD.x - 110
	v.add_child(n)
	var g := Label.new()
	g.name = "Group"
	g.add_theme_font_size_override("font_size", 20)
	v.add_child(g)
	_group_labels.append(g)
	h.add_child(v)
	b.add_child(h)
	return b


## A tap on choice i: that is the guess now.
func choose(i: int) -> void:
	if sort or i < 0 or i >= buttons.size():
		return
	chosen = i
	Audio.play(&"ui_click")
	_show()
	changed.emit()


## A tap on thing i: the next group.
func tap(i: int) -> void:
	if not sort or i < 0 or i >= picked.size():
		return
	picked[i] = (picked[i] + 1) % (ex.get("groups", []) as Array).size()
	Audio.play(&"ui_click")
	_show()
	changed.emit()


func response() -> Variant:
	return picked.duplicate() if sort else chosen


func is_ready() -> bool:
	return not picked.has(-1) if sort else chosen >= 0


func _show() -> void:
	var groups: Array = ex.get("groups", [])
	for i in buttons.size():
		var group := picked[i] if sort else (0 if i == chosen else -1)
		var col: Color = (COLORS[group % COLORS.size()] if sort else PICKED) if group >= 0 else Color(0.2, 0.24, 0.36)
		for state: String in ["normal", "hover", "pressed"]:
			buttons[i].add_theme_stylebox_override(state, UiKit.box(col if state != "pressed" else col.lightened(0.15), 16, 8))
		if sort:
			_group_labels[i].text = str(groups[picked[i]]) if picked[i] >= 0 else "tap to guess"
