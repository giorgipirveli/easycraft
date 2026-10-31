class_name SuccessCast
extends RefCounted
## Owner #115 (Success S2): the people of the practice rooms as Life's friendly blocky buddies (LifeBuddy), dressed from
## data/success/people.json (SuccessPeople: their colour and "look": a baker's hat, a straw hat, a hard hat, glasses, a
## white beard, a wheelchair...), their faces in the village's many skin tones (SuccessIcons.SKINS), and their name
## over their head (a billboard sign, readable in VR). Every part is a LifeRoomKit box, cylinder or sphere: only shaders
## the game already warms. Robo is the robot buddy who does EXACTLY what the child says.

const SIGN_PIXEL := 0.0032


## A person of the book, standing at `at` and facing `yaw` (0: towards +Z, where the child usually stands).
static func person(id: String, at: Vector3, yaw: float = 0.0, with_name: bool = true) -> LifeBuddy:
	var data := SuccessPeople.person(id)
	var b := LifeBuddy.new(Color(str(data.get("colour", "1fa6a0"))), id.capitalize())
	b.position = at
	b.rotation.y = yaw
	var skin: Color = SuccessIcons.SKINS.get(id, LifeBuddy.SKIN)
	var face := b.head.get_node_or_null("Face") as MeshInstance3D
	if face:
		face.material_override = LifeRoomKit.material(skin)
	for paw: Node in b.find_children("Paw", "MeshInstance3D", true, false):
		(paw as MeshInstance3D).material_override = LifeRoomKit.material(skin)
	dress(b, str(data.get("look", "plain")), Color(str(data.get("colour", "1fa6a0"))))
	if with_name:
		var n := LifeRoomKit.sign(b, "Name", str(data.get("name", id)).to_upper(), Vector3(0, 1.32, 0), SIGN_PIXEL)
		n.modulate = Color("fff6d8")
	return b


## Clothes and things for a look (on the head unless said).
static func dress(b: LifeBuddy, look: String, colour: Color) -> void:
	var h := b.head
	match look:
		"chef_hat":
			LifeRoomKit.cylinder(h, "ChefHat", 0.13, 0.2, Vector3(0, 0.41, 0), Color.WHITE)
		"flat_cap":
			LifeRoomKit.box(h, "Cap", Vector3(0.34, 0.06, 0.34), Vector3(0, 0.33, 0), Color("6b5a44"))
			LifeRoomKit.box(h, "Peak", Vector3(0.3, 0.03, 0.12), Vector3(0, 0.31, 0.2), Color("5a4a36"))
		"straw_hat":
			LifeRoomKit.cylinder(h, "Brim", 0.3, 0.03, Vector3(0, 0.32, 0), Color("e6c35a"))
			LifeRoomKit.cylinder(h, "Crown", 0.15, 0.12, Vector3(0, 0.39, 0), Color("e6c35a"))
		"goggles":
			for x: float in [-0.07, 0.07]:
				LifeRoomKit.box(h, "Goggle", Vector3(0.08, 0.06, 0.03), Vector3(x, 0.27, 0.16), Color("9fd8ff"))
		"hard_hat":
			LifeRoomKit.cylinder(h, "HardHat", 0.18, 0.1, Vector3(0, 0.36, 0), Color("ffc93c"))
		"glasses":
			for x: float in [-0.07, 0.07]:
				LifeRoomKit.box(h, "Glasses", Vector3(0.08, 0.05, 0.02), Vector3(x, 0.19, 0.166), Color("1f2a4a"))
		"beard":
			LifeRoomKit.box(h, "Beard", Vector3(0.26, 0.12, 0.04), Vector3(0, 0.06, 0.16), Color("e8e8e8"))
			LifeRoomKit.box(h, "Hair", Vector3(0.34, 0.05, 0.32), Vector3(0, 0.33, 0), Color("dcdcdc"))
		"bow":
			LifeRoomKit.box(h, "Bow", Vector3(0.16, 0.07, 0.05), Vector3(0.09, 0.34, 0.05), Color("f39ac0"))
		"pencil":
			LifeRoomKit.box(h, "Pencil", Vector3(0.02, 0.02, 0.16), Vector3(0.17, 0.2, 0.02), Color("ffc93c"))
		"explorer_hat":
			LifeRoomKit.cylinder(h, "Brim", 0.24, 0.025, Vector3(0, 0.32, 0), Color("c2a878"))
			LifeRoomKit.cylinder(h, "Crown", 0.15, 0.1, Vector3(0, 0.38, 0), Color("c2a878"))
		"headscarf":
			LifeRoomKit.box(h, "Scarf", Vector3(0.36, 0.2, 0.34), Vector3(0, 0.26, -0.01), colour.darkened(0.15))
		"bun":
			LifeRoomKit.sphere(h, "Bun", 0.08, Vector3(0, 0.36, -0.04), Color("3b2a18"))
		"suit":
			LifeRoomKit.box(b.hips, "Tie", Vector3(0.05, 0.22, 0.02), Vector3(0, 0.26, 0.115), Color("e8544e"))
		"wheelchair":
			wheelchair(b)


## A wheelchair: the person sits, with two big wheels and a seat (Omar's: his hands are the steadiest in the village).
static func wheelchair(b: LifeBuddy) -> void:
	b.pose("sit")
	var chair := Node3D.new()
	chair.name = "Wheelchair"
	b.add_child(chair)
	LifeRoomKit.box(chair, "Seat", Vector3(0.44, 0.06, 0.4), Vector3(0, 0.42, 0.02), Color("3b3f4a"))
	LifeRoomKit.box(chair, "Back", Vector3(0.44, 0.4, 0.05), Vector3(0, 0.62, -0.18), Color("3b3f4a"))
	for x: float in [-0.25, 0.25]:
		var w := LifeRoomKit.cylinder(chair, "Wheel", 0.24, 0.04, Vector3(x, 0.26, 0.0), Color("1f2a4a"))
		w.rotation.z = PI / 2


## Robo, the robot buddy: grey, an antenna, square eyes.
static func robo(at: Vector3, yaw: float = 0.0) -> LifeBuddy:
	var b := LifeBuddy.new(Color("9aa7b5"), "Robo")
	b.position = at
	b.rotation.y = yaw
	LifeRoomKit.cylinder(b.head, "Antenna", 0.012, 0.16, Vector3(0, 0.38, 0), Color("6b7a99"))
	LifeRoomKit.sphere(b.head, "AntennaBall", 0.035, Vector3(0, 0.47, 0), Color("e8544e"))
	for x: float in [-0.07, 0.07]:
		LifeRoomKit.box(b.head, "Screen", Vector3(0.07, 0.07, 0.02), Vector3(x, 0.19, 0.162), Color("7ad3ff"))
	var n := LifeRoomKit.sign(b, "Name", "ROBO", Vector3(0, 1.3, 0), SIGN_PIXEL)
	n.modulate = Color("fff6d8")
	return b
