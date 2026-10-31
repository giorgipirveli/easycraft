class_name MarketRoom
extends LifeRoom
## Owner #112, #115 (docs/design/life-skills.md §5 #3; docs/design/success-skills.md §2.1: My Money Stall is My
## Business's first step): a sunny market square. The child's stand (a counter under a striped awning) with its goods
## crate, the cash box, the coin tray (pretend market coins of 1, 2, 5, 10 and a 20 note: never the child's real gold),
## the saving jar for the rocket; buddy customers across the counter; the pretend bank (the money grows week by week on
## the Middle and Big tracks) and the shop with a list and a budget. A coin given flies from the tray to where it goes.
## `vars` (LifeExperience.vars: the run's money) are set by the host before the room is built.

const COBBLE := Color("d8cbb0")
const COUNTER := Color("b07a46")
const AWNING_A := Color("e8544e")
const AWNING_B := Color("fdfdf8")
const COIN := Color("ffc93c")
const NOTE := Color("8fd18a")
const STALL_HAND := Vector3(0, 1.0, -1.2)
const TRAY_AT := Vector3(-0.05, 0.91, -0.64)
const BANK_TRAY_AT := Vector3(4.75, 0.98, -2.15)
## The coins and notes on the tray, per track (the change steps' and the bank's).
const TRAY := {"little": [1, 2], "middle": [1, 2, 5, 10], "big": [1, 2, 5, 10, 20]}
const ITEMS := {"shop_bread": [2, "bread"], "shop_milk": [3, "milk"], "shop_apples": [2, "apples"],
	"shop_rice": [4, "rice"], "shop_sweets": [3, "sweets"], "shop_toy": [6, "toy"]}

var customer: LifeBuddy
var stranger: LifeBuddy
var goods := {}
var coin_piles := {}   # where coins went ("hand", "jar", "bank") -> Array of coin meshes
var paid: Array[MeshInstance3D] = []
var box_count := 0
var box_label: Label3D
var bank_label: Label3D
var jar_label: Label3D
var basket_ticks := {}
var tray: Node3D
## The shop's price tags: shown while the child shops (the rooms' look: from the stall they ran off the first view).
var _shop_tags: Array[Label3D] = []


func build() -> void:
	name = "MarketRoom"
	env = LifeRoomKit.environment(Color("7fbfef"), Color("f4f0e0"), 0.7)
	start_view = "stall"
	var d := decor()   # the rooms' look (2026-10-18): a town square round the stalls
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.town_square(Rect2(-9, -10, 18, 16))
	LifeRoomKit.light(self, Vector3(0, 4, -1), 0.6, 12.0)
	for x: float in [-7.0, 7.0]:
		_decor_stall(Vector3(x, 0, -6))
	_stall()
	_customers()
	if track != "little":
		_bank()
		_shop()
	for b: LifeBuddy in [customer, stranger]:   # the Quest's draws: a head and a body each (they never change pose)
		LifeRoomPeople.merge_person(b, true)
	add_view("stall", Vector3(0, 1.45, 0.85), Vector3(0, 0.9, -1.0), Vector3(0, 0, 0.0), 0.0)
	add_view("square", Vector3(0, 3.0, 3.6), Vector3(0, 0.3, -1.5), Vector3(0, 0, 0.0), 0.0)
	add_view("jar", Vector3(-0.45, 1.3, 0.35), Vector3(-0.9, 1.0, -0.6), Vector3(-0.3, 0, -0.05), 0.3)
	add_view("bank", Vector3(4.0, 1.45, -0.5), Vector3(5.0, 1.0, -2.6), Vector3(4.2, 0, -1.4), atan2(-0.8, 1.2))
	add_view("spot_bank", Vector3(4.0, 1.45, -0.5), Vector3(5.0, 1.0, -2.6), Vector3(4.2, 0, -1.4), atan2(-0.8, 1.2))
	add_view("shop", Vector3(-3.5, 1.5, -0.3), Vector3(-5.0, 1.0, -2.6), Vector3(-4.0, 0, -1.1), atan2(1.0, 1.5))
	add_view("spot_shop", Vector3(-3.5, 1.5, -0.3), Vector3(-5.0, 1.0, -2.6), Vector3(-4.0, 0, -1.1), atan2(1.0, 1.5))


