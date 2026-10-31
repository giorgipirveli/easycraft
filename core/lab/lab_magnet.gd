class_name LabMagnet
extends LabModel
## Magnetic or not (spec §23.1): a tap holds the magnet to a thing, once; a magnetic one jumps and sticks, the rest stay
## where they are (the content test checks each against the metals a magnet pulls). Done when every thing was tried.

var things: Array[Dictionary] = []
var tested: Array[bool] = []


func _init(s: Dictionary = {}) -> void:
	super(s)
	for t: Variant in s.get("things", []):
		if t is Dictionary:
			things.append(t)
			tested.append(false)


func test(i: int) -> void:
	if i < 0 or i >= things.size() or tested[i]:
		return
	tested[i] = true
	last = LabModel.sentence(LabModel.the(str(things[i].name))
		+ (" jumps and sticks!" if sticks(i) else " does not stick."))


func is_tested(i: int) -> bool:
	return i >= 0 and i < tested.size() and tested[i]


func sticks(i: int) -> bool:
	return bool(things[i].get("magnetic", false))


func done() -> bool:
	return not tested.is_empty() and not tested.has(false)


## Each thing as it went: 0 sticks, 1 does not, -1 not tried yet.
func sorted() -> Array[int]:
	var out: Array[int] = []
	for i in things.size():
		out.append(-1 if not tested[i] else (0 if sticks(i) else 1))
	return out
