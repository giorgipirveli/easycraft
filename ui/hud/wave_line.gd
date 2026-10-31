class_name WaveLine
extends Control
## The HUD's wave line (M2 Task 9, spec §12.8): top-centre above the toasts, a little slime and short
## words, "Wave 3 starts in 5…" (a tick each second) and then "Wave 3 — 5 left" with a bar for the time
## left (it runs down by itself between the host's messages; the last 30 s turn orange, and the bar's
## length says it without the colour). Hidden while no wave is on. Never takes a tap; redrawn at most
## five times a second, and only while a wave runs.

const SIZE := Vector2(264, 64)
const FONT_SIZE := 20
const ICON := 36.0
const PAD := 8.0
const BAR_HEIGHT := 7.0
const LOW_SECONDS := 30.0
const REDRAW_EVERY := 0.2
const PANEL := Color(0.08, 0.1, 0.17, 0.85)
const BAR_BACK := Color(1, 1, 1, 0.18)
const BAR := Color("ffd23f")
const BAR_LOW := Color("ff8a3d")

var _label := Label.new()
var _icon := MonsterIcon.new(ICON)
var _box := StyleBoxFlat.new()
var _running := false
var _time_left := 0.0
var _count := -1
var _redraw_t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_box.bg_color = PANEL
	_box.set_corner_radius_all(16)
	add_child(_icon)
	_icon.position = Vector2(PAD, (SIZE.y - BAR_HEIGHT - ICON) * 0.5 - 2.0)
	_icon.size = Vector2(ICON, ICON)
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 6)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.clip_text = true
	add_child(_label)
	_label.position = Vector2(PAD * 2.0 + ICON, 4.0)
	_label.size = Vector2(text_room(), SIZE.y - BAR_HEIGHT - 14.0)
	set_process(false)


## The host's wave state (WaveDirector.state()).
func show_state(s: Dictionary) -> void:
	var phase := int(s.get("phase", WaveDirector.Phase.IDLE))
	visible = phase == WaveDirector.Phase.COUNTDOWN or phase == WaveDirector.Phase.RUNNING
	_running = phase == WaveDirector.Phase.RUNNING
	set_process(_running)
	if phase == WaveDirector.Phase.COUNTDOWN:
		var c := int(s.get("count", 0))
		_label.text = WaveRules.countdown_line(int(s.get("wave", 1)), c)
		if c != _count:
			_count = c
			Audio.play(&"ui_click")   # tick... tick...
	else:
		_count = -1
		if _running:
			_label.text = WaveRules.line(int(s.get("wave", 1)), int(s.get("left", 0)))
			_time_left = float(s.get("time_left", 0.0))
	queue_redraw()


func text() -> String:
	return _label.text


## The time bar: the share of the 3 minutes left (0 when no wave runs).
func time_share() -> float:
	return clampf(_time_left / WaveRules.TIME_LIMIT, 0.0, 1.0) if _running else 0.0


func text_room() -> float:
	return SIZE.x - PAD * 3.0 - ICON


func text_width() -> float:
	return _label.get_theme_font("font").get_string_size(_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


func _process(delta: float) -> void:
	_time_left = maxf(_time_left - delta, 0.0)
	_redraw_t -= delta
	if _redraw_t <= 0.0:
		_redraw_t = REDRAW_EVERY
		queue_redraw()


func _draw() -> void:
	draw_style_box(_box, Rect2(Vector2.ZERO, size))
	if not _running:
		return
	var bar := Rect2(PAD * 2.0 + ICON, size.y - BAR_HEIGHT - 9.0, text_room(), BAR_HEIGHT)
	draw_rect(bar, BAR_BACK)
	bar.size.x *= time_share()
	draw_rect(bar, BAR_LOW if _time_left <= LOW_SECONDS else BAR)
