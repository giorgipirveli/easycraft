class_name KitchenRoom
extends LifeRoom
## Owner #112, #117 (docs/design/life-skills.md §5 #5, §13): The Kitchen's practice kitchen, child-sized and bright: the
## worktop along the back wall with the sink (the tap, the soap pump, the towel), the kettle on its base, the hob with
## its knobs and its hot light, the oven below; the fridge by the left wall; the table in the middle with the healthy
## plate's foods, the chopping board and its child-safe knife, the jug and the measuring cup, the scales, the bowl; on the
## Big track the pantry's shelf with price tags (pretend coins) and its PAY board. Calm: no flames, only a soft orange
## glow under a pan; the hot light is a small warm dot. The run's recipe (LifeKitchen) names what is on the board.
## - Hands: the germs are small green glowing dots that fade while the hands are rubbed (20 s), cartoon hands over the
##   sink on a screen (the child's own hands in VR).
## - Measuring: the cup fills to the level poured (its marks at 1/4, 1/2, 3/4); the scales show the grams.

const WALL := Color("fbeccc")
const WORKTOP := Color("e2e6ea")
const CUPBOARD := Color("7fb8d6")
const WOOD := Color("c99a63")
const FLOOR := Color("d9c3a0")
const GERM := Color(0.45, 0.95, 0.4, 0.7)
const SINK_X := -1.6
const HOB_X := 1.3
const KETTLE_BASE := Vector3(-0.6, 0.92, -1.3)
const FOODS := {
	"carrot": [Vector3(-0.8, 0.8, 0.3), Color("f08a1c")], "broccoli": [Vector3(-0.6, 0.82, 0.3), Color("3f9a3e")],
	"tomato": [Vector3(-0.4, 0.8, 0.3), Color("e8544e")], "apple": [Vector3(-0.2, 0.8, 0.3), Color("9bd04a")],
	"rice": [Vector3(0.0, 0.8, 0.3), Color("f3efe2")], "bread": [Vector3(0.2, 0.8, 0.3), Color("b07a46")],
	"beans": [Vector3(0.4, 0.8, 0.3), Color("8a4a3a")], "egg": [Vector3(0.58, 0.8, 0.3), Color("fdf6e3")],
	"fish": [Vector3(0.76, 0.8, 0.3), Color("f2a07a")]}
const TREATS := {"sweets": [Vector3(-0.5, 0.8, 0.12), Color("e85a9a")], "crisps": [Vector3(0.1, 0.82, 0.12), Color("ffd23f")],
	"fizzy": [Vector3(0.6, 0.85, 0.12), Color("b5562a")]}
const PANTRY := {"shop_rice": ["RICE 4", Color("f3efe2")], "shop_lentils": ["LENTILS 3", Color("e0743a")],
	"shop_veg": ["VEGETABLES 6", Color("3f9a3e")], "shop_eggs": ["EGGS 3", Color("fdf6e3")], "shop_milk": ["MILK 2", Color.WHITE],
	"shop_crisps": ["CRISPS 3", Color("ffd23f")], "shop_fizzy": ["FIZZY 3", Color("b5562a")],
	"shop_sweets": ["SWEETS 3", Color("e85a9a")]}

var germs: Array[MeshInstance3D] = []
var water: MeshInstance3D
var cup_fill: MeshInstance3D
var scales_label: Label3D
var scales_offset := 0
var kettle: Node3D
var kettle_level: MeshInstance3D
var kettle_light: MeshInstance3D
var ring_glow: MeshInstance3D
var hot_light: MeshInstance3D
var pan_handle: Node3D
var oven_door: Node3D
var tray: MeshInstance3D
var fridge_door: Node3D
var gloves: MeshInstance3D
var placed := {}
var slices := 0
var basket_ticks := {}
var hands_model: Node3D
## Life L3b (owner #118): the pan fire (Middle), the baby's small things (Little), Bobo at the sink (Big).
var flame: Node3D
var lid: Node3D
var nia: LifeBuddy
var smalls := {}
var tidied := 0
var bobo: LifeBuddy
var _flame_t := 0.0
## The pantry's price tags: shown once the child is at the pantry (the rooms' look: they ran off the first view).
var _pantry_tags: Array[Label3D] = []


