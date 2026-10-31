class_name PlanetGuideCard
extends PanelContainer
## Owner #88: the explorer's card on landing on a planet with sights: "EXPLORE MERCURY", what to do (PlanetGuideRules:
## intro, with a speaker for children who don't read yet), each place marked "(found!)" once found, and LET'S GO. The HUD's
## compass then points to the nearest place not found.

signal closed

var go_button: Button
var lines: Array[Label] = []


## groups (owner #78: the wonders' two tours): [{title, list}] shown side by side under their titles in place of `list`
## (every line still in `lines`).
func _init(planet: String, list: Array[Dictionary], own_words: String = "", groups: Array = []) -> void:
	name = "PlanetGuideCard"
	add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.2, 0.95), 22, 24))
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	var title := UiKit.title("EXPLORE " + planet.to_upper(), 38)
	var intro := own_words if own_words != "" else PlanetGuideRules.intro(planet, list)   # owner #78: a tour's own
	v.add_child(ReadAloud.with_speaker(title, self, func() -> String: return intro))
	var words := Label.new()
	words.text = intro
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.custom_minimum_size.x = 640
	words.add_theme_font_size_override("font_size", 22)
	v.add_child(words)
	if groups.is_empty():
		for e: Dictionary in list:
			v.add_child(_line(e, 26))
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 28)
		v.add_child(row)
		for g: Dictionary in groups:
			var col := VBoxContainer.new()
			col.add_theme_constant_override("separation", 4)
			var head := Label.new()
			head.text = str(g.title)
			head.add_theme_font_size_override("font_size", 24)
			head.add_theme_color_override("font_color", Color("ffe14d"))
			col.add_child(head)
			for e: Dictionary in g.list:
				col.add_child(_line(e, 21))
			row.add_child(col)
	go_button = UiKit.big_button("LET'S GO!", UiKit.GREEN, Vector2(280, 80))
	go_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go_button.pressed.connect(close)
	v.add_child(go_button)


func _line(e: Dictionary, font: int) -> Label:
	var l := Label.new()
	l.text = "•  " + str(e.name) + ("   (found!)" if bool(e.found) else "")   # the font has no tick
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", Color("7be08a") if bool(e.found) else Color.WHITE)
	lines.append(l)
	return l


func _ready() -> void:
	PadFocus.take(self, go_button)   # owner #90: LET'S GO has a game controller's focus; Cross / A goes


## Owner #90: Circle / B on the card is LET'S GO too (the game's Back would open the pause menu under it).
func pad_back() -> bool:
	close()
	return true


func close() -> void:
	visible = false
	closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if visible and k != null and k.pressed and not k.echo and k.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		close()
		get_viewport().set_input_as_handled()
