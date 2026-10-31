class_name HomeHelperRoom
extends LifeRoom
## Owner #112 (docs/design/life-skills.md §5 row 11, §13 "Home: washing machine, dishwasher, bins and recycling, smoke
## alarm test"; Life L3c): Home Helper's practice house, its corners built for the track: the laundry corner (the
## washing pile, the WHITES and COLOURS baskets; Middle's red sock hiding in the whites; Big's washing machine with its
## door, dial and start button, and the care label's big picture board), the bedroom (the bed with a T-shirt to fold,
## socks to pair, the chest of drawers; toys on the floor and their homes: the toy box, the shelf, the bed, the shoe rack),
## the kitchen (the table to set, the four practice bins: PAPER blue, PLASTIC AND CANS yellow, GLASS green, FOOD WASTE
## brown, each with its picture; Big's dishwasher with its racks and cutlery basket), the windowsill's plant and the
## watering can, Biscuit's corner (his bowls, his lead on its hook, his bed) and the hall's practice smoke alarm (low on
## the wall, with Gus). Chores have no safe mistakes: a wrong bin or a knife pointing up is a kind miss with its why.
## Hands fold, pour and sort in VR; everything within a child's reach.

const FLOOR := Color("d9c3a0")
const WALL := Color("f3efe6")
const WOOD := Color("a8642a")
const INK := Color("1f2a4a")
const WHITE := Color("f4f6f8")
const BASKET := Color("c9a46a")
const SOIL_DRY := Color("b98a5a")
const SOIL_WET := Color("5a3a22")
const LAUNDRY := Vector3(-6, 0, 0)
const PETS := Vector3(-11, 0, 0)
const KITCHEN := Vector3(6, 0, 0)
const PLANTS := Vector3(11, 0, 0)
const HALL := Vector3(15, 0, 0)
## The bins: target, words, colour, x in the kitchen.
const BINS := [["bin_paper", "PAPER", Color("3a7be8"), -1.35], ["bin_plastic", "PLASTIC AND CANS", Color("f2c230"), -0.45],
	["bin_glass", "GLASS", Color("2fae4e"), 0.45], ["bin_food", "FOOD WASTE", Color("8a5a34"), 1.35]]
## Recycling's items (the react event -> its look and its bin).
const ITEMS := {"item_paper": ["bin_paper", Color("fdfdf8"), Vector3(0.3, 0.02, 0.22)],
	"item_bottle": ["bin_plastic", Color("cfe8f8"), Vector3(0.08, 0.24, 0.08)],
	"item_can": ["bin_plastic", Color("c9ced6"), Vector3(0.07, 0.12, 0.07)],
	"item_jar": ["bin_glass", Color(0.75, 0.95, 0.85, 0.8), Vector3(0.1, 0.12, 0.1)],
	"item_apple": ["bin_food", Color("e8544e"), Vector3(0.08, 0.08, 0.08)]}

var gus: LifeBuddy
var dog: LifeDog
var baskets := {}
var tshirt: Node3D
var sleeves: Array[MeshInstance3D] = []
var plant_soil: MeshInstance3D
var water: MeshInstance3D
var item: MeshInstance3D
var item_event := ""
var label_board: Node3D
var labels := {}
var wm_door: MeshInstance3D
var wm_screen: Label3D
var homes := {}


func build() -> void:
	name = "HomeHelperRoom"
	env = LifeRoomKit.environment(Color("e4eef7"), Color("f7f8fa"), 0.8)
	start_view = "laundry"
	_house_look()   # the rooms' look (2026-10-18): one home, its corners apart
	# lower on the back wall, smaller (high up the first view cut it)
	var house_sign := LifeRoomKit.sign(self, "HouseSign", "PRACTICE HOUSE", Vector3(-6, 1.75, -2.35), 0.0034, Color("2f7f6a"))
	house_sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED   # painted on the wall (turned to the eye, it sank into the wall)
	for x: float in [-9.0, -1.0, 7.0, 14.0]:
		LifeRoomKit.light(self, Vector3(x, 2.4, 0), 0.5, 8.0)
	sun(Color(1.0, 0.95, 0.86), 0.8)   # indoors: a softer key light
	_laundry()
	_bedroom()
	_kitchen()
	if track != "big":
		_pets()
	_plants()
	_hall()
	_views()