func build() -> void:
	name = "KitchenRoom"
	env = LifeRoomKit.environment(Color("cfe8f5"), Color("fdf6ea"), 0.75)
	start_view = "kitchen"
	_room()
	_sink()
	_hob_and_oven()
	_kettle()
	_fridge()
	_table()
	if track == "big":
		_pantry()
	match track:   # Life L3b (owner #118): fire and heat, choking
		"little":
			_playmat()
		"middle":
			_pan_fire()
		"big":
			_scald_buddy()
	# on two lines between the window and the hood, painted on the wall (on one line the window's frame and the hood
	# stood in front of its ends)
	var recipe := LifeRoomKit.sign(self, "Recipe", "TODAY:\n%s" % str(vars.get("recipe", "a healthy meal")).to_upper(),
		Vector3(0.03, 1.8, -1.55), 0.0032, Color("1f2a4a"))
	recipe.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# over the window, painted on the wall, smaller (on the left it ran into the side wall, turned to the eye into the
	# back wall)
	var practice := LifeRoomKit.sign(self, "PracticeSign", "PRACTICE KITCHEN", Vector3(-1.6, 2.45, -1.55), 0.0034)
	practice.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_kitchen_look()   # the rooms' look (2026-10-18)
	for b: LifeBuddy in [nia, bobo]:   # the Quest's draws: part by part (they may move their arms and legs)
		if b != null:
			LifeRoomPeople.merge_person(b)
	for n: Node3D in [tray, hands_model, kettle]:   # and the tray's vegetables, the cartoon hands, the kettle's marks
		LifeRoomPeople.merge_parts(self, n)
	_views()


func _room() -> void:
	var d := decor()   # the rooms' look: a tiled floor, the walls with a tiled splashback, the window over the sink
	d.tiled("Floor", LifeRoomDecor.TILE, Vector3(6.4, 0.1, 5.4), Vector3(0, -0.05, 0.3), Color("e8c4a0"), 0.5)
	d.box("BackWall", Vector3(6.4, 2.8, 0.1), Vector3(0, 1.4, -1.65), WALL, 0.0, LifeRoomDecor.SHELL)
	d.tiled("Splashback", LifeRoomDecor.TILE, Vector3(5.3, 0.62, 0.02), Vector3(0, 1.22, -1.59), Color("d6ecf2"), 0.2)
	for x: float in [-3.2, 3.2]:
		d.box("SideWall", Vector3(0.1, 2.8, 5.4), Vector3(x, 1.4, 0.3), WALL.darkened(0.04), 0.0, LifeRoomDecor.SHELL)
	var sc := scenery()
	LifeRoomKit.box(sc, "Cupboards", Vector3(5.2, 0.86, 0.58), Vector3(0, 0.43, -1.26), CUPBOARD)
	LifeRoomKit.box(sc, "Worktop", Vector3(5.3, 0.05, 0.64), Vector3(0, 0.885, -1.26), WORKTOP)
	d.window("Window", Vector3(SINK_X, 1.88, -1.59), 1.3, 0.62, 0.0)
	LifeRoomKit.light(self, Vector3(0, 2.4, 0), 0.55, 8.0)
	sun(Color(1.0, 0.95, 0.86), 0.8)   # indoors: a softer key light through the windows


func _sink() -> void:
	LifeRoomKit.box(self, "Sink", Vector3(0.7, 0.04, 0.45), Vector3(SINK_X, 0.9, -1.25), Color("b9c3d6"))
	var tap := LifeRoomKit.box(self, "Tap", Vector3(0.06, 0.24, 0.06), Vector3(SINK_X, 1.03, -1.48), Color("c3cbd4"))
	LifeRoomKit.box(tap, "Spout", Vector3(0.05, 0.05, 0.18), Vector3(0, 0.1, 0.09), Color("c3cbd4"))
	add_target("tap", tap, 0.12)
	water = LifeRoomKit.box(self, "Water", Vector3(0.04, 0.2, 0.04), Vector3(SINK_X, 1.0, -1.31), Color(0.6, 0.85, 1.0, 0.55))
	water.visible = false
	add_spot_target("water", self, Vector3(SINK_X, 1.0, -1.28), 0.13)
	var soap := LifeRoomKit.cylinder(self, "Soap", 0.05, 0.16, Vector3(SINK_X + 0.45, 0.99, -1.38), Color("9b7fd6"))
	add_target("soap", soap, 0.1)
	LifeRoomKit.box(self, "TowelRail", Vector3(0.5, 0.03, 0.03), Vector3(SINK_X - 0.75, 0.98, -0.94), Color("9aa7b5"))
	var towel := LifeRoomKit.box(self, "Towel", Vector3(0.4, 0.4, 0.03), Vector3(SINK_X - 0.75, 0.8, -0.92), Color("f6b5a8"))
	add_target("towel", towel, 0.16)
	hands_model = Node3D.new()
	hands_model.name = "CartoonHands"
	hands_model.position = Vector3(SINK_X, 1.05, -1.12)
	add_child(hands_model)
	for x: float in [-0.06, 0.06]:
		LifeRoomKit.box(hands_model, "Hand", Vector3(0.09, 0.03, 0.15), Vector3(x, 0, 0), LifeBuddy.SKIN)
	hands_model.visible = not Vr.active()   # in a headset the child's own hands are there
	for i in 9:
		var a := TAU * i / 9.0
		germs.append(LifeRoomKit.sphere(self, "Germ", 0.012, hands_model.position + Vector3(cos(a) * 0.09, 0.02 + (i % 3) * 0.01,
			sin(a) * 0.06), GERM))
	add_spot_target("hands", self, hands_model.position, 0.15)


