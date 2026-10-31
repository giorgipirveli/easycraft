class_name RaceClock
extends PanelContainer
## The race clock (M3 Task 7): a label, never a button, top-centre under the wave line and the boss bar
## (HudLayout spot "race"; they never overlap). While this player races: a clock picture, the time (0:00.0
## standing on START, then running on the host's clock) and the course's coins (a star coin: course score,
## never gold). At FINISH: the medal's picture (a star without one), the time and the coins for
## RESULT_SECONDS, then it hides. Pictures are drawn in code (Picture), no textures.

const RESULT_SECONDS := 5.0
const TIME_SIZE := 30

## () -> int: the time on this player's clock (CourseDirector.clock_ms).
var clock_ms: Callable = func() -> int: return 0
var picture := Picture.new()
var time_label := Label.new()
var coin := Picture.new()
var coins_label := Label.new()
var showing_result := false
var medal: StringName = &""

var _result_t := 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.85), 16, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	picture.kind = &"clock"
	picture.custom_minimum_size = Vector2(42, 42)
	row.add_child(picture)
	for l: Label in [time_label, coins_label]:
		l.add_theme_font_size_override("font_size", TIME_SIZE if l == time_label else 24)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 6)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_label.text = CourseRules.format_time(0)
	time_label.custom_minimum_size.x = 104
	row.add_child(time_label)
	coin.kind = &"coin"
	coin.custom_minimum_size = Vector2(28, 28)
	row.add_child(coin)
	coins_label.text = "0"
	coins_label.custom_minimum_size.x = 34
	row.add_child(coins_label)


## This player's run as the host sent it (CourseDirector.state_changed).
func show_state(state: Dictionary) -> void:
	var event := str(state.get("event", ""))
	coins_label.text = str(int(state.get("coins", 0)))
	if event == "finish":
		showing_result = true
		_result_t = RESULT_SECONDS
		medal = StringName(str(state.get("medal", "")))
		picture.kind = medal if CourseRules.MEDALS.has(medal) else &"star"
		picture.best = bool(state.get("best", false))
		time_label.text = CourseRules.format_time(int(state.get("ms", 0)))
		visible = true
	elif bool(state.get("on", false)):
		showing_result = false
		picture.kind = &"clock"
		picture.best = false
		time_label.text = CourseRules.format_time(int(clock_ms.call()))
		visible = true
	else:
		showing_result = false
		visible = false
	picture.queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	if showing_result:
		_result_t -= delta
		if _result_t <= 0.0:
			showing_result = false
			visible = false
		return
	time_label.text = CourseRules.format_time(int(clock_ms.call()))


## A picture drawn in code: &"clock", &"coin" (a course coin: a star on gold), &"gold" / &"silver" /
## &"bronze" (a medal on its ribbon) or &"star" (finished without a medal); `best` adds sparkles.
class Picture:
	extends Control
	const MEDAL_COLORS := {&"gold": Color("ffd23f"), &"silver": Color("d9e2ec"), &"bronze": Color("d9955a")}
	var kind: StringName = &"clock"
	var best := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.5
		var c := size * 0.5
		match kind:
			&"clock":
				draw_circle(c, r, Color("2b3242"))
				draw_circle(c, r * 0.84, Color("f4f6f8"))
				draw_line(c, c + Vector2(0, -r * 0.6), Color("2b3242"), maxf(2.0, r * 0.12))
				draw_line(c, c + Vector2(r * 0.45, 0), Color("e5484d"), maxf(2.0, r * 0.12))
				draw_circle(c, r * 0.1, Color("2b3242"))
			&"coin":
				draw_circle(c, r, Color("c9971e"))
				draw_circle(c, r * 0.8, Color("ffd23f"))
				_star(c, r * 0.5, Color(1, 1, 1, 0.95))
			&"gold", &"silver", &"bronze":
				var ribbon := PackedVector2Array([c + Vector2(-r * 0.55, -r), c + Vector2(-r * 0.1, -r),
					c + Vector2(r * 0.1, -r * 0.1), c + Vector2(-r * 0.3, -r * 0.1)])
				draw_colored_polygon(ribbon, Color("3a7be8"))
				var ribbon2 := PackedVector2Array([c + Vector2(r * 0.55, -r), c + Vector2(r * 0.1, -r),
					c + Vector2(-r * 0.1, -r * 0.1), c + Vector2(r * 0.3, -r * 0.1)])
				draw_colored_polygon(ribbon2, Color("d9463b"))
				var mc: Color = MEDAL_COLORS[kind]
				draw_circle(c + Vector2(0, r * 0.25), r * 0.72, mc.darkened(0.35))
				draw_circle(c + Vector2(0, r * 0.25), r * 0.6, mc)
				_star(c + Vector2(0, r * 0.25), r * 0.36, mc.lightened(0.5))
			_:
				_star(c, r * 0.95, Color("ffd23f"))
		if best:
			for p: Vector2 in [Vector2(-0.9, -0.8), Vector2(0.9, -0.6), Vector2(0.8, 0.9)]:
				_star(c + p * r, r * 0.22, Color.WHITE)

	func _star(c: Vector2, r: float, color: Color) -> void:
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI * 0.5 + i * PI / 5.0
			pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
		draw_colored_polygon(pts, color)
