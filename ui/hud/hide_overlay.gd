class_name HideOverlay
extends Control
## The view from inside a barrel or closet (M2 Task 5; research G5 "hiding feels safe"): a cosy, warm
## dark vignette around the edges, a closed eye with "They can't see me!", sounds muffled, and a small
## hint how to come out. It never takes a tap: a tap (or moving) reaches the game, which asks to come
## out. One gradient texture, made once; it fades in and out.

const TEXT := "They can't see me!"
const HINT := "Tap or move to come out"
const FADE := 0.35
const WARM := Color(0.16, 0.09, 0.04, 0.92)

static var _vignette: GradientTexture2D

var _label := Label.new()
var _hint := Label.new()
var _eye := Control.new()
var _tween: Tween
var _hidden := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var shade := TextureRect.new()
	shade.texture = vignette()
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eye.draw.connect(func() -> void: StealthMeter.draw_eye(_eye, _eye.size * 0.5, 70.0, StealthRules.EYE_CLOSED))
	_eye.anchor_left = 0.5
	_eye.anchor_right = 0.5
	_eye.anchor_top = 1.0
	_eye.anchor_bottom = 1.0
	_eye.offset_left = -45
	_eye.offset_right = 45
	_eye.offset_top = -250
	_eye.offset_bottom = -200
	add_child(_eye)
	for l: Label in [_label, _hint]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 8)
		l.anchor_left = 0.5
		l.anchor_right = 0.5
		l.anchor_top = 1.0
		l.anchor_bottom = 1.0
		l.offset_left = -300
		l.offset_right = 300
		add_child(l)
	_label.text = TEXT
	_label.add_theme_font_size_override("font_size", 34)
	_label.offset_top = -196
	_label.offset_bottom = -150
	_hint.text = HINT
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.modulate = Color(1, 1, 1, 0.8)
	_hint.offset_top = -148
	_hint.offset_bottom = -120


## The warm dark ring around the view (clear in the middle), shared by every overlay.
static func vignette() -> GradientTexture2D:
	if _vignette == null:
		var g := Gradient.new()
		g.set_color(0, Color(WARM, 0.0))
		g.set_color(1, WARM)
		g.add_point(0.55, Color(WARM, 0.0))
		g.add_point(0.8, Color(WARM, 0.55))
		_vignette = GradientTexture2D.new()
		_vignette.gradient = g
		_vignette.fill = GradientTexture2D.FILL_RADIAL
		_vignette.fill_from = Vector2(0.5, 0.5)
		_vignette.fill_to = Vector2(1.0, 1.0)
		_vignette.width = 256
		_vignette.height = 256
	return _vignette


## In (fades in, sounds muffled) or out (fades away).
func set_hidden(on: bool) -> void:
	if on == _hidden:
		return
	_hidden = on
	Audio.set_muffled(on)
	if _tween and _tween.is_valid():
		_tween.kill()
	if on:
		visible = true
		modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0 if on else 0.0, FADE)
	if not on:
		_tween.tween_callback(func() -> void: visible = false)


func _exit_tree() -> void:
	if _hidden:
		Audio.set_muffled(false)   # never leave the game muffled (back to the menu)