func _hob_and_oven() -> void:
	LifeRoomKit.box(self, "Hob", Vector3(0.6, 0.02, 0.5), Vector3(HOB_X, 0.92, -1.25), Color("2b2f38"))
	ring_glow = LifeRoomKit.cylinder(self, "Ring", 0.12, 0.005, Vector3(HOB_X - 0.1, 0.935, -1.3), Color("4a4f5a"))
	hot_light = LifeRoomKit.sphere(self, "HotLight", 0.015, Vector3(HOB_X + 0.24, 0.935, -1.04), Color("4a4f5a"))
	var pan := LifeRoomKit.cylinder(self, "Pan", 0.13, 0.08, Vector3(HOB_X - 0.1, 0.98, -1.3), Color("6b7380"))
	pan_handle = Node3D.new()
	pan_handle.name = "PanHandle"
	pan_handle.position = Vector3(HOB_X - 0.1, 1.0, -1.3)
	add_child(pan_handle)
	var grip := LifeRoomKit.box(pan_handle, "Grip", Vector3(0.04, 0.03, 0.32), Vector3(0, 0, 0.27), Color("2b2f38"))
	add_target("pan_handle", grip, 0.1)
	var knob := LifeRoomKit.cylinder(self, "Knob", 0.035, 0.03, Vector3(HOB_X - 0.15, 0.78, -0.95), Color("2b2f38"))
	knob.rotation.x = PI / 2
	add_target("knob", knob, 0.07)
	var oknob := LifeRoomKit.cylinder(self, "OvenKnob", 0.035, 0.03, Vector3(HOB_X + 0.18, 0.78, -0.95), Color("2b2f38"))
	oknob.rotation.x = PI / 2
	add_target("oven_knob", oknob, 0.07)
	oven_door = Node3D.new()
	oven_door.name = "OvenDoor"
	oven_door.position = Vector3(HOB_X, 0.12, -0.95)
	add_child(oven_door)
	var door := LifeRoomKit.box(oven_door, "Door", Vector3(0.58, 0.55, 0.04), Vector3(0, 0.28, 0), Color("3b3f4a"))
	LifeRoomKit.box(door, "Glass", Vector3(0.4, 0.25, 0.01), Vector3(0, 0.03, 0.025), Color(0.95, 0.75, 0.45, 0.6))
	add_target("oven_door", door, 0.2)
	tray = LifeRoomKit.box(self, "Tray", Vector3(0.44, 0.03, 0.34), Vector3(HOB_X, 0.38, -1.22), Color("9aa7b5"))
	for i in 4:
		LifeRoomKit.box(tray, "Veg", Vector3(0.07, 0.04, 0.07), Vector3(-0.15 + i * 0.1, 0.03, 0.03 * (i % 2)), Color("e0743a"))
	add_target("tray", tray, 0.16)
	var mat := LifeRoomKit.box(self, "HeatMat", Vector3(0.36, 0.01, 0.3), Vector3(0.45, 0.915, -1.2), Color("c0563a"))
	add_target("heat_mat", mat, 0.18)
	gloves = LifeRoomKit.box(self, "OvenGloves", Vector3(0.2, 0.26, 0.05), Vector3(2.05, 1.05, -1.55), Color("e8544e"))
	add_target("gloves", gloves, 0.14)


func _kettle() -> void:
	LifeRoomKit.box(self, "KettleBase", Vector3(0.2, 0.02, 0.2), KETTLE_BASE, Color("2b2f38"))
	kettle = Node3D.new()
	kettle.name = "Kettle"
	kettle.position = KETTLE_BASE + Vector3(0, 0.12, 0)
	add_child(kettle)
	var body := LifeRoomKit.box(kettle, "Body", Vector3(0.16, 0.22, 0.14), Vector3.ZERO, Color("c9ced6"))
	LifeRoomKit.box(kettle, "Window", Vector3(0.03, 0.16, 0.01), Vector3(0.04, 0, 0.075), Color(0.75, 0.9, 1.0, 0.6))
	kettle_level = LifeRoomKit.box(kettle, "Level", Vector3(0.025, 0.16, 0.012), Vector3(0.04, -0.08, 0.077), Color("5aa8e6"))
	kettle_level.scale.y = 0.01
	for y: float in [-0.05, 0.06]:
		LifeRoomKit.box(kettle, "Mark", Vector3(0.04, 0.005, 0.014), Vector3(0.04, y, 0.08), Color("1f2a4a"))
	kettle_light = LifeRoomKit.sphere(kettle, "KettleLight", 0.012, Vector3(-0.05, -0.1, 0.075), Color("4a4f5a"))
	add_target("kettle", body, 0.14)
	add_spot_target("kettle_switch", kettle, Vector3(-0.09, -0.08, 0.0), 0.06)
	if track == "big":
		kettle.position = Vector3(SINK_X, 1.03, -1.25)   # it starts in the sink, to be filled


