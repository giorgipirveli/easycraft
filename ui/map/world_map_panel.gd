class_name WorldMapPanel
extends Control
## The world map (owner feedback #45b, spec §14.18), from the HUD's MORE panel (MAP): a picture page of the places
## found in this world, each a round badge with its picture and its name, round the child's arrow and the home
## marker, north (-z) up, scaled so every one fits. Only what entries_source gives is drawn (the PlacesDirector's
## found places, and other tasks' marks): a place nobody found is never on it. A tap on a place sets the find arrow
## towards it (point_to: the /find arrow) and closes the map. While open it takes every new touch (the HUD's buttons
## and the world never hear them; its own buttons get the touch's click); pausing closes it.

signal closed

const CARD := Vector2(1000, 600)
const MAP_TOP := 104.0
const MAP_PAD := 24.0
const BADGE := 84.0
const MIN_SPAN := 48.0            # blocks from the middle to the map's edge, at the closest
const PAPER := Color("f3e2b8")
const PAPER_DARK := Color("d8c08a")
const INK := Color("5a3d1e")
## The kinds with a picture of their own (anything else gets a star).
const PICTURES: Array[StringName] = [&"windmill", &"village", &"town", &"tower", &"lighthouse", &"ship", &"castle",
	&"launch"]   # owner #98: the Launch Site (a rocket on its pad)

## () -> Array of {id, kind, name, pos: Vector3}: the places to show.
var entries_source: Callable = func() -> Array: return []
## () -> Vector3: where the child stands (the map's middle).
var player_position: Callable = func() -> Vector3: return Vector3.ZERO
## () -> float: which way the child looks (the arrow).
var player_yaw: Callable = func() -> float: return 0.0
## () -> Vector3: home (the bed or the world spawn), or INF.
var home_position: Callable = func() -> Vector3: return Vector3.INF
## (label, pos) -> void: point the find arrow there.
var point_to: Callable

var card := Panel.new()
var map_area := Control.new()
var close_button := Button.new()
var empty_label := Label.new()
var badges: Array[Button] = []

var _entries: Array = []
var _middle := Vector3.ZERO
var _span := MIN_SPAN


## The MORE panel's button for the map (the sandbox connects it to open).
static func more_button() -> TouchButton:
	var b := TouchButton.new()
	b.name = "Map"
	b.text = "MAP"
	b.symbol = &"map"
	return b


## True for the kinds with a picture of their own (any other kind still shows a star).
static func knows_picture(kind: StringName) -> bool:
	return PICTURES.has(kind) or ProspectPictures.knows(kind)   # spec §26: the deposits found


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	card.add_theme_stylebox_override("panel", UiKit.box(PAPER, 28, 0))
	card.anchor_left = 0.5
	card.anchor_right = 0.5
	card.anchor_top = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -CARD.x * 0.5
	card.offset_right = CARD.x * 0.5
	card.offset_top = -CARD.y * 0.5
	card.offset_bottom = CARD.y * 0.5
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(card)
	var title := Label.new()
	title.text = "MY MAP"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", INK)
	title.position = Vector2(36, 20)
	card.add_child(title)
	close_button.text = "CLOSE"
	close_button.add_theme_font_size_override("font_size", 30)
	close_button.add_theme_stylebox_override("normal", UiKit.box(INK, 18, 10))
	close_button.add_theme_stylebox_override("hover", UiKit.box(INK.lightened(0.15), 18, 10))
	close_button.add_theme_stylebox_override("pressed", UiKit.box(INK.darkened(0.2), 18, 10))
	close_button.position = Vector2(CARD.x - 200, 16)
	close_button.size = Vector2(176, 76)
	close_button.custom_minimum_size = Vector2(176, 76)
	close_button.pressed.connect(close)
	card.add_child(close_button)
	map_area.position = Vector2(MAP_PAD, MAP_TOP)
	map_area.size = Vector2(CARD.x - 2 * MAP_PAD, CARD.y - MAP_TOP - MAP_PAD)
	map_area.clip_contents = true
	map_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_area.draw.connect(_draw_map)
	card.add_child(map_area)
	empty_label.text = "Go exploring!\nPlaces you find show up here."
	empty_label.add_theme_font_size_override("font_size", 34)
	empty_label.add_theme_color_override("font_color", INK)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_area.add_child(empty_label)


