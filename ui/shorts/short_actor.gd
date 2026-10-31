class_name ShortActor
extends Control
## One actor of a Short on its stage (owner #94, spec §5.12b): words, a School picture (SchoolPicture, as the School
## draws it), a block's or a rocket part's icon (BlockIcons), a planet or moon in the Star Map's colours, a character
## (Professor Hoot, any animal of the game, a robot, an astronaut), an arrow or a line that draws itself on, a shape,
## a map of dots at their real latitude and longitude, or a number that counts. `apply(state)` puts it where
## ShortTimeline says (its middle at state.pos, turned and scaled round its middle); everything else is drawn here in
## UI draw calls (no textures but the game's own icons, nothing to license).
## Owner #96: the kinds are pluggable. What an actor shows is its kind's ShortDrawer's (ShortDrawers): the built-in kinds'
## drawer calls setup_builtin, draw_builtin and update_builtin below; a new kind (scene3d, video) brings its own.

const OUTLINE := Color(0.05, 0.06, 0.1, 0.85)
const INK := Color("1f2a4a")
const PAPER := Color("fdf6e3")

var data: Dictionary
var kind := ""
var draw_amount := 1.0
var value := 0.0
## Seconds into its scene (twinkles, flames and waves move with it: a seek shows the same frame).
var time := 0.0
## Its drawing changes with the time (a flame, the Sun's rays, a wave): the player redraws it every frame it shows.
var animated := false

## Its kind's drawer (ShortDrawers).
var drawer: ShortDrawer
## The drawing's scale on top of the timeline's (a School picture is made 480 wide and shown `w` wide).
var base_scale := 1.0

var _label: Label
var _anchor := Vector2.ZERO   # an arrow's or a line's middle (they are drawn in stage units)
var _colour := Color.WHITE


func _init(d: Dictionary) -> void:
	data = d
	kind = str(d.get("kind", ""))
	name = "Actor_" + kind
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_colour = ShortRules.colour(d.get("color"), _default_colour())
	value = float(d.get("value", d.get("from", 0.0))) if typeof(d.get("value", d.get("from", 0.0))) in [TYPE_INT, TYPE_FLOAT] else 0.0
	drawer = ShortDrawers.get_drawer(kind)
	drawer.setup(self)
	pivot_offset = _anchor if kind in ["arrow", "line"] else size * 0.5


## The built-in kinds' setup (BuiltinDrawer): their children and their box.
func setup_builtin() -> void:
	var d := data
	var side := float(d.get("size", 80.0))
	match kind:
		"words", "count":
			_label = Label.new()
			_label.text = str(d.get("text", "")) if kind == "words" else _count_text(value)
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			var fs := ShortStyle.letter_size(d.get("size", 32))
			_label.add_theme_font_size_override("font_size", fs)
			_label.add_theme_color_override("font_color", _colour)
			_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if d.has("box"):
				var box := StyleBoxFlat.new()
				box.bg_color = ShortRules.colour(d.box)
				box.set_corner_radius_all(fs / 2)
				box.content_margin_left = 16
				box.content_margin_right = 16
				box.content_margin_top = 6
				box.content_margin_bottom = 6
				box.border_color = box.bg_color.darkened(0.3)
				box.border_width_bottom = 5
				_label.add_theme_stylebox_override("normal", box)
			# The style guide: words read on their sticker (or on what they stand on, `on`), else on a dark outline.
			var behind: Variant = ShortRules.colour(d.box) if d.has("box") else (ShortRules.colour(d.on) if d.has("on") else null)
			if ShortStyle.needs_outline(_colour, behind):
				_label.add_theme_color_override("font_outline_color", OUTLINE)
				_label.add_theme_constant_override("outline_size", ShortStyle.outline_of(fs) if behind == null else maxi(3, fs / 8))
			else:
				_label.add_theme_constant_override("outline_size", 0)
			if d.has("width"):
				_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				_label.custom_minimum_size.x = float(d.width)
			add_child(_label)
			_label.minimum_size_changed.connect(_fit_label)
			_fit_label()
		"picture":
			var pic := SchoolPicture.new(d.get("picture", {}), Vector2(480, 280))
			add_child(pic)
			pic.size = Vector2(480, 280)
			size = Vector2(480, 280)
			base_scale = float(d.get("w", 320.0)) / 480.0
		"block", "part":
			var icon := TextureRect.new()
			icon.texture = BlockIcons.icon(ShortCheck.block_id(d.get(kind)))
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.size = Vector2(side, side)
			add_child(icon)
			size = Vector2(side, side)
		"character":
			var who := str(d.get("who", ""))
			size = Vector2(side, side)
			if who == "hoot":
				var t := SchoolUi.teacher(side)
				add_child(t)
				t.size = size
			elif AnimalRules.SPECIES.has(StringName(who)):
				var a := AnimalPortrait.new(StringName(who), side)
				add_child(a)
				a.size = size
		"arrow", "line":
			size = ShortRules.STAGE
			_anchor = ShortRules.anchor(d)
		"planet":
			var ring := bool(StarMap.body(StringName(str(d.get("body", "")))).get("ring", false))
			size = Vector2(side * (1.9 if ring else 1.0), side)
		"map":
			size = Vector2(float(d.get("w", 320.0)), float(d.get("h", 240.0)))
		"shape":
			size = Vector2(float(d.get("w", side)), float(d.get("h", side)))
			animated = str(d.get("shape", "")) in ["sun", "flame", "wave", "gas"]