# --- The laundry corner -------------------------------------------------------------------------------------------------

func _laundry() -> void:
	var l := LAUNDRY
	for b: Array in [["whites", "WHITES", Vector3(-0.7, 0, -1.3)], ["colours", "COLOURS", Vector3(0.7, 0, -1.3)]]:
		var at: Vector3 = l + (b[2] as Vector3)
		LifeRoomKit.box(scenery(), "Basket", Vector3(0.6, 0.4, 0.45), at + Vector3(0, 0.2, 0), BASKET)
		LifeRoomKit.sign(self, "BasketSign", str(b[1]), at + Vector3(0, 0.75, 0), 0.0035, INK)
		baskets[b[0]] = at + Vector3(0, 0.42, 0)
	if track == "little":
		_cloth("w_shirt", Vector3(-0.5, 0.04, -0.2), WHITE, Vector3(0.3, 0.04, 0.26))
		_cloth("w_socks", Vector3(0.0, 0.04, 0.0), WHITE, Vector3(0.16, 0.04, 0.1))
		_cloth("w_towel", Vector3(0.45, 0.04, -0.25), WHITE, Vector3(0.34, 0.04, 0.22))
		_cloth("w_vest", Vector3(-0.15, 0.04, -0.5), WHITE, Vector3(0.24, 0.04, 0.2))
		for c: Array in [[Vector3(0.25, 0.04, 0.15), Color("e8544e")], [Vector3(-0.35, 0.04, 0.2), Color("3a7be8")]]:
			LifeRoomKit.box(scenery(), "Colour", Vector3(0.26, 0.04, 0.2), l + (c[0] as Vector3), c[1])
	elif track == "middle":
		_cloth("c_red", Vector3(-0.5, 0.04, -0.2), Color("e8544e"), Vector3(0.3, 0.04, 0.26))
		_cloth("c_blue", Vector3(0.0, 0.04, 0.0), Color("3a7be8"), Vector3(0.24, 0.04, 0.34))
		_cloth("c_green", Vector3(0.45, 0.04, -0.25), Color("2fae4e"), Vector3(0.3, 0.04, 0.24))
		_cloth("c_yellow", Vector3(-0.15, 0.04, -0.5), Color("ffd23f"), Vector3(0.16, 0.04, 0.1))
		for i in 2:
			LifeRoomKit.box(scenery(), "White", Vector3(0.28, 0.04, 0.2), (baskets.whites as Vector3) + Vector3(-0.12 + i * 0.2, 0.01 + i * 0.03, 0), WHITE)
		var sock := LifeRoomKit.box(self, "RedSock", Vector3(0.14, 0.05, 0.08), (baskets.whites as Vector3) + Vector3(0.05, 0.07, 0.08),
			Color("e8544e"))
		add_target("red_sock", sock, 0.12)
		sock.visible = false
	else:
		# Big: the washing machine and the care label's picture board
		var m := l + Vector3(-1.9, 0, -1.6)
		LifeRoomKit.box(scenery(), "Machine", Vector3(0.6, 0.85, 0.6), m + Vector3(0, 0.425, 0), WHITE)
		wm_door = LifeRoomKit.cylinder(self, "Door", 0.2, 0.04, m + Vector3(0, 0.42, 0.31), Color("9fd8ff"))
		wm_door.rotation.x = PI / 2
		add_target("wm_door", wm_door, 0.16)
		var dial := LifeRoomKit.cylinder(self, "Dial", 0.05, 0.03, m + Vector3(-0.15, 0.74, 0.31), Color("9aa7b5"))
		dial.rotation.x = PI / 2
		add_target("wm_dial", dial, 0.07)
		var start := LifeRoomKit.box(self, "Start", Vector3(0.08, 0.05, 0.03), m + Vector3(0.15, 0.74, 0.31), Color("2fae4e"))
		add_target("wm_start", start, 0.07)
		wm_screen = LifeRoomKit.sign(self, "Time", "--", m + Vector3(0.02, 0.76, 0.33), 0.0018, INK)
		wm_screen.outline_size = 0
		label_board = Node3D.new()
		label_board.name = "CareLabel"
		label_board.position = l + Vector3(1.6, 1.3, -2.3)
		add_child(label_board)
		LifeRoomKit.box(label_board, "Tag", Vector3(0.9, 0.7, 0.03), Vector3.ZERO, WHITE)
		LifeRoomKit.sign(label_board, "Title", "CARE LABEL", Vector3(0, 0.27, 0.03), 0.0025, INK)
		for k: Array in [["label_30", "30"], ["label_40", "40"], ["label_hand", "HAND"], ["label_no_tumble", "NO DRYER"]]:
			var n := Node3D.new()
			n.name = "Symbol_" + str(k[0])
			n.visible = false
			label_board.add_child(n)
			labels[k[0]] = n
			LifeRoomKit.box(n, "Symbol", Vector3(0.36, 0.26, 0.01), Vector3(0, -0.05, 0.025), Color("dfe7f5"))
			LifeRoomKit.sign(n, "Words", str(k[1]), Vector3(0, -0.05, 0.04), 0.004, INK)
		var jumper := LifeRoomKit.box(self, "Jumper", Vector3(0.4, 0.04, 0.36), l + Vector3(0.0, 0.04, -0.2), Color("7b5cd6"))
		jumper.name = "Jumper"