func is_open() -> bool:
	return visible


func open() -> void:
	_entries = entries_source.call() if entries_source.is_valid() else []
	visible = true
	UiMotion.pop_in(self)   # owner #94: every panel pops in the same way
	_layout()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## The map's controls for the HUD's look area (a touch on the map never builds).
func blockers() -> Array[Control]:
	return [self]


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		close()


## Every new finger is the map's while it shows (its buttons still get the touch's click).
func _input(event: InputEvent) -> void:
	if visible and event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		get_viewport().set_input_as_handled()


func choose(i: int) -> void:
	if i < 0 or i >= _entries.size():
		return
	var e: Dictionary = _entries[i]
	if point_to.is_valid():
		point_to.call(str(e.get("name", "")), e.get("pos", Vector3.ZERO))
	close()


# --- Layout and drawing ---

func _layout() -> void:
	for b in badges:
		b.free()
	badges.clear()
	var p: Variant = player_position.call() if player_position.is_valid() else Vector3.ZERO
	_middle = p if p is Vector3 and (p as Vector3).is_finite() else Vector3.ZERO
	var span := MIN_SPAN
	var home: Variant = home_position.call() if home_position.is_valid() else Vector3.INF
	var points: Array[Vector3] = []
	for e: Dictionary in _entries:
		points.append(e.get("pos", Vector3.ZERO))
	if home is Vector3 and (home as Vector3).is_finite():
		points.append(home)
	for q in points:
		span = maxf(span, Vector2(q.x - _middle.x, q.z - _middle.z).length() * 1.05)
	_span = span
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var b := _Badge.new()
		b.kind = StringName(e.get("kind", &""))
		b.set_meta(&"kind", b.kind)
		b.tooltip_text = str(e.get("name", ""))
		b.custom_minimum_size = Vector2(BADGE, BADGE)
		b.size = Vector2(BADGE, BADGE)
		b.position = _badge_spot(_to_map(e.get("pos", Vector3.ZERO)))
		var label := Label.new()
		label.text = b.tooltip_text
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", INK)
		label.add_theme_color_override("font_outline_color", PAPER)
		label.add_theme_constant_override("outline_size", 6)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-50, BADGE - 4)
		label.size = Vector2(BADGE + 100, 24)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(label)
		var index := i
		b.pressed.connect(func() -> void: choose(index))
		map_area.add_child(b)
		badges.append(b)
	_spread()
	empty_label.visible = _entries.is_empty()
	map_area.queue_redraw()


func _badge_spot(at: Vector2) -> Vector2:
	return (at - Vector2(BADGE, BADGE) * 0.5).clamp(Vector2(2, 2), map_area.size - Vector2(BADGE + 2, BADGE + 24))


## Badges that would cover each other (or each other's names: they are wider than the badges) push apart a little, a
## few rounds, so every picture and name can be read and tapped.
func _spread() -> void:
	var gap := BADGE + 12.0
	var wide := 1.9                    # a name is about twice as wide as its badge
	for round in 16:
		var moved := false
		for i in badges.size():
			for j in range(i + 1, badges.size()):
				var d := badges[j].position - badges[i].position
				var e := Vector2(d.x / wide, d.y)
				var dist := e.length()
				if dist >= gap:
					continue
				var away := e / dist if dist > 0.01 else Vector2(0, 1).rotated(j * 1.7)
				var push := Vector2(away.x * wide, away.y) * (gap - dist) * 0.5
				badges[i].position = _badge_spot(badges[i].position + Vector2(BADGE, BADGE) * 0.5 - push)
				badges[j].position = _badge_spot(badges[j].position + Vector2(BADGE, BADGE) * 0.5 + push)
				moved = true
		if not moved:
			return


