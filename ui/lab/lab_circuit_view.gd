class_name LabCircuitView
extends LabView
## A simple circuit (LabCircuit) on a wooden board: a battery, copper wires round one loop, a bulb (and a second one's
## holder), and a knife switch. A tap on the switch opens or closes it; a tap on a wire takes it out (a gap) or puts it
## back; ADD A BULB puts a second bulb in the loop. While the loop is closed little dots of electricity flow round it
## and the bulbs glow (two in one loop: more dimly).

const BOARD := Rect2(16, 14, 780, 312)
const TL := Vector2(110, 62)
const TR := Vector2(700, 62)
const BR := Vector2(700, 288)
const BL := Vector2(110, 288)
const BATTERY := Rect2(84, 128, 52, 112)
const BULB_1 := Vector2(330, 62)
const BULB_2 := Vector2(500, 62)
const BULB_R := 26.0
const SWITCH_A := Vector2(400, 288)
const SWITCH_B := Vector2(480, 288)
const WIRE := 8.0
## The wires a child may take out: [from, to] (the rest of the loop is fixed).
const WIRES := [[Vector2(110, 62), Vector2(304, 62)], [Vector2(700, 62), Vector2(700, 288)], [Vector2(480, 288), Vector2(700, 288)]]
## Their tap areas (at least 64 px each way).
const WIRE_TAPS := [Rect2(120, 28, 170, 68), Rect2(666, 92, 68, 170), Rect2(500, 254, 180, 68)]

var switch_button: Button
var wire_buttons: Array[Button] = []
var bulb_button: Button
var lit_label: Label
var _flow := 0.0


func _init(m: LabModel = null) -> void:
	super(m)
	var c := model as LabCircuit
	for i in c.wires.size():
		var r: Rect2 = WIRE_TAPS[i % WIRE_TAPS.size()]
		var b := _hotspot("Wire%d" % i, r)
		b.pressed.connect(_wire.bind(i))
		wire_buttons.append(b)
	switch_button = _hotspot("Switch", Rect2(SWITCH_A.x - 6, SWITCH_A.y - 44, SWITCH_B.x - SWITCH_A.x + 12, 80))
	switch_button.pressed.connect(_switch)
	lit_label = place_label("", 28, INK, Vector2(812, 40), 350)
	lit_label.name = "Light"
	place_label("Tap the switch or a wire.", 20, SOFT, Vector2(812, 150), 350)
	bulb_button = place_button("ADD A BULB", Color("f0a020"), Vector2(830, 226), Vector2(310, 84), 26)
	bulb_button.name = "Bulb"
	bulb_button.pressed.connect(_bulb)
	refresh()


## A see-through button over a part of the board (the switch, a wire).
func _hotspot(n: String, r: Rect2) -> Button:
	var b := Button.new()
	b.name = n
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.custom_minimum_size = r.size
	add_child(b)
	b.position = r.position
	b.size = r.size
	return b


func _switch() -> void:
	(model as LabCircuit).toggle_switch()
	Audio.play(&"ui_click")
	tapped()


func _wire(i: int) -> void:
	(model as LabCircuit).toggle_wire(i)
	Audio.play(&"ui_tick")
	tapped()


func _bulb() -> void:
	var c := model as LabCircuit
	if c.bulbs < c.max_bulbs:
		c.add_bulb()
	else:
		c.remove_bulb()
	Audio.play(&"ui_tick")
	tapped()


func refresh() -> void:
	var c := model as LabCircuit
	if c.lit():
		lit_label.text = "The bulb is lit!" if c.bulbs == 1 else "Both bulbs are lit, more dimly."
	else:
		lit_label.text = "No light: the loop has a gap." if c.switch_on or c.wires.has(false) else "No light: the switch is open."
	bulb_button.text = "ADD A BULB" if c.bulbs < c.max_bulbs else "ONE BULB"
	bulb_button.visible = c.max_bulbs > 1
	set_process(c.lit())
	super.refresh()


func _ready() -> void:
	set_process((model as LabCircuit).lit())


func _process(delta: float) -> void:
	_flow = fmod(_flow + delta * 90.0, 10000.0)
	queue_redraw()


func _draw() -> void:
	super._draw()
	var c := model as LabCircuit
	draw_style_box(UiKit.box(Color("d8b27a"), 16, 0), BOARD)
	for i in 5:   # the board's grain
		var y := BOARD.position.y + 30 + i * 60
		draw_line(Vector2(BOARD.position.x + 20, y), Vector2(BOARD.end.x - 20, y + 6), Color("c49a5c"), 2.0)
	# the fixed wires
	var fixed := [[TL, Vector2(110, BATTERY.position.y)], [Vector2(110, BATTERY.end.y), BL], [BL, SWITCH_A],
		[BULB_1 + Vector2(BULB_R, 0), BULB_2 - Vector2(BULB_R, 0)], [BULB_2 + Vector2(BULB_R, 0), TR], [Vector2(304, 62), BULB_1 - Vector2(BULB_R, 0)]]
	for f: Array in fixed:
		_wire_line(f[0], f[1], true)
	for i in c.wires.size():
		var w: Array = WIRES[i % WIRES.size()]
		if c.wires[i]:
			_wire_line(w[0], w[1], true)
		else:   # taken out: where it was, a dashed outline, and the wire lying beside the gap
			var a: Vector2 = w[0]
			var b: Vector2 = w[1]
			draw_dashed_line(a, b, Color(0.3, 0.2, 0.1, 0.5), 3.0, 10.0)
			var side := (b - a).orthogonal().normalized() * 26.0
			_wire_line(a.lerp(b, 0.2) + side, a.lerp(b, 0.8) + side * 1.3, true)
			for p: Vector2 in [a, b]:
				draw_circle(p, 7.0, LabArt.METAL_DARK)
	LabArt.battery(self, BATTERY)
	LabArt.switch(self, SWITCH_A, SWITCH_B, c.switch_on, 8.0)
	var glow := c.brightness()
	LabArt.bulb(self, BULB_1, BULB_R, glow)
	if c.bulbs >= 2:
		LabArt.bulb(self, BULB_2, BULB_R, glow)
	else:
		_wire_line(BULB_2 - Vector2(BULB_R, 0), BULB_2 + Vector2(BULB_R, 0), true)
		draw_circle(BULB_2 + Vector2(0, 22), 10.0, Color(0.5, 0.4, 0.3, 0.4))   # the empty holder
	if c.lit():   # electricity flowing round the loop, from the battery's + round to its −
		var path := PackedVector2Array([Vector2(110, BATTERY.position.y), TL, TR, BR, BL, Vector2(110, BATTERY.end.y)])
		var total := 0.0
		for k in range(1, path.size()):
			total += path[k - 1].distance_to(path[k])
		for d in range(0, int(total), 40):
			var at := _along(path, fmod(d + _flow, total))
			draw_circle(at, 4.0, Color(1.0, 0.95, 0.4))


func _wire_line(a: Vector2, b: Vector2, insulated: bool) -> void:
	draw_line(a, b, Color("b0412e") if insulated else LabArt.COPPER, WIRE)
	draw_line(a, b, Color(1, 1, 1, 0.25), WIRE * 0.3)


static func _along(path: PackedVector2Array, d: float) -> Vector2:
	var left := d
	for k in range(1, path.size()):
		var seg := path[k - 1].distance_to(path[k])
		if left <= seg:
			return path[k - 1].lerp(path[k], left / seg)
		left -= seg
	return path[path.size() - 1]