func _decor_stall(at: Vector3) -> void:
	var sc := scenery()
	LifeRoomKit.box(sc, "Stall", Vector3(2.0, 0.9, 0.7), at + Vector3(0, 0.45, 0), COUNTER.darkened(0.1))
	LifeRoomKit.box(sc, "Roof", Vector3(2.2, 0.08, 1.0), at + Vector3(0, 2.1, 0), Color("3a7be8"))
	for k in 4:   # its wares
		LifeRoomKit.box(sc, "Wares", Vector3(0.3, 0.16, 0.24), at + Vector3(-0.6 + k * 0.4, 0.98, 0.05),
			[Color("e8544e"), Color("ffc93c"), Color("3fbf5a"), Color("f3d2a8")][k])
	for x: float in [-0.95, 0.95]:
		LifeRoomKit.box(sc, "Pole", Vector3(0.06, 2.1, 0.06), at + Vector3(x, 1.05, -0.3), Color("6b4a2a"))


func _stall() -> void:
	var sc := scenery()
	decor().tiled("Counter", LifeRoomDecor.PLANKS, Vector3(2.2, 0.9, 0.7), Vector3(0, 0.45, -0.9), Color("f6dcb4"), 0.9, 0.0,
		LifeRoomDecor.BAKED)   # a wooden counter (where the plain box stood)
	for i in 6:
		LifeRoomKit.box(sc, "Awning", Vector3(0.38, 0.06, 1.1), Vector3(-0.95 + i * 0.38, 2.15, -0.9),
			AWNING_A if i % 2 == 0 else AWNING_B)
	for x: float in [-1.05, 1.05]:
		LifeRoomKit.box(sc, "Pole", Vector3(0.06, 2.15, 0.06), Vector3(x, 1.07, -1.2), Color("6b4a2a"))
	# on top of the awning (in front of it the first view cut it at the frame's top)
	LifeRoomKit.sign(self, "StallSign", "MY STALL", Vector3(0, 2.42, -0.4), 0.0034)
	LifeRoomKit.box(sc, "Crate", Vector3(0.5, 0.12, 0.34), Vector3(0.78, 0.96, -0.78), Color("c9a063"))
	for g: Array in [["bread_1", Vector3(0.66, 1.07, -0.78), Color("d99a4e")], ["bread_2", Vector3(0.86, 1.07, -0.82),
			Color("d99a4e")], ["jam", Vector3(0.98, 1.08, -0.72), Color("b0303f")]]:
		var m := LifeRoomKit.box(self, g[0], Vector3(0.22, 0.12, 0.13) if g[0] != "jam" else Vector3(0.09, 0.13, 0.09),
			g[1], g[2])
		goods[g[0]] = m
		add_target(g[0], m, 0.15)
	var box := LifeRoomKit.box(self, "CashBox", Vector3(0.3, 0.12, 0.22), Vector3(-0.58, 0.96, -0.72), Color("3a5aa8"))
	add_target("box", box, 0.17)
	box_label = LifeRoomKit.sign(self, "BoxCount", "0", Vector3(-0.58, 1.1, -0.62), 0.003)
	var jar := LifeRoomKit.cylinder(self, "Jar", 0.09, 0.22, Vector3(-0.95, 1.01, -0.68), Color(0.8, 0.92, 1.0, 0.7))
	LifeRoomKit.sign(jar, "Goal", "ROCKET", Vector3(0, 0.0, 0.1), 0.0022, Color("1f2a4a"))
	jar_label = LifeRoomKit.sign(self, "JarCount", "", Vector3(-0.95, 1.22, -0.62), 0.003)
	add_target("jar", jar, 0.14)
	coin_piles.jar = []
	tray = Node3D.new()
	tray.name = "Tray"
	tray.position = TRAY_AT
	add_child(tray)
	LifeRoomKit.box(tray, "TrayBase", Vector3(0.7, 0.02, 0.22), Vector3.ZERO, Color("6b4a2a"))
	var values: Array = TRAY.get(track, TRAY.little)
	var all: Array = [1, 2, 5, 10, 20]
	for i in all.size():
		var v := int(all[i])
		var at := Vector3(-0.27 + i * 0.135, 0.02, 0)
		var coin: MeshInstance3D
		if v == 20:
			coin = LifeRoomKit.box(tray, "Note20", Vector3(0.11, 0.01, 0.07), at, NOTE)
		else:
			coin = LifeRoomKit.cylinder(tray, "Coin%d" % v, 0.03 + 0.004 * i, 0.012, at, COIN)
		LifeRoomKit.sign(coin, "Value", str(v), Vector3(0, 0.06, 0), 0.0024, Color("1f2a4a"))
		coin.visible = values.has(v)
		add_target("coin_%d" % v, coin, 0.06)
	add_spot_target("hand", self, STALL_HAND, 0.15)
	add_spot_target("coins_back", self, STALL_HAND + Vector3(0, -0.06, 0.1), 0.12)
	coin_piles.hand = []
	add_spot_target("paid_coins", self, Vector3(0.32, 0.93, -1.0), 0.14)


