class_name MarketSquareRoom
extends LifeRoom
## Owner #115 (docs/design/success-skills.md §2.2 the Market Square; the S3 brief): the Market Square's practice room.
## A sunny cobbled square: the child's own stall in front (the coin tray of pretend coins), the buddy merchants' stalls
## round it (Tomas's flour, Ana's apples and wheat, Kenji's honey, Amara's cakes: the Connections Book's people), and at
## the back the big PRICE BOARD: a row for each good (its name, today's price, an arrow up or down and why it moved), read
## by laser in VR. Beside the square a strip of wheat field (short and dry in a dry summer, golden at the harvest).
## - Little: the swap stall (your apples, Lina's pears, the swap table; Mo with a sticker; Rosa with a jar).
## - Middle: the board's causes come to life: a dry summer, the festival's bunting, four more apple carts, autumn's
##   harvest; Tomas's stall to buy flour, Ana's cart to haggle and shake hands.
## - Big: the storage shed, three baskets (wheat, apples, honey), a storm over the wheat, and the dice table: a big soft
##   dice and a chart board that draws 600 throws with pretend counters (the line falls: why gambling loses over time).
## Only LifeRoomKit's warmed shaders; no shadows of its own.

const COBBLE := Color("d8cbb0")
const COUNTER := Color("b07a46")
const BOARD := Color("2f4a3d")
const WHEAT := Color("e6c35a")
const WHEAT_DRY := Color("b89a5a")
const GREEN := Color("6aa84f")
const UP := Color("4fbf6a")
const DOWN := Color("e8705a")
const TRAY_AT := Vector3(-0.05, 0.91, -0.64)
const HAND_AT := Vector3(0, 1.0, -1.2)
const BOARD_AT := Vector3(0, 2.0, -6.5)
const ROWS: Array[String] = ["wheat", "flour", "apples", "honey", "cakes"]
const TOMAS_AT := Vector3(-4.0, 0, -3.0)
const ANA_AT := Vector3(4.0, 0, -3.0)
const SHED_AT := Vector3(5.6, 0, 0.6)
const DICE_AT := Vector3(-3.5, 0.0, 1.15)
const CHART_AT := Vector3(-4.6, 1.45, 1.15)

var till := SuccessTill.new()
var rows := {}         # good -> {price: Label3D, arrow: Label3D, why: Label3D}
var prices := {}       # good -> the price shown now
var field: Array[MeshInstance3D] = []
var bunting: Node3D
var extra_carts: Node3D
var extra_cakes: Node3D
var storm: Node3D
var customer: LifeBuddy
var lina: LifeBuddy
var mo: LifeBuddy
var rosa: LifeBuddy
var pip: LifeBuddy
var apples_on_table: Array[MeshInstance3D] = []
var apple_basket: Node3D
var shed_bags: Array[MeshInstance3D] = []
var basket_fill := {}
var dice: MeshInstance3D
var dice_face: Label3D
var dice_count: Label3D
var chart_points: Array[MeshInstance3D] = []
var chart_label: Label3D
var throws_seen := 0
var merchants: Array[LifeBuddy] = []
var _field_look: MeshInstance3D
var _chart_line: Node3D