## A words' or a count's box is its text's (known once the theme's font is: in the tree).
func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_READY:
		_fit_label()


func _fit_label() -> void:
	if _label == null:
		return
	var old_centre := position + pivot_offset
	_label.size = Vector2.ZERO
	size = _label.get_combined_minimum_size()
	_label.size = size
	pivot_offset = size * 0.5
	position = old_centre - pivot_offset


## Where the actor is drawn now, on the stage (its box turned, scaled and moved; an arrow's or a line's own points):
## the quality checks and the reel studio use it.
func stage_rect() -> Rect2:
	var box := Rect2(Vector2.ZERO, size)
	if kind in ["arrow", "line"]:
		var a := ShortRules.point(data.from)
		var b := ShortRules.point(data.to)
		var bend := float(data.get("bend", 0.0))
		var mid := (a + b) * 0.5 + (b - a).orthogonal().normalized() * bend * 0.5
		box = Rect2(a, Vector2.ZERO).expand(b).expand(mid).grow(float(data.get("width", 9.0)) * 0.5)
	return get_transform() * box


func _default_colour() -> Color:
	match kind:
		"arrow":
			return ShortRules.COLOURS.red
		"line":
			return ShortRules.COLOURS.white
		"shape":
			return ShortRules.COLOURS.yellow
	return Color.WHITE


## Puts the actor where ShortTimeline's state says.
func apply(s: Dictionary, t: float) -> void:
	var show := bool(s.visible) and float(s.alpha) > 0.004
	if visible != show:
		visible = show
	if not show:
		return
	var p: Vector2 = s.pos
	position = p - pivot_offset
	scale = Vector2.ONE * maxf(float(s.scale) * base_scale, 0.0001)
	rotation = float(s.rot)
	modulate.a = float(s.alpha)
	var d := float(s.draw)
	var v := float(s.value)
	if d != draw_amount or v != value or (animated and t != time):
		draw_amount = d
		value = v
		time = t
		drawer.update(self, s, t)
	time = t


## The built-in kinds' update (BuiltinDrawer): a count's number, words typed on, a drawing drawn again.
func update_builtin() -> void:
	if _label:
		if kind == "count":
			_label.text = _count_text(value)
		else:
			_label.visible_ratio = draw_amount
	else:
		queue_redraw()


## A count's words: its number (grouped in thousands, `decimals` after the point) between its prefix and suffix.
func _count_text(v: float) -> String:
	return str(data.get("prefix", "")) + number_words(v, clampi(int(data.get("decimals", 0)), 0, 3)) + str(data.get("suffix", ""))


static func number_words(v: float, decimals: int = 0) -> String:
	var fixed := ("%." + str(decimals) + "f") % absf(v)
	var parts := fixed.split(".")
	var digits := parts[0]
	var grouped := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			grouped += ","
		grouped += digits[i]
	var negative := v < 0.0 and fixed.to_float() != 0.0
	return ("−" if negative else "") + grouped + ("." + parts[1] if parts.size() > 1 else "")


# --- Drawing ---------------------------------------------------------------------------------------------------------

func _draw() -> void:
	if drawer:
		drawer.draw(self)