func _customers() -> void:
	customer = LifeBuddy.new(Color("ffb347"), "Customer")
	customer.position = Vector3(0, 0, -1.85)
	customer.visible = false
	add_child(customer)
	add_target("customer", customer.hips, 0.35)
	stranger = LifeBuddy.new(Color("7d8a99"), "Stranger")
	stranger.position = Vector3(1.7, 0, -1.2)
	stranger.rotation.y = -0.6
	stranger.visible = false
	add_child(stranger)


func _bank() -> void:
	var sc := scenery()
	var at := Vector3(5.2, 0, -3.0)
	LifeRoomKit.box(sc, "BankHouse", Vector3(2.4, 2.4, 1.6), at + Vector3(0, 1.2, -0.3), Color("f3e1c0"))
	LifeRoomKit.box(sc, "BankRoof", Vector3(2.7, 0.3, 1.9), at + Vector3(0, 2.55, -0.3), Color("c49a12"))
	LifeRoomKit.box(sc, "BankSteps", Vector3(2.6, 0.12, 0.5), at + Vector3(0, 0.06, 0.85), Color("e6e2da"))
	for x: float in [-0.9, -0.3, 0.3, 0.9]:
		LifeRoomKit.box(sc, "Column", Vector3(0.14, 2.3, 0.14), at + Vector3(x, 1.15, 0.6), Color.WHITE)
	LifeRoomKit.sign(self, "BankSign", "PRETEND BANK", at + Vector3(0, 2.2, 0.62), 0.005, Color("1f2a4a"))
	var slot := LifeRoomKit.box(self, "Slot", Vector3(0.5, 0.06, 0.2), at + Vector3(0, 1.0, 0.62), Color("1f2a4a"))
	LifeRoomKit.box(sc, "BankShelf", Vector3(0.8, 0.05, 0.3), BANK_TRAY_AT + Vector3(0, -0.04, 0), Color("a8642a"))
	add_target("bank", slot, 0.2)
	bank_label = LifeRoomKit.sign(self, "Balance", "", at + Vector3(0, 1.45, 0.65), 0.004)
	coin_piles.bank = []
	add_spot_target("spot_bank", self, Vector3(4.2, 0.05, -1.4), 0.55)
	LifeRoomKit.cylinder(self, "BankRing", 0.45, 0.02, Vector3(4.2, 0.03, -1.4), Color(0.3, 0.85, 0.4, 0.6))