func build() -> void:
	name = "MarketSquareRoom"
	env = LifeRoomKit.environment(Color("7fbfef"), Color("f4f0e0"), 0.72)
	start_view = "swap" if track == "little" else "stall"
	_square_look()   # the rooms' look (2026-10-17): the square's paving, houses, lamps and trees
	LifeRoomKit.light(self, Vector3(0, 4, -2), 0.6, 14.0)
	_stall()
	if track == "little":
		_swap_stall()
	else:
		_board()
		_field()
		_merchants()
		customer = LifeBuddy.new(Color("8b6fd6"), "Customer")
		customer.position = Vector3(0, 0, -1.85)
		customer.visible = false
		add_child(customer)
		add_target("customer", customer.hips, 0.35)
	if track == "big":
		_shed()
		_baskets()
		_dice_table()
	_people_look()
	add_view("stall", Vector3(0, 1.45, 0.85), Vector3(0, 0.95, -1.0), Vector3(0, 0, 0), 0.0)
	add_view("swap", Vector3(0, 1.45, 0.85), Vector3(0, 0.95, -1.0), Vector3(0, 0, 0), 0.0)
	if track != "little":
		add_view("board", Vector3(0, 1.6, -2.4), BOARD_AT, Vector3(0, 0, -3.0), 0.0)
		add_view("square", Vector3(0, 3.2, 3.2), Vector3(-1.4, 0.2, -2.2), Vector3(0, 0, 0), 0.0)
		add_view("tomas", Vector3(-2.6, 1.5, -1.0), TOMAS_AT + Vector3(0, 1.0, 0), Vector3(-3.2, 0, -1.8),
			atan2(-(TOMAS_AT.x + 3.2), -(TOMAS_AT.z + 1.8)))
		add_view("ana", Vector3(2.6, 1.5, -1.0), ANA_AT + Vector3(0, 1.0, 0), Vector3(3.2, 0, -1.8),
			atan2(-(ANA_AT.x - 3.2), -(ANA_AT.z + 1.8)))
	if track == "big":
		add_view("shed", Vector3(3.3, 1.5, 1.7), SHED_AT + Vector3(-0.3, 0.9, 0), Vector3(3.9, 0, 1.2),
			atan2(-(SHED_AT.x - 3.9), -(SHED_AT.z - 1.2)))
		add_view("baskets", Vector3(0, 1.45, 0.7), Vector3(0, 0.95, -1.0), Vector3(0, 0, 0), 0.0)
		add_view("dice", Vector3(-2.0, 1.5, 1.6), DICE_AT + Vector3(-0.4, 1.0, 0), Vector3(-2.7, 0, 1.3),
			atan2(-(DICE_AT.x + 2.7), -(DICE_AT.z - 1.3)))


func _stall() -> void:
	var sc := scenery()
	decor().tiled("Counter", LifeRoomDecor.PLANKS, Vector3(2.2, 0.9, 0.7), Vector3(0, 0.45, -0.9), Color("f6dcb4"), 0.9, 0.0,
		LifeRoomDecor.BAKED)   # a wooden counter (where the plain box stood)
	for i in 6:
		LifeRoomKit.box(sc, "Awning", Vector3(0.38, 0.06, 1.1), Vector3(-0.95 + i * 0.38, 2.15, -0.9),
			Color("3a7be8") if i % 2 == 0 else Color("fdfdf8"))
	for x: float in [-1.05, 1.05]:
		LifeRoomKit.box(sc, "Pole", Vector3(0.06, 2.15, 0.06), Vector3(x, 1.07, -1.2), Color("6b4a2a"))
	# on top of the awning (in front of it the first view cut it at the frame's top)
	LifeRoomKit.sign(self, "StallSign", "SWAP STALL" if track == "little" else "MY STALL", Vector3(0, 2.42, -0.4), 0.0034)
	var values: Array = {"little": [], "middle": [1, 2, 5], "big": [1, 2, 5, 10]}.get(track, [])
	till.build(self, TRAY_AT, values)
	till.add_place("hand", HAND_AT, 0.15)
	if track != "little":
		till.add_place("tomas", at_stall(TOMAS_AT, Vector3(0.3, 1.0, 0.45)), 0.15)