func _fridge() -> void:
	var sc := scenery()
	var at := Vector3(-2.85, 0, 0.3)
	LifeRoomKit.box(sc, "Fridge", Vector3(0.6, 1.8, 0.7), at + Vector3(0, 0.9, 0), Color.WHITE)
	for y: float in [0.4, 0.85, 1.3]:
		LifeRoomKit.box(sc, "Shelf", Vector3(0.5, 0.02, 0.6), at + Vector3(0.05, y, 0), Color("dfe7f5"))
	LifeRoomKit.sign(self, "FridgeTemp", "4 °C", at + Vector3(0.32, 1.5, 0), 0.003, Color("3a7be8"))
	add_spot_target("fridge_bottom", self, at + Vector3(0.12, 0.5, 0), 0.18)
	fridge_door = Node3D.new()
	fridge_door.name = "FridgeDoor"
	fridge_door.position = at + Vector3(0.31, 0, 0.35)
	add_child(fridge_door)
	LifeRoomKit.box(fridge_door, "Door", Vector3(0.04, 1.75, 0.7), Vector3(0, 0.9, -0.35), Color("f6f8fb"))


func _table() -> void:
	var sc := scenery()
	LifeRoomKit.box(sc, "Table", Vector3(1.9, 0.05, 0.9), Vector3(0, 0.75, 0.5), WOOD)
	for c: Vector2 in [Vector2(-0.85, 0.15), Vector2(0.85, 0.15), Vector2(-0.85, 0.85), Vector2(0.85, 0.85)]:
		LifeRoomKit.box(sc, "Leg", Vector3(0.06, 0.75, 0.06), Vector3(c.x, 0.375, c.y), WOOD.darkened(0.2))
	var plate := LifeRoomKit.cylinder(self, "Plate", 0.17, 0.02, Vector3(0, 0.785, 0.72), Color.WHITE)
	add_target("plate", plate, 0.18)
	for id: String in FOODS:
		var f: Array = FOODS[id]
		var m := LifeRoomKit.box(self, id.capitalize(), Vector3(0.09, 0.07, 0.09), f[0], f[1])
		add_target(id, m, 0.08)
	for id: String in TREATS:
		LifeRoomKit.box(sc, id.capitalize(), Vector3(0.1, 0.1 if id == "fizzy" else 0.06, 0.08), TREATS[id][0], TREATS[id][1])
	LifeRoomKit.box(self, "Glass", Vector3(0.06, 0.12, 0.06), Vector3(-0.3, 0.83, 0.82), Color(0.75, 0.9, 1.0, 0.6))
	# the chopping board, its food and the child-safe knife (round-tipped)
	LifeRoomKit.box(sc, "Board", Vector3(0.36, 0.02, 0.24), Vector3(0.55, 0.785, 0.72), Color("e8c48c"))
	var food := LifeRoomKit.cylinder(self, "FoodToCut", 0.035, 0.22, Vector3(0.55, 0.82, 0.72), Color("f3d36a"))
	food.rotation.z = PI / 2
	add_target("cut_food", food, 0.1, 0.12)
	LifeRoomKit.box(sc, "Knife", Vector3(0.2, 0.01, 0.03), Vector3(0.6, 0.8, 0.82), Color("c9ced6"))
	# the jug and the measuring cup (its fill shows the amount)
	var jug := LifeRoomKit.box(self, "Jug", Vector3(0.1, 0.16, 0.1), Vector3(-0.65, 0.86, 0.66), Color(0.95, 0.95, 0.98, 0.85))
	add_target("jug", jug, 0.1)
	LifeRoomKit.cylinder(self, "Cup", 0.05, 0.12, Vector3(-0.45, 0.84, 0.72), Color(1, 1, 1, 0.45))
	cup_fill = LifeRoomKit.cylinder(self, "CupFill", 0.045, 0.12, Vector3(-0.45, 0.78, 0.72), Color("fdf6e3"))
	cup_fill.scale.y = 0.01
	for k in 3:
		LifeRoomKit.box(sc, "CupMark", Vector3(0.02, 0.004, 0.004), Vector3(-0.4, 0.81 + k * 0.03, 0.77), Color("1f2a4a"))
	# the scales
	var scales := LifeRoomKit.box(self, "Scales", Vector3(0.18, 0.04, 0.16), Vector3(-0.35, 0.79, 0.52), Color.WHITE)
	add_target("scales", scales, 0.1)
	scales_label = LifeRoomKit.sign(self, "ScalesShow", "0 g", Vector3(-0.35, 0.86, 0.62), 0.0025, Color("1f2a4a"))
	scales_label.outline_size = 0
	add_spot_target("scales_zero", self, Vector3(-0.29, 0.8, 0.61), 0.05)
	LifeRoomKit.box(sc, "ZeroButton", Vector3(0.03, 0.01, 0.02), Vector3(-0.29, 0.81, 0.61), Color("3a7be8"))
	var bowl := LifeRoomKit.cylinder(self, "Bowl", 0.12, 0.07, Vector3(0.3, 0.81, 0.6), Color("7fb8d6"))
	add_target("bowl", bowl, 0.14, 0.12)
	add_spot_target("worktop", self, Vector3(-0.1, 0.78, 0.62), 0.2, 0.3)


