class_name LifeDummy
extends Node3D
## Owner #112 (docs/design/life-skills.md §5 #1, §6): Max, the CPR training dummy: a friendly practice mannequin (a torso
## and a head, lying face up along -X), clearly a training tool. Its chest goes down a little on each push and comes
## back up. Marks: shoulders, face, chest.

const BODY := Color("e5e9f0")
const FACE := Color("f6f2ea")
const VEST := Color("3a7be8")

var chest: Node3D
var marks := {}


func _init() -> void:
	name = "Max"
	LifeRoomKit.box(self, "Torso", Vector3(0.6, 0.18, 0.4), Vector3(0, 0.09, 0), BODY)
	chest = Node3D.new()
	chest.name = "Chest"
	chest.position = Vector3(-0.08, 0.18, 0)
	add_child(chest)
	LifeRoomKit.box(chest, "Vest", Vector3(0.26, 0.03, 0.3), Vector3(0, 0.015, 0), VEST)
	LifeRoomKit.box(chest, "HandMark", Vector3(0.08, 0.035, 0.08), Vector3(0, 0.02, 0), Color("ffd23f"))
	LifeRoomKit.box(self, "Neck", Vector3(0.08, 0.1, 0.12), Vector3(-0.34, 0.09, 0), FACE)
	LifeRoomKit.box(self, "Head", Vector3(0.22, 0.2, 0.2), Vector3(-0.48, 0.1, 0), FACE)
	for z: float in [-0.05, 0.05]:
		LifeRoomKit.box(self, "Eye", Vector3(0.03, 0.02, 0.025), Vector3(-0.48, 0.205, z), Color("6b7a99"))
	_mark("shoulders", Vector3(-0.22, 0.2, 0))
	_mark("face", Vector3(-0.5, 0.22, 0))
	_mark("chest", Vector3(-0.08, 0.22, 0))
	_mark("aed_spot", Vector3(0.1, 0.0, 0.42))


func _mark(mark_name: String, at: Vector3) -> void:
	var n := Node3D.new()
	n.name = "Mark_" + mark_name
	n.position = at
	add_child(n)
	marks[mark_name] = n


func mark(mark_name: String) -> Node3D:
	return marks.get(mark_name)


## One push: the chest goes down and comes back up.
func push() -> void:
	if not is_inside_tree() or UiMotion.calm():
		return
	var tw := create_tween()
	tw.tween_property(chest, "position:y", 0.15, 0.12)
	tw.tween_property(chest, "position:y", 0.18, 0.16)