## The built-in kinds' drawing (BuiltinDrawer).
func draw_builtin() -> void:
	match kind:
		"arrow", "line":
			_draw_arrow()
		"planet":
			_draw_planet()
		"shape":
			_draw_shape(str(data.get("shape", "")))
		"map":
			_draw_map()
		"character":
			match str(data.get("who", "")):
				"robot":
					_draw_robot()
				"astronaut":
					_draw_astronaut()


func _draw_arrow() -> void:
	var a := ShortRules.point(data.from)
	var b := ShortRules.point(data.to)
	var bend := float(data.get("bend", 0.0))
	var w := float(data.get("width", 9.0))
	var mid := (a + b) * 0.5 + (b - a).orthogonal().normalized() * bend
	var pts := PackedVector2Array()
	var steps := 24
	var upto := int(ceilf(steps * draw_amount))
	for i in upto + 1:
		var t := minf(float(i) / steps, draw_amount)
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	if pts.size() >= 2:
		draw_polyline(pts, OUTLINE, w + 5.0, true)
		draw_polyline(pts, _colour, w, true)
		draw_circle(pts[0], w * 0.5, _colour)
	if kind == "arrow" and draw_amount > 0.82 and pts.size() >= 2:
		var head := clampf((draw_amount - 0.82) / 0.18, 0.0, 1.0)   # the head pops on as the line arrives
		var tip: Vector2 = pts[pts.size() - 1]
		var dir := (tip - pts[pts.size() - 2]).normalized()
		var h := w * 3.0 * ShortTimeline.ease_value("back", head)
		var tri := PackedVector2Array([tip + dir * h * 0.6, tip - dir * h * 0.7 + dir.orthogonal() * h * 0.75,
			tip - dir * h * 0.7 - dir.orthogonal() * h * 0.75])
		draw_colored_polygon(tri, _colour)
		draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), OUTLINE, 3.0, true)


func _draw_planet() -> void:
	var b := StarMap.body(StringName(str(data.get("body", ""))))
	var r := size.y * 0.5
	var c := size * 0.5
	var col: Color = b.get("color", Color.WHITE)
	var col2: Color = b.get("color2", col)
	var ring := bool(b.get("ring", false))
	if str(b.get("kind", "")) == "star":
		for i in 4:
			draw_circle(c, r * (1.5 - i * 0.12), Color(col2, 0.1 + 0.06 * i))
	if ring:
		_planet_ring(c, r, col2, true)
	draw_circle(c, r, col)
	draw_circle(c + Vector2(-r * 0.25, r * 0.2), r * 0.45, Color(col2, 0.55))
	if str(b.get("id", "")) == "jupiter" or str(b.get("id", "")) == "saturn":
		for k in 3:
			var y := c.y + r * (-0.45 + k * 0.4)
			var half := sqrt(maxf(r * r - (y - c.y) * (y - c.y), 0.0))
			draw_line(Vector2(c.x - half, y), Vector2(c.x + half, y), Color(col2, 0.5), r * 0.12)
	draw_circle(c + Vector2(r * 0.3, -r * 0.35), r * 0.28, Color(1, 1, 1, 0.2))
	if ring:
		_planet_ring(c, r, col2, false)


func _planet_ring(c: Vector2, r: float, col: Color, back: bool) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := (PI if back else 0.0) + PI * i / 32.0
		pts.append(c + Vector2(cos(a) * r * 1.8, sin(a) * r * 0.45))
	draw_polyline(pts, Color(col.lightened(0.2), 0.9), maxf(3.0, r * 0.2), true)


