class_name OnlineUi
extends RefCounted
## The shared look of the online screens (M4 Wave 1, Agent C) on top of UiKit: pictures first, short
## words, big buttons (every one at least MIN_WIDTH wide and MIN_HEIGHT tall, spec §5.15).

const PURPLE := Color("7b4bd6")   # online play (the PLAY ONLINE and INVITE buttons)
const MIN_WIDTH := 135.0
const MIN_HEIGHT := 64.0
const HINT_COLOR := Color("ffd166")


## A big button with a picture on its left (or none when `icon` is &"").
static func button(text: String, color: Color = Color(), min_size: Vector2 = Vector2(300, 86), icon: StringName = &"") -> Button:
	var b := UiKit.big_button(text, color, Vector2(maxf(min_size.x, MIN_WIDTH), maxf(min_size.y, MIN_HEIGHT)))
	if icon != &"":
		var side := minf(b.custom_minimum_size.y - 24.0, 96.0)
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			var own := b.get_theme_stylebox(state) if b.has_theme_stylebox_override(state) \
				else UiKit.theme().get_stylebox(state, "Button")
			var box := own.duplicate() as StyleBoxFlat
			if box:
				box.content_margin_left = side + 30.0
				b.add_theme_stylebox_override(state, box)
		var pic := OnlineIcon.new(icon)
		pic.name = "Icon"
		pic.anchor_top = 0.5
		pic.anchor_bottom = 0.5
		pic.offset_left = 18.0
		pic.offset_right = 18.0 + side
		pic.offset_top = -side * 0.5
		pic.offset_bottom = side * 0.5
		b.add_child(pic)
	return b


## Owner #93: under a "can't reach the game", what still works without the internet (OnlineRules.PLAY_ALONE), in the
## hint colour; null for any other trouble.
static func play_alone(text: String, font_size: int = 24, width: float = 900.0) -> Label:
	var hint := OnlineRules.play_alone_hint(text)
	if hint == "":
		return null
	var l := words(hint, font_size, width)
	l.name = "PlayAlone"
	l.add_theme_color_override("font_color", HINT_COLOR)
	return l


## Centred words that wrap within `width`.
static func words(text: String, font_size: int = 28, width: float = 620.0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	l.add_theme_font_size_override("font_size", font_size)
	return l


## A row of controls, centred.
static func row(controls: Array, gap: int = 18) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.alignment = BoxContainer.ALIGNMENT_CENTER
	r.add_theme_constant_override("separation", gap)
	for c: Control in controls:
		r.add_child(c)
	return r


static func column(gap: int = 18) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", gap)
	return v


## Frees a container's children at once (tests count what is there in the same frame).
static func clear(parent: Node) -> void:
	for c in parent.get_children():
		parent.remove_child(c)
		c.queue_free()
