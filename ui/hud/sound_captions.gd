class_name SoundCaptions
extends Control
## Sound captions on the HUD (M5 Task 1, spec §15.1a; CaptionRules): an important sound (Audio.sound_played) shows a
## small chip with a picture and a few words, on an oval round the middle of the screen towards the sound (behind
## the camera: at the bottom), following it as the camera turns, for a moment. Night falling (the world's clock)
## shows one too. The Sound captions setting turns them off (on by default); with Reduce motion a new chip never
## pops. Nothing to tap: touches go through.

const BACK := Color(0.06, 0.08, 0.14, 0.86)
const EDGE := Color(1, 1, 1, 0.85)
const INK := Color(1, 1, 1)
const POP := 1.18                 # a new chip's size, easing to 1 in POP_TIME
const POP_TIME := 0.25
const NIGHT_LOOK := 0.5           # seconds between looks at the clock

## The world's clock (SkyCycle; anything with `time`); by default the scene's `sky` (the sandbox's).
var sky: Node

var _chips: Array[Dictionary] = []   # {kind, at (Vector3; INF: flat), age}
var _last := {}                      # kind -> the clock when one last showed
var _clock := 0.0
var _night_look := 0.0
var _night := false
var _night_known := false
var _box := StyleBoxFlat.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.bg_color = BACK
	_box.border_color = EDGE
	_box.set_border_width_all(2)
	_box.set_corner_radius_all(16)
	Audio.sound_played.connect(_on_sound)


func _process(delta: float) -> void:
	tick(delta)


func _on_sound(sound: StringName, at: Vector3, _volume_db: float) -> void:
	hear(sound, at)


## A sound was heard at `at` (INF: everywhere); true when it shows a caption.
func hear(sound: StringName, at: Vector3 = Vector3.INF) -> bool:
	var kind := CaptionRules.kind_of(sound)
	return kind != &"" and show_caption(kind, at)


## Shows a caption of `kind` for a sound at `at` if the setting is on and CaptionRules allow it.
func show_caption(kind: StringName, at: Vector3 = Vector3.INF) -> bool:
	if not bool(Profile.data.settings.get("captions", true)):
		return false
	if not CaptionRules.may_show(kind, _clock, _last, _chips.size()):
		return false
	_last[kind] = _clock
	_chips.append({"kind": kind, "at": at, "age": 0.0})
	queue_redraw()
	return true


## Moves time on by `delta`: chips age and go, and the clock is looked at for night falling.
func tick(delta: float) -> void:
	_clock += delta
	_night_look -= delta
	if _night_look <= 0.0:
		_night_look = NIGHT_LOOK
		_look_at_the_sky()
	if _chips.is_empty():
		return
	for c in _chips:
		c.age += delta
	_chips = _chips.filter(func(c: Dictionary) -> bool: return c.age < CaptionRules.SHOW_TIME)
	queue_redraw()


func count() -> int:
	return _chips.size()


func kind(i: int) -> StringName:
	return _chips[i].kind


## Chip `i`'s rectangle on the screen now (before its pop).
func chip_rect(i: int) -> Rect2:
	return _rects()[i]


## How big chip `i` is drawn now (1 = its size; a new one pops a little, never with Reduce motion).
func chip_scale(i: int) -> float:
	if not Feel.motion_allowed():
		return 1.0
	var age: float = _chips[i].age
	return lerpf(POP, 1.0, clampf(age / POP_TIME, 0.0, 1.0))


func _look_at_the_sky() -> void:
	var s := _sky()
	if s == null:
		return
	var night := DayCycle.is_night(float(s.get("time")))
	if _night_known and night and not _night:
		show_caption(&"night")
	_night = night
	_night_known = true


func _sky() -> Node:
	if is_instance_valid(sky):
		return sky
	var scene := get_tree().current_scene if is_inside_tree() else null
	var s: Variant = scene.get("sky") if scene else null
	return s as Node if s is Node and is_instance_valid(s) else null


## Every chip's place: towards its sound (flat sounds at the top), a later one moved on if it would cover another.
func _rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var screen := get_viewport_rect().size
	var cam := VrUi.world_camera(self)   # owner #101: the world's camera (in VR the HUD is in the canvas)
	for c in _chips:
		var p := CaptionRules.place(screen, _direction(cam, c.at))
		var r := Rect2(p - CaptionRules.CHIP * 0.5, CaptionRules.CHIP)
		for i in 6:
			var clash := false
			for o in out:
				if o.intersects(r):
					clash = true
			if not clash:
				break
			r.position.y += CaptionRules.CHIP.y + 8.0 if r.get_center().y < screen.y * 0.5 else -(CaptionRules.CHIP.y + 8.0)
		out.append(r)
	return out


## From the middle of the screen towards `at` (camera space: right +x, up -y on the screen); flat sounds: up.
func _direction(cam: Camera3D, at: Vector3) -> Vector2:
	if cam == null or not at.is_finite():
		return Vector2.UP
	var local := cam.global_transform.affine_inverse() * at
	if local.z > 0.0 and absf(local.x) < 0.5:
		return Vector2.DOWN   # behind the camera: the bottom
	var d := Vector2(local.x, -local.y)
	if local.z > 0.0:
		d.y = maxf(d.y, 0.0) + absf(d.x) * 0.5   # behind and to the side: a low side
	if d.length() < 0.001:
		return Vector2.DOWN
	return d.normalized()