func _draw_shape(shape: String) -> void:
	var s := size
	var c := s * 0.5
	var r := minf(s.x, s.y) * 0.5
	var col := _colour
	match shape:
		"circle":
			draw_circle(c, r, col)
			draw_arc(c, r - 2.0, 0.0, TAU, 48, col.darkened(0.25), 4.0, true)
			draw_circle(c + Vector2(r * 0.3, -r * 0.35), r * 0.22, Color(1, 1, 1, 0.25))
		"ring":   # an orbit's path: its radius is half its size, drawn round from the top by `draw`
			var w := float(data.get("width", 3.0))
			draw_arc(c, r - w * 0.5, -PI / 2.0, -PI / 2.0 + TAU * draw_amount, 96, col, w, true)
		"rect":
			var box := StyleBoxFlat.new()
			box.bg_color = col
			box.set_corner_radius_all(int(minf(s.x, s.y) * 0.12))
			box.border_color = col.darkened(0.3)
			box.border_width_bottom = 6
			draw_style_box(box, Rect2(Vector2.ZERO, s))
		"star":
			var pts := SchoolUi.star_points(c, r)
			draw_colored_polygon(pts, col)
			pts.append(pts[0])
			draw_polyline(pts, col.darkened(0.35), 3.0, true)
		"drop":
			var pts := PackedVector2Array([c + Vector2(0, -r)])
			for i in 21:
				var a := -0.15 * PI + PI * 1.3 * i / 20.0
				pts.append(c + Vector2(cos(a), sin(a)) * r * 0.62 + Vector2(0, r * 0.3))
			draw_colored_polygon(pts, col)
			draw_circle(c + Vector2(-r * 0.2, r * 0.2), r * 0.13, Color(1, 1, 1, 0.5))
		"cloud":
			var white := Color(col, 1.0) if data.has("color") else Color.WHITE
			for p: Vector3 in [Vector3(-0.45, 0.15, 0.32), Vector3(0.0, -0.1, 0.45), Vector3(0.45, 0.12, 0.34),
					Vector3(0.1, 0.25, 0.35), Vector3(-0.2, 0.28, 0.3)]:
				draw_circle(c + Vector2(p.x, p.y + 0.06) * s.x, p.z * s.x * 0.5, Color(0.55, 0.62, 0.75, 0.35))
			for p: Vector3 in [Vector3(-0.45, 0.15, 0.32), Vector3(0.0, -0.1, 0.45), Vector3(0.45, 0.12, 0.34),
					Vector3(0.1, 0.25, 0.35), Vector3(-0.2, 0.28, 0.3)]:
				draw_circle(c + Vector2(p.x, p.y) * s.x, p.z * s.x * 0.5, white)
		"sun":
			var turn := time * 0.4
			for i in 12:
				var a := turn + TAU * i / 12.0
				draw_line(c + Vector2(cos(a), sin(a)) * r * 0.62, c + Vector2(cos(a), sin(a)) * r * 0.98,
					Color("ffb21c"), r * 0.1, true)
			draw_circle(c, r * 0.55, Color("ffd23a"))
			draw_circle(c, r * 0.42, Color("ffe57a"))
		"leaf":
			var pts := PackedVector2Array()
			for i in 25:
				var t := float(i) / 24.0
				pts.append(c + Vector2(-r + 2.0 * r * t, -sin(t * PI) * r * 0.55))
			for i in 25:
				var t := 1.0 - float(i) / 24.0
				pts.append(c + Vector2(-r + 2.0 * r * t, sin(t * PI) * r * 0.55))
			draw_colored_polygon(pts, col if data.has("color") else ShortRules.COLOURS.leaf)
			draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), Color(0.15, 0.4, 0.15), 3.0, true)
		"flame":
			var flick := sin(time * 11.0) * 0.06 + sin(time * 7.3) * 0.04
			_flame(c + Vector2(0, r * 0.2), r * (1.0 + flick), Color("ff6a1c"))
			_flame(c + Vector2(0, r * 0.35), r * (0.7 - flick), Color("ffc93a"))
			_flame(c + Vector2(0, r * 0.5), r * 0.38, Color("fff3b0"))
		"bolt":
			var pts := PackedVector2Array([c + Vector2(0.15, -1) * r, c + Vector2(-0.45, 0.1) * r, c + Vector2(0.0, 0.1) * r,
				c + Vector2(-0.2, 1) * r, c + Vector2(0.5, -0.2) * r, c + Vector2(0.05, -0.2) * r])
			draw_colored_polygon(pts, col)
			pts.append(pts[0])
			draw_polyline(pts, col.darkened(0.4), 3.0, true)
		"pizza":
			_draw_pizza(c, r)
		"moon_phase":
			_draw_moon(c, r)
		"bulb":
			var glow := clampf(value, 0.0, 1.0)
			if glow > 0.0:
				for i in 4:
					draw_circle(c + Vector2(0, -r * 0.2), r * (0.95 - i * 0.12), Color(1.0, 0.9, 0.3, 0.12 * glow))
			draw_circle(c + Vector2(0, -r * 0.2), r * 0.55, Color(1.0, 0.95, 0.55).lerp(Color(0.85, 0.88, 0.92), 1.0 - glow))
			draw_arc(c + Vector2(0, -r * 0.2), r * 0.55, 0.0, TAU, 40, INK, 3.0, true)
			draw_rect(Rect2(c + Vector2(-r * 0.25, r * 0.3), Vector2(r * 0.5, r * 0.45)), Color("9a948c"))
			for k in 3:
				draw_line(c + Vector2(-r * 0.25, r * (0.4 + k * 0.12)), c + Vector2(r * 0.25, r * (0.4 + k * 0.12)), INK, 2.0)
			draw_polyline(PackedVector2Array([c + Vector2(-r * 0.12, r * 0.3), c + Vector2(-r * 0.08, -r * 0.2),
				c + Vector2(r * 0.08, -r * 0.2), c + Vector2(r * 0.12, r * 0.3)]), Color(0.5, 0.4, 0.2), 2.0, true)
		"battery":
			var body := Rect2(c + Vector2(-r * 0.9, -r * 0.42), Vector2(r * 1.7, r * 0.84))
			draw_rect(body, Color("2b2f3a"))
			draw_rect(Rect2(body.position, Vector2(body.size.x * 0.35, body.size.y)), Color("c9772b"))
			draw_rect(Rect2(c + Vector2(r * 0.8, -r * 0.18), Vector2(r * 0.18, r * 0.36)), Color("9a948c"))
			draw_rect(body, INK, false, 3.0)
			draw_line(c + Vector2(r * 0.35, 0), c + Vector2(r * 0.65, 0), Color.WHITE, 4.0)
			draw_line(c + Vector2(r * 0.5, -r * 0.15), c + Vector2(r * 0.5, r * 0.15), Color.WHITE, 4.0)
		"spark":
			for i in 10:
				var a := TAU * i / 10.0 + 0.3
				var from := c + Vector2(cos(a), sin(a)) * r * (0.35 + 0.4 * draw_amount)
				var to := c + Vector2(cos(a), sin(a)) * r * (0.55 + 0.45 * draw_amount)
				draw_line(from, to, Color(col, 1.0 - draw_amount * 0.4), r * 0.07, true)
		"ice":
			var pts := PackedVector2Array([c + Vector2(-0.8, -0.3) * r, c + Vector2(-0.2, -0.8) * r, c + Vector2(0.7, -0.5) * r,
				c + Vector2(0.85, 0.35) * r, c + Vector2(0.1, 0.85) * r, c + Vector2(-0.75, 0.5) * r])
			draw_colored_polygon(pts, Color("bfe9ff"))
			draw_colored_polygon(PackedVector2Array([pts[0], pts[1], pts[2], c]), Color("e6f7ff"))
			pts.append(pts[0])
			draw_polyline(pts, Color("5aa9d6"), 3.0, true)
		"crater":
			draw_circle(c, r, Color("9a9ca6"))
			draw_set_transform(c, 0.0, Vector2(1.0, 0.55))
			draw_circle(Vector2.ZERO, r * 0.8, Color("6e707a"))
			draw_circle(Vector2(0, r * 0.1), r * 0.62, Color("4d4f58"))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"tree":
			draw_rect(Rect2(c + Vector2(-r * 0.12, r * 0.1), Vector2(r * 0.24, r * 0.9)), Color("7a4a24"))
			draw_circle(c + Vector2(0, -r * 0.25), r * 0.65, Color("2f8a3e"))
			draw_circle(c + Vector2(-r * 0.3, -r * 0.05), r * 0.4, Color("3aa04a"))
			draw_circle(c + Vector2(r * 0.3, -r * 0.1), r * 0.42, Color("3aa04a"))
		"pyramid":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r, r * 0.7), c + Vector2(0.15 * r, -r * 0.8), c + Vector2(0, r * 0.95)]),
				Color("e0b872"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0.15 * r, -r * 0.8), c + Vector2(r, r * 0.6), c + Vector2(0, r * 0.95)]),
				Color("b8894a"))
			for k in 4:
				var y := -r * 0.8 + (k + 1) * r * 0.35
				var t := (y + r * 0.8) / (r * 1.75)
				draw_line(c + Vector2(lerpf(0.15 * r, -r, t), y), c + Vector2(lerpf(0.15 * r, 0.0, t), y + t * r * 0.1),
					Color(0.5, 0.35, 0.15, 0.35), 2.0)
		"mountain":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r, r), c + Vector2(0, -r), c + Vector2(r, r)]), Color("8a8f98"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.3, -r * 0.4), c + Vector2(0, -r), c + Vector2(r * 0.3, -r * 0.4),
				c + Vector2(0, -r * 0.25)]), Color.WHITE)
		"heart":
			var pts := PackedVector2Array()
			for i in 41:
				var t := TAU * i / 40.0
				pts.append(c + Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * r / 17.0)
			draw_colored_polygon(pts, col if data.has("color") else ShortRules.COLOURS.red)
		"thermometer":
			var tube := Rect2(c + Vector2(-r * 0.14, -r), Vector2(r * 0.28, r * 1.5))
			draw_rect(tube, Color.WHITE)
			var fill := clampf(value, 0.0, 1.0)
			draw_rect(Rect2(Vector2(tube.position.x, tube.end.y - tube.size.y * fill), Vector2(tube.size.x, tube.size.y * fill)), Color("d9463b"))
			draw_rect(tube, INK, false, 3.0)
			draw_circle(c + Vector2(0, r * 0.68), r * 0.3, Color("d9463b"))
			draw_arc(c + Vector2(0, r * 0.68), r * 0.3, 0.0, TAU, 32, INK, 3.0, true)
		"cube":
			var top := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.87, -r * 0.5), c, c + Vector2(-r * 0.87, -r * 0.5)])
			var left := PackedVector2Array([c + Vector2(-r * 0.87, -r * 0.5), c, c + Vector2(0, r), c + Vector2(-r * 0.87, r * 0.5)])
			var right := PackedVector2Array([c, c + Vector2(r * 0.87, -r * 0.5), c + Vector2(r * 0.87, r * 0.5), c + Vector2(0, r)])
			draw_colored_polygon(top, col.lightened(0.25))
			draw_colored_polygon(left, col)
			draw_colored_polygon(right, col.darkened(0.2))
		"plus", "equals":
			var w := r * 0.28
			if shape == "plus":
				draw_rect(Rect2(c + Vector2(-r * 0.8, -w * 0.5), Vector2(r * 1.6, w)), col)
				draw_rect(Rect2(c + Vector2(-w * 0.5, -r * 0.8), Vector2(w, r * 1.6)), col)
			else:
				draw_rect(Rect2(c + Vector2(-r * 0.8, -r * 0.45), Vector2(r * 1.6, w)), col)
				draw_rect(Rect2(c + Vector2(-r * 0.8, r * 0.45 - w), Vector2(r * 1.6, w)), col)
		"wave":
			var pts := PackedVector2Array()
			for i in 33:
				var x := s.x * i / 32.0
				pts.append(Vector2(x, c.y + sin(x / s.x * TAU * 2.0 + time * 2.5) * s.y * 0.2))
			draw_polyline(pts, col if data.has("color") else ShortRules.COLOURS.sky, maxf(4.0, s.y * 0.12), true)
		"gas":
			for i in 7:
				var ph := i * 1.7
				var p := c + Vector2(sin(time * 0.9 + ph) * r * 0.6, cos(time * 0.7 + ph * 1.3) * r * 0.6)
				draw_circle(p, r * 0.16, Color(col, 0.85))
				draw_circle(p + Vector2(r * 0.12, 0), r * 0.1, Color(col.lightened(0.3), 0.85))


