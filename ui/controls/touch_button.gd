class_name TouchButton
extends Control
## Multi-touch button: tracks its own finger, so it works while another finger holds the joystick.
## Optionally presses an Input Map action while held. Draws itself (round or rounded-square).
## With a `symbol` (M2 Task 17) it shows a picture (HudIcons) with its word under it; otherwise a
## texture icon and/or a word in the middle (the hotbar's slots).

signal pressed
signal released

@export var action: StringName = &""
@export var text := ""
@export var icon: Texture2D
@export var round_shape := true
@export var font_size := 26
## The picture drawn above the word (HudIcons.SYMBOLS); empty: no picture.
@export var symbol: StringName = &"":
	set(value):
		symbol = value
		queue_redraw()

var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _index := -1
var _frame := StyleBoxFlat.new()
## P5 (VR draws): redraws through the headset's one-draw path (CanvasBatch); tests count them.
var vr_draws := 0
## P5: a square slot whose frame its parent draws in a headset, in one batch with its neighbours' (the Hotbar).
var frame_drawn_by_parent := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_down() -> bool:
	return _index != -1


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _index == -1 and _hit(t.position):
			_index = t.index
			if action != &"":
				Input.action_press(action)
			pressed.emit()
			Audio.touch(symbol, action)   # the audio pass: a click, a softer click, a tick or nothing (UiSoundRules)
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif not t.pressed and t.index == _index:
			_release()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _index:
		get_viewport().set_input_as_handled()


## Hiding or pausing lets go, as if the finger lifted. The HUD pauses with the game, so a finger
## lifted during the pause menu would never be heard and the action would stay pressed.
func _notification(what: int) -> void:
	if _index == -1:
		return
	if what == NOTIFICATION_PAUSED or (what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree()):
		_release()


## Owner #90: Cross / A on a picture button the game controller's focus is on (the MORE panel's): a tap, pressed and
## let go (PadFocus).
func pad_press() -> bool:
	if action != &"":
		Input.action_press(action)
	pressed.emit()
	Audio.touch(symbol, action)
	if action != &"":
		Input.action_release(action)
	released.emit()
	return true


func _release() -> void:
	_index = -1
	if action != &"":
		Input.action_release(action)
	released.emit()
	queue_redraw()


func _hit(pos: Vector2) -> bool:
	var rect := get_global_rect()
	if round_shape:
		return pos.distance_to(rect.get_center()) <= rect.size.x * 0.55
	return rect.has_point(pos)


func _draw() -> void:
	if GraphicsPreset.vr_session and symbol != &"" and get_script() == TouchButton:
		_draw_vr()   # P5: in a headset's HUD the frame and the picture as one draw (a subclass's own picture: as before)
		return
	var bg := Color(1, 1, 1, 0.45) if is_down() else Color(0.08, 0.1, 0.16, 0.45)
	var border := Color(1, 0.85, 0.2) if selected else Color(1, 1, 1, 0.85)
	var border_w := 4.0 if selected else 2.5
	if round_shape:
		var r := size.x * 0.5
		draw_circle(size * 0.5, r, bg)
		draw_arc(size * 0.5, r - border_w * 0.5, 0.0, TAU, 48, border, border_w, true)
	elif not (frame_drawn_by_parent and GraphicsPreset.vr_session):   # P5: the Hotbar draws it in a headset
		_frame.bg_color = bg
		_frame.border_color = border
		_frame.set_border_width_all(int(border_w))
		_frame.set_corner_radius_all(14 if symbol != &"" else 10)
		draw_style_box(_frame, Rect2(Vector2.ZERO, size))
	if symbol != &"":
		_draw_icon(icon_rect())
		_draw_word()
		return
	if icon:
		var inset := size * 0.18
		draw_texture_rect(icon, Rect2(inset, size - inset * 2.0), false)
	if text != "":
		var font := get_theme_default_font()
		var h := font.get_height(font_size)
		draw_string(font, Vector2(0, size.y * 0.5 + h * 0.3), atr(text), HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color.WHITE)