func _cloth(target_name: String, at: Vector3, colour: Color, size: Vector3) -> void:
	var c := LifeRoomKit.box(self, "Cloth_" + target_name, size, LAUNDRY + at, colour)
	add_target(target_name, c, 0.16)


# --- The bedroom ----------------------------------------------------------------------------------------------------------

func _bedroom() -> void:
	LifeRoomKit.box(scenery(), "Bed", Vector3(1.9, 0.45, 0.9), Vector3(0.4, 0.225, -1.5), Color("5aa8e6"))
	LifeRoomKit.box(scenery(), "Pillow", Vector3(0.4, 0.1, 0.6), Vector3(-0.35, 0.5, -1.5), WHITE)
	LifeRoomKit.box(scenery(), "Drawers", Vector3(0.7, 0.8, 0.45), Vector3(2.0, 0.4, -2.0), WOOD)
	var drawer := LifeRoomKit.box(self, "Drawer", Vector3(0.6, 0.18, 0.04), Vector3(2.0, 0.62, -1.76), WOOD.lightened(0.15))
	add_target("drawer", drawer, 0.14)
	# the T-shirt on the bed: two sleeves and its body
	tshirt = Node3D.new()
	tshirt.name = "TShirt"
	tshirt.position = Vector3(0.6, 0.47, -1.35)
	add_child(tshirt)
	LifeRoomKit.box(tshirt, "Body", Vector3(0.34, 0.02, 0.4), Vector3.ZERO, Color("3a7be8"))
	for side: int in [-1, 1]:
		var s := LifeRoomKit.box(tshirt, "Sleeve", Vector3(0.16, 0.02, 0.14), Vector3(0.25 * side, 0, -0.12), Color("3a7be8").darkened(0.1))
		sleeves.append(s)
	add_target("fold_left", sleeves[0], 0.08)
	add_target("fold_right", sleeves[1], 0.08)
	add_spot_target("fold_half", tshirt, Vector3(0, 0.02, 0.14), 0.09)
	# the socks to pair
	LifeRoomKit.box(self, "SockA", Vector3(0.08, 0.03, 0.18), Vector3(-0.15, 0.47, -1.2), Color("e8544e"))
	for s: Array in [["sock_stripe_b", Vector3(1.15, 0.47, -1.15), Color("e8544e")], ["sock_spot_a", Vector3(1.0, 0.47, -1.6), Color("ffd23f")],
			["sock_spot_b", Vector3(-0.05, 0.47, -1.65), Color("ffd23f")]]:
		var sock := LifeRoomKit.box(self, "Sock", Vector3(0.08, 0.03, 0.18), s[1], s[2])
		add_target(str(s[0]), sock, 0.08)
		LifeRoomKit.box(sock, "Mark", Vector3(0.082, 0.032, 0.03), Vector3(0, 0, 0.03), WHITE if str(s[0]).contains("stripe") else Color("e85a9a"))
	# the toys and their homes
	LifeRoomKit.box(scenery(), "ToyBox", Vector3(0.6, 0.45, 0.45), Vector3(-1.6, 0.225, -2.0), Color("e8544e"))
	LifeRoomKit.box(scenery(), "Shelf", Vector3(0.8, 0.04, 0.25), Vector3(-0.6, 1.0, -2.3), WOOD)
	LifeRoomKit.box(scenery(), "ShoeRack", Vector3(0.7, 0.3, 0.3), Vector3(1.6, 0.15, 0.7), WOOD.darkened(0.1))
	homes = {"toy_car": Vector3(-1.6, 0.5, -2.0), "book": Vector3(-0.6, 1.12, -2.3), "teddy": Vector3(-0.35, 0.62, -1.3),
		"shoes": Vector3(1.6, 0.36, 0.7)}
	if track == "little":
		var car := LifeRoomKit.box(self, "ToyCar", Vector3(0.18, 0.08, 0.1), Vector3(-0.7, 0.04, 0.0), Color("ffd23f"))
		add_target("toy_car", car, 0.14)
		var book := LifeRoomKit.box(self, "Book", Vector3(0.2, 0.04, 0.26), Vector3(0.2, 0.02, 0.2), Color("7b5cd6"))
		add_target("book", book, 0.14)
		var teddy := LifeRoomKit.sphere(self, "Teddy", 0.12, Vector3(-0.15, 0.12, -0.55), Color("c98a4a"))
		add_target("teddy", teddy, 0.14)
		var shoes := LifeRoomKit.box(self, "Shoes", Vector3(0.26, 0.08, 0.2), Vector3(0.75, 0.04, 0.35), Color("3a5aa8"))
		add_target("shoes", shoes, 0.14)