func _swap_stall() -> void:
	apple_basket = Node3D.new()
	apple_basket.name = "Apples"
	apple_basket.position = Vector3(-0.55, 0.9, -0.78)
	add_child(apple_basket)
	LifeRoomKit.cylinder(apple_basket, "Basket", 0.16, 0.12, Vector3(0, 0.06, 0), Color("c9a063"))
	for i in 6:
		LifeRoomKit.sphere(apple_basket, "Apple", 0.045, Vector3(-0.07 + (i % 3) * 0.07, 0.15, -0.04 + (i / 3) * 0.08), Color("e8544e"))
	add_spot_target("apples", apple_basket, Vector3(0, 0.12, 0), 0.16)
	var pears := Node3D.new()
	pears.name = "Pears"
	pears.position = Vector3(0.55, 0.9, -0.78)
	scenery().add_child(pears)
	LifeRoomKit.cylinder(pears, "Basket", 0.16, 0.12, Vector3(0, 0.06, 0), Color("c9a063"))
	for i in 6:
		LifeRoomKit.sphere(pears, "Pear", 0.045, Vector3(-0.07 + (i % 3) * 0.07, 0.15, -0.04 + (i / 3) * 0.08), Color("b8d65a"))
	add_spot_target("pears", pears, Vector3(0, 0.12, 0), 0.16)
	LifeRoomKit.box(scenery(), "SwapTable", Vector3(0.5, 0.02, 0.3), Vector3(0, 0.91, -0.86), Color("fdf6e3"))
	LifeRoomKit.sign(self, "SwapWords", "SWAP", Vector3(0, 1.02, -0.86), 0.0026, Color("1f2a4a"))
	lina = SuccessCast.person("lina", Vector3(0.2, 0, -1.85))
	add_child(lina)
	add_target("lina", lina.hips, 0.35)
	add_spot_target("lina_hand", self, Vector3(0.1, 1.0, -1.0), 0.16)
	mo = SuccessCast.person("mo", Vector3(-1.4, 0, -1.7), 0.4)
	mo.visible = false
	add_child(mo)
	LifeRoomKit.box(mo.hips, "Sticker", Vector3(0.1, 0.1, 0.01), Vector3(0.2, 0.35, 0.16), Color("ffd23f"))
	rosa = SuccessCast.person("rosa", Vector3(1.4, 0, -1.7), -0.4)
	rosa.visible = false
	add_child(rosa)
	LifeRoomKit.cylinder(rosa.hips, "Jar", 0.05, 0.12, Vector3(-0.22, 0.35, 0.18), Color("d9437a"))


func _board() -> void:
	var sc := scenery()
	LifeRoomKit.box(sc, "PriceBoard", Vector3(3.4, 2.2, 0.08), BOARD_AT, BOARD)
	for x: float in [-1.6, 1.6]:
		LifeRoomKit.box(sc, "BoardLeg", Vector3(0.08, 1.0, 0.08), Vector3(x, 0.5, BOARD_AT.z), Color("6b4a2a"))
	LifeRoomKit.sign(self, "BoardTitle", "PRICE BOARD", BOARD_AT + Vector3(0, 0.9, 0.06), 0.006, Color("ffd23f"))
	# its title is the board's own target, clear of the rows: a laser on a row never hits the whole board first
	add_spot_target("price_board", self, BOARD_AT + Vector3(0, 0.92, 0.06), 0.3)
	for i in ROWS.size():
		var id: String = ROWS[i]
		var y := BOARD_AT.y + 0.55 - i * 0.33
		var g := SuccessMarket.good(id)
		LifeRoomKit.sign(self, "Row_" + id, str(g.get("name", id)).to_upper(), Vector3(-1.1, y, BOARD_AT.z + 0.06), 0.004)
		var price := LifeRoomKit.sign(self, "Price_" + id, "", Vector3(0.1, y, BOARD_AT.z + 0.06), 0.0045, Color("ffd23f"))
		var arrow := LifeRoomKit.sign(self, "Arrow_" + id, "", Vector3(0.65, y, BOARD_AT.z + 0.06), 0.004)
		var why := LifeRoomKit.sign(self, "Why_" + id, "", Vector3(1.25, y, BOARD_AT.z + 0.06), 0.0025)
		rows[id] = {"price": price, "arrow": arrow, "why": why}
		add_spot_target("row_" + id, self, Vector3(-0.3, y, BOARD_AT.z + 0.06), 0.15)
		_set_row(id, int(g.get("base", 1)), "")


