class_name OilWell
extends Node3D
## An oil well (spec §26.3), standing where a child's oil quest marked the dome's top: a derrick (the steel tower that
## drilled the well; real ones stand 30-60 m tall, this one 10) and a pump jack beside it (a "nodding donkey": a motor
## turns a crank, the crank rocks the walking beam, and its horse head lifts a rod up and down the well, pulling oil up).
## Clean and careful: no fire, no spill; a small sign says how deep the oil is. Walking up to it lets a child pump a drum
## (ProspectDirector). Cheap: four meshes of vertex-coloured boxes with the Theater's shared material (ProspectModels);
## only the beam and the crank move.

const PUMP_REACH := 4.0
const PUMP_HIGH := 4.0
const NOD_SPEED := 1.4            # the beam's rocking, radians a second of the crank
const NOD_ANGLE := 0.22
## The pump jack stands beside the derrick, its horse head over its own wellhead (an oil field has many wells).
const JACK_AT := Vector3(4.0, 0, 0)

var deposit_id := ""
var beam := Node3D.new()
var crank := Node3D.new()
var sign_label: Label3D
var _t := 0.0


## At `pos` (the dome's top, on the ground), the oil `depth_m` down.
func setup(id: String, pos: Vector3, depth_m: int) -> void:
	deposit_id = id
	name = "OilWell_" + id.replace(":", "_")
	position = pos
	_derrick()
	_pump_jack()
	sign_label = ProspectModels.label(self, "Oil well\n%s m deep" % ProspectQuests._thousands(depth_m),
		Vector3(1.8, 3.2, 1.4), 36)


## True when feet at `feet` stand close enough to the pump jack to pump a drum.
func near(feet: Vector3) -> bool:
	var jack := global_position + JACK_AT if is_inside_tree() else position + JACK_AT
	return feet.is_finite() and Vector2(jack.x - feet.x, jack.z - feet.z).length() <= PUMP_REACH \
		and absf(jack.y - feet.y) <= PUMP_HIGH


func _process(delta: float) -> void:
	_t += delta * NOD_SPEED
	crank.rotation.z = _t
	beam.rotation.z = sin(_t) * NOD_ANGLE


func _derrick() -> void:
	var steel := Color("8d9098")
	var tall := 10.0
	var boxes: Array = []
	for c: Vector2 in [Vector2(-1.2, -1.2), Vector2(1.2, -1.2), Vector2(-1.2, 1.2), Vector2(1.2, 1.2)]:
		boxes.append([Vector3(0.14, tall, 0.14), Vector3(c.x * 0.6, tall * 0.5, c.y * 0.6), steel,
			Vector3(-c.y * 0.055, 0, c.x * 0.055)])   # the legs, leaning in to the crown
	for y: float in [2.0, 4.5, 7.0]:
		var w := 2.4 - y * 0.2
		boxes.append([Vector3(w, 0.1, 0.1), Vector3(0, y, -w * 0.5), steel])
		boxes.append([Vector3(w, 0.1, 0.1), Vector3(0, y, w * 0.5), steel])
		boxes.append([Vector3(0.1, 0.1, w), Vector3(-w * 0.5, y, 0), steel])
		boxes.append([Vector3(0.1, 0.1, w), Vector3(w * 0.5, y, 0), steel])
	boxes.append([Vector3(0.9, 0.3, 0.9), Vector3(0, tall, 0), Color("f08a1c")])   # the crown block
	boxes.append([Vector3(2.8, 0.2, 2.8), Vector3(0, 0.1, 0), Color("6e6e6e")])   # its floor
	boxes.append([Vector3(0.3, 0.6, 0.3), Vector3(0, 0.4, 0), Color("3b404b")])   # the wellhead
	boxes.append([Vector3(0.36, 0.1, 0.36), Vector3(0, 0.74, 0), Color("2a7fd4")])   # its valve
	ProspectModels.add(self, boxes, "Derrick")


func _pump_jack() -> void:
	var jack := Node3D.new()
	jack.name = "PumpJack"
	jack.position = JACK_AT
	add_child(jack)
	ProspectModels.add(jack, [
		[Vector3(3.6, 0.3, 1.0), Vector3(0, 0.15, 0), Color("6e6e6e")],   # the base
		[Vector3(0.2, 1.8, 0.2), Vector3(0, 1.05, -0.3), Color("f08a1c")],   # the samson post
		[Vector3(0.2, 1.8, 0.2), Vector3(0, 1.05, 0.3), Color("f08a1c")],
		[Vector3(0.6, 0.5, 0.5), Vector3(1.6, 0.55, 0.0), Color("dfe5ec")],   # the motor
		[Vector3(0.3, 0.5, 0.3), Vector3(-1.9, 0.25, 0), Color("3b404b")],   # its wellhead
	], "Base")
	beam.position = Vector3(0, 1.95, 0)
	jack.add_child(beam)
	ProspectModels.add(beam, [
		[Vector3(3.4, 0.24, 0.24), Vector3(0, 0, 0), Color("139e9b")],   # the walking beam
		[Vector3(0.3, 0.9, 0.34), Vector3(-1.8, -0.2, 0), Color("139e9b")],   # the horse head
		[Vector3(0.04, 1.8, 0.04), Vector3(-1.9, -1.1, 0), Color("3b404b")],   # the rod down the well
	], "Beam")
	crank.position = Vector3(1.3, 0.8, 0)
	jack.add_child(crank)
	ProspectModels.add(crank, [[Vector3(1.0, 0.5, 0.18), Vector3(0.25, 0, 0), Color("3b404b")]], "Crank")   # the counterweight