func _pantry() -> void:
	var x := 3.05
	for row in 2:
		LifeRoomKit.box(scenery(), "PantryShelf", Vector3(0.3, 0.03, 1.6), Vector3(x, 0.85 + row * 0.5, 0.3), WOOD)
	var i := 0
	for id: String in PANTRY:
		var p := Vector3(x - 0.05, 0.94 + (i / 4) * 0.5, -0.3 + (i % 4) * 0.4)
		var m := LifeRoomKit.box(self, id, Vector3(0.14, 0.16, 0.14), p, PANTRY[id][1])
		var tag := LifeRoomKit.sign(self, id + "_price", str(PANTRY[id][0]), p + Vector3(-0.12, 0.14, 0), 0.0022)
		tag.outline_size = 10
		tag.visible = false   # shown at the pantry (from the kitchen view the first view's right edge cut them): step_started
		_pantry_tags.append(tag)
		add_target(id, m, 0.12)
		i += 1
	var till := LifeRoomKit.box(self, "PayBoard", Vector3(0.05, 0.3, 0.4), Vector3(x - 0.1, 1.15, 1.25), Color("3fbf5a"))
	LifeRoomKit.sign(till, "Pay", "PAY", Vector3(-0.05, 0, 0), 0.004)
	add_target("till", till, 0.2)


func _views() -> void:
	add_view("kitchen", Vector3(0, 1.9, 2.9), Vector3(0, 0.6, -0.6), Vector3(0, 0, 1.6), 0.0)
	add_view("sink", Vector3(SINK_X, 1.5, 0.25), Vector3(SINK_X, 0.9, -1.3), Vector3(SINK_X, 0, -0.45), 0.0)
	add_view("table", Vector3(0, 1.55, 1.8), Vector3(0, 0.7, 0.35), Vector3(0, 0, 1.45), 0.0)
	add_view("board", Vector3(0.5, 1.35, 1.35), Vector3(0.55, 0.75, 0.65), Vector3(0.45, 0, 1.4), 0.0)
	add_view("hob", Vector3(HOB_X, 1.5, 0.25), Vector3(HOB_X, 0.85, -1.2), Vector3(HOB_X, 0, -0.45), 0.0)
	add_view("oven", Vector3(HOB_X - 0.2, 1.15, 0.6), Vector3(HOB_X, 0.6, -1.0), Vector3(HOB_X, 0, -0.55), 0.0)
	add_view("kettle", Vector3(-0.45, 1.5, 0.25), Vector3(-0.5, 0.9, -1.3), Vector3(-0.45, 0, -0.45), 0.0)
	add_view("fridge", Vector3(-1.3, 1.4, 0.3), Vector3(-2.7, 0.7, 0.3), Vector3(-1.85, 0, 0.3), PI / 2)
	add_view("pantry", Vector3(1.4, 1.55, 0.35), Vector3(3.0, 1.0, 0.45), Vector3(2.15, 0, 0.45), -PI / 2)
	add_view("playmat", Vector3(1.3, 1.45, 2.6), Vector3(2.0, 0.05, 1.3), Vector3(1.5, 0, 2.3), -0.35)   # Life L3b


# --- Events and progress ---------------------------------------------------------------------------------------------

func on_event(event: String) -> void:
	match event:
		"water_on":
			water.visible = true
		"water_off":
			water.visible = false
		"soap_on":
			for g in germs:
				g.visible = true
		"scales_off_zero":
			scales_offset = 35
			scales_label.text = "35 g"
		"handle_in":
			_turn(pan_handle, PI * 0.6)
		"hob_on":
			ring_glow.material_override = LifeRoomKit.material(Color(1.0, 0.55, 0.25), true)
			hot_light.material_override = LifeRoomKit.material(Color(1.0, 0.55, 0.25), true)
		"hob_off":
			ring_glow.material_override = LifeRoomKit.material(Color("4a4f5a"))   # the hot light stays on: still hot
		"kettle_on":
			kettle_light.material_override = LifeRoomKit.material(Color(1.0, 0.6, 0.3), true)
		"kettle_over":
			kettle_level.scale.y = 1.15
		"gloves_on":
			gloves.visible = false
		"oven_open":
			_tilt(oven_door, -1.3)
		"tray_out":
			tray.position = Vector3(HOB_X - 0.3, 0.75, -0.6)
		"tray_on_mat":
			tray.position = Vector3(0.45, 0.94, -1.2)
			_tilt(oven_door, 0.0)
		"fridge_open":
			_turn(fridge_door, -1.6)
		"pan_fire":   # Life L3b: oil in the pan catches fire: a small cartoon flame over the pan, the ring glowing
			if flame:
				flame.visible = true
				ring_glow.material_override = LifeRoomKit.material(Color(1.0, 0.55, 0.25), true)
		"lid_on":   # the lid keeps the air out: the flame goes out under it
			if lid:
				lid.position = Vector3(HOB_X - 0.1, 1.035, -1.3)
			if flame:
				flame.visible = false
		"baby_visits":
			if nia:
				nia.visible = true
		"splash_hand":
			if bobo:
				bobo.visible = true
				bobo.show_ouch("near_hand")


