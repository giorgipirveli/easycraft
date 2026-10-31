class_name CoinShower
extends CanvasLayer
## Spinning gold coins raining over the whole screen, then gone (a code's gold, M3 Task 13; the
## Gold Farm's welcome back can reuse it). Drawn with plain circles: no textures, no materials,
## and it never catches a tap. Add it anywhere; it frees itself.

const GOLD := Color("ffd23f")
const RIM := Color("d99a00")
const SHINE := Color(1, 1, 1, 0.55)
const LAYER := 20        # over the menus (their CanvasLayer is 1)
const FADE := 0.4        # seconds of fade-out at the end

var duration := 2.6
## M5 Task 1: Reduce motion: a third of the coins, falling straight without turning over.
var calm := false
var _coins: Array[Dictionary] = []   # x (0..1 of the width), delay, fall (screens/s), radius, spin, phase, sway
var _t := 0.0
var _canvas := Control.new()


func _init(count: int = 48, seconds: float = 2.6) -> void:
	layer = LAYER
	duration = maxf(seconds, 0.5)
	calm = bool(Profile.data.settings.get("reduce_motion", false))
	if calm:
		count = maxi(6, count / 3)
	_canvas.name = "Coins"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.anchor_right = 1.0
	_canvas.anchor_bottom = 1.0
	_canvas.draw.connect(_draw_coins)
	add_child(_canvas)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		var delay := rng.randf_range(0.0, duration * 0.4)
		# every coin is off the bottom before the fade ends: 1.15 screens in (duration - delay - FADE / 2)
		var fall := 1.15 / (duration - delay - FADE * 0.5) * rng.randf_range(1.0, 1.35)
		_coins.append({"x": rng.randf(), "delay": delay, "fall": fall, "radius": rng.randf_range(14.0, 26.0),
			"spin": rng.randf_range(5.0, 10.0), "phase": rng.randf() * TAU, "sway": rng.randf_range(-30.0, 30.0)})


func coin_count() -> int:
	return _coins.size()


func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	_canvas.modulate.a = clampf((duration - _t) / FADE, 0.0, 1.0)
	_canvas.queue_redraw()


func _draw_coins() -> void:
	var screen := _canvas.size
	for c: Dictionary in _coins:
		var t: float = _t - c.delay
		if t < 0.0:
			continue
		var r: float = c.radius
		var sway: float = 0.0 if calm else c.sway
		var pos := Vector2(c.x * screen.x + sin(t * 3.0 + c.phase) * sway, -r * 2.0 + t * c.fall * screen.y)
		var flip := 1.0 if calm else maxf(absf(cos(c.phase + t * c.spin)), 0.15)   # the coin turning over
		_canvas.draw_set_transform(pos, 0.0, Vector2(flip, 1.0))
		_canvas.draw_circle(Vector2.ZERO, r, RIM)
		_canvas.draw_circle(Vector2.ZERO, r * 0.78, GOLD)
		_canvas.draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.22, SHINE)
	_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
