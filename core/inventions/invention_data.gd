class_name InventionData
extends RefCounted
## The inventions' part of the profile (owner #78, spec §21e; ProfileData.inventions): what this child invented, in the
## order made (InventionLine ids), the "try it" moments already paid, and the flying machine picked for Survivor ("":
## the newest one invented). Account-wide (an invention is knowledge: it goes into every world), parsed field by field,
## kept by the server backup (merge_from never loses an invention or a paid "try it").

var invented: Array[StringName] = []
var tried: Array[StringName] = []
## The machine picked in the Inventions book for Survivor's flying (an InventionLine id of a flyer, or "").
var craft: StringName = &""


## Every invention of the line up to `last` (tests and smoke runs: a child who invented that far).
static func invented_to(last: StringName) -> InventionData:
	var d := InventionData.new()
	for id in InventionLine.ORDER:
		d.add(id)
		if id == last:
			break
	return d


func is_empty() -> bool:
	return invented.is_empty() and tried.is_empty()


func has(id: StringName) -> bool:
	return invented.has(id)


## Invented now: true the first time (only the line's inventions).
func add(id: StringName) -> bool:
	if not InventionLine.has(id) or invented.has(id):
		return false
	invented.append(id)
	return true


func was_tried(id: StringName) -> bool:
	return tried.has(id)


## Its "try it" was done (and paid): true the first time.
func mark_tried(id: StringName) -> bool:
	if not InventionLine.has(id) or tried.has(id):
		return false
	tried.append(id)
	return true


func to_dict() -> Dictionary:
	var inv: Array[String] = []
	for id in invented:
		inv.append(String(id))
	var tr: Array[String] = []
	for id in tried:
		tr.append(String(id))
	return {"invented": inv, "tried": tr, "craft": String(craft)}


static func from_dict(v: Variant) -> InventionData:
	var d := InventionData.new()
	if not v is Dictionary:
		return d
	var inv: Variant = (v as Dictionary).get("invented")
	if inv is Array:
		for id: Variant in inv:
			if id is String:
				d.add(StringName(id))
	var tr: Variant = (v as Dictionary).get("tried")
	if tr is Array:
		for id: Variant in tr:
			if id is String:
				d.mark_tried(StringName(id))
	var c: Variant = (v as Dictionary).get("craft")
	if c is String and d.has(StringName(c)) and FlightCrafts.of_invention(StringName(c)) != FlightCrafts.Craft.NONE:
		d.craft = StringName(c)
	return d


## Keeps the best of both copies: every invention (in this copy's order, then the other's), every paid "try it".
func merge_from(other: InventionData) -> void:
	for id in other.invented:
		add(id)
	for id in other.tried:
		mark_tried(id)
	if craft == &"" and other.craft != &"":
		craft = other.craft
