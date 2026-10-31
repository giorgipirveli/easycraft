class_name ToolProp
extends Node3D
## Owner #116, #117 (docs/design/life-skills.md §13, "Tools: a hand's motion, recognised"): a tool in a practice room. In
## VR a hand takes it (VR-HANDS' shared grab: a VrGrabbable of kind &"tool", near or by the laser's pull) and uses it on
## the work; let go, it goes back to its place (never thrown, never lost). Off VR it lies on the bench and the flat tool
## tray picks it. Its model is ToolModels' at true size; its tips are where it works, per motion (ToolSample's tip).

signal taken(side: StringName)
signal put_down

const RADIUS := 0.12

var tool_id := ""
var tips := {}
var grabbable: VrGrabbable
## Where it lies when nobody holds it (in its parent's space).
var rest := Transform3D.IDENTITY
var model: Node3D


func _init(id: String = "") -> void:
	tool_id = id
	name = "Tool_" + id
	var built := ToolModels.build(id)
	model = built.model
	add_child(model)
	for m: String in built.tips:
		var tip := Node3D.new()
		tip.name = "Tip_" + m
		tip.transform = built.tips[m]
		add_child(tip)
		tips[m] = tip
	grabbable = VrGrabbable.new()
	grabbable.name = "VrGrabbable"
	grabbable.kind = &"tool"
	grabbable.throwable = false
	grabbable.far_pull = true
	grabbable.radius = RADIUS
	add_child(grabbable)
	grabbable.grabbed.connect(func(side: StringName) -> void: taken.emit(side))
	grabbable.released.connect(func(_side: StringName, _v: Vector3) -> void: go_back())


func _ready() -> void:
	rest = transform


## The tip it works with for a motion (global), its first tip for another.
func tip(motion: String) -> Transform3D:
	var n: Node3D = tips.get(motion, null)
	if n == null and not tips.is_empty():
		n = tips.values()[0]
	return n.global_transform if n != null else global_transform


func has_motion(motion: String) -> bool:
	return tips.has(motion)


func held() -> bool:
	return grabbable.held_by() != &""


## Back to its place on the bench.
func go_back() -> void:
	transform = rest
	put_down.emit()


func _process(_delta: float) -> void:
	# a plumb line's string and weight always hang straight down, whatever the hand does
	for c: Node in model.get_children():
		if c is Node3D and (c as Node3D).has_meta(&"hangs"):
			var n := c as Node3D
			var top := model.global_position
			var drop := 0.3 if n.name == "String" else 0.62
			n.global_transform = Transform3D(Basis(), top + Vector3(0, -drop, 0))
