class_name RocketBar
extends Control
## The rocket science panel's bar (spec §21d.3): from the ground to the mission's planet, one segment per leg of the
## trip (Earth orbit, on to the planet, braking and landing) as long as its speed change, the legs' names and numbers
## under them, and how far this rocket's fuel reaches: a marker, green when it gets there. Drawn, no children.

const HEIGHT := 92.0
const BAR_H := 30.0
const COLORS: Array[Color] = [Color("5aa9f0"), Color("9b7cf0"), Color("f0a24a"), Color("5be37a")]

## [[name, km/s], …], from the ground first.
var legs: Array = []
## km/s this rocket reaches.
var reach := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(980, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_trip(trip_legs: Array, rocket_reach: float) -> void:
	legs = trip_legs
	reach = maxf(rocket_reach, 0.0)
	queue_redraw()


func need() -> float:
	var total := 0.0
	for leg: Array in legs:
		total += float(leg[1])
	return total


## The bar's scale: the trip, or the rocket when it goes further (a little room at the end).
func scale_km() -> float:
	return maxf(need(), reach) * 1.08


func _draw() -> void:
	var w := size.x
	var full := scale_km()
	if full <= 0.0:
		return
	var font := get_theme_default_font()
	var x := 0.0
	var top := 26.0
	draw_rect(Rect2(0, top, w, BAR_H), Color(1, 1, 1, 0.08))
	for i in legs.size():
		var km := float(legs[i][1])
		var len := w * km / full
		draw_rect(Rect2(x, top, len - 2.0, BAR_H), Color(COLORS[i % COLORS.size()], 0.8))
		var words := "%s %.1f" % [legs[i][0], km]
		if font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x > len - 6.0:
			words = "%.1f" % km   # a short leg: its number (the card says its name)
		draw_string(font, Vector2(x + 4.0, top + BAR_H + 22.0), words, HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			Color(1, 1, 1, 0.85))
		x += len
	var at := w * reach / full
	var ok := reach >= need()
	var mark := Color("5be37a") if ok else Color("ffb347")
	draw_rect(Rect2(at - 2.0, top - 8.0, 4.0, BAR_H + 16.0), mark)
	draw_string(font, Vector2(clampf(at - 90.0, 0.0, w - 200.0), 18.0), "Your rocket: %.1f km/s" % reach,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, mark)
