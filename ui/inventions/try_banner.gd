class_name TryBanner
extends PanelContainer
## Owner #78 (spec §21e): while an invention's "try it" runs, a small banner under the top of the screen says what to
## do, fills a bar as the child does it and gives the hint for now; for the kite and the balloon an arrow shows where
## the wind blows (turned with the camera: up is where the child looks). Display only (touches go through).

const SIZE := Vector2(470, 118)
const TOP := 222.0   # under the game clock (HudLayout's "game_clock" ends at 216)

var picture := InventionPicture.new(&"kite", 72.0)
var goal_label := Label.new()
var hint_label := Label.new()
var bar := ProgressBar.new()
var arrow := Control.new()
## Where the wind blows on the screen (radians, 0 = up, clockwise); NAN: no arrow.
var wind_angle := NAN


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", BookKit.card_box(Color("f3e6c4"), 10))
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -SIZE.x * 0.5
	offset_right = SIZE.x * 0.5
	offset_top = TOP
	offset_bottom = TOP + SIZE.y
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.add_child(picture)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	for l: Label in [goal_label, hint_label]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_color_override("font_color", BookKit.INK)
		l.custom_minimum_size.x = SIZE.x - 190
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(l)
	goal_label.add_theme_font_size_override("font_size", 17)
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color("a8401a"))
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(SIZE.x - 190, 16)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(bar)
	arrow.custom_minimum_size = Vector2(64, 64)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.draw.connect(_draw_arrow)
	row.add_child(arrow)


func show_try(kind: StringName, goal: String) -> void:
	picture.kind = kind
	goal_label.text = goal
	hint_label.text = ""
	bar.value = 0.0
	visible = true


func follow(progress: float, hint: String, angle: float) -> void:
	bar.value = clampf(progress, 0.0, 1.0)
	if hint_label.text != hint:
		hint_label.text = hint
	wind_angle = angle
	arrow.visible = is_finite(angle)
	arrow.queue_redraw()


func _draw_arrow() -> void:
	if not is_finite(wind_angle):
		return
	var c := arrow.size * 0.5
	var dir := Vector2(sin(wind_angle), -cos(wind_angle))
	var side := Vector2(-dir.y, dir.x)
	arrow.draw_circle(c, 30.0, Color(1, 1, 1, 0.7))
	arrow.draw_line(c - dir * 20.0, c + dir * 12.0, Color("1f5fa8"), 6.0)
	arrow.draw_colored_polygon(PackedVector2Array([c + dir * 24.0, c + dir * 8.0 + side * 10.0, c + dir * 8.0 - side * 10.0]),
		Color("1f5fa8"))
