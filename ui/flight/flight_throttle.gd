class_name FlightThrottle
extends Control
## The rocket's big throttle lever (owner #79, spec §25.3): a tall track with a glowing handle. A finger (or the mouse)
## on it pushes the throttle to where it is (the top: full); let go and it springs back down (a burn is held, never
## left on by mistake). Tracks its own finger, so it works while another finger steers. `value` 0..1; `held`.

signal pressed

var value := 0.0
var held := false
## Shown under the lever on a PC ("Shift").
var key_word := ""

var _index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _index == -1 and get_global_rect().grow(16.0).has_point(t.position):
			_index = t.index
			held = true
			_follow(t.position)
			pressed.emit()
			get_viewport().set_input_as_handled()
		elif not t.pressed and t.index == _index:
			_index = -1
			held = false
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _index:
		_follow((event as InputEventScreenDrag).position)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or (what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree()):
		_index = -1
		held = false


func is_down() -> bool:
	return _index != -1


func _follow(pos: Vector2) -> void:
	var r := get_global_rect()
	value = clampf(1.0 - (pos.y - r.position.y - 30.0) / maxf(r.size.y - 60.0, 1.0), 0.0, 1.0)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var track := Rect2(w * 0.32, 24.0, w * 0.36, h - 48.0)
	draw_rect(track, Color(0.05, 0.07, 0.12, 0.85))
	var fill := Rect2(track.position.x, track.end.y - track.size.y * value, track.size.x, track.size.y * value)
	draw_rect(fill, Color(1.0, 0.55, 0.12, 0.85).lerp(Color(1.0, 0.9, 0.35, 0.95), value))
	draw_rect(track, Color(1, 1, 1, 0.8), false, 2.5)
	for i in 5:
		var y := track.position.y + track.size.y * i / 4.0
		draw_line(Vector2(track.position.x - 10, y), Vector2(track.position.x, y), Color(1, 1, 1, 0.7), 2.0)
	var hy := track.end.y - track.size.y * value
	var handle := Rect2(4.0, hy - 22.0, w - 8.0, 44.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.62, 0.18) if held else Color(0.92, 0.46, 0.12)
	sb.set_corner_radius_all(12)
	sb.border_color = Color(1, 1, 1, 0.9)
	sb.set_border_width_all(3)
	draw_style_box(sb, handle)
	var font := get_theme_default_font()
	draw_string_outline(font, Vector2(0, 18), atr("THROTTLE"), HORIZONTAL_ALIGNMENT_CENTER, w, 17, 4, Color(0, 0, 0, 0.8))
	draw_string(font, Vector2(0, 18), atr("THROTTLE"), HORIZONTAL_ALIGNMENT_CENTER, w, 17, Color.WHITE)
	if key_word != "":
		draw_string_outline(font, Vector2(0, -4), key_word, HORIZONTAL_ALIGNMENT_CENTER, w, 17, 4, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, -4), key_word, HORIZONTAL_ALIGNMENT_CENTER, w, 17, Color(1, 0.93, 0.6))