## A world spot's point on the map (north, -z, up): nearer places are spread out more than far ones (the distance's
## square root), so the places round the child never crowd while the farthest still fits.
func _to_map(pos: Vector3) -> Vector2:
	var d := Vector2(pos.x - _middle.x, pos.z - _middle.z)
	var half := map_area.size * 0.5 - Vector2(BADGE * 0.5 + 4.0, BADGE * 0.5 + 26.0)
	if d.length() < 0.001:
		return map_area.size * 0.5
	var reach := sqrt(minf(d.length() / _span, 1.0))
	var dir := d.normalized()
	return map_area.size * 0.5 + Vector2(dir.x * half.x, dir.y * half.y) * reach


func _draw_map() -> void:
	var r := Rect2(Vector2.ZERO, map_area.size)
	map_area.draw_rect(r, PAPER_DARK.lerp(PAPER, 0.55))
	for i in range(1, 6):   # a faint grid
		var x := r.size.x * i / 6.0
		var y := r.size.y * i / 6.0
		map_area.draw_line(Vector2(x, 0), Vector2(x, r.size.y), Color(INK, 0.08), 2.0)
		map_area.draw_line(Vector2(0, y), Vector2(r.size.x, y), Color(INK, 0.08), 2.0)
	# the compass: N at the top right
	var c := Vector2(r.size.x - 56, 56)
	map_area.draw_circle(c, 34, Color(PAPER, 0.9))
	map_area.draw_arc(c, 34, 0, TAU, 32, INK, 3.0, true)
	map_area.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -28), c + Vector2(9, 0), c + Vector2(-9, 0)]), Color("c0392b"))
	map_area.draw_colored_polygon(PackedVector2Array([c + Vector2(0, 28), c + Vector2(9, 0), c + Vector2(-9, 0)]), INK)
	map_area.draw_string(get_theme_default_font(), c + Vector2(-9, -38), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
	var home: Variant = home_position.call() if home_position.is_valid() else Vector3.INF
	if home is Vector3 and (home as Vector3).is_finite():
		var h := _to_map(home)
		HudIcons.draw(map_area, &"home", Rect2(h - Vector2(22, 22), Vector2(44, 44)), Color("2f7d32"))
	# the child: an arrow the way they look
	var me := map_area.size * 0.5
	var yaw: float = player_yaw.call() if player_yaw.is_valid() else 0.0
	var fwd := Vector2(-sin(yaw), -cos(yaw))
	var side := Vector2(-fwd.y, fwd.x)
	map_area.draw_circle(me, 22, Color(1, 1, 1, 0.85))
	map_area.draw_colored_polygon(PackedVector2Array([me + fwd * 18, me - fwd * 12 + side * 12, me - fwd * 5, me - fwd * 12 - side * 12]),
		Color("1f6fd1"))


## A place's picture in the square r (drawn in code, like HudIcons).
static func draw_picture(ci: CanvasItem, kind: StringName, r: Rect2) -> void:
	var at := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	var box := func(x0: float, y0: float, x1: float, y1: float, col: Color) -> void:
		ci.draw_rect(Rect2(at.call(x0, y0), (at.call(x1, y1) as Vector2) - at.call(x0, y0)), col)
	var tri := func(pts: Array, col: Color) -> void:
		var poly := PackedVector2Array()
		for i in range(0, pts.size(), 2):
			poly.append(at.call(pts[i], pts[i + 1]))
		ci.draw_colored_polygon(poly, col)
	match kind:
		&"windmill":
			box.call(0.38, 0.4, 0.62, 0.92, Color("f2eee4"))
			tri.call([0.34, 0.42, 0.66, 0.42, 0.5, 0.26], Color("c4492f"))
			for a in 4:
				var ang := PI * 0.25 + a * PI * 0.5
				var tip: Vector2 = at.call(0.5, 0.36) + Vector2(cos(ang), sin(ang)) * r.size.x * 0.36
				ci.draw_line(at.call(0.5, 0.36), tip, Color("8a5a36"), r.size.x * 0.08)
		&"village", &"town":
			var houses: Array = [[0.22, 0.46, 0.56]] if kind == &"village" else [[0.06, 0.52, 0.42], [0.52, 0.44, 0.42]]
			for h: Array in houses:
				var x: float = h[0]
				var y: float = h[1]
				var w: float = h[2]
				box.call(x, y, x + w, 0.9, Color("f2eee4"))
				tri.call([x - 0.06, y, x + w + 0.06, y, x + w * 0.5, y - 0.3], Color("c4492f"))
				box.call(x + w * 0.4, 0.66, x + w * 0.6, 0.9, Color("8a5a36"))
		&"tower":
			box.call(0.34, 0.24, 0.66, 0.92, Color("8c8c8c"))
			for x: float in [0.34, 0.46, 0.58]:
				box.call(x, 0.14, x + 0.08, 0.24, Color("8c8c8c"))
			box.call(0.64, 0.02, 0.68, 0.16, Color("6e4527"))
			tri.call([0.68, 0.02, 0.86, 0.07, 0.68, 0.12], Color("d64545"))
		&"lighthouse":
			tri.call([0.36, 0.92, 0.64, 0.92, 0.58, 0.3, 0.42, 0.3], Color("f2eee4"))
			box.call(0.38, 0.72, 0.62, 0.8, Color("d64545"))
			box.call(0.41, 0.48, 0.59, 0.56, Color("d64545"))
			box.call(0.4, 0.16, 0.6, 0.3, Color("ffd23f"))
			tri.call([0.36, 0.16, 0.64, 0.16, 0.5, 0.04], Color("d64545"))
		&"ship":
			tri.call([0.1, 0.62, 0.9, 0.62, 0.76, 0.86, 0.24, 0.86], Color("8a5a36"))
			box.call(0.48, 0.12, 0.53, 0.64, Color("6e4527"))
			tri.call([0.55, 0.16, 0.55, 0.56, 0.84, 0.56], Color("f4efe2"))
			tri.call([0.46, 0.2, 0.46, 0.56, 0.2, 0.56], Color("f4efe2"))
		&"launch":   # owner #98: a rocket on its pad
			box.call(0.12, 0.86, 0.88, 0.94, Color("8c8c8c"))
			box.call(0.4, 0.3, 0.6, 0.86, Color("f4f6f8"))
			tri.call([0.4, 0.3, 0.6, 0.3, 0.5, 0.06], Color("e0413a"))
			tri.call([0.4, 0.62, 0.4, 0.86, 0.26, 0.86], Color("e0413a"))
			tri.call([0.6, 0.62, 0.6, 0.86, 0.74, 0.86], Color("e0413a"))
			box.call(0.45, 0.42, 0.55, 0.5, Color("3a7be8"))
		&"castle":
			box.call(0.12, 0.4, 0.88, 0.92, Color("8c8c8c"))
			for x: float in [0.12, 0.3, 0.48, 0.66, 0.8]:
				box.call(x, 0.3, x + 0.08, 0.4, Color("8c8c8c"))
			box.call(0.42, 0.62, 0.58, 0.92, Color("4a3222"))
			box.call(0.2, 0.5, 0.3, 0.6, Color("5d8f2f"))
		_:
			if ProspectPictures.draw(ci, kind, r):   # spec §26: a deposit found (a gold nugget, an oil derrick, ...)
				return
			var pts := PackedVector2Array()
			for i in 10:
				var ang := -PI * 0.5 + i * PI / 5.0
				var rad := 0.42 if i % 2 == 0 else 0.18
				pts.append(at.call(0.5 + cos(ang) * rad, 0.52 + sin(ang) * rad))
			ci.draw_colored_polygon(pts, Color("ffd23f"))


## A place on the map: a round badge with its picture (its name is a label under it).
class _Badge:
	extends Button

	var kind: StringName

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, size.x * 0.5, Color("5a3d1e"))
		draw_circle(c, size.x * 0.5 - 4.0, Color("fffaf0"))
		WorldMapPanel.draw_picture(self, kind, Rect2(Vector2(size.x * 0.16, size.y * 0.14), size * 0.68))