# --- The kitchen: the table, the bins, the dishwasher ---------------------------------------------------------------------

func _kitchen() -> void:
	var k := KITCHEN
	LifeRoomKit.box(scenery(), "Counter", Vector3(1.2, 0.9, 0.5), k + Vector3(-2.2, 0.45, -1.6), Color("7fb8d6"))
	for b: Array in BINS:
		var at := k + Vector3(float(b[3]), 0, -1.9)
		var bin := LifeRoomKit.box(self, "Bin", Vector3(0.55, 0.8, 0.45), at + Vector3(0, 0.4, 0), b[2])
		LifeRoomKit.box(bin, "Lid", Vector3(0.6, 0.06, 0.5), Vector3(0, 0.43, 0), (b[2] as Color).darkened(0.2))
		LifeRoomKit.sign(self, "BinSign", str(b[1]), at + Vector3(0, 1.05, 0.1), 0.0028, INK)
		add_target(str(b[0]), bin, 0.3)
		homes[b[0]] = at + Vector3(0, 0.75, 0)
	# the table to set: its places
	var t := k + Vector3(0, 0, 0.9)
	LifeRoomKit.box(scenery(), "Table", Vector3(1.2, 0.72, 0.8), t + Vector3(0, 0.36, 0), WOOD)
	LifeRoomKit.box(scenery(), "Mat", Vector3(0.6, 0.01, 0.4), t + Vector3(0, 0.725, -0.1), Color("f6b5a8"))
	for p: Array in [["lay_plate", Vector3(0, 0.74, -0.1)], ["lay_fork", Vector3(-0.24, 0.74, -0.1)],
			["lay_knife", Vector3(0.24, 0.74, -0.1)], ["lay_cup", Vector3(0.24, 0.76, -0.3)]]:
		add_spot_target(str(p[0]), self, t + (p[1] as Vector3), 0.08)
	if track == "big":
		var d := k + Vector3(2.4, 0, -1.6)
		LifeRoomKit.box(scenery(), "Dishwasher", Vector3(0.6, 0.85, 0.6), d + Vector3(0, 0.425, 0), Color("dfe3ea"))
		LifeRoomKit.box(scenery(), "Door", Vector3(0.6, 0.05, 0.6), d + Vector3(0, 0.05, 0.6), Color("c9ced6"))
		add_spot_target("rack_plate", self, d + Vector3(-0.12, 0.25, 0.05), 0.1)
		add_spot_target("rack_cup", self, d + Vector3(0.12, 0.62, 0.05), 0.1)
		var basket := LifeRoomKit.box(scenery(), "Basket", Vector3(0.16, 0.18, 0.12), d + Vector3(0.2, 0.25, 0.25), Color("9aa7b5"))
		basket.name = "CutleryBasket"
		var down := add_spot_target("slot_down", self, d + Vector3(0.16, 0.36, 0.25), 0.05)
		LifeRoomKit.sign(down, "Down", "POINT DOWN", Vector3(0, 0.12, 0), 0.0018, INK)
		var up := add_spot_target("slot_up", self, d + Vector3(0.27, 0.36, 0.25), 0.05)
		LifeRoomKit.sign(up, "Up", "POINT UP", Vector3(0, 0.2, 0), 0.0018, INK)


