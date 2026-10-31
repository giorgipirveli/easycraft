class_name ToolModels
extends RefCounted
## Owner #116, #117 (docs/design/life-skills.md §13): the tools as models built in code from the practice rooms' kit
## (LifeRoomKit: boxes and cylinders in the game's blocky look, only shaders the game already warms), at true size, in
## the hand's grip space (the fist at the origin, -Z forward from the fist, +Y up from the back of the hand). Each says
## where it works: its tips per motion (ToolSample's tip: -Z where it points, +X its side, +Y its up).

const WOOD := Color("b07a45")
const STEEL := Color("a9b3bf")
const DARK := Color("3b4252")
const YELLOW := Color("f2c230")
const RED := Color("d9473b")
const GREEN := Color("7ad96b")
const ORANGE := Color("f08a1c")
const WHITE := Color("f4f4f0")
const BLUE := Color("3a7be8")


## {model: Node3D, tips: {motion: Transform3D (in the model's space)}} for a Tool Book id (a plain box for one with no
## model of its own).
static func build(id: String) -> Dictionary:
	var m := Node3D.new()
	m.name = "Model"
	var tips := {}
	match id:
		"trowel":
			_bar(m, "Handle", Vector3(0.03, 0.03, 0.12), Vector3(0, 0, 0.02), WOOD)
			LifeRoomKit.box(m, "Shank", Vector3(0.01, 0.04, 0.01), Vector3(0, -0.02, -0.045), STEEL)
			LifeRoomKit.box(m, "Blade", Vector3(0.11, 0.004, 0.25), Vector3(0, -0.04, -0.18), STEEL)
			var t := Transform3D(Basis(), Vector3(0, -0.043, -0.18))
			tips = {"spread": t, "strike": t}
		"hammer":
			_bar(m, "Handle", Vector3(0.025, 0.03, 0.3), Vector3(0, 0, -0.1), WOOD)
			LifeRoomKit.box(m, "Head", Vector3(0.03, 0.11, 0.035), Vector3(0, 0.0, -0.24), DARK)
			tips = {"strike": Transform3D(Basis(), Vector3(0, -0.055, -0.24))}
		"saw":
			_bar(m, "Handle", Vector3(0.03, 0.09, 0.1), Vector3(0, 0, 0.02), RED)
			LifeRoomKit.box(m, "Blade", Vector3(0.003, 0.1, 0.42), Vector3(0, -0.02, -0.24), STEEL)
			tips = {"stroke": Transform3D(Basis(), Vector3(0, -0.07, -0.24))}
		"spirit_level":
			LifeRoomKit.box(m, "Body", Vector3(0.025, 0.05, 0.6), Vector3(0, -0.05, 0), YELLOW)
			LifeRoomKit.box(m, "Vial", Vector3(0.012, 0.012, 0.06), Vector3(0, -0.022, 0), GREEN)
			tips = {"aim": Transform3D(Basis(), Vector3(0, -0.075, 0))}
		"plumb_line":
			LifeRoomKit.box(m, "Reel", Vector3(0.04, 0.04, 0.04), Vector3.ZERO, ORANGE)
			var string := LifeRoomKit.box(m, "String", Vector3(0.003, 0.6, 0.003), Vector3(0, -0.3, 0), WHITE)
			string.set_meta(&"hangs", true)
			var bob := LifeRoomKit.cylinder(m, "Bob", 0.018, 0.05, Vector3(0, -0.62, 0), STEEL)
			bob.set_meta(&"hangs", true)
			tips = {"aim": Transform3D(Basis(), Vector3.ZERO)}
		"tape":
			LifeRoomKit.box(m, "Case", Vector3(0.035, 0.07, 0.07), Vector3.ZERO, YELLOW)
			var blade := LifeRoomKit.box(m, "Blade", Vector3(0.02, 0.003, 0.06), Vector3(0, -0.03, -0.06), YELLOW.lightened(0.3))
			blade.set_meta(&"tape", true)
			LifeRoomKit.box(m, "Hook", Vector3(0.022, 0.012, 0.004), Vector3(0, -0.034, -0.09), DARK)
			tips = {"measure": Transform3D(Basis(), Vector3(0, -0.034, -0.09))}
		"shovel":
			_bar(m, "Handle", Vector3(0.03, 0.03, 0.7), Vector3(0, 0, -0.25), WOOD)
			LifeRoomKit.box(m, "Blade", Vector3(0.2, 0.01, 0.24), Vector3(0, -0.02, -0.7), DARK)
			tips = {"pour": Transform3D(Basis(), Vector3(0, -0.02, -0.75))}
		"bucket":
			LifeRoomKit.cylinder(m, "Pail", 0.12, 0.25, Vector3(0, -0.15, 0), BLUE)
			tips = {"pour": Transform3D(Basis(), Vector3(0, -0.03, -0.12))}
		"square":
			LifeRoomKit.box(m, "ArmA", Vector3(0.03, 0.006, 0.3), Vector3(0, -0.02, -0.15), STEEL)
			LifeRoomKit.box(m, "ArmB", Vector3(0.2, 0.006, 0.03), Vector3(0.1, -0.02, 0), STEEL)
			tips = {"aim": Transform3D(Basis(), Vector3(0, -0.023, 0))}
		"hard_hat":
			LifeRoomKit.sphere(m, "Dome", 0.11, Vector3(0, 0.02, 0), YELLOW)
			LifeRoomKit.cylinder(m, "Brim", 0.14, 0.012, Vector3(0, -0.02, 0), YELLOW.darkened(0.1))
		"goggles":
			LifeRoomKit.box(m, "Lens", Vector3(0.16, 0.05, 0.03), Vector3.ZERO, Color(0.75, 0.9, 1.0))
			LifeRoomKit.box(m, "Strap", Vector3(0.18, 0.015, 0.01), Vector3(0, 0, 0.02), DARK)
		"gloves":
			LifeRoomKit.box(m, "Left", Vector3(0.08, 0.025, 0.14), Vector3(-0.05, 0, 0), ORANGE)
			LifeRoomKit.box(m, "Right", Vector3(0.08, 0.025, 0.14), Vector3(0.05, 0, 0.02), ORANGE)
		_:
			LifeRoomKit.box(m, "Body", Vector3(0.05, 0.05, 0.15), Vector3.ZERO, STEEL)
	return {"model": m, "tips": tips}


## A box along the grip's forward axis (a handle).
static func _bar(parent: Node3D, name: String, size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	return LifeRoomKit.box(parent, name, size, at, colour)
