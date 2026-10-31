class_name WelcomeCards
extends RefCounted
## M3 Task 21a: a card the menu shows once (at first launch, or once at the next start for a child who played
## before): "Simple controls?" after the look (research O8: two equal picture cards, no nudge; SETTINGS can switch
## any time), with a speaker. (Its LANGUAGE card was removed by owner #52: the game is English only.)

const CONTROLS := &"controls"
const CHOICE_SIZE := Vector2(340, 224)


## The cards still to show, in order.
static func due(settings: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	if not bool(settings.get("simple_asked", false)) and not PlatformRules.keyboard_first(PlatformRules.current()):   # #84
		out.append(CONTROLS)
	return out


## The card of `kind`; `saver` saves the profile (default Profile.save; tests pass a no-op). It emits `chosen`.
static func card(kind: StringName, saver := Callable()) -> Control:
	var c: Card = ControlsCard.new()
	c.saver = saver
	return c


## A card: a title with a speaker, the choices, and `chosen` once one is picked.
class Card:
	extends VBoxContainer

	signal chosen

	var saver := Callable()

	func _title(text: String) -> void:
		add_theme_constant_override("separation", 20)
		add_child(ReadAloud.with_speaker(UiKit.title(text), self))

	func _row() -> HBoxContainer:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 28)
		add_child(row)
		return row

	func _save() -> void:
		if saver.is_valid():
			saver.call()
		else:
			Profile.save()


## "Simple controls?": SIMPLE and CLASSIC, the same size, each a picture with a short line.
class ControlsCard:
	extends Card

	func _ready() -> void:
		_title("How do you like to play?")
		var row := _row()
		for simple: bool in [true, false]:
			var b := Button.new()
			b.name = "SimpleCard" if simple else "ClassicCard"
			b.custom_minimum_size = CHOICE_SIZE
			var word := Label.new()   # the word under the picture
			word.text = "SIMPLE" if simple else "CLASSIC"
			word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			word.add_theme_font_size_override("font_size", 34)
			word.mouse_filter = Control.MOUSE_FILTER_IGNORE
			word.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
			word.offset_top = -58
			word.offset_bottom = -8
			b.add_child(word)
			var pic := ControlsPicture.new()
			pic.name = "Picture"
			pic.simple = simple
			pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pic.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
			pic.offset_top = 12
			pic.offset_bottom = 156
			b.add_child(pic)
			b.pressed.connect(_pick.bind(simple))
			var col := VBoxContainer.new()
			col.add_theme_constant_override("separation", 8)
			col.add_child(b)
			var about := Label.new()
			about.text = "Hop up steps by yourself, the camera follows you, fewer buttons." if simple \
				else "Every button, and you move the camera."
			about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			about.custom_minimum_size.x = CHOICE_SIZE.x
			about.add_theme_font_size_override("font_size", 24)
			col.add_child(about)
			row.add_child(col)
		var hint := Label.new()
		hint.text = "You can change it any time in SETTINGS."
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 24)
		add_child(hint)

	func _pick(simple: bool) -> void:
		Profile.data.settings.simple_controls = simple
		Profile.data.settings.simple_asked = true
		_save()
		chosen.emit()


## The picture on a controls card, drawn in code: SIMPLE, a child hopping up a step by itself with the camera
## behind; CLASSIC, the stick and a few round buttons.
class ControlsPicture:
	extends Control

	var simple := true

	func _draw() -> void:
		var u := minf(size.x, size.y)
		var c := size * 0.5
		var ink := Color.WHITE
		if simple:
			var block := Color("7bc043")
			var step := Rect2(c + Vector2(0.05, 0.12) * u, Vector2(0.42, 0.34) * u)
			draw_rect(Rect2(c + Vector2(-0.62, 0.46) * u, Vector2(1.24, 0.06) * u), block.darkened(0.3))
			draw_rect(step, block)
			var head := c + Vector2(-0.12, -0.2) * u
			draw_circle(head, 0.1 * u, Color("ffd7a8"))
			draw_line(head + Vector2(0, 0.1) * u, head + Vector2(0, 0.32) * u, ink, 0.05 * u)
			draw_line(head + Vector2(0, 0.32) * u, head + Vector2(-0.1, 0.46) * u, ink, 0.05 * u)
			draw_line(head + Vector2(0, 0.32) * u, head + Vector2(0.12, 0.4) * u, ink, 0.05 * u)
			draw_arc(c + Vector2(0.02, -0.02) * u, 0.3 * u, PI * 1.1, PI * 1.75, 14, Color("ffd23f"), 0.04 * u)
			var cam := c + Vector2(-0.5, -0.3) * u     # the camera, following behind
			draw_rect(Rect2(cam - Vector2(0.08, 0.05) * u, Vector2(0.16, 0.1) * u), Color("9fd3ff"))
			draw_circle(cam + Vector2(0.1, 0) * u, 0.035 * u, Color("9fd3ff"))
		else:
			var stick := c + Vector2(-0.34, 0.12) * u
			draw_circle(stick, 0.24 * u, Color(1, 1, 1, 0.25))
			draw_circle(stick + Vector2(0.06, -0.05) * u, 0.1 * u, ink)
			for p: Vector2 in [Vector2(0.26, 0.2), Vector2(0.46, 0.02), Vector2(0.24, -0.18), Vector2(0.48, -0.36)]:
				draw_circle(c + p * u, 0.09 * u, Color(1, 1, 1, 0.3))
				draw_arc(c + p * u, 0.09 * u, 0.0, TAU, 20, ink, 0.02 * u)