## A row of the Price Board: its price, an arrow (UP, DOWN, or nothing) and why it moved.
func _set_row(id: String, price: int, why: String) -> void:
	if not rows.has(id):
		return
	var base := int(SuccessMarket.good(id).get("base", price))
	prices[id] = price
	(rows[id].price as Label3D).text = str(price)
	var arrow: Label3D = rows[id].arrow
	arrow.text = "UP" if price > base else ("DOWN" if price < base else "")
	arrow.modulate = UP if price > base else DOWN
	(rows[id].why as Label3D).text = why


func _field() -> void:
	var d := LifeRoomDecor.new()   # the field drawn as one mesh (the Quest's draws); its boxes stay as the field's own
	for i in 9:
		var at := Vector3(-7.0 + (i % 3) * 0.7, 0.35, -4.5 + (i / 3) * 0.7)
		var m := LifeRoomKit.box(self, "Wheat", Vector3(0.6, 0.7, 0.6), at, WHEAT)
		m.visible = false
		field.append(m)
		d.box("Wheat", Vector3(0.6, 0.7, 0.6), at, WHEAT)
	_field_look = d.commit(self, "WheatField").get_child(0) as MeshInstance3D
	_field_look.material_override = LifeRoomKit.material(WHEAT)


func _set_field(height: float, colour: Color) -> void:
	for m in field:
		m.scale = Vector3(1, height, 1)
		m.position.y = 0.35 * height
		m.material_override = LifeRoomKit.material(colour)
	if _field_look:
		(_field_look.get_parent() as Node3D).scale = Vector3(1, height, 1)
		_field_look.material_override = LifeRoomKit.material(colour)


