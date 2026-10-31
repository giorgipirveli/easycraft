class_name LabHeatView
extends LabView
## Melting and freezing (LabHeat): a beaker on a lab burner (its blue flame while WARM heats it) or standing in an ice
## bath (after COOL), a big thermometer in °C with the melting and boiling points marked once seen, the temperature in
## big numbers and what is in the beaker in words, and the WARM and COOL buttons.

const BEAKER := Rect2(150, 34, 170, 184)
const THERMOMETER := Rect2(440, 18, 96, 300)

var warm_button: Button
var cool_button: Button
var state_label: Label
var _tapped_once := false


func _init(m: LabModel = null) -> void:
	super(m)
	state_label = place_label("", 28, INK, Vector2(620, 104), 540)
	state_label.name = "State"
	warm_button = place_button("WARM", Color("f08a1c"), Vector2(640, 196), Vector2(250, 100), 32)
	warm_button.name = "Warm"
	warm_button.pressed.connect(_tap.bind(true))
	cool_button = place_button("COOL", Color("3a7be8"), Vector2(910, 196), Vector2(250, 100), 32)
	cool_button.name = "Cool"
	cool_button.pressed.connect(_tap.bind(false))
	refresh()


func _tap(warm: bool) -> void:
	var h := model as LabHeat
	_tapped_once = true
	if warm:
		h.warm()
	else:
		h.cool()
	Audio.play(&"ui_tick")
	tapped()


func refresh() -> void:
	var h := model as LabHeat
	state_label.text = "%s at %s" % [h.state_words(), LabHeat.degrees(h.temp)]
	super.refresh()


func _draw() -> void:
	super._draw()
	var h := model as LabHeat
	var flame := h.warming
	LabArt.burner(self, Vector2(BEAKER.get_center().x, BEAKER.end.y + 72), 78.0, flame)   # the flame's tip under the ring
	# the stand: a metal ring and legs holding the beaker over the burner
	draw_line(Vector2(BEAKER.position.x - 20, BEAKER.end.y + 4), Vector2(BEAKER.end.x + 20, BEAKER.end.y + 4), LabArt.METAL_DARK, 6)
	for x: float in [BEAKER.position.x - 14, BEAKER.end.x + 14]:
		draw_line(Vector2(x, BEAKER.end.y + 4), Vector2(x + (x - BEAKER.get_center().x) * 0.2, SIZE.y - 14), LabArt.METAL_DARK, 5)
	LabArt.beaker(self, BEAKER, h.ice, h.boiling)
	if _tapped_once and not flame:   # the ice bath: ice with salt round the beaker's foot
		var bath := Rect2(BEAKER.position.x - 30, BEAKER.end.y - 70, BEAKER.size.x + 60, 80)
		draw_style_box(UiKit.box(Color(0.75, 0.9, 1.0, 0.75), 16, 0), bath)
		for i in 6:
			var at := bath.position + Vector2(14 + i * (bath.size.x - 40) / 5.0, 10 + (i % 2) * 22)
			draw_rect(Rect2(at, Vector2(22, 22)), Color("eafaff"))
			draw_rect(Rect2(at, Vector2(22, 22)), Color("7cc3e3"), false, 2.0)
		text_at("ice bath", bath.get_center() + Vector2(0, 26), 18, SOFT)
	LabArt.thermometer(self, THERMOMETER, h.temp, h.low, h.boil + 10, true)
	var y_of := func(t: int) -> float:
		var tube_h := THERMOMETER.size.y * 0.86
		return THERMOMETER.position.y + tube_h - float(t - h.low) / float(h.boil + 10 - h.low) * tube_h * 0.94
	if h.saw_melt:
		text_at("melts", Vector2(THERMOMETER.position.x - 36, y_of.call(h.melt)), 20, Color("2f7dc0"))
	if h.saw_boil:
		text_at("boils", Vector2(THERMOMETER.position.x - 36, y_of.call(h.boil)), 20, Color("c0392b"))
	text_at(LabHeat.degrees(h.temp), Vector2(890, 58), 58, INK)
