class_name OnlineDot
extends Control
## A friend's online dot (M4 Wave 1, Agent C): a filled green dot with a white ring when online, an
## empty grey ring when away, so the shape tells it too, never the colour alone (spec §5.15).
##
## On the HUD it follows `source` (() -> bool), asked once a second: visible only while this game
## is online. Tests call refresh().

signal changed(on: bool)

const GREEN := Color("35d05a")
const GREY := Color(0.7, 0.72, 0.78)
const POLL_SECONDS := 1.0

var on := false:
	set(v):
		if on != v:
			on = v
			queue_redraw()
			changed.emit(v)
## When set, the dot shows only while source.call() is true (the HUD's).
var source := Callable()

var _timer: Timer


func _init(is_on: bool = false) -> void:
	on = is_on
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(28, 28)


func _ready() -> void:
	if source.is_valid():
		_timer = Timer.new()
		_timer.wait_time = POLL_SECONDS
		_timer.autostart = true
		_timer.timeout.connect(refresh)
		add_child(_timer)
		refresh()


## Follows the source now.
func refresh() -> void:
	if source.is_valid():
		on = bool(source.call())
		visible = on


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var c := size * 0.5
	if on:
		draw_circle(c, r, Color.WHITE)
		draw_circle(c, r * 0.72, GREEN)
	else:
		draw_arc(c, r * 0.8, 0, TAU, 32, GREY, maxf(2.0, r * 0.25), true)