func step_started(step: Dictionary) -> void:
	if str(step.get("view", "")) == "pantry":
		for tag in _pantry_tags:
			tag.visible = true
	if str(step.get("id", "")) == "tidy" and smalls.has("small_battery"):   # Life L3b: the battery only when asked for
		(smalls.small_battery as Node3D).visible = (step.get("targets", []) as Array).has("small_battery")
	if str(step.get("id", "")) == "switch" and kettle:
		kettle.position = KETTLE_BASE + Vector3(0, 0.12, 0)   # filled at the tap, back on its base
		if kettle_level.scale.y > 1.0:
			kettle_level.scale.y = 0.6


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"zero":
			scales_offset = 0
			scales_label.text = "0 g"
		"too_full":
			kettle_level.scale.y = 0.6
		"oven_off":
			hot_light.material_override = LifeRoomKit.material(Color("4a4f5a"))


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"rub":   # the germs' glow fades as the seconds go by
			var left := 1.0 - LifeCheck.fraction(step, state)
			for i in germs.size():
				germs[i].visible = float(i) / germs.size() < left
		"pour":
			var level := float(state.get("level", 0.0))
			match str(step.get("target", "")):
				"jug":
					cup_fill.scale.y = maxf(level / float(step.get("full", 1.0)), 0.01)
					cup_fill.position.y = 0.78 + 0.06 * cup_fill.scale.y
				"scales":
					scales_label.text = "%d g" % (roundi(level) + scales_offset)
				"kettle":
					kettle_level.scale.y = maxf(level / float(step.get("full", 1.0)), 0.01)
		"sweep":
			if str(step.get("target", "")) == "cut_food":
				var n := int(state.get("crossings", 0))
				while slices < n:
					LifeRoomKit.cylinder(self, "Slice", 0.035, 0.012, Vector3(0.43 + slices * 0.03, 0.8, 0.66), Color("f3d36a"))
					slices += 1
		"find":
			if str(step.get("id", "")) == "tidy":   # Life L3b: the small things go up high, into the box on the worktop
				for t: Variant in state.get("found", []):
					if smalls.has(t) and not placed.has(t):
						(smalls[t] as Node3D).position = Vector3(0.9 + tidied * 0.07, 0.96, -1.3)
						placed[t] = true
						tidied += 1
				return
			for t: Variant in state.get("found", []):
				if placed.has(t) or not has_target(str(t)):
					continue
				var n := target_node(str(t))
				var k := placed.size()
				n.position = Vector3(-0.08 + (k % 3) * 0.08, 0.81, 0.68 + (k / 3) * 0.07)   # onto the plate
				placed[t] = true
		"basket":
			for id: String in PANTRY:
				if not has_target(id):
					continue
				var inside := (state.get("in", []) as Array).has(id)
				if inside and not basket_ticks.has(id):
					basket_ticks[id] = LifeRoomKit.sphere(self, "InBasket", 0.04, to_local(target_position(id)) + Vector3(-0.1, 0.14, 0),
						Color(0.3, 0.85, 0.4, 0.9))
				elif not inside and basket_ticks.has(id):
					(basket_ticks[id] as Node3D).queue_free()
					basket_ticks.erase(id)


func _turn(n: Node3D, yaw: float) -> void:
	if is_inside_tree() and not UiMotion.calm():
		create_tween().tween_property(n, "rotation:y", yaw, 0.5).set_trans(Tween.TRANS_SINE)
	else:
		n.rotation.y = yaw


func _tilt(n: Node3D, x: float) -> void:
	if is_inside_tree() and not UiMotion.calm():
		create_tween().tween_property(n, "rotation:x", x, 0.6).set_trans(Tween.TRANS_SINE)
	else:
		n.rotation.x = x


# --- Life L3b (owner #118): fire and heat, choking ----------------------------------------------------------------------

