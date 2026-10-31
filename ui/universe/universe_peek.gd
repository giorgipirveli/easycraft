class_name UniversePeek
extends CanvasLayer
## Universe 6, the Glow Caves (brief: "worth paying for", owner #72; docs/design fair-fun rules): a free peek at a locked
## universe that has one (UniverseRegistry.peek), from the hub's locked card (UniverseCard's PEEK) and the Star Map's
## card (SpacePanel's PEEK). Over the screen it came from (the same viewport: a VR panel's too): the universe's own
## picture (UniverseArt, its true colours) with its lights twinkling, its name, what is inside and how it opens (beat
## the boss before it), spoken too when the play's voice is on (PlayVoice, owner #133/#134). No price, no timer shown,
## nothing that hurries; it closes on CLOSE, a tap outside it, or by itself after PEEK_SECONDS. Nothing is kept or sent.

const PEEK_SECONDS := 10.0
const LAYER := 90
const PICTURE := Vector2(620, 300)
const TWINKLES := 34

var universe := 0
var close_button: Button
var picture := UniverseCard.UniversePicture.new()
var _twinkles := Control.new()
var _labels: Array[Label] = []
var _t := 0.0


## Opens the peek of universe `u` over `near`'s screen; null when `u` has none.
static func show_for(u: int, near: Node) -> UniversePeek:
	if UniverseRegistry.peek(u).is_empty() or near == null or not near.is_inside_tree():
		return null
	var p := UniversePeek.new()
	p.universe = u
	near.get_viewport().add_child(p)
	return p


func _ready() -> void:
	layer = LAYER
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and (e as InputEventMouseButton).pressed) or (e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed):
			close())
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.06, 0.07, 0.18, 0.97), 24, 22))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(column)
	var title := UiKit.title(UniverseRegistry.display_name(universe), 40)
	title.add_theme_color_override("font_color", Color("ffe14d"))
	column.add_child(title)
	_labels.append(title)
	picture.universe = universe
	picture.locked = false
	picture.custom_minimum_size = PICTURE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(picture)
	_twinkles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_twinkles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_twinkles.draw.connect(_draw_twinkles)
	picture.add_child(_twinkles)
	for line: String in UniverseRegistry.peek(universe):
		column.add_child(_line(tr(line), 26, Color.WHITE))
	column.add_child(_line(tr(StarMap.action_words(StarMap.LOCKED)), 22, Color(0.8, 0.84, 0.95)))
	close_button = UiKit.big_button("CLOSE", UiKit.BLUE, Vector2(240, 72))
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	var row := CenterContainer.new()
	row.add_child(close_button)
	column.add_child(row)
	Audio.play(&"ui_click")
	PlayVoice.say(words())   # owner #133/#134: what is inside, heard (when the voice is on)


func _process(delta: float) -> void:
	tick(delta)
	_twinkles.queue_redraw()


## The peek's clock: it closes by itself after PEEK_SECONDS.
func tick(delta: float) -> void:
	_t += delta
	if _t >= PEEK_SECONDS:
		close()


func close() -> void:
	if not is_queued_for_deletion():
		queue_free()


## Everything it says (tests, read-aloud).
func words() -> String:
	var out: Array[String] = []
	for l in _labels:
		out.append(l.text)
	return "\n".join(out)


func _line(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = PICTURE.x
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	_labels.append(l)
	return l


## Soft lights over the picture, each glowing up and down at its own pace (its ground's colour, lighter).
func _draw_twinkles() -> void:
	var s := _twinkles.size
	var glow: Color = UniverseRegistry.card_colors(universe).ground
	for i in TWINKLES:
		var h := absi(hash(Vector2i(universe * 97 + i, i * 31)))
		var p := Vector2(float(h % 1000) / 1000.0 * s.x, (0.15 + float((h >> 10) % 700) / 1000.0) * s.y)
		var k := 0.5 + 0.5 * sin(_t * (1.2 + float((h >> 20) % 10) / 10.0) + float(i))
		var c := glow.lightened(0.45)
		c.a = 0.25 + 0.6 * k
		_twinkles.draw_circle(p, 2.0 + 2.5 * k, c)