# --- Biscuit's corner ------------------------------------------------------------------------------------------------------

func _pets() -> void:
	var p := PETS
	dog = LifeDog.new(LifeDog.COAT, "Biscuit")
	dog.position = p + Vector3(-0.3, 0, -1.2)
	add_child(dog)
	LifeRoomPeople.merge_dog(dog)   # the Quest's draws: his head's boxes in one
	var bowl := LifeRoomKit.cylinder(self, "FoodBowl", 0.12, 0.08, p + Vector3(-0.25, 0.04, -0.45), Color("e8544e"))
	add_target("dog_bowl", bowl, 0.14)
	var wbowl := LifeRoomKit.cylinder(self, "WaterBowl", 0.12, 0.08, p + Vector3(0.2, 0.04, -0.45), Color("3a7be8"))
	add_target("water_bowl", wbowl, 0.14)
	water = LifeRoomKit.cylinder(wbowl, "Water", 0.1, 0.01, Vector3(0, 0.0, 0), Color(0.45, 0.75, 0.95, 0.85))
	water.visible = false
	LifeRoomKit.box(scenery(), "Hook", Vector3(0.04, 0.04, 0.08), p + Vector3(0.7, 1.25, -2.36), Color("9aa7b5"))
	var lead := LifeRoomKit.box(self, "Lead", Vector3(0.04, 0.5, 0.03), p + Vector3(0.7, 1.0, -2.32), Color("e8544e"))
	add_target("dog_lead", lead, 0.12)
	LifeRoomKit.box(scenery(), "DogBed", Vector3(0.8, 0.12, 0.6), p + Vector3(-0.9, 0.06, -1.7), Color("ffb347"))


# --- The windowsill's plant -----------------------------------------------------------------------------------------------

func _plants() -> void:
	var p := PLANTS
	decor().window("Window", p + Vector3(0, 1.6, -2.39), 1.3, 0.85, 0.0)
	LifeRoomKit.box(scenery(), "Sill", Vector3(1.4, 0.05, 0.3), p + Vector3(0, 0.88, -2.2), WHITE)
	LifeRoomKit.box(scenery(), "SillStand", Vector3(1.4, 0.86, 0.3), p + Vector3(0, 0.43, -2.2), WALL.darkened(0.05))
	var pot := LifeRoomKit.cylinder(self, "Pot", 0.12, 0.2, p + Vector3(0, 1.0, -2.2), Color("c0563a"))
	add_target("plant_a", pot, 0.16)
	plant_soil = LifeRoomKit.cylinder(pot, "Soil", 0.11, 0.02, Vector3(0, 0.1, 0), SOIL_DRY)
	LifeRoomKit.sphere(pot, "Leaves", 0.16, Vector3(0, 0.28, 0), Color("4f9a3e"))
	LifeRoomKit.box(scenery(), "WateringCan", Vector3(0.24, 0.18, 0.12), p + Vector3(0.5, 1.0, -2.2), Color("2fae4e"))


# --- The hall's practice smoke alarm --------------------------------------------------------------------------------------

func _hall() -> void:
	var h := HALL
	LifeRoomKit.box(scenery(), "Alarm", Vector3(0.2, 0.2, 0.06), h + Vector3(0, 1.55, -2.37), WHITE)
	var button := LifeRoomKit.cylinder(self, "TestButton", 0.035, 0.02, h + Vector3(0, 1.55, -2.33), Color("e8544e"))
	button.rotation.x = PI / 2
	add_target("smoke_test", button, 0.07)
	LifeRoomKit.sign(self, "AlarmSign", "PRACTICE SMOKE ALARM", h + Vector3(0, 1.85, -2.3), 0.003, INK)
	gus = LifeBuddy.new(Color("7b5cd6"), "Gus")
	gus.scale = Vector3.ONE * 1.55
	gus.position = h + Vector3(-0.8, 0, -1.4)
	gus.rotation.y = 0.6
	add_child(gus)
	LifeRoomPeople.merge_person(gus, true)   # the Quest's draws: Gus never changes pose


