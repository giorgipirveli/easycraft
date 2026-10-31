class_name BottleRocket
extends VBoxContainer
## Owner #78 (spec §21e): the rocket's "try it" in the Inventions book: a bottle rocket (a plastic bottle a third full
## of water, upside down on a pad). PUMP pushes air in (the gauge fills; only as much as is safe: InventionTry's
## BOTTLE_MAX_PUMPS); LAUNCH lets go: the air pushes the water down, the water pushes the bottle up, and it flies as
## high as the air pushed (a height ruler shows the metres). The book's director scores the flight (`launch`).

signal back_pressed

const STAGE := Vector2(560, 260)
const TOP_METRES := 50.0
const FLIGHT_TIME := 2.4

## (pumps) -> float: the flight's height in metres (the director's InventionTry; the book's own rule until set).
var launch: Callable = func(pumps: int) -> float: return InventionTry.bottle_height(pumps)
var pumps := 0
var height := 0.0

var pump_button := BookKit.button("PUMP", Vector2(200, 72))
var launch_button := BookKit.button("LAUNCH!", Vector2(220, 72))
var back_button := BookKit.button("BACK", Vector2(160, 72))
var words_label := BookKit.label("", 22)

var _stage := Control.new()
var _fly_t := -1.0


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	alignment = BoxContainer.ALIGNMENT_CENTER
	var title := BookKit.label("Try it: a bottle rocket", 30, BookKit.TITLE_INK)
	add_child(title)
	_stage.custom_minimum_size = STAGE
	_stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.draw.connect(_draw_stage)
	add_child(_stage)
	words_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words_label.custom_minimum_size.x = STAGE.x + 200
	add_child(words_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.add_child(pump_button)
	row.add_child(launch_button)
	row.add_child(back_button)
	add_child(row)
	pump_button.pressed.connect(func() -> void: pump())
	launch_button.pressed.connect(func() -> void: fire())
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	back_button.set_meta(&"pad_back", true)
	reset()


func reset() -> void:
	pumps = 0
	height = 0.0
	_fly_t = -1.0
	_say("Pump air into the bottle, then LAUNCH. How high will it go?")


## One more pump of air (false when the bottle holds as much as is safe).
func pump() -> bool:
	if _fly_t >= 0.0:
		return false
	if pumps >= InventionTry.BOTTLE_MAX_PUMPS:
		_say("That's enough air! Real bottle rockets are pumped only as much as is safe, with a grown-up.")
		return false
	pumps += 1
	Audio.play(&"ui_tick")
	_say("Pumps: %d of %d. The air inside pushes harder with every pump." % [pumps, InventionTry.BOTTLE_MAX_PUMPS])
	_stage.queue_redraw()
	return true


## Lets go: the flight's height (m).
func fire() -> float:
	if _fly_t >= 0.0:
		return height
	height = float(launch.call(pumps))
	if height <= 0.0:
		_say("No air, no push: pump some air in first!")
		return 0.0
	_fly_t = 0.0
	Audio.play(&"splash_small")
	Audio.play(&"whoosh")
	var goal := height >= InventionTry.BOTTLE_GOAL
	_say(("It flew %d metres! " % roundi(height)) + ("The air pushed the water down, and the water pushed the bottle up."
		if goal else "Pump more air in: a harder push down sends it higher. Try for 30 metres!"))
	return height


func words() -> String:
	return words_label.text


func flying() -> bool:
	return _fly_t >= 0.0


func _process(delta: float) -> void:
	if _fly_t < 0.0:
		return
	_fly_t += delta
	if _fly_t >= FLIGHT_TIME:
		_fly_t = -1.0
		pumps = 0
	_stage.queue_redraw()


func _say(text: String) -> void:
	words_label.text = text


func _draw_stage() -> void:
	var r := Rect2(Vector2.ZERO, _stage.size)
	_stage.draw_rect(r, Color("bfe6ff"), true)
	var ground := r.size.y - 36.0
	_stage.draw_rect(Rect2(0, ground, r.size.x, 36), Color("7cc36b"), true)
	var per_metre := (ground - 20.0) / TOP_METRES
	for m in range(0, int(TOP_METRES) + 1, 10):   # the ruler
		var y := ground - m * per_metre
		_stage.draw_line(Vector2(0, y), Vector2(40, y), BookKit.INK, 2.0)
		_stage.draw_string(get_theme_default_font(), Vector2(46, y + 7), "%d m" % m, HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
			BookKit.INK)
	var goal_y := ground - InventionTry.BOTTLE_GOAL * per_metre
	_stage.draw_dashed_line(Vector2(110, goal_y), Vector2(r.size.x - 10, goal_y), Color("e8403a"), 2.0, 10.0)
	var x := r.size.x * 0.55
	_stage.draw_rect(Rect2(x - 40, ground - 10, 80, 10), Color("4a4f5a"), true)   # the pad
	var up := 0.0
	if _fly_t >= 0.0:
		up = height * sin(PI * clampf(_fly_t / FLIGHT_TIME, 0.0, 1.0)) * per_metre
		if _fly_t < 0.6:   # the water rushing down
			for k in 6:
				var sx := x + (k - 2.5) * 6.0
				_stage.draw_line(Vector2(sx, ground - 10 - up), Vector2(sx + (k - 2.5) * 3.0, ground), Color("4d96ff"), 3.0)
	var base := ground - 10.0 - up
	_stage.draw_rect(Rect2(x - 14, base - 70, 28, 70), Color(1, 1, 1, 0.9), true)   # the bottle, upside down
	_stage.draw_colored_polygon(PackedVector2Array([Vector2(x - 14, base - 70), Vector2(x + 14, base - 70),
		Vector2(x, base - 92)]), Color("e8403a"))   # its nose cone
	if _fly_t < 0.0:
		_stage.draw_rect(Rect2(x - 14, base - 24, 28, 24), Color("4d96ff"), true)   # a third full of water
	for side: float in [-1.0, 1.0]:
		_stage.draw_colored_polygon(PackedVector2Array([Vector2(x + 14 * side, base - 22), Vector2(x + 28 * side, base),
			Vector2(x + 14 * side, base)]), Color("1fb5a8"))   # fins
	var gauge := Rect2(r.size.x - 70, 30, 28, ground - 60)   # the pump's gauge
	_stage.draw_rect(gauge, Color(1, 1, 1, 0.8), true)
	var fill := gauge.size.y * pumps / float(InventionTry.BOTTLE_MAX_PUMPS)
	_stage.draw_rect(Rect2(gauge.position.x, gauge.end.y - fill, gauge.size.x, fill), Color("ffb02e"), true)
	_stage.draw_rect(gauge, BookKit.INK, false, 2.0)