func _merchants() -> void:
	for m: Array in [["tomas", TOMAS_AT, "TOMAS'S FLOUR", Color("f4ecd8")], ["ana", ANA_AT, "ANA'S APPLES AND WHEAT", Color("e8544e")],
			["kenji", Vector3(-2.6, 0, -5.2), "KENJI'S HONEY", Color("e8b04a")], ["amara", Vector3(2.6, 0, -5.2), "AMARA'S CAKES",
			Color("f3d2a8")]]:
		var at: Vector3 = m[1]
		var face_yaw := atan2(-at.x, -at.z)   # the stall's front (+Z) towards the middle of the square
		var stall := Node3D.new()
		stall.name = "Stall_" + str(m[0])
		stall.position = at
		stall.rotation.y = face_yaw
		scenery().add_child(stall)
		LifeRoomKit.box(stall, "Counter", Vector3(1.4, 0.9, 0.6), Vector3(0, 0.45, 0.4), COUNTER.darkened(0.1))
		LifeRoomKit.box(stall, "Roof", Vector3(1.6, 0.08, 1.0), Vector3(0, 2.1, 0.3), Color("e8544e") if str(m[0]) == "ana" else Color("3a7be8"))
		for i in 3:
			LifeRoomKit.box(stall, "Goods", Vector3(0.22, 0.14, 0.18), Vector3(-0.4 + i * 0.4, 0.97, 0.45), m[3])
		# the far stalls: painted on a board up on a post over the roof; the near ones (by the first view's edges): painted
		# on the counter's front (floating in front of the roof each stood over its merchant's own name tag, and ran off
		# the first view's edges)
		var near := absf(at.z) < 4.0
		var sign_at := Vector3(0, 0.55, 0.715) if near else Vector3(0, 2.98, 0.335)
		if not near:
			LifeRoomKit.box(stall, "SignPost", Vector3(0.06, 0.8, 0.06), Vector3(0, 2.5, 0.3), Color("6b4a2a"))
			LifeRoomKit.box(stall, "SignBoard", Vector3(1.3, 0.5, 0.05), Vector3(0, 2.98, 0.3), Color("fdf6e3"))
		var sign := LifeRoomKit.sign(stall, "Sign", LifeRoomLook.two_lines(str(m[2])), sign_at, 0.0021,
			Color("fff6d8") if near else Color("1f2a4a"))
		sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		sign.outline_size = 8 if near else 0
		# a little in towards the square's middle (by the stall's end the first view cut Ana's head)
		var p := SuccessCast.person(str(m[0]), Vector3(-0.3 * signf(at.x), 0, -0.15))
		stall.add_child(p)
		merchants.append(p)
	add_spot_target("spot_tomas", self, Vector3(-3.2, 0.05, -1.8), 0.55)
	LifeRoomKit.cylinder(self, "TomasRing", 0.45, 0.02, Vector3(-3.2, 0.03, -1.8), Color(0.3, 0.85, 0.4, 0.6))
	add_spot_target("ana_hand", self, at_stall(ANA_AT, Vector3(0, 1.0, 0.8)), 0.16)
	bunting = Node3D.new()
	bunting.name = "Bunting"
	bunting.visible = false
	add_child(bunting)
	var cols := [Color("e8544e"), Color("ffd23f"), Color("3a7be8"), Color("6aa84f")]
	for i in 12:
		LifeRoomKit.box(bunting, "Flag", Vector3(0.22, 0.26, 0.02), Vector3(-3.3 + i * 0.6, 3.1, -4.0), cols[i % 4])
	extra_carts = Node3D.new()
	extra_carts.name = "MoreApples"
	extra_carts.visible = false
	add_child(extra_carts)
	for i in 4:
		var at := Vector3(5.0 + (i % 2) * 1.4, 0, -5.0 + (i / 2) * 1.5)
		LifeRoomKit.box(extra_carts, "Cart", Vector3(1.0, 0.45, 0.6), at + Vector3(0, 0.5, 0), Color("a8642a"))
		for j in 3:
			LifeRoomKit.sphere(extra_carts, "Apple", 0.08, at + Vector3(-0.25 + j * 0.25, 0.8, 0), Color("e8544e"))
	extra_cakes = Node3D.new()
	extra_cakes.name = "MoreCakes"
	extra_cakes.visible = false
	add_child(extra_cakes)
	for i in 3:
		var at := Vector3(-6.0 + i * 1.3, 0, -6.6)
		LifeRoomKit.box(extra_cakes, "CakeStall", Vector3(1.0, 0.8, 0.5), at + Vector3(0, 0.4, 0), COUNTER)
		LifeRoomKit.box(extra_cakes, "Cake", Vector3(0.24, 0.12, 0.24), at + Vector3(0, 0.86, 0), Color("f3d2a8"))


func _shed() -> void:
	var sc := scenery()
	decor().tiled("Shed", LifeRoomDecor.PLANKS, Vector3(1.6, 2.0, 1.6), SHED_AT + Vector3(0.4, 1.0, 0), Color("e8c8a0"), 0.8, 0.0,
		LifeRoomDecor.BAKED)
	LifeRoomKit.box(sc, "ShedRoof", Vector3(1.9, 0.2, 1.9), SHED_AT + Vector3(0.4, 2.1, 0), Color("6b4a2a"))
	LifeRoomKit.box(sc, "ShedDoor", Vector3(0.04, 1.4, 0.8), SHED_AT + Vector3(-0.41, 0.7, 0), Color("3b2a18"))
	LifeRoomKit.sign(self, "ShedSign", "MY SHED: 20 BAGS", SHED_AT + Vector3(-0.45, 1.8, 0), 0.0035)
	add_spot_target("shed", self, SHED_AT + Vector3(-0.45, 0.9, 0), 0.4)
	for i in 3:
		var b := LifeRoomKit.box(self, "Bag", Vector3(0.24, 0.3, 0.2), SHED_AT + Vector3(-0.9, 0.15, -0.35 + i * 0.35), Color("e8d39a"))
		shed_bags.append(b)


