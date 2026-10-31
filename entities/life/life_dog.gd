class_name LifeDog
extends Node3D
## Owner #118 (docs/design/life-skills.md §14, the catalogue's row 8: animals; Life L3b): a friendly blocky dog for Safe
## with Animals, about knee high (a big shepherd dog at `size` 1.5). It faces +X. Its moods are its body language, the
## same signs the Dogs Trust and the Kennel Club teach: "relaxed" (a loose body, soft ears, a low gently wagging tail),
## "warning" (a stiff, still body, ears up, a hard stare, lips pulled back, the tail held high and stiff: never a bite,
## never a snarl's sound), "play" (the play bow: front legs down, bottom up, the tail up and wagging), "sleep" (lying, eyes
## shut), "sniff" (the head down and forward), "uneasy" (the head turned away, ears back: being hugged). Marks follow
## the body: body, eyes, lips, tail, side, head, neck, nose.

const COAT := Color("c98a4a")
const EYES := Color("1f2a4a")
const MOODS: Array[String] = ["relaxed", "warning", "play", "sleep", "sniff", "uneasy"]

var coat := COAT
var mood := "relaxed"
var body := Node3D.new()
var head := Node3D.new()
var tail := Node3D.new()
var ears: Array[Node3D] = []
var legs: Array[Node3D] = []
var lips: MeshInstance3D
var brow: MeshInstance3D
var marks := {}
var wag := 0.0   # the tail's wag (rad), the room moves it by its own time


func _init(colour: Color = COAT, dog_name: String = "Dog", size: float = 1.0) -> void:
	coat = colour
	name = dog_name
	scale = Vector3.ONE * size
	body.name = "Body"
	body.position = Vector3(0, 0.32, 0)
	add_child(body)
	LifeRoomKit.box(body, "Torso", Vector3(0.5, 0.2, 0.22), Vector3.ZERO, coat)
	head.name = "Head"
	head.position = Vector3(0.3, 0.12, 0)
	body.add_child(head)
	LifeRoomKit.box(head, "Skull", Vector3(0.18, 0.17, 0.17), Vector3(0.02, 0.04, 0), coat.lightened(0.1))
	LifeRoomKit.box(head, "Muzzle", Vector3(0.1, 0.08, 0.1), Vector3(0.13, 0.0, 0), coat.lightened(0.2))
	LifeRoomKit.box(head, "Nose", Vector3(0.03, 0.03, 0.04), Vector3(0.19, 0.03, 0), EYES)
	for z: float in [-0.045, 0.045]:
		LifeRoomKit.box(head, "Eye", Vector3(0.02, 0.025, 0.02), Vector3(0.11, 0.08, z), EYES)
	brow = LifeRoomKit.box(head, "Brow", Vector3(0.02, 0.012, 0.13), Vector3(0.115, 0.105, 0), EYES)
	brow.visible = false
	lips = LifeRoomKit.box(head, "Teeth", Vector3(0.02, 0.012, 0.07), Vector3(0.18, -0.03, 0), Color("fdfdf8"))
	lips.visible = false   # lips pulled back: a small white line, shown only as a warning sign
	for z: float in [-0.07, 0.07]:
		var ear := Node3D.new()
		ear.name = "Ear"
		ear.position = Vector3(-0.02, 0.12, z)
		head.add_child(ear)
		LifeRoomKit.box(ear, "Flap", Vector3(0.05, 0.1, 0.03), Vector3(0, -0.04, 0), coat.darkened(0.2))
		ears.append(ear)
	tail.name = "Tail"
	tail.position = Vector3(-0.25, 0.05, 0)
	body.add_child(tail)
	LifeRoomKit.box(tail, "Tail", Vector3(0.04, 0.2, 0.04), Vector3(0, 0.09, 0), coat.darkened(0.15))
	for x: float in [-0.18, 0.18]:
		for z: float in [-0.07, 0.07]:
			var leg := Node3D.new()
			leg.name = "Leg"
			leg.position = Vector3(x, -0.1, z)
			body.add_child(leg)
			LifeRoomKit.box(leg, "Leg", Vector3(0.06, 0.22, 0.06), Vector3(0, -0.11, 0), coat.darkened(0.1))
			legs.append(leg)
	for m: Array in [["body", body, Vector3(0, 0.02, 0.12)], ["eyes", head, Vector3(0.12, 0.08, 0.06)],
			["lips", head, Vector3(0.19, -0.03, 0.06)], ["tail", tail, Vector3(0, 0.17, 0.03)], ["side", body, Vector3(-0.05, 0.05, 0.12)],
			["head", head, Vector3(0.02, 0.13, 0)], ["neck", body, Vector3(0.22, 0.1, 0.1)], ["nose", head, Vector3(0.2, 0.02, 0)]]:
		var n := Node3D.new()
		n.name = "Mark_" + str(m[0])
		n.position = m[2]
		(m[1] as Node3D).add_child(n)
		marks[str(m[0])] = n
	set_mood("relaxed")


func mark(mark_name: String) -> Node3D:
	return marks.get(mark_name)


func set_mood(which: String) -> void:
	if not MOODS.has(which):
		return
	mood = which
	body.rotation = Vector3.ZERO
	body.position = Vector3(0, 0.32, 0)
	head.rotation = Vector3.ZERO
	tail.rotation = Vector3.ZERO
	lips.visible = false
	brow.visible = false
	for e in ears:
		e.rotation = Vector3.ZERO
	for l in legs:
		l.rotation = Vector3.ZERO
		l.visible = true
	for e: Node in head.find_children("Eye", "MeshInstance3D", false, false):
		(e as Node3D).scale = Vector3.ONE
	match which:
		"relaxed":
			tail.rotation.z = 0.9   # low and loose
			for e in ears:
				e.rotation.z = -0.4   # soft
		"warning":
			tail.rotation.z = -0.25   # high and stiff
			for e in ears:
				e.rotation.z = 0.25   # up, forward
			lips.visible = true
			brow.visible = true   # a hard stare
			head.rotation.z = -0.08
		"play":
			body.rotation.z = -0.35   # front down, bottom up
			body.position.y = 0.27
			tail.rotation.z = -0.5
		"sleep":
			body.position.y = 0.13
			for l in legs:
				l.visible = false
			for e: Node in head.find_children("Eye", "MeshInstance3D", false, false):
				(e as Node3D).scale = Vector3(1, 0.25, 1)
			head.rotation.z = -0.25
			tail.rotation.z = 1.4
		"sniff":
			head.rotation.z = -0.45
			tail.rotation.z = 0.7
		"uneasy":
			head.rotation.y = 0.8   # turned away
			for e in ears:
				e.rotation.z = -1.0   # flat back
			tail.rotation.z = 1.3


## The tail's gentle wag (relaxed and playing only), by the room's own time.
func wag_tail(t: float) -> void:
	if mood in ["relaxed", "play"]:
		tail.rotation.x = 0.35 * sin(t * 7.0)