func _flame(base: Vector2, h: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 21:
		var a := PI * i / 20.0
		pts.append(base + Vector2(cos(a) * h * 0.45, sin(a) * h * 0.4))
	pts.append(base + Vector2(0, -h))
	draw_colored_polygon(pts, col)


## A pizza cut into `slices`: `value` of them lifted away and drawn in the topic's colour (a fraction).
func _draw_pizza(c: Vector2, r: float) -> void:
	var n := clampi(int(data.get("slices", 8)), 1, 16)
	var shaded := clampf(value, 0.0, float(n))
	draw_circle(c, r, Color("c98a3b"))
	draw_circle(c, r * 0.88, Color("f4c542"))
	for i in n:
		var a0 := -PI / 2.0 + TAU * i / n
		var a1 := -PI / 2.0 + TAU * (i + 1) / n
		var part := clampf(shaded - i, 0.0, 1.0)
		if part > 0.0:
			var mid := (a0 + a1) * 0.5
			var out := Vector2(cos(mid), sin(mid)) * r * 0.16 * part
			var pts := PackedVector2Array([c + out])
			for k in 9:
				var a := lerpf(a0, a1, k / 8.0)
				pts.append(c + out + Vector2(cos(a), sin(a)) * r * 0.88)
			draw_colored_polygon(pts, Color(_colour, 0.9))
			pts.append(pts[0])
			draw_polyline(pts, Color(1, 1, 1, part), maxf(2.0, r * 0.035), true)
		for k in 2:   # pepperoni
			var a := lerpf(a0, a1, 0.35 + 0.3 * k)
			draw_circle(c + Vector2(cos(a), sin(a)) * r * (0.45 + 0.2 * k), r * 0.08, Color("c0392b"))
	for i in n:
		var a := -PI / 2.0 + TAU * i / n
		draw_line(c, c + Vector2(cos(a), sin(a)) * r, Color("8a5a24"), 3.0, true)


## The Moon: `value` 0 new, 0.25 first quarter (lit on the right, as seen from the north), 0.5 full, 0.75 last quarter.
func _draw_moon(c: Vector2, r: float) -> void:
	draw_circle(c, r, Color("2a2e3d"))
	var p := fposmod(value, 1.0)
	var t := cos(TAU * p)
	var side := 1.0 if p <= 0.5 else -1.0
	var pts := PackedVector2Array()
	for i in 33:   # the lit limb, top to bottom
		var a := -PI / 2.0 + PI * i / 32.0
		pts.append(c + Vector2(side * cos(a) * r, sin(a) * r))
	for i in 33:   # back up along the terminator
		var a := PI / 2.0 - PI * i / 32.0
		pts.append(c + Vector2(side * t * cos(a) * r, sin(a) * r))
	if absf(t) < 0.999 or p > 0.25 and p < 0.75:
		draw_colored_polygon(pts, Color("e8e6dc"))
	for k: Vector3 in [Vector3(-0.3, -0.2, 0.16), Vector3(0.25, 0.3, 0.12), Vector3(0.1, -0.45, 0.09)]:
		draw_circle(c + Vector2(k.x, k.y) * r, k.z * r, Color(0.3, 0.3, 0.35, 0.18))
	draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 2.0, true)