func _shop() -> void:
	var sc := scenery()
	var at := Vector3(-5.2, 0, -3.0)
	LifeRoomKit.box(sc, "ShopHouse", Vector3(2.6, 2.4, 0.4), at + Vector3(0, 1.2, -0.6), Color("cfe9b0"))
	LifeRoomKit.box(sc, "ShopRoof", Vector3(2.9, 0.12, 1.2), at + Vector3(0, 2.45, -0.15), Color("3fbf5a"))
	# at the shop's right end, smaller (in the middle the first view's left edge cut it)
	LifeRoomKit.sign(self, "ShopSign", "SHOP", at + Vector3(0.95, 2.15, -0.36), 0.0042, Color("1f2a4a"))
	for row in 2:
		LifeRoomKit.box(sc, "Shelf", Vector3(2.2, 0.05, 0.4), at + Vector3(0, 0.75 + row * 0.55, -0.25), Color("a8642a"))
	var i := 0
	for id: String in ITEMS:
		if id == "shop_rice" and track != "big":
			continue
		var p := at + Vector3(-0.85 + (i % 3) * 0.85, 0.88 + (i / 3) * 0.55, -0.2)
		var colour: Color = {"bread": Color("d99a4e"), "milk": Color.WHITE, "apples": Color("e8544e"), "rice": Color("f3e6c8"),
			"sweets": Color("e85a9a"), "toy": Color("3a7be8")}[ITEMS[id][1]]
		var item := LifeRoomKit.box(self, id, Vector3(0.2, 0.2, 0.15), p, colour)
		var tag := LifeRoomKit.sign(self, id + "_price", "%s  %d" % [str(ITEMS[id][1]).to_upper(), int(ITEMS[id][0])],
			p + Vector3(0, 0.17, 0.1), 0.0028)
		tag.visible = false   # shown at the shop (from the stall the first view's left edge cut them): step_started
		_shop_tags.append(tag)
		add_target(id, item, 0.16)
		i += 1
	LifeRoomKit.box(sc, "Till", Vector3(0.6, 0.9, 0.5), at + Vector3(1.3, 0.45, 1.3), Color("9aa7b5"))
	var register := LifeRoomKit.box(self, "Register", Vector3(0.36, 0.22, 0.3), at + Vector3(1.3, 1.01, 1.3), Color("3b3f4a"))
	LifeRoomKit.sign(self, "TillSign", "PAY HERE", at + Vector3(1.3, 1.3, 1.46), 0.004)
	add_target("till", register, 0.3)
	add_spot_target("spot_shop", self, Vector3(-4.0, 0.05, -1.1), 0.55)
	LifeRoomKit.cylinder(self, "ShopRing", 0.45, 0.02, Vector3(-4.0, 0.03, -1.1), Color(0.3, 0.85, 0.4, 0.6))


func on_event(event: String) -> void:
	match event:
		"customer_1", "customer_2":
			customer.visible = true
			customer.colour = Color("ffb347") if event == "customer_1" else Color("8b6fd6")
			_restyle(customer)
			LifeRoomPeople.redraw(customer)   # the merged body in its new colour
			_clear_pile("hand")
			if event == "customer_1":
				_put_paid(int(vars.get("first_paid", 2)))
				if track != "little":   # the Middle and Big tracks: the first customer's coins go in by themselves
					_into_box(int(vars.get("first_paid", 2)))
					_clear_paid()
			else:
				_put_paid(0)
				_into_box(int(vars.get("paid", 5)))
			customer.nod()
		"give_bread":
			for g: String in ["bread_1", "bread_2"]:
				var m := goods.get(g) as MeshInstance3D
				if m != null and m.visible and m.position.z < -1.0:
					m.visible = false
					break
			customer.nod()
		"stranger":
			stranger.visible = true
		"bank_grow":
			if bank_label:
				_count_up(bank_label, int(vars.get("deposit", 10)), int(vars.get("bank_after", 13)))


