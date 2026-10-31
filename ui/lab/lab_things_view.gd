class_name LabThingsView
extends LabView
## Float or sink (LabTank) and magnetic or not (LabMagnet): the things as big buttons on the right (a tap drops one into
## the tank, or holds the magnet to it), the tank or the magnet on the left. A floater bobs at the surface and a sinker
## rests on the bottom; a magnetic thing jumps up and sticks under the magnet, the rest go into the "Did not stick" tray.
## Each moves there over a moment (drawn only: the model has already decided).

const AREA := Rect2(16, 14, 580, 312)
const TANK := Rect2(40, 50, 530, 262)
const WATER := 0.62
const MOVE := 0.7   # seconds a thing takes to get where it goes
const PICTURE := 62.0
const MAGNET_AT := Vector2(300, 64)
const MAGNET_SIZE := 170.0
const TRAY := Rect2(36, 250, 540, 70)

var thing_buttons: Array[Button] = []
var _moving := {}   # thing index -> 0..1 of its move


func _init(m: LabModel = null) -> void:
	super(m)
	var things := _things()
	var x0 := SIZE.x - 16 - (4 * THING_BUTTON.x + 3 * 8)
	for i in things.size():
		var b := thing_button(things[i], Vector2(x0 + (i % 4) * (THING_BUTTON.x + 8), 14 + (i / 4) * (THING_BUTTON.y + 12)))
		b.pressed.connect(_tap.bind(i))
		thing_buttons.append(b)
	refresh()


func _things() -> Array[Dictionary]:
	return (model as LabTank).things if model is LabTank else (model as LabMagnet).things


func _done_with(i: int) -> bool:
	return (model as LabTank).is_dropped(i) if model is LabTank else (model as LabMagnet).is_tested(i)


## Group of thing i: 0 floats / sticks, 1 sinks / does not.
func _group(i: int) -> int:
	return (0 if (model as LabTank).floats(i) else 1) if model is LabTank else (0 if (model as LabMagnet).sticks(i) else 1)


func _tap(i: int) -> void:
	if _done_with(i):
		return
	if model is LabTank:
		(model as LabTank).drop(i)
	else:
		(model as LabMagnet).test(i)
	_moving[i] = 0.0
	set_process(true)
	Audio.play(&"splash_small" if model is LabTank else &"ui_tick")
	tapped()


func refresh() -> void:
	var things := _things()
	for i in thing_buttons.size():
		var done := _done_with(i)
		var what := thing_buttons[i].find_child("What", true, false) as Label
		if done:
			if model is LabTank:
				what.text = "floats" if _group(i) == 0 else "sinks"
			else:
				what.text = "sticks" if _group(i) == 0 else "no pull"
		else:
			what.text = "tap me"
		thing_buttons[i].disabled = done
		thing_buttons[i].modulate = Color(1, 1, 1, 0.6) if done else Color.WHITE
		thing_buttons[i].tooltip_text = str(things[i].name)
	super.refresh()


func _process(delta: float) -> void:
	var busy := false
	for i: int in _moving:
		_moving[i] = minf(float(_moving[i]) + delta / MOVE, 1.0)
		busy = busy or float(_moving[i]) < 1.0
	queue_redraw()
	if not busy:
		set_process(false)


func _ready() -> void:
	set_process(false)


## Where thing i ends up, and where it starts its move.
func _spot(i: int) -> Array[Vector2]:
	var things := _things()
	var group := _group(i)
	var same: Array[int] = []
	for k in things.size():
		if _group(k) == group:
			same.append(k)
	var slot := same.find(i)
	if model is LabTank:
		var step := TANK.size.x / float(same.size() + 1)
		var x := TANK.position.x + step * (slot + 1)
		var surface := TANK.end.y - TANK.size.y * WATER
		var end := Vector2(x, surface - 4.0) if group == 0 else Vector2(x, TANK.end.y - PICTURE * 0.5 - 4.0)
		return [end, Vector2(x, TANK.position.y - 20.0)]
	var tips := [MAGNET_AT + Vector2(-MAGNET_SIZE * 0.4, MAGNET_SIZE * 0.5), MAGNET_AT + Vector2(MAGNET_SIZE * 0.4, MAGNET_SIZE * 0.5)]
	if group == 0:
		var row: float = (tips[0] as Vector2).y + PICTURE * 0.45   # hanging from the poles, in a row
		var spots := [Vector2((tips[0] as Vector2).x, row), Vector2((tips[1] as Vector2).x, row), Vector2(MAGNET_AT.x, row),
			Vector2((tips[0] as Vector2).x - 70, row), Vector2((tips[1] as Vector2).x + 70, row)]
		var end: Vector2 = spots[mini(slot, spots.size() - 1)]
		return [end, end + Vector2(0, 90)]
	var step2 := TRAY.size.x / float(same.size() + 1)
	var at := Vector2(TRAY.position.x + step2 * (slot + 1), TRAY.get_center().y + 4)
	return [at, Vector2(at.x, MAGNET_AT.y + MAGNET_SIZE * 0.7)]


func _draw() -> void:
	super._draw()
	var things := _things()
	if model is LabTank:
		LabArt.tank(self, TANK, WATER, false)
		text_at("The bench's water tank", Vector2(TANK.get_center().x, 30), 22, SOFT)
	else:
		text_at("Stuck to the magnet", Vector2(MAGNET_AT.x + 190, MAGNET_AT.y), 20, SOFT)
		draw_style_box(UiKit.box(Color(0.85, 0.78, 0.66, 0.6), 12, 0), TRAY)
		text_at("Did not stick", Vector2(TRAY.get_center().x, TRAY.position.y - 12), 20, SOFT)
		var tips := LabArt.magnet(self, MAGNET_AT, MAGNET_SIZE)
		var last_i := -1
		for i: int in _moving:
			last_i = i
		if last_i >= 0 and _group(last_i) == 0 and float(_moving[last_i]) >= 1.0:   # the pull, drawn as little arcs
			for t: Vector2 in tips:
				for k in 2:
					draw_arc(t + Vector2(0, 14 + 10 * k), 10 + 8 * k, 0.3, PI - 0.3, 8, Color(0.85, 0.3, 0.25, 0.7), 2.0)
	for i in things.size():
		if not _done_with(i):
			continue
		var s := _spot(i)
		var t := float(_moving.get(i, 1.0))
		var e := 1.0 - pow(1.0 - t, 3.0)
		var at: Vector2 = s[1].lerp(s[0], e)
		if model is LabTank and _group(i) == 0 and t >= 1.0:
			at.y += sin(Time.get_ticks_msec() / 400.0 + i) * 2.0   # bobbing
		var px := PICTURE if not (model is LabMagnet and _group(i) == 1) else 48.0
		LabThings.draw(self, str(things[i].thing), Rect2(at - Vector2(px, px) * 0.5, Vector2(px, px)))
	if model is LabTank:
		LabArt.tank_water(self, TANK, WATER)