func _views() -> void:
	add_view("laundry", LAUNDRY + Vector3(0.3, 1.9, 1.7), LAUNDRY + Vector3(0, 0.3, -0.8), LAUNDRY + Vector3(0, 0, 0.6), 0.0)
	add_view("machine", LAUNDRY + Vector3(-1.5, 1.3, 0.4), LAUNDRY + Vector3(-1.9, 0.6, -1.3), LAUNDRY + Vector3(-1.9, 0, -0.6), 0.0)
	add_view("label", LAUNDRY + Vector3(1.4, 1.4, 0.2), LAUNDRY + Vector3(1.6, 1.25, -2.3), LAUNDRY + Vector3(1.5, 0, -1.2), 0.0)
	add_view("bed", Vector3(0.5, 1.45, 0.1), Vector3(0.5, 0.45, -1.4), Vector3(0.6, 0, -0.55), 0.0)
	add_view("bedroom", Vector3(0.2, 2.2, 2.4), Vector3(0.0, 0.3, -0.7), Vector3(0, 0, 0.9), 0.0)
	add_view("bins", KITCHEN + Vector3(0, 1.7, 0.7), KITCHEN + Vector3(0, 0.7, -1.9), KITCHEN + Vector3(0, 0, -0.6), 0.0)
	add_view("table", KITCHEN + Vector3(0, 1.6, 2.4), KITCHEN + Vector3(0, 0.72, 0.8), KITCHEN + Vector3(0, 0, 1.75), 0.0)
	add_view("dishwasher", KITCHEN + Vector3(2.3, 1.4, 0.6), KITCHEN + Vector3(2.4, 0.4, -1.4), KITCHEN + Vector3(2.4, 0, -0.7), 0.0)
	add_view("pet", PETS + Vector3(0.0, 1.6, 1.4), PETS + Vector3(-0.1, 0.3, -1.1), PETS + Vector3(0, 0, 0.0), 0.0)
	add_view("plants", PLANTS + Vector3(0.2, 1.5, -0.6), PLANTS + Vector3(0.1, 1.0, -2.2), PLANTS + Vector3(0, 0, -1.45), 0.0)
	add_view("hall", HALL + Vector3(0.3, 1.5, -0.6), HALL + Vector3(0, 1.45, -2.3), HALL + Vector3(0, 0, -1.6), 0.0)


# --- Steps and events -------------------------------------------------------------------------------------------------------

func on_event(event: String) -> void:
	if ITEMS.has(event):
		_show_item(event)
		return
	match event:
		"red_sock_in_whites":
			if has_target("red_sock"):
				target_node("red_sock").visible = true
		"alarm_beep":
			if is_inside_tree():
				Audio.play(&"beep", Vector3.INF, -10.0)
		"label_30", "label_40", "label_hand", "label_no_tumble":
			for k: String in labels:
				(labels[k] as Node3D).visible = k == event