func _draw_map() -> void:
	var s := size
	var lat := ShortRules.point(data.lat)
	var lon := ShortRules.point(data.long)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("f3e6c4")
	box.set_corner_radius_all(14)
	box.border_color = Color("7a4a24")
	box.set_border_width_all(4)
	draw_style_box(box, Rect2(Vector2.ZERO, s))
	var at := func(la: float, lo: float) -> Vector2:
		return Vector2((lo - lon.x) / (lon.y - lon.x) * s.x, (lat.y - la) / (lat.y - lat.x) * s.y)
	var seas: Array = data.get("seas", [])
	if data.has("sea"):
		seas = [data.sea] + seas
	var shores := [[seas, Color("7fc4ea"), Color("4f97c6")], [data.get("lands", []), Color("f3e6c4"), Color("4f97c6")]]
	for shore: Array in shores:   # the seas, then islands over them
		for sea: Array in shore[0]:
			if sea.size() >= 3:
				var pts := PackedVector2Array()
				for corner: Array in sea:
					pts.append(at.call(float(corner[0]), float(corner[1])))
				draw_colored_polygon(pts, shore[1])
				pts.append(pts[0])
				draw_polyline(pts, shore[2], 2.0, true)
	var step := 5.0
	var font := get_theme_default_font()
	var g := ceilf(lon.x / step) * step
	while g <= lon.y:
		var x: float = at.call(lat.x, g).x
		draw_line(Vector2(x, 0), Vector2(x, s.y), Color(0.48, 0.29, 0.14, 0.25), 1.5)
		g += step
	g = ceilf(lat.x / step) * step
	while g <= lat.y:
		var y: float = at.call(g, lon.x).y
		draw_line(Vector2(0, y), Vector2(s.x, y), Color(0.48, 0.29, 0.14, 0.25), 1.5)
		g += step
	var points: Array = data.get("points", [])
	var shown := draw_amount * points.size()
	for i in points.size():
		var grow := clampf(shown - i, 0.0, 1.0)
		if grow <= 0.0:
			continue
		var pt: Dictionary = points[i]
		var p: Vector2 = at.call(float(pt.lat), float(pt.long))
		var k := ShortTimeline.ease_value("back", grow)
		draw_circle(p, 9.0 * k, Color("d9463b"))
		draw_arc(p, 9.0 * k, 0.0, TAU, 20, Color.WHITE, 2.5, true)
		var label := str(pt.get("label", ""))
		if label != "" and grow >= 1.0:
			var fs := 17
			var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var off := ShortRules.point(pt.get("offset", [0, -16]))
			var pos := p + off - Vector2(w * 0.5, 0)
			pos.x = clampf(pos.x, 4.0, s.x - w - 4.0)
			draw_string_outline(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(1, 1, 1, 0.9))
			draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