func _baskets() -> void:
	for b: Array in [["basket_wheat", -0.62, WHEAT], ["basket_apples", 0.0, Color("e8544e")], ["basket_honey", 0.62, Color("e8b04a")]]:
		var at := Vector3(float(b[1]), 0.9, -1.02)
		LifeRoomKit.cylinder(scenery(), str(b[0]), 0.15, 0.14, at + Vector3(0, 0.07, 0), Color("c9a063"))
		var fill := LifeRoomKit.cylinder(self, str(b[0]) + "_fill", 0.12, 0.05, at + Vector3(0, 0.16, 0), b[2])
		fill.visible = false
		basket_fill[b[0]] = fill
		add_spot_target(str(b[0]), self, at + Vector3(0, 0.12, 0), 0.15)
	storm = Node3D.new()
	storm.name = "Storm"
	storm.visible = false
	add_child(storm)
	LifeRoomKit.box(storm, "Cloud", Vector3(3.0, 0.6, 1.5), Vector3(-7.0, 3.4, -4.0), Color("7d8a99"))
	var rain := LifeRoomDecor.new()   # the drops in one see-through mesh (the Quest's draws)
	for i in 10:
		rain.glass("Rain", Vector3(0.015, 0.4, 0.015), Vector3(-8.0 + (i % 5) * 0.5, 2.2 - (i / 5) * 0.8, -4.5 + (i % 3) * 0.4),
			Color(0.55, 0.75, 1.0, 0.6))
	rain.commit(storm, "")


func _dice_table() -> void:
	var sc := scenery()
	LifeRoomKit.box(sc, "DiceTable", Vector3(0.9, 0.75, 0.7), DICE_AT + Vector3(0, 0.375, 0), Color("a8642a"))
	dice = LifeRoomKit.box(self, "Dice", Vector3(0.2, 0.2, 0.2), DICE_AT + Vector3(0.15, 0.85, -0.05), Color("fdfdf8"))
	add_target("dice", dice, 0.16)
	dice_face = LifeRoomKit.sign(dice, "Face", "", Vector3(0, 0.2, 0), 0.006, Color("1f2a4a"))
	dice_face.outline_size = 0
	dice_count = LifeRoomKit.sign(self, "Sixes", "", DICE_AT + Vector3(0.15, 1.35, -0.05), 0.0035)
	LifeRoomKit.sign(self, "Counters", "PRETEND COUNTERS", DICE_AT + Vector3(-0.2, 0.8, 0.2), 0.0025)
	LifeRoomKit.box(sc, "ChartBoard", Vector3(0.06, 1.2, 1.6), CHART_AT, Color("fdf6e3"))
	LifeRoomKit.sign(self, "ChartTitle", "COUNTERS AFTER EACH THROW", CHART_AT + Vector3(0.06, 0.7, 0), 0.0028, Color("1f2a4a"))
	LifeRoomKit.box(sc, "Zero", Vector3(0.02, 0.01, 1.5), CHART_AT + Vector3(0.05, 0.4, 0), Color("1f2a4a"))
	chart_label = LifeRoomKit.sign(self, "ChartEnd", "", CHART_AT + Vector3(0.08, -0.45, 0), 0.003, Color("1f2a4a"))
	pip = LifeBuddy.new(Color("ffd23f"), "PipPop")
	pip.position = DICE_AT + Vector3(0.55, 0, -0.75)   # across the table (behind it his name stood under the dice's count)
	pip.visible = false
	add_child(pip)
	LifeRoomKit.sign(pip, "Name", "PIP-POP", Vector3(0, 1.3, 0), SuccessCast.SIGN_PIXEL)


