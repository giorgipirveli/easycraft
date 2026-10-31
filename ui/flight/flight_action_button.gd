class_name FlightActionButton
extends TouchButton
## The cockpit's big round ACTION button (owner #79): it says what the child can do now (LIFT-OFF!, STAGE, BURN,
## LEGS, CHUTE) and glows and pulses while the rocket waits for it; dim when there is nothing to do. A burn is held
## (the button is down: is_down()). The game's own touch button underneath (multi-touch, the click).

var waiting := false
## Shown under the word on a PC ("Space").
var key_word := ""

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if waiting or is_down():
		queue_redraw()


func _draw() -> void:
	var r := size.x * 0.5
	var c := size * 0.5
	var pulse := 0.5 + 0.5 * sin(_t * 6.0) if waiting else 0.0
	if waiting:
		draw_circle(c, r * (1.0 + 0.1 * pulse), Color(1.0, 0.8, 0.25, 0.25 + 0.25 * pulse))
	var fill := Color(0.95, 0.42, 0.12) if waiting else Color(0.18, 0.2, 0.28, 0.7)
	if is_down():
		fill = fill.lightened(0.25)
	draw_circle(c, r * 0.9, fill)
	draw_arc(c, r * 0.9, 0.0, TAU, 48, Color(1, 1, 1, 0.95 if waiting else 0.5), 4.0, true)
	if text == "":
		return
	var font := get_theme_default_font()
	var fs := clampi(roundi(size.y * 0.17), 16, 38)
	while fs > 14 and font.get_string_size(atr(text), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > size.x * 0.8:
		fs -= 1
	var base := Vector2(0, c.y + fs * 0.35)
	var col := Color.WHITE if waiting else Color(1, 1, 1, 0.55)
	draw_string_outline(font, base, atr(text), HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, 6, Color(0, 0, 0, 0.75))
	draw_string(font, base, atr(text), HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, col)
	if key_word != "":
		draw_string(font, Vector2(0, c.y + fs * 0.35 + 26), key_word, HORIZONTAL_ALIGNMENT_CENTER, size.x, 17,
			Color(1, 0.93, 0.6, 0.9))