## Little: the hot and cold taps' colours, a play mat with small things a baby could put in her mouth, the box up high.
func _playmat() -> void:
	LifeRoomKit.sphere(self, "HotKnob", 0.025, Vector3(SINK_X + 0.12, 1.12, -1.48), Color("e8544e"))
	LifeRoomKit.sphere(self, "ColdKnob", 0.025, Vector3(SINK_X - 0.12, 1.12, -1.48), Color("3a7be8"))
	LifeRoomKit.box(self, "PlayMat", Vector3(1.4, 0.02, 1.0), Vector3(2.0, 0.01, 1.3), Color("9bd04a"))
	LifeRoomKit.box(self, "TidyBox", Vector3(0.4, 0.12, 0.25), Vector3(1.0, 0.97, -1.3), Color("ffd23f"))
	var things := {"small_marble": [Vector3(1.6, 0.04, 1.1), Color("3a7be8"), "ball"],
		"small_coin": [Vector3(2.0, 0.03, 1.55), Color("ffc93c"), "coin"],
		"small_wheel": [Vector3(2.4, 0.04, 1.0), Color("2b2f38"), "coin"],
		"small_beads": [Vector3(1.8, 0.03, 1.4), Color("e85a9a"), "beads"],
		"small_battery": [Vector3(2.5, 0.025, 1.5), Color("c9ced6"), "coin"]}
	for id: String in things:
		var t: Array = things[id]
		var n: MeshInstance3D
		match str(t[2]):
			"ball":
				n = LifeRoomKit.sphere(self, id, 0.025, t[0], t[1])
			"coin":
				n = LifeRoomKit.cylinder(self, id, 0.03 if id == "small_wheel" else 0.022, 0.008, t[0], t[1])
			_:
				n = LifeRoomKit.box(self, id, Vector3(0.08, 0.02, 0.03), t[0], t[1])
		add_target(id, n, 0.1)
		smalls[id] = n
	(smalls.small_battery as Node3D).visible = false   # the Expert try's fifth thing (step_started shows it)
	nia = LifeBuddy.new(Color("f6b5a8"), "Nia")
	nia.scale = Vector3.ONE * 0.6
	nia.position = Vector3(2.6, 0, 1.9)
	nia.rotation.y = PI * 1.2
	nia.visible = false
	add_child(nia)
	nia.pose("sit_floor")
	LifeRoomPeople.feel(nia, "happy")


## Middle: the pan's lid on the worktop, the jug of water (the safe mistake) and the cartoon flame.
func _pan_fire() -> void:
	lid = Node3D.new()
	lid.name = "PanLid"
	lid.position = Vector3(HOB_X + 0.45, 0.93, -1.3)
	add_child(lid)
	LifeRoomKit.cylinder(lid, "Lid", 0.14, 0.015, Vector3.ZERO, Color("9aa7b5"))
	LifeRoomKit.box(lid, "Knob", Vector3(0.04, 0.03, 0.04), Vector3(0, 0.02, 0), Color("2b2f38"))
	add_target("pan_lid", lid, 0.13)
	var jug := LifeRoomKit.box(self, "WaterJug", Vector3(0.1, 0.16, 0.1), Vector3(HOB_X - 0.7, 0.99, -1.25),
		Color(0.6, 0.85, 1.0, 0.85))
	LifeRoomKit.sign(jug, "Label", "WATER", Vector3(0, 0.15, 0.06), 0.0022, Color("1f2a4a"))
	add_target("water_jug", jug, 0.1)
	flame = Node3D.new()
	flame.name = "PanFlame"
	flame.position = Vector3(HOB_X - 0.1, 1.03, -1.3)
	flame.visible = false
	add_child(flame)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.1
	cone.height = 0.2
	cone.radial_segments = 10
	var f := MeshInstance3D.new()
	f.mesh = cone
	f.position = Vector3(0, 0.1, 0)
	f.material_override = LifeRoomKit.material(Color(1.0, 0.6, 0.18), true)
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flame.add_child(f)


## Big: Bobo by the sink, for the scald's first aid.
func _scald_buddy() -> void:
	bobo = LifeBuddy.new(Color("1fa6a0"), "Bobo")
	bobo.position = Vector3(SINK_X + 0.55, 0, -0.75)
	bobo.rotation.y = PI * 0.85
	bobo.visible = false
	add_child(bobo)
	LifeRoomPeople.feel(bobo, "worried")


func _process(delta: float) -> void:
	super(delta)
	if flame and flame.visible:   # the flame flickers softly by the room's own time (slow on the first tries)
		_flame_t += sim_delta(delta)
		flame.scale = Vector3.ONE * (1.0 + 0.12 * sin(_flame_t * 7.0))