## P5 (VR draws): a picture button in a headset's HUD (drawn every frame into the tray's texture): its round frame and
## HudIcons' picture as one CanvasBatch draw (Godot 4 draws each circle, polygon and line as a draw call of its own:
## 7-11 a button before); a square's StyleBoxFlat and the word stay their own draws, as in _draw.
func _draw_vr() -> void:
	vr_draws += 1
	var bg := Color(1, 1, 1, 0.45) if is_down() else Color(0.08, 0.1, 0.16, 0.45)
	var border := Color(1, 0.85, 0.2) if selected else Color(1, 1, 1, 0.85)
	var border_w := 4.0 if selected else 2.5
	var batch := CanvasBatch.new()
	if round_shape:
		batch.draw_circle(size * 0.5, size.x * 0.5, bg)
		batch.draw_arc(size * 0.5, size.x * 0.5 - border_w * 0.5, 0.0, TAU, 48, border, border_w, true)
	else:
		_frame.bg_color = bg
		_frame.border_color = border
		_frame.set_border_width_all(int(border_w))
		_frame.set_corner_radius_all(14)
		draw_style_box(_frame, Rect2(Vector2.ZERO, size))
	HudIcons.draw_into(batch, symbol, icon_rect())
	batch.flush(self)
	_draw_word()


## P5: this square slot's frame (_draw's colours, its modulate's alpha) as triangles round (0, 0) ({points, colors,
## indices}), built once per look (a size, pressed or not, selected or not, the alpha) and kept: a hotbar redraw only
## moves them. Every look has the same shape of triangles.
static var _frame_meshes := {}


func frame_mesh() -> Dictionary:
	var key := "%s|%s|%s|%.2f" % [size, is_down(), selected, modulate.a]
	if not _frame_meshes.has(key):
		var a := modulate.a
		var bg := Color(1, 1, 1, 0.45) if is_down() else Color(0.08, 0.1, 0.16, 0.45)
		var border := Color(1, 0.85, 0.2) if selected else Color(1, 1, 1, 0.85)
		var batch := CanvasBatch.new()
		batch.draw_rounded_box(Rect2(Vector2.ZERO, size), 10.0, Color(bg, bg.a * a), Color(border, border.a * a),
			float(int(4.0 if selected else 2.5)))
		_frame_meshes[key] = {"points": batch.points, "colors": batch.colors, "indices": batch.indices}
	return _frame_meshes[key]


## The picture's square: the top part of the button, centred, above the word.
func icon_rect() -> Rect2:
	var side := size.y * (0.46 if round_shape else 0.5)
	return Rect2(Vector2((size.x - side) * 0.5, size.y * (0.15 if round_shape else 0.1)), Vector2(side, side))


## The word's font size: about a sixth of the button's height, smaller if the word would not fit
## (inside a round button the word sits where the circle is narrower).
func word_size() -> int:
	var fs := clampi(roundi(size.y * 0.16), 16, 34)
	var room := size.x * (0.78 if round_shape else 0.9)
	var font := get_theme_default_font()
	while fs > 12 and font.get_string_size(atr(text), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:   # M3 Task 21a: the word in its language
		fs -= 1
	return fs


## Subclasses may draw their own picture (the emote button's little figure).
func _draw_icon(r: Rect2) -> void:
	HudIcons.draw(self, symbol, r)


func _draw_word() -> void:
	if text == "":
		return
	var font := get_theme_default_font()
	var fs := word_size()
	var base := Vector2(0, size.y * (0.8 if round_shape else 0.86))
	var word := atr(text)   # M3 Task 21a: drawn words are translated here (a Control's own text translates itself)
	draw_string_outline(font, base, word, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, 5, Color(0, 0, 0, 0.75))
	draw_string(font, base, word, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color.WHITE)