func _show_item(event: String) -> void:
	if is_instance_valid(item):
		item.queue_free()
	var d: Array = ITEMS[event]
	item = LifeRoomKit.box(self, "Item", d[2], KITCHEN + Vector3(-2.2, 0.92 + (d[2] as Vector3).y * 0.5, -1.55), d[1])
	item_event = event


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"socks":
			target_node("sock_stripe_b").position = Vector3(-0.05, 0.47, -1.2)   # beside its partner: a pair
		"red_sock":
			target_node("red_sock").position = (baskets.colours as Vector3) + Vector3(0, 0.07, 0)
		"paper", "bottle", "can", "jar", "apple":
			if is_instance_valid(item):
				item.position = homes.get(str(ITEMS[item_event][0]), item.position)
				item.visible = false   # in its bin
		"food":
			LifeRoomKit.sphere(target_node("dog_bowl"), "Food", 0.08, Vector3(0, 0.05, 0), Color("a8642a"))
		"walk":
			target_node("dog_lead").visible = false
		"knives":
			var knife := LifeRoomKit.box(self, "Knife", Vector3(0.02, 0.2, 0.01), to_local(target_position("slot_down"))
				+ Vector3(0, -0.05, 0), Color("a9b3bf"))
			knife.name = "KnifeDown"


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"find":
			var into := "colours" if str(step.get("id", "")) == "sort" else "whites"
			var found: Array = state.get("found", [])
			for i in found.size():
				var t := str(found[i])
				if not has_target(t) or target_node(t).has_meta(&"home"):
					continue
				var n := target_node(t)
				n.set_meta(&"home", true)
				if homes.has(t):   # a toy back in its home
					n.position = homes[t]
				else:   # washing into its basket, one on another
					n.position = (baskets[into] as Vector3) + Vector3(-0.1 + 0.07 * (i % 3), 0.02 + 0.03 * i, 0)
		"sequence":
			var done: Array = (step.targets as Array).slice(0, int(state.get("i", 0)))
			for t: Variant in done:
				_sequence_done(str(t))
		"pour":
			var level := clampf(float(state.get("level", 0.0)), 0.0, 1.0)
			if str(step.get("target", "")) == "plant_a" and is_instance_valid(plant_soil):
				var damp := snappedf(clampf(level / 0.6, 0.0, 1.0), 0.25)   # four shades: the cache keeps four materials
				plant_soil.material_override = LifeRoomKit.material(SOIL_DRY.lerp(SOIL_WET, damp))
			elif str(step.get("target", "")) == "water_bowl" and is_instance_valid(water):
				water.visible = level > 0.05
				water.position.y = -0.03 + 0.06 * level