func _draw_robot() -> void:
	var u := size.x
	var body := Color("5ad1c7")
	var dark := Color("2c6f78")
	draw_line(Vector2(u * 0.5, u * 0.18), Vector2(u * 0.5, u * 0.06), dark, u * 0.03)
	draw_circle(Vector2(u * 0.5, u * 0.05), u * 0.045, Color("ffd23f"))
	var head := StyleBoxFlat.new()
	head.bg_color = body
	head.set_corner_radius_all(int(u * 0.08))
	head.border_color = dark
	head.set_border_width_all(maxi(2, int(u * 0.02)))
	draw_style_box(head, Rect2(Vector2(u * 0.25, u * 0.18), Vector2(u * 0.5, u * 0.32)))
	draw_circle(Vector2(u * 0.4, u * 0.33), u * 0.06, Color.WHITE)
	draw_circle(Vector2(u * 0.6, u * 0.33), u * 0.06, Color.WHITE)
	draw_circle(Vector2(u * 0.41, u * 0.34), u * 0.03, INK)
	draw_circle(Vector2(u * 0.61, u * 0.34), u * 0.03, INK)
	draw_arc(Vector2(u * 0.5, u * 0.4), u * 0.07, 0.3, PI - 0.3, 12, dark, u * 0.02, true)
	var chest := head.duplicate() as StyleBoxFlat
	draw_style_box(chest, Rect2(Vector2(u * 0.3, u * 0.53), Vector2(u * 0.4, u * 0.3)))
	draw_circle(Vector2(u * 0.5, u * 0.66), u * 0.05, Color("ffd23f"))
	draw_line(Vector2(u * 0.3, u * 0.6), Vector2(u * 0.16, u * 0.74), dark, u * 0.05, true)
	draw_line(Vector2(u * 0.7, u * 0.6), Vector2(u * 0.84, u * 0.74), dark, u * 0.05, true)
	draw_line(Vector2(u * 0.4, u * 0.83), Vector2(u * 0.4, u * 0.97), dark, u * 0.06)
	draw_line(Vector2(u * 0.6, u * 0.83), Vector2(u * 0.6, u * 0.97), dark, u * 0.06)


