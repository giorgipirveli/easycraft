class_name LabColoursView
extends LabView
## Mixing colours (LabColours). PAINT: a tap on a pot drops its paint into the bowl (the School's ColourMix colours it
## and names a mix it knows); CLEAN empties it. LIGHT: a tap on a torch switches it; its light is drawn with additive
## blending on a dark wall, so red and green make yellow where they overlap and all three make white. A dot per goal
## (orange, green, brown; yellow, white) fills in once that mix was made.

const WALL := Rect2(620, 48, 524, 196)
const BOWL := Vector2(468, 128)
const BOWL_R := 72.0
const SPOTS := [Vector2(217, 70), Vector2(307, 70), Vector2(262, 128)]   # overlapping, so the lights mix
const SPOT_R := 64.0
const GOAL_COLOURS := {"orange": Color("f08a1c"), "green": Color("2fae4e"), "brown": Color("7a4a24"),
	"yellow": Color(1, 1, 0), "white": Color(1, 1, 1), "cyan": Color(0, 1, 1), "magenta": Color(1, 0, 1)}

var paint_buttons: Array[Button] = []
var light_buttons: Array[Button] = []
var clean_button: Button
var bowl_label: Label
var _spots: Array[Control] = []


func _init(m: LabModel = null) -> void:
	super(m)
	var c := model as LabColours
	for i in c.paints.size():
		var p := c.paints[i]
		var b := place_button("", Color(), Vector2(24 + i * 112, 52), Vector2(104, 118))
		b.name = "Paint_" + p
		var pot := PaintPot.new(ColourMix.PAINT_COLOURS.get(p, Color.WHITE))
		pot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(pot)
		var word := LabView._label(p, 20, Color.WHITE)
		word.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		word.offset_top = -30
		b.add_child(word)
		b.pressed.connect(_paint.bind(p))
		paint_buttons.append(b)
	clean_button = place_button("CLEAN", Color("6b7a8f"), Vector2(30, 196), Vector2(170, 72), 24)
	clean_button.name = "Clean"
	clean_button.pressed.connect(_clean)
	bowl_label = place_label("", 24, INK, Vector2(BOWL.x - 110, BOWL.y + BOWL_R + 6), 220)
	bowl_label.name = "Bowl"
	var wall := Control.new()
	wall.name = "Wall"
	wall.clip_contents = true
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wall)
	wall.position = WALL.position
	wall.size = WALL.size
	for i in c.light_list.size():
		var spot := LightSpot.new(LabColours.LIGHTS.get(c.light_list[i], Color.WHITE), SPOT_R)
		wall.add_child(spot)
		spot.position = SPOTS[i % SPOTS.size()] - Vector2(SPOT_R, SPOT_R)
		spot.size = Vector2(SPOT_R, SPOT_R) * 2.0
		_spots.append(spot)
		var colour: Color = LabColours.LIGHTS.get(c.light_list[i], Color.WHITE)
		var t := place_button(c.light_list[i].to_upper(), colour.darkened(0.35), Vector2(636 + i * 172, 256), Vector2(160, 72), 24)
		t.name = "Torch_" + c.light_list[i]
		t.pressed.connect(_light.bind(i))
		light_buttons.append(t)
	refresh()


func _paint(p: String) -> void:
	(model as LabColours).add_paint(p)
	Audio.play(&"ui_tick")
	tapped()


func _clean() -> void:
	(model as LabColours).clean()
	Audio.play(&"splash_small")
	tapped()


func _light(i: int) -> void:
	(model as LabColours).toggle_light(i)
	Audio.play(&"ui_click")
	tapped()


func refresh() -> void:
	var c := model as LabColours
	var name := c.paint_name()
	bowl_label.text = name if name != "" else ("" if c.drops.is_empty() else "a new colour")
	for i in _spots.size():
		_spots[i].visible = c.lights[i]
		light_buttons[i].text = c.light_list[i].to_upper() + (" ON" if c.lights[i] else "")
		light_buttons[i].modulate = Color.WHITE if c.lights[i] else Color(1, 1, 1, 0.75)
	super.refresh()


func _draw() -> void:
	super._draw()
	var c := model as LabColours
	text_at("PAINT", Vector2(96, 28), 26, INK)
	_goals(c.scene.get("paint_goals", []), c.found_paint, Vector2(200, 28))
	text_at("LIGHT", Vector2(690, 28), 26, INK)
	_goals(c.scene.get("light_goals", []), c.found_light, Vector2(790, 28))
	# the bowl
	draw_circle(BOWL, BOWL_R, Color("e9e4d8"))
	draw_circle(BOWL, BOWL_R * 0.8, ColourMix.colour(c.drops))
	draw_arc(BOWL, BOWL_R, 0, TAU, 40, Color("9c8f78"), 4.0)
	draw_arc(BOWL + Vector2(-BOWL_R * 0.3, -BOWL_R * 0.3), BOWL_R * 0.4, PI, PI * 1.4, 10, Color(1, 1, 1, 0.5), 4.0)
	# the dark wall the torches shine on
	draw_rect(WALL, Color(0.04, 0.05, 0.09))
	draw_rect(WALL, Color("3b4a5e"), false, 4.0)


## A dot per goal, filled with its colour once made, then its name.
func _goals(goals: Array, found: Dictionary, at: Vector2) -> void:
	var x := at.x
	var font := ThemeDB.fallback_font
	for g: Variant in goals:
		var col: Color = GOAL_COLOURS.get(str(g), Color.GRAY)
		var done := found.has(str(g))
		var dot := Vector2(x + 10, at.y)
		if done:   # filled with the colour made, and a drawn tick
			draw_circle(dot, 10, col)
			var tick := INK if col.get_luminance() > 0.6 else Color.WHITE
			draw_polyline(PackedVector2Array([dot + Vector2(-5, 0), dot + Vector2(-1, 4), dot + Vector2(5, -4)]), tick, 2.5)
		draw_arc(dot, 10, 0, TAU, 20, INK, 2.0)
		draw_string(font, Vector2(x + 26, at.y + 8), str(g), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK if done else SOFT)
		x += 36 + font.get_string_size(str(g), HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 12


## A paint pot of `colour` (a pot button's picture).
class PaintPot:
	extends Control
	var colour := Color.WHITE

	func _init(c: Color) -> void:
		colour = c
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var body := Rect2(Vector2(w * 0.24, h * 0.2), Vector2(w * 0.52, h * 0.44))
		draw_rect(body, Color("c9ced6"))
		draw_rect(Rect2(body.position + Vector2(0, body.size.y * 0.25), Vector2(body.size.x, body.size.y * 0.5)), colour)
		draw_rect(Rect2(Vector2(w * 0.2, h * 0.14), Vector2(w * 0.6, h * 0.08)), Color("8e98a4"))
		draw_circle(Vector2(w * 0.5, h * 0.16), w * 0.09, colour)   # a drip of paint on the lid
		draw_rect(body, Color("5d6772"), false, 2.0)


## A torch's round patch of light on the wall, blended by adding (so overlaps mix like light).
class LightSpot:
	extends Control
	var colour := Color.WHITE
	var radius := 60.0

	func _init(c: Color, r: float) -> void:
		colour = c
		radius = r
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func _draw() -> void:
		draw_circle(size * 0.5, radius, colour)
