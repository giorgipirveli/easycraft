class_name SleepOverlay
extends Control
## The sleep fade (M1b Task 10): while you sleep the screen slowly goes dark with a floating
## "Z z z"; when you wake up it goes black for a moment (the time skips behind it) and fades back.

const DIM := 0.85
const FALL_ASLEEP_TIME := 1.6
const BLACK_TIME := 0.25
const WAKE_TIME := 1.2

var _shade := ColorRect.new()
var _zzz := Label.new()
var _tween: Tween
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	modulate.a = 0.0
	_shade.color = Color(0.02, 0.03, 0.08)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_zzz.text = "Z z z"
	_zzz.add_theme_font_size_override("font_size", 84)
	_zzz.add_theme_color_override("font_color", Color(0.8, 0.88, 1.0))
	_zzz.add_theme_color_override("font_outline_color", Color(0.1, 0.12, 0.3))
	_zzz.add_theme_constant_override("outline_size", 10)
	_zzz.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zzz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_zzz)
	_zzz.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_zzz.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_zzz.grow_vertical = Control.GROW_DIRECTION_BOTH


func is_asleep() -> bool:
	return visible and _zzz.visible


func fall_asleep() -> void:
	visible = true
	_zzz.visible = true
	_fade([[DIM, FALL_ASLEEP_TIME]])


func wake_up() -> void:
	if not visible:
		return
	_zzz.visible = false
	_fade([[1.0, BLACK_TIME], [0.0, WAKE_TIME]])
	_tween.tween_callback(func() -> void: visible = false)


## Tweens the overlay's alpha through [[alpha, seconds], ...].
func _fade(steps: Array) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	for step: Array in steps:
		_tween.tween_property(self, "modulate:a", step[0], step[1])


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_zzz.pivot_offset = _zzz.size * 0.5
	_zzz.position.y = (size.y - _zzz.size.y) * 0.5 - 30.0 - fmod(_t * 18.0, 40.0)
	_zzz.modulate.a = 0.55 + 0.45 * sin(_t * 2.2)