func _draw_astronaut() -> void:
	var u := size.x
	var suit := Color("f4f4f0")
	var edge := Color("9aa0ad")
	draw_rect(Rect2(Vector2(u * 0.22, u * 0.4), Vector2(u * 0.12, u * 0.36)), Color("c9ccd6"))   # the backpack
	var torso := StyleBoxFlat.new()
	torso.bg_color = suit
	torso.set_corner_radius_all(int(u * 0.1))
	torso.border_color = edge
	torso.set_border_width_all(maxi(2, int(u * 0.02)))
	draw_style_box(torso, Rect2(Vector2(u * 0.3, u * 0.42), Vector2(u * 0.42, u * 0.36)))
	draw_line(Vector2(u * 0.4, u * 0.76), Vector2(u * 0.4, u * 0.96), suit, u * 0.1)
	draw_line(Vector2(u * 0.6, u * 0.76), Vector2(u * 0.6, u * 0.96), suit, u * 0.1)
	draw_line(Vector2(u * 0.7, u * 0.5), Vector2(u * 0.84, u * 0.36), suit, u * 0.09, true)   # a wave
	draw_circle(Vector2(u * 0.52, u * 0.26), u * 0.2, suit)
	draw_arc(Vector2(u * 0.52, u * 0.26), u * 0.2, 0.0, TAU, 32, edge, u * 0.02, true)
	draw_set_transform(Vector2(u * 0.54, u * 0.27), 0.0, Vector2(1.0, 0.72))
	draw_circle(Vector2.ZERO, u * 0.14, Color("2a4fa8"))
	draw_circle(Vector2(u * 0.05, -u * 0.05), u * 0.04, Color(1, 1, 1, 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(Vector2(u * 0.42, u * 0.5), Vector2(u * 0.16, u * 0.08)), Color("d9463b"))
