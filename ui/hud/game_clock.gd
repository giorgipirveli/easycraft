class_name GameClock
extends Control
## The HUD's game clock (owner feedback #33, spec §12.18): one label, never a button, on HudLayout's
## "game_clock" spot (top, left of the middle, under the potion chips). A picture drawn by HudIcons and two
## short lines:
## - Build to Survive: a moon and "Night in 1:20" by day, a sun and "Morning in 0:45" at night (BuildRules);
##   under it the score ("Nights 3 · Best 5"), or, from NEAR seconds before the night and all night, the
##   shelter's words ("Close the gap!", "Safe inside!" with a house).
## - Monster Wave (spec §12.20): a sword, "3:24 · Wave 5" and the best; a kill bonus pops up there for POP seconds.
## Game time only (the sky's clock): nothing here counts real days. Redrawn only when its words change.

const SIZE := Vector2(300, 60)
const ICON := 40.0
const PAD := 10.0
const NEAR := 60.0
const POP := 1.5
const PANEL := Color(0.08, 0.1, 0.17, 0.85)
const NIGHT_INK := Color("ffd23f")
const POP_INK := Color("ffd23f")

var pop_left := 0.0

var _symbol: StringName = &"moon"
var _line := Label.new()
var _small := Label.new()
var _box := StyleBoxFlat.new()
var _pop_text := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = SIZE
	custom_minimum_size = SIZE
	_box.bg_color = PANEL
	_box.set_corner_radius_all(16)
	for l: Label in [_line, _small]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("outline_size", 6)
		l.clip_text = true
		l.position = Vector2(PAD * 2.0 + ICON, 4.0 if l == _line else 32.0)
		l.size = Vector2(SIZE.x - PAD * 3.0 - ICON, 28.0 if l == _line else 24.0)
		add_child(l)
	_line.add_theme_font_size_override("font_size", 22)
	_small.add_theme_font_size_override("font_size", 17)
	set_process(false)


## Build to Survive at time of day t, with the player's score and shelter (ShelterRules state).
func show_build(t: float, nights: int, best: int, shelter: StringName) -> void:
	var night := BuildRules.clock_is_night(t)
	_line.text = BuildRules.clock_line(t)
	var near := night or BuildRules.seconds_to_night(t) <= NEAR
	_small.text = ShelterRules.hint(shelter) if near else BuildRules.score_line(nights, best)
	_set_symbol(&"home" if near and shelter == ShelterRules.SAFE else (&"wake" if night else &"moon"))
	_line.add_theme_color_override("font_color", NIGHT_INK if night else Color.WHITE)


## Monster Wave (spec §12.20): the time survived and the wave, the arena's best under it.
func show_arena(seconds: float, wave: int, best: Dictionary) -> void:
	_line.text = ArenaRules.run_line(seconds, wave)
	_small.text = _pop_text if pop_left > 0.0 else ArenaRules.best_line(best)
	_set_symbol(&"attack")


## A defeat's kill bonus ("+4 × 2!"), for POP seconds.
func show_paid(gold: int, combo: int) -> void:
	_pop_text = ArenaRules.paid_line(gold, combo)
	pop_left = POP
	_small.text = _pop_text
	_small.add_theme_color_override("font_color", POP_INK)
	set_process(true)


func _process(delta: float) -> void:
	pop_left -= delta
	if pop_left <= 0.0:
		pop_left = 0.0
		_small.remove_theme_color_override("font_color")
		set_process(false)


func symbol() -> StringName:
	return _symbol


func line() -> String:
	return _line.text


func small_line() -> String:
	return _small.text


func _set_symbol(s: StringName) -> void:
	if s != _symbol:
		_symbol = s
		queue_redraw()


func _draw() -> void:
	draw_style_box(_box, Rect2(Vector2.ZERO, SIZE))
	HudIcons.draw(self, _symbol, Rect2(PAD, (SIZE.y - ICON) * 0.5, ICON, ICON))