## The pan fire's safe mistake, frozen before the flare: the water's splash hanging over the pan, and calm words.
func on_mistake(event: String, on: bool) -> void:
	if not on or event != "flare":
		return
	var holder := mistake_holder()
	for i in 4:
		LifeRoomKit.sphere(holder, "Water", 0.025, Vector3(HOB_X - 0.18 + i * 0.05, 1.32 + 0.03 * (i % 2), -1.3),
			Color(0.6, 0.85, 1.0, 0.9))
	LifeRoomKit.sign(holder, "Why", "WATER MAKES BURNING OIL JUMP UP", Vector3(HOB_X - 0.1, 1.7, -1.3), 0.0035,
		Color("ffd23f"))


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## A bright family kitchen: skirting, a ceiling with its lights, the cupboards' doors and handles, a hood over the hob,
## wall cupboards, a shelf of jars, a plant on the sill, a clock, a front wall with its door behind the child, a garden
## outside the window. Never over the recipe's sign, a hand's reach or a view's line.
func _kitchen_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Garden", Vector3(70, 0.1, 70), Vector3(0, -0.16, 0.3), Color("8cc56a"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Ceiling", LifeRoomDecor.TILE, Vector3(6.4, 0.1, 5.5), Vector3(0, 2.85, 0.3), Color("fbf8f2"), 0.8)
	for c: Vector3 in [Vector3(-1.0, 2.78, 0.0), Vector3(1.0, 2.78, 0.0), Vector3(0.0, 2.78, 1.9)]:
		d.ceiling_light("Light", c, 0.28)
	d.skirting("Skirting", Vector3(-3.14, 0, -1.6), Vector3(-3.14, 0, 3.0), Color("c89a62"))
	d.skirting("Skirting", Vector3(3.14, 0, -1.6), Vector3(3.14, 0, 3.0), Color("c89a62"))
	# the cupboards' doors (lines) and handles, along the front at z -0.97 (none by the towel or the oven's door)
	for i in 9:
		var x := -2.6 + i * 0.65
		if absf(x - HOB_X) > 0.45 and x > -2.0:
			d.box("DoorLine", Vector3(0.012, 0.74, 0.01), Vector3(x, 0.45, -0.965), CUPBOARD.darkened(0.25))
		if i < 8 and absf(x + 0.325 - HOB_X) > 0.55 and x + 0.325 > -2.0:
			d.box("Handle", Vector3(0.12, 0.025, 0.025), Vector3(x + 0.325, 0.74, -0.95), Color("e2e6ea"))
	# the hood over the hob, wall cupboards beside it, a shelf of jars over the kettle's corner
	d.box("Hood", Vector3(0.7, 0.18, 0.45), Vector3(HOB_X, 1.78, -1.38), Color("c9ced6"))
	d.box("WallCupboard", Vector3(0.95, 0.65, 0.34), Vector3(2.35, 1.95, -1.45), CUPBOARD.lightened(0.15))
	d.box("WallCupboardLine", Vector3(0.012, 0.6, 0.01), Vector3(2.35, 1.95, -1.275), CUPBOARD.darkened(0.2))
	for k in 4:
		d.cylinder("Jar", 0.045, 0.12 + 0.02 * (k % 2), Vector3(-2.93 + k * 0.14, 1.66, -1.5), [Color("f3d2a8"), Color("e8544e"),
			Color("ffc93c"), Color("9bd04a")][k], -1.0, 8)
	d.box("JarShelf", Vector3(0.7, 0.03, 0.18), Vector3(-2.72, 1.58, -1.5), Color("c89a62"))   # left of the window (under the recipe they hid its words)
	d.plant("WorktopPlant", Vector3(-2.45, 0.91, -1.42), 0.5, Color("d9774a"), Color("5aa548"))
	d.box("Clock", Vector3(0.32, 0.32, 0.04), Vector3(-3.13, 2.0, -0.6), Color("fdfdf8"), PI / 2)
	d.box("ClockRim", Vector3(0.38, 0.38, 0.03), Vector3(-3.14, 2.0, -0.6), Color("e8544e"), PI / 2)
	# the front wall with its door, behind the child
	d.box("FrontWall", Vector3(2.6, 2.8, 0.1), Vector3(-1.9, 1.4, 3.05), WALL, 0.0, LifeRoomDecor.SHELL)
	d.box("FrontWall", Vector3(2.6, 2.8, 0.1), Vector3(1.9, 1.4, 3.05), WALL, 0.0, LifeRoomDecor.SHELL)
	d.box("FrontWallTop", Vector3(1.2, 0.7, 0.1), Vector3(0, 2.45, 3.05), WALL, 0.0, LifeRoomDecor.SHELL)
	d.box("FrontDoor", Vector3(1.0, 2.05, 0.05), Vector3(0, 1.03, 3.08), Color("b07a46"))
	d.picture("Picture", Vector3(3.14, 1.7, 2.0), Vector2(0.6, 0.45), -PI / 2, Color("8a6239"), Color("fff6e0"), 0)
	if track != "big":   # Big's pantry stands along the right wall
		d.picture("Picture", Vector3(3.14, 1.65, -0.1), Vector2(0.5, 0.6), -PI / 2, Color("3a7be8"), Color("fff6e0"), 1)