func _restyle(b: LifeBuddy) -> void:
	for m: Node in b.hips.find_children("Torso", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = LifeRoomKit.material(b.colour)


func step_started(step: Dictionary) -> void:
	if str(step.get("kind", "")) == "coins":
		_clear_pile(str(step.get("target", "")))
		tray.position = BANK_TRAY_AT if str(step.get("target", "")) == "bank" else TRAY_AT   # the coins go along
	if str(step.get("id", "")) != "scam" and str(step.get("id", "")) != "scam1" and stranger:
		stranger.visible = false
	var at_shop := str(step.get("view", "")) in ["shop", "spot_shop"] or str(step.get("goes", "")) == "spot_shop"
	for tag in _shop_tags:
		tag.visible = tag.visible or at_shop   # once at the shop they stay


func step_done(step: Dictionary) -> void:
	match str(step.get("kind", "")):
		"coins":
			if str(step.target) == "hand":
				_into_box(-int(step.sum))
		"taps":
			_clear_paid()


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"find":
			for t: Variant in state.get("found", []):
				var m := goods.get(str(t)) as MeshInstance3D
				if m != null and m.position.z > -0.9:
					var i := goods.keys().find(t)
					m.position = Vector3(-0.45 + i * 0.32, 0.97, -1.12)
		"taps":
			var n := int(state.get("t", 0))
			while paid.size() > maxi(int(step.get("count", 1)) - n, 0):
				var c: MeshInstance3D = paid.pop_back()
				c.queue_free()
				_into_box(1)
		"coins":
			_show_pile(str(step.target), state.get("given", []))
		"basket":
			for id: String in ITEMS:
				if not has_target(id):
					continue
				var inside := (state.get("in", []) as Array).has(id)
				if inside and not basket_ticks.has(id):
					basket_ticks[id] = LifeRoomKit.sphere(self, "InBasket", 0.05, to_local(target_position(id)) + Vector3(0, 0.2, 0),
						Color(0.3, 0.85, 0.4, 0.9))
				elif not inside and basket_ticks.has(id):
					(basket_ticks[id] as Node3D).queue_free()
					basket_ticks.erase(id)


## The coins given so far, shown where they went (one coin each, a little stack).
func _show_pile(where: String, given: Array) -> void:
	if not coin_piles.has(where) or not has_target(where):
		return
	var pile: Array = coin_piles[where]
	while pile.size() > given.size():
		(pile.pop_back() as Node3D).queue_free()
	var base := to_local(target_position(where))
	while pile.size() < given.size():
		var i := pile.size()
		var v := int(given[i])
		var c := LifeRoomKit.cylinder(self, "Given", 0.03, 0.012, base + Vector3((i % 4) * 0.05 - 0.07, 0.01 + (i / 4) * 0.014, 0),
			NOTE if v == 20 else COIN)
		pile.append(c)
	if where == "jar" and jar_label:
		jar_label.text = str(given.reduce(func(a: int, b: Variant) -> int: return a + int(b), 0))


func _clear_pile(where: String) -> void:
	if coin_piles.has(where):
		for c: Node3D in coin_piles[where]:
			c.queue_free()
		(coin_piles[where] as Array).clear()


func _put_paid(n: int) -> void:
	_clear_paid()
	for i in n:
		paid.append(LifeRoomKit.cylinder(self, "Paid", 0.03, 0.012, Vector3(-0.06 + i * 0.07, 0.93, -1.0), COIN))


func _clear_paid() -> void:
	for c in paid:
		c.queue_free()
	paid.clear()


func _into_box(n: int) -> void:
	box_count = maxi(box_count + n, 0)
	box_label.text = str(box_count)


func _count_up(label: Label3D, from: int, to: int) -> void:
	label.text = str(from)
	if not is_inside_tree() or UiMotion.calm():
		label.text = str(to)
		return
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: label.text = str(roundi(v)), float(from), float(to), 4.0)