func on_event(event: String) -> void:
	match event:
		"dry":
			_set_field(0.45, WHEAT_DRY)
		"board_wheat":
			_set_row("wheat", int(vars.get("wheat_dry", 4)), "DRY SUMMER")
		"festival", "festival_both":
			bunting.visible = true
			if event == "festival_both" and extra_cakes:
				extra_cakes.visible = true
		"board_cakes":
			_set_row("cakes", int(vars.get("cake_festival", 6)), "FESTIVAL")
		"board_cakes_same":
			_set_row("cakes", int(vars.get("cake_base", 4)), "FESTIVAL, MORE SELLERS")
		"many_apples":
			extra_carts.visible = true
		"board_apples":
			_set_row("apples", int(vars.get("apple_many", 2)), "MANY SELLERS")
		"autumn":
			if bunting:
				bunting.visible = false
			if extra_carts:
				extra_carts.visible = false
			_set_field(1.2, WHEAT)
			if track == "big":
				_set_row("apples", int(vars.get("apple_autumn", 2)), "HARVEST")
				_set_row("wheat", int(vars.get("wheat_autumn", 1)), "HARVEST")
		"board_wheat_down":
			_set_row("wheat", int(vars.get("wheat_autumn", 1)), "HARVEST")
		"winter":
			_set_field(0.3, Color("e8eef4"))
			_set_row("apples", int(vars.get("apple_winter", 5)), "WINTER: FEW APPLES")
		"cake_customer", "apple_customer":
			customer.visible = true
			customer.nod()
			till.clear_pile("hand")
		"ana":
			pass
		"mo_offer":
			mo.visible = true
			LifeRoomPeople.feel(mo, "happy")
		"rosa":
			mo.visible = false
			rosa.visible = true
			LifeRoomPeople.feel(rosa, "happy")
		"storm":
			storm.visible = true
			_set_field(0.2, WHEAT_DRY)
			if basket_fill.has("basket_wheat"):
				(basket_fill.basket_wheat as MeshInstance3D).material_override = LifeRoomKit.material(Color("9aa7b5"))
		"dice_game":
			pip.visible = true
			throws_seen = 0
			if dice_count:
				dice_count.text = "SIXES: 0"
		"chart":
			_draw_chart()


func step_started(step: Dictionary) -> void:
	var kind := str(step.get("kind", ""))
	if kind == "coins":
		var where := str(step.get("target", ""))
		till.clear_pile(where)
		till.move_to(at_stall(TOMAS_AT, Vector3(-0.1, 0.91, 0.62)) if where == "tomas" else TRAY_AT)


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"coins":
			till.show_pile(str(step.target), state.get("given", []))
		"taps":
			var n := int(state.get("t", 0))
			match str(step.target):
				"apples":
					while apples_on_table.size() < n:
						apples_on_table.append(LifeRoomKit.sphere(self, "Swapped", 0.045, Vector3(-0.16 + apples_on_table.size() * 0.08,
							0.96, -0.86), Color("e8544e")))
				"shed":
					for i in mini(n, shed_bags.size()):
						shed_bags[i].visible = false
				"dice":
					_throw_to(n)
		"find":
			for t: Variant in state.get("found", []):
				if basket_fill.has(str(t)):
					(basket_fill[str(t)] as MeshInstance3D).visible = true


## The dice shows the try's next throws (its seed's faces: the same try, the same throws), the sixes counted.
func _throw_to(n: int) -> void:
	var faces: Array = vars.get("dice_faces", [])
	while throws_seen < n and throws_seen < faces.size():
		dice_face.text = str(faces[throws_seen])
		throws_seen += 1
		dice.rotation = Vector3(0.3 * throws_seen, 0.7 * throws_seen, 0)
	var sixes := 0
	for i in throws_seen:
		if int(faces[i]) == 6:
			sixes += 1
	dice_count.text = "SIXES: %d" % sixes


## The chart of 600 throws (pretend counters): each point the counters won minus paid so far; the line falls.
func _draw_chart() -> void:
	for p in chart_points:
		p.queue_free()
	chart_points.clear()
	var line: Array = vars.get("chart_line", [])
	if line.is_empty():
		return
	var low := 1.0
	for v: Variant in line:
		low = minf(low, float(v))
	if is_instance_valid(_chart_line):
		_chart_line.queue_free()
	var d := LifeRoomDecor.new()   # the line drawn as one mesh (the Quest's draws); the points stay as the chart's own
	for i in line.size():
		var y := 0.4 + float(line[i]) / absf(low) * 0.75 if low < 0.0 else 0.4
		var z := -0.7 + 1.4 * float(i) / maxf(line.size() - 1, 1.0)
		var point := LifeRoomKit.box(self, "Point", Vector3(0.02, 0.03, 0.04), CHART_AT + Vector3(0.05, y, -z), DOWN)
		point.visible = false
		chart_points.append(point)
		d.box("Point", Vector3(0.02, 0.03, 0.04), CHART_AT + Vector3(0.05, y, -z), DOWN)
	_chart_line = d.commit(self, "ChartLine")
	chart_label.text = "AFTER 600 THROWS: %d" % int(line.back())


