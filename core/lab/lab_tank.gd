class_name LabTank
extends LabModel
## Float or sink (spec §23.1): the bench's water tank. A tap drops a thing in, once; it floats or sinks as its data says
## (the content test checks each against its density). Done when every thing is in the tank.

var things: Array[Dictionary] = []
var dropped: Array[bool] = []


func _init(s: Dictionary = {}) -> void:
	super(s)
	for t: Variant in s.get("things", []):
		if t is Dictionary:
			things.append(t)
			dropped.append(false)


func drop(i: int) -> void:
	if i < 0 or i >= things.size() or dropped[i]:
		return
	dropped[i] = true
	last = LabModel.sentence(LabModel.the(str(things[i].name)) + (" floats!" if floats(i) else " sinks!"))


func is_dropped(i: int) -> bool:
	return i >= 0 and i < dropped.size() and dropped[i]


func floats(i: int) -> bool:
	return bool(things[i].get("floats", false))


func done() -> bool:
	return not dropped.is_empty() and not dropped.has(false)


## Each thing as it went: 0 floats, 1 sinks, -1 not dropped yet (the prediction's sort compares with it).
func sorted() -> Array[int]:
	var out: Array[int] = []
	for i in things.size():
		out.append(-1 if not dropped[i] else (0 if floats(i) else 1))
	return out