func _sequence_done(t: String) -> void:
	match t:
		"fold_left":
			sleeves[0].position = Vector3(-0.08, 0.02, -0.08)
		"fold_right":
			sleeves[1].position = Vector3(0.08, 0.02, -0.08)
		"fold_half":
			tshirt.scale = Vector3(1, 1, 0.5)
			tshirt.position.z = -1.45
		"drawer":
			tshirt.visible = false
		"wm_door":
			if wm_door:
				wm_door.material_override = LifeRoomKit.material(Color("6fb7ea"))
		"wm_dial":
			if wm_screen:
				wm_screen.text = "30"
		"wm_start":
			if wm_screen:
				wm_screen.text = "1:30"
		"lay_plate", "lay_fork", "lay_knife", "lay_cup":
			var n := target_node(t)
			if n and n.get_node_or_null("Laid") == null:
				var size: Vector3 = {"lay_plate": Vector3(0.24, 0.02, 0.24), "lay_fork": Vector3(0.03, 0.01, 0.2),
					"lay_knife": Vector3(0.03, 0.01, 0.22), "lay_cup": Vector3(0.08, 0.1, 0.08)}[t]
				var c: Color = Color("fdfdf8") if t == "lay_plate" else (Color("5aa8e6") if t == "lay_cup" else Color("a9b3bf"))
				LifeRoomKit.box(n, "Laid", size, Vector3.ZERO, c)
		"rack_plate", "rack_cup":
			var n := target_node(t)
			if n and n.get_node_or_null("Loaded") == null:
				LifeRoomKit.box(n, "Loaded", Vector3(0.2, 0.2, 0.02) if t == "rack_plate" else Vector3(0.08, 0.1, 0.08), Vector3.ZERO,
					Color("fdfdf8"))


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## One home along its back wall: a plank floor, warm walls with a wallpaper band and a skirting, short walls between its
## corners (the dog's corner, the laundry, the bedroom, the kitchen, the plants, the hall), windows over the garden, a
## ceiling with lights, pictures, rugs, a laundry shelf, a kitchen splashback, a coat rack and the front door in the hall.
## Never on a chore's things, a view's line or where the child stands.
func _house_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Garden", Vector3(80, 0.1, 70), Vector3(2, -0.16, 0), Color("8cc56a"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(30, 0.1, 5), Vector3(2, -0.05, -0.3), Color("f2dcc0"), 0.75)
	d.box("BackWall", Vector3(30, 2.6, 0.1), Vector3(2, 1.3, -2.45), WALL, 0.0, LifeRoomDecor.SHELL)
	d.box("Wallpaper", Vector3(30, 1.5, 0.02), Vector3(2, 1.85, -2.395), Color("eef3e6"), 0.0, LifeRoomDecor.SHELL)
	d.skirting("Skirting", Vector3(-13, 0, -2.39), Vector3(17, 0, -2.39), Color("c89a62"))
	for x: float in [-13.0, 17.0]:
		d.box("EndWall", Vector3(0.1, 2.6, 5.0), Vector3(x, 1.3, -0.3), WALL.darkened(0.03), 0.0, LifeRoomDecor.SHELL)
	for x: float in [-8.5, -3.0, 2.9, 9.0, 13.0]:   # short walls between the corners
		d.box("Partition", Vector3(0.1, 1.2, 1.0), Vector3(x, 0.6, -1.9), Color("c89a62"), 0.0, LifeRoomDecor.SHELL)
		d.box("PartitionTop", Vector3(0.14, 0.05, 1.04), Vector3(x, 1.22, -1.9), Color("8a6239"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Ceiling", LifeRoomDecor.TILE, Vector3(30, 0.1, 5.0), Vector3(2, 2.65, -0.3), Color("fbf8f2"), 0.8)
	for x: float in [-11.0, -6.0, 0.0, 6.0, 11.0, 15.0]:
		d.ceiling_light("Light", Vector3(x, 2.58, -0.6), 0.28)
	# windows over the garden: the bedroom and the kitchen (the plants' is its own)
	d.window("Window", Vector3(0.95, 1.6, -2.39), 0.9, 0.8, 0.0)
	d.window("Window", Vector3(6.0, 1.78, -2.39), 1.0, 0.7, 0.0)
	# the dog's corner: a picture of a bone, a rug
	d.picture("DogPicture", Vector3(-12.2, 1.6, -2.39), Vector2(0.5, 0.4), 0.0, Color("ffb347"), Color("fff6e0"), 0)
	# the laundry: its tiled floor, a shelf of soap bottles high on the wall
	d.tiled("LaundryFloor", LifeRoomDecor.TILE, Vector3(5.4, 0.012, 4.9), Vector3(-5.75, 0.006, -0.3), Color("dfeef2"), 0.5)
	d.box("LaundryShelf", Vector3(1.0, 0.04, 0.24), Vector3(-7.6, 1.95, -2.28), Color("c89a62"))
	for k in 4:
		d.box("Bottle", Vector3(0.1, 0.22, 0.1), Vector3(-7.95 + k * 0.23, 2.08, -2.28), [Color("3a7be8"), Color("e85a9a"),
			Color("2fae4e"), Color("ffd23f")][k])
	# the bedroom: a rug, a picture
	d.rug("Rug", Vector3(0.0, 0.0, 0.55), Vector2(1.8, 1.1), Color("cfe0ee"), Color("3a7be8"))
	d.picture("BedPicture", Vector3(-1.9, 1.6, -2.39), Vector2(0.55, 0.45), 0.0, Color("e8544e"), Color("fff6e0"), 2)
	# the kitchen: a tiled splashback behind the counter, a clock
	d.tiled("Splashback", LifeRoomDecor.TILE, Vector3(1.3, 0.5, 0.02), Vector3(3.8, 1.2, -2.385), Color("d6ecf2"), 0.2)
	d.box("Clock", Vector3(0.3, 0.3, 0.04), Vector3(8.3, 1.95, -2.39), Color("fdfdf8"))
	# the plants: a second plant on the floor
	d.plant("FloorPlant", Vector3(12.4, 0, -2.0), 1.2, Color("3a7be8"))
	# the hall: a coat rack, the front door, a mat
	d.box("FrontDoor", Vector3(1.0, 2.05, 0.06), Vector3(16.1, 1.03, -2.4), Color("b07a46"))
	d.box("DoorMat", Vector3(1.0, 0.02, 0.6), Vector3(16.1, 0.01, -1.9), Color("8a6239"), 0.0, LifeRoomDecor.SHELL)
	d.box("CoatRack", Vector3(0.6, 0.06, 0.1), Vector3(13.8, 1.7, -2.36), Color("8a6239"))
	d.box("Coat", Vector3(0.26, 0.55, 0.08), Vector3(13.65, 1.4, -2.33), Color("3a7be8"))
	d.box("Coat", Vector3(0.24, 0.5, 0.08), Vector3(13.95, 1.42, -2.32), Color("e8544e"))