func _draw() -> void:
	if _chips.is_empty():
		return
	var rects := _rects()
	var font := get_theme_default_font()
	for i in _chips.size():
		var c: Dictionary = _chips[i]
		var left := CaptionRules.SHOW_TIME - float(c.age)
		var alpha := clampf(left / CaptionRules.FADE_TIME, 0.0, 1.0)
		var s := chip_scale(i)
		var r: Rect2 = rects[i]
		r = Rect2(r.get_center() - r.size * s * 0.5, r.size * s)
		_box.bg_color = Color(BACK, BACK.a * alpha)
		_box.border_color = Color(EDGE, EDGE.a * alpha)
		draw_style_box(_box, r)
		var k: Dictionary = CaptionRules.KINDS[c.kind]
		var side := r.size.y - 12.0
		var pic := Rect2(r.position + Vector2(8, 6), Vector2(side, side))
		_icon(k.icon, pic, alpha)
		var fs := roundi(22 * s)
		var base := Vector2(pic.end.x + 8, r.get_center().y + fs * 0.35)
		draw_string_outline(font, base, str(k.words), HORIZONTAL_ALIGNMENT_LEFT, r.end.x - base.x - 6, fs, 4,
			Color(0, 0, 0, 0.8 * alpha))
		draw_string(font, base, str(k.words), HORIZONTAL_ALIGNMENT_LEFT, r.end.x - base.x - 6, fs, Color(INK, alpha))


## The caption's picture, drawn in code (no art asset): a horned monster face, a bell, a snake, a crown, rumble waves,
## a horn; the moon and a speech bubble from HudIcons.
func _icon(icon: StringName, r: Rect2, alpha: float) -> void:
	var c := r.get_center()
	var u := r.size.x
	var ink := Color(1, 1, 1, alpha)
	match icon:
		&"moon", &"chat":
			HudIcons.draw(self, icon, r, Color(HudIcons.INK, alpha))
		&"monster":
			var green := Color(0.45, 0.85, 0.35, alpha)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-0.34, -0.2) * u, c + Vector2(-0.26, -0.48) * u,
				c + Vector2(-0.12, -0.28) * u]), ink)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0.34, -0.2) * u, c + Vector2(0.26, -0.48) * u,
				c + Vector2(0.12, -0.28) * u]), ink)
			draw_circle(c, u * 0.36, green)
			draw_circle(c + Vector2(-0.13, -0.06) * u, u * 0.08, ink)
			draw_circle(c + Vector2(0.13, -0.06) * u, u * 0.08, ink)
			draw_line(c + Vector2(-0.14, 0.16) * u, c + Vector2(0.14, 0.16) * u, Color(0, 0, 0, alpha), u * 0.06)
		&"bell":
			var gold := Color(1.0, 0.82, 0.25, alpha)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-0.3, 0.22) * u, c + Vector2(-0.2, -0.2) * u,
				c + Vector2(0.2, -0.2) * u, c + Vector2(0.3, 0.22) * u]), gold)
			draw_circle(c + Vector2(0, -0.2) * u, u * 0.2, gold)
			draw_circle(c + Vector2(0, 0.32) * u, u * 0.08, ink)
		&"snake":
			var pts := PackedVector2Array()
			for i in 13:
				var t := float(i) / 12.0
				pts.append(c + Vector2((t - 0.5) * 0.8, sin(t * TAU * 1.25) * 0.18) * u)
			draw_polyline(pts, Color(0.5, 0.9, 0.4, alpha), u * 0.12, true)
			draw_circle(pts[pts.size() - 1], u * 0.1, Color(0.5, 0.9, 0.4, alpha))
		&"crown":
			var gold := Color(1.0, 0.82, 0.25, alpha)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-0.4, 0.25) * u, c + Vector2(-0.4, -0.25) * u,
				c + Vector2(-0.2, 0.0) * u, c + Vector2(0, -0.35) * u, c + Vector2(0.2, 0.0) * u,
				c + Vector2(0.4, -0.25) * u, c + Vector2(0.4, 0.25) * u]), gold)
		&"rumble":
			for i in 3:
				var y := (i - 1) * 0.22
				var pts := PackedVector2Array()
				for j in 9:
					var t := float(j) / 8.0
					pts.append(c + Vector2((t - 0.5) * 0.8, y + (0.07 if j % 2 == 0 else -0.07)) * u)
				draw_polyline(pts, ink, u * 0.07, true)
		&"horn":
			var brass := Color(1.0, 0.75, 0.3, alpha)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-0.4, -0.06) * u, c + Vector2(0.25, -0.3) * u,
				c + Vector2(0.25, 0.3) * u, c + Vector2(-0.4, 0.06) * u]), brass)
			draw_circle(c + Vector2(0.28, 0) * u, u * 0.18, brass)
