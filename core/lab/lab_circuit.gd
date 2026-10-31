class_name LabCircuit
extends LabModel
## A simple circuit (spec §23.1): a battery, a switch, wires and a bulb on a small board, in one loop. The bulb lights
## only when the loop is closed (the switch closed and every wire in); a tap takes a wire out (a gap) or puts it back;
## a second bulb goes in the same loop (series): both light, each with a quarter of one bulb's power (the battery's
## push is shared: I = V / 2R, P = I²R). Done once the child lit it, saw a gap put it out and lit two bulbs.

var wires: Array[bool] = []   # each wire in place
var switch_on := false        # closed
var bulbs := 1
var max_bulbs := 2
var saw_lit := false
var saw_gap := false
var saw_two := false


func _init(s: Dictionary = {}) -> void:
	super(s)
	for i in clampi(int(s.get("wires", 3)), 1, 4):
		wires.append(true)
	max_bulbs = clampi(int(s.get("bulbs", 2)), 1, 2)


func toggle_switch() -> void:
	switch_on = not switch_on
	if lit():
		last = "The switch closes the loop: the bulb lights up!" if bulbs == 1 \
			else "The switch closes the loop: both bulbs light up, more dimly."
	elif switch_on:
		last = "The switch is closed, but a wire is out: there is still a gap."
	else:
		last = "The switch is open: a gap in the loop, so the light goes out." if saw_lit else "The switch is open."
	_look()


func toggle_wire(i: int) -> void:
	if i < 0 or i >= wires.size():
		return
	wires[i] = not wires[i]
	if not wires[i]:
		last = "You took a wire out: a gap in the loop!"
	elif lit():
		last = "The wire is back: the loop is closed and the light is on."
	else:
		last = "The wire is back in its place."
	_look()


func add_bulb() -> void:
	if bulbs >= max_bulbs:
		return
	bulbs += 1
	last = "A second bulb in the loop: both glow, more dimly." if lit() else "A second bulb goes in the loop."
	_look()


func remove_bulb() -> void:
	if bulbs <= 1:
		return
	bulbs -= 1
	last = "One bulb again: it glows brightly." if lit() else "One bulb again."
	_look()


func closed() -> bool:
	return switch_on and not wires.has(false)


func lit() -> bool:
	return closed()


## Each bulb's light, as a share of one bulb alone (0 when the loop is open).
func brightness() -> float:
	return 1.0 / float(bulbs * bulbs) if lit() else 0.0


func done() -> bool:
	return saw_lit and saw_gap and saw_two


func _look() -> void:
	if lit():
		saw_lit = true
		saw_two = saw_two or bulbs == 2
	elif saw_lit:
		saw_gap = true