## A point in a merchant's stall's own frame (its front, +Z, towards the middle of the square), in the room.
static func at_stall(stall: Vector3, local: Vector3) -> Vector3:
	return stall + Basis(Vector3.UP, atan2(-stall.x, -stall.z)) * local


func price_of(good: String) -> int:
	return int(prices.get(good, -1))


# --- The rooms' look (2026-10-17, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## The square: paving slabs, little houses round it, flags, lamps, planters and trees, a sunny sky.
func _square_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Grass", Vector3(70, 0.1, 70), Vector3(0, -0.13, -3.0), Color("8cc56a"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Square", LifeRoomDecor.SLABS, Vector3(22, 0.1, 20), Vector3(0, -0.05, -3.0), Color("f2e4c9"), 1.25)
	var fronts := [Color("f3e1c0"), Color("f6c9b4"), Color("cfe9d6"), Color("d6e4f6"), Color("f6e7a8"), Color("e8d6f2")]
	var roofs := [Color("c8553d"), Color("b5583f"), Color("8f5a4a")]
	var i := 0
	for x: float in [-8.2, -3.2, 3.2, 8.2]:
		d.house("House", Vector3(x, 0, -11.8), Vector3(4.4, 2.9 + 0.5 * (i % 2), 2.6), 0.0, fronts[i % 6], roofs[i % 3])
		i += 1
	for z: float in [-7.2, -2.2, 3.2]:
		d.house("House", Vector3(-11.8, 0, z), Vector3(4.4, 3.0, 2.6), PI / 2, fronts[i % 6], roofs[i % 3])
		i += 1
		d.house("House", Vector3(11.8, 0, z), Vector3(4.4, 3.2, 2.6), -PI / 2, fronts[i % 6], roofs[i % 3])
		i += 1
	for at: Vector3 in [Vector3(-6.4, 0, 2.6), Vector3(6.4, 0, 2.6), Vector3(-8.8, 0, -9.2), Vector3(8.8, 0, -9.2)]:
		d.street_lamp("Lamp", at)
	d.bunting("Flags", Vector3(-10.3, 3.4, -9.6), Vector3(10.3, 3.4, -9.6), 0.5)
	d.planter("Planter", Vector3(-9.6, 0, -10.6), Vector2(0.9, 0.5), Color("e85a9a"))
	d.planter("Planter", Vector3(9.6, 0, -10.6), Vector2(0.9, 0.5), Color("ffc93c"))
	d.bench("Bench", Vector3(-9.9, 0, -4.6), PI / 2)
	d.tree("Tree", Vector3(-8.2, 0, 5.6), 1.1)
	d.tree("Tree", Vector3(8.2, 0, 5.6), 1.0, Color("5aa548"))
	d.tree("Tree", Vector3(0.9, 0, 6.6), 1.2, Color("5aa548"))


## The square's people in few meshes (the Quest's draws): none changes pose; faces through feel. The festival's flags,
## the extra carts and stalls, the apples' basket: each drawn as one.
func _people_look() -> void:
	for b: LifeBuddy in [customer, lina, mo, rosa, pip]:
		if b != null:
			LifeRoomPeople.merge_person(b, true)
	for b in merchants:
		LifeRoomPeople.merge_person(b, true)
	for n: Node3D in [bunting, extra_carts, extra_cakes, apple_basket]:
		if n != null:
			LifeRoomPeople.merge_parts(self, n)
