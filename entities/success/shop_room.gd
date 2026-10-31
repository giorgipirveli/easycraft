class_name ShopRoom
extends LifeRoom
## Owner #115 (docs/design/success-skills.md §2.1 My Business; the S3 brief): the shop's practice room.
## - Little: the child's stand under a striped awning (My Money Stall's stand grown a sign): the bread and the cake, the
##   cash box, the FLOUR jar (money kept to make more), the coin tray of pretend coins, the customers across the counter
##   (the Connections Book's people, then Mo) and the stars they give.
## - Middle and Big: a small bakery, open to the market square: the counter with the till and the coin tray, the goods on
##   a little shelf on the counter (bread, cakes, honey buns: in VR within the hand's reach), the shop's sign over it, the
##   bake corner behind the child (the oven, the flour sack, the scales on their table), the review board on the left wall
##   (each customer's honest, kind review), the ledger board on the right (money in, money out, profit, a week's bars),
##   Bobo the helper at the counter's end, and across the square Pip-pop's bakery (the rival).
## The people come and go with the steps' events; their faces follow the moods (LifeBuddy.face: a cross face at most,
## never a scary one). Only LifeRoomKit's warmed shaders; no shadows of its own.

const FLOOR := Color("e4cfa6")
const COBBLE := Color("d8cbb0")
const COUNTER := Color("b07a46")
const WALL := Color("fbefd8")
const AWNING_A := Color("e8544e")
const AWNING_B := Color("fdfdf8")
const BOARD := Color("3b5a4a")
const IN_GREEN := Color("4fbf6a")
const OUT_RED := Color("e8705a")
const GOLD := Color("ffc93c")
const CUSTOMER_AT := Vector3(0, 0, -1.85)
const HAND_AT := Vector3(0, 1.0, -1.2)
const TRAY_AT := Vector3(-0.05, 0.91, -0.64)
const GOODS := {"good_bread": [Vector3(0.42, 1.0, -0.78), Color("d99a4e"), Vector3(0.2, 0.11, 0.12)],
	"good_cake": [Vector3(0.62, 1.0, -0.78), Color("f3d2a8"), Vector3(0.16, 0.1, 0.16)],
	"good_honey_bun": [Vector3(0.82, 0.99, -0.78), Color("e8b04a"), Vector3(0.12, 0.08, 0.12)]}
const REVIEWS_AT := Vector3(-2.35, 1.5, -0.4)
const LEDGER_AT := Vector3(2.35, 1.5, -0.4)
const SCALES_AT := Vector3(0.5, 0.86, 1.2)
const RIVAL_AT := Vector3(3.0, 0, -7.0)
## Bobo the helper's place: behind the counter's right end, beside the child (out of the first view, clear of the boards).
const BOBO_AT := Vector3(1.62, 0, 0.72)
const MAX_REVIEW_CARDS := 4

var till := SuccessTill.new()
var goods := {}
var goods_home := {}
var price_tags: Array[Label3D] = []
var customer: LifeBuddy
var mo: LifeBuddy
var waiting: LifeBuddy
var bobo: LifeBuddy
var pip: LifeBuddy
var sign_label: Label3D
var stars_label: Label3D
var review_cards: Array[Label3D] = []
var ledger_bars := {}
var week_bars: Array[MeshInstance3D] = []
var scales_label: Label3D
var oven_light: MeshInstance3D
var tray_out: Node3D
var order_box: MeshInstance3D
var rain: Node3D
var rival_sign: Label3D
var rival_shop: Node3D
var stars := 0


func build() -> void:
	name = "ShopRoom"
	env = LifeRoomKit.environment(Color("8ec5f0"), Color("f4f0e0"), 0.72)
	start_view = "counter"
	_square()   # the rooms' look (2026-10-17): the market square round the shop
	LifeRoomKit.light(self, Vector3(0, 3.2, -0.4), 0.6, 10.0)
	_counter()
	if track == "little":
		_stand()
	else:
		_bakery()
		_bake_corner()
		_boards()
		_rival()
		bobo = LifeBuddy.new(Color("1fa6a0"), "Bobo")
		bobo.position = BOBO_AT   # beside the child behind the counter's end (at its end the first view cut his head)
		bobo.rotation.y = PI
		add_child(bobo)
		LifeRoomKit.sign(bobo, "Name", "BOBO", Vector3(0, 1.32, 0), SuccessCast.SIGN_PIXEL).modulate = Color("fff6d8")
	_people()
	_people_look()
	add_view("counter", Vector3(0, 1.45, 0.85), Vector3(0, 0.95, -1.0), Vector3(0, 0, 0), 0.0)
	if track != "little":
		add_view("bake", Vector3(0, 1.5, -0.35), Vector3(0.35, 0.85, 1.3), Vector3(0, 0, 0.3), PI)
		add_view("reviews", Vector3(0.3, 1.5, 0.3), REVIEWS_AT + Vector3(0, -0.05, 0), Vector3(0, 0, 0), PI / 2)
		add_view("ledger", Vector3(-0.3, 1.5, 0.3), LEDGER_AT + Vector3(0, -0.05, 0), Vector3(0, 0, 0), -PI / 2)
		add_view("square", Vector3(0, 2.0, 1.0), RIVAL_AT + Vector3(0, 1.0, 0), Vector3(0, 0, 0), atan2(-RIVAL_AT.x, -RIVAL_AT.z))


func _counter() -> void:
	decor().tiled("Counter", LifeRoomDecor.PLANKS, Vector3(2.2, 0.9, 0.7), Vector3(0, 0.45, -0.9), Color("f6dcb4"), 0.9, 0.0,
		LifeRoomDecor.BAKED)   # a wooden counter (where the plain box stood)
	var values: Array = {"little": [1, 2], "middle": [1, 2, 5], "big": [1, 2, 5, 10]}.get(track, [1, 2])
	till.build(self, TRAY_AT, values)
	till.add_place("hand", HAND_AT, 0.15)
	for id: String in GOODS:
		if id == "good_honey_bun" and track == "little":
			continue
		var g: Array = GOODS[id]
		var m := LifeRoomKit.box(self, id, g[2], g[0], g[1])
		goods[id] = m
		goods_home[id] = g[0]
		add_target(id, m, 0.12)
	LifeRoomKit.box(scenery(), "GoodsShelf", Vector3(0.66, 0.04, 0.24), Vector3(0.62, 0.93, -0.78), Color("8a5a34"))


func _stand() -> void:
	var sc := scenery()
	for i in 6:
		LifeRoomKit.box(sc, "Awning", Vector3(0.38, 0.06, 1.1), Vector3(-0.95 + i * 0.38, 2.15, -0.9),
			AWNING_A if i % 2 == 0 else AWNING_B)
	for x: float in [-1.05, 1.05]:
		LifeRoomKit.box(sc, "Pole", Vector3(0.06, 2.15, 0.06), Vector3(x, 1.07, -1.2), Color("6b4a2a"))
	# on top of the awning (the first view looks down at the counter: in front of it the sign was cut by the frame's top)
	sign_label = LifeRoomKit.sign(self, "StandSign", "", Vector3(0, 2.42, -0.4), 0.0042)
	LifeRoomKit.box(sc, "CashBox", Vector3(0.3, 0.12, 0.22), Vector3(-0.58, 0.96, -0.72), Color("3a5aa8"))
	till.add_place("box", Vector3(-0.58, 1.04, -0.72), 0.17, true)
	var jar := LifeRoomKit.cylinder(self, "FlourJar", 0.09, 0.22, Vector3(-0.95, 1.01, -0.68), Color(0.85, 0.92, 1.0, 0.7))
	LifeRoomKit.sign(jar, "Words", "FLOUR", Vector3(0, 0.0, 0.1), 0.0022, Color("1f2a4a"))
	till.add_place("flour_jar", Vector3(-0.95, 1.13, -0.68), 0.14, true)
	stars_label = LifeRoomKit.sign(self, "Stars", "", Vector3(0.75, 1.5, -0.5), 0.004, GOLD)


func _bakery() -> void:
	var sc := scenery()
	_bakery_look()
	for i in 12:
		LifeRoomKit.box(sc, "Awning", Vector3(0.42, 0.06, 0.9), Vector3(-2.3 + i * 0.42, 2.6, -2.25),
			AWNING_A if i % 2 == 0 else AWNING_B)
	var reg := LifeRoomKit.box(self, "Till", Vector3(0.34, 0.2, 0.28), Vector3(-0.62, 1.0, -0.8), Color("3b3f4a"))
	LifeRoomKit.sign(reg, "Words", "TILL", Vector3(0, 0.16, 0.1), 0.0026)
	till.add_place("till", Vector3(-0.62, 1.13, -0.8), 0.18, true)
	till.add_place("bobo", Vector3(1.15, 1.0, -0.62), 0.15)
	sign_label = LifeRoomKit.sign(self, "ShopSign", "", Vector3(0, 2.25, -1.3), 0.0045)


func _bake_corner() -> void:
	var sc := scenery()
	LifeRoomKit.box(sc, "Oven", Vector3(1.0, 1.1, 0.7), Vector3(-1.0, 0.55, 1.55), Color("9aa7b5"))
	oven_light = LifeRoomKit.box(self, "OvenDoor", Vector3(0.6, 0.4, 0.02), Vector3(-1.0, 0.6, 1.19), Color("3b3f4a"))
	LifeRoomKit.box(sc, "Table", Vector3(0.9, 0.78, 0.6), Vector3(0.55, 0.39, 1.3), Color("a8642a"))
	LifeRoomKit.box(sc, "FlourSack", Vector3(0.3, 0.4, 0.25), Vector3(1.6, 0.2, 1.5), Color("f4ecd8"))
	LifeRoomKit.sign(self, "SackWords", "FLOUR", Vector3(1.6, 0.55, 1.36), 0.003, Color("1f2a4a"))
	var scales := LifeRoomKit.box(self, "Scales", Vector3(0.28, 0.06, 0.22), SCALES_AT, Color("e8e8f0"))
	LifeRoomKit.cylinder(sc, "Bowl", 0.11, 0.06, SCALES_AT + Vector3(0, 0.06, 0), Color("cfe7ff"))
	add_target("scales", scales, 0.16)
	scales_label = LifeRoomKit.sign(self, "Grams", "0 g", SCALES_AT + Vector3(0, 0.2, -0.1), 0.003)
	tray_out = Node3D.new()
	tray_out.name = "FreshTray"
	tray_out.position = Vector3(-0.2, 0.82, 1.32)
	tray_out.visible = false
	add_child(tray_out)
	LifeRoomKit.box(tray_out, "Tray", Vector3(0.4, 0.02, 0.3), Vector3.ZERO, Color("6b6f7a"))
	for i in 3:
		LifeRoomKit.box(tray_out, "Loaf", Vector3(0.1, 0.07, 0.2), Vector3(-0.12 + i * 0.12, 0.05, 0), Color("d99a4e"))


func _boards() -> void:
	var sc := scenery()
	var rev := LifeRoomKit.box(self, "ReviewBoard", Vector3(0.04, 1.1, 1.6), REVIEWS_AT, BOARD)
	LifeRoomKit.sign(self, "ReviewTitle", "REVIEWS", REVIEWS_AT + Vector3(0.05, 0.65, 0), 0.004)
	add_target("reviews", rev, 0.5)
	for i in MAX_REVIEW_CARDS:
		var c := LifeRoomKit.sign(self, "Review%d" % i, "", REVIEWS_AT + Vector3(0.06, 0.38 - i * 0.24, 0), 0.0024)
		review_cards.append(c)
	LifeRoomKit.box(sc, "LedgerBoard", Vector3(0.04, 1.1, 1.6), LEDGER_AT, Color("fdf6e3"))
	LifeRoomKit.sign(self, "LedgerTitle", "LEDGER", LEDGER_AT + Vector3(-0.05, 0.65, 0), 0.004, Color("1f2a4a"))
	add_spot_target("ledger", self, LEDGER_AT, 0.5)
	for k: Array in [["in", "IN", IN_GREEN, 0.5], ["out", "OUT", OUT_RED, 0.25], ["profit", "PROFIT", GOLD, 0.0]]:
		var bar := LifeRoomKit.box(self, "Bar_" + str(k[0]), Vector3(0.02, 0.05, 0.16), LEDGER_AT + Vector3(-0.04, -0.15, float(k[3])),
			k[2])
		ledger_bars[k[0]] = [bar, LifeRoomKit.sign(self, "Words_" + str(k[0]), str(k[1]), LEDGER_AT + Vector3(-0.06, -0.24,
			float(k[3])), 0.0022, Color("1f2a4a"))]
	for i in 7:
		var b := LifeRoomKit.box(self, "Week%d" % i, Vector3(0.02, 0.05, 0.07), LEDGER_AT + Vector3(-0.04, -0.15, -0.25 - i * 0.08),
			Color("3a7be8"))
		b.visible = false
		week_bars.append(b)
	LifeRoomKit.box(sc, "Line", Vector3(0.02, 0.01, 0.62), LEDGER_AT + Vector3(-0.04, -0.15, -0.49), Color("1f2a4a"))


func _rival() -> void:
	rival_shop = Node3D.new()
	rival_shop.name = "RivalShop"
	rival_shop.position = RIVAL_AT
	scenery().add_child(rival_shop)
	LifeRoomKit.box(rival_shop, "Walls", Vector3(2.6, 2.2, 1.6), Vector3(0, 1.1, -0.6), Color("cfe9b0"))
	LifeRoomKit.box(rival_shop, "Roof", Vector3(2.9, 0.3, 1.9), Vector3(0, 2.35, -0.6), Color("8b6fd6"))
	LifeRoomKit.box(rival_shop, "Door", Vector3(0.7, 1.5, 0.04), Vector3(0, 0.75, 0.22), Color("8a5a34"))
	rival_sign = LifeRoomKit.sign(rival_shop, "Sign", "", Vector3(0, 2.0, 0.3), 0.005)
	pip = LifeBuddy.new(Color("ffd23f"), "PipPop")
	pip.position = Vector3(0.9, 0, 0.6)
	pip.visible = false
	rival_shop.add_child(pip)
	LifeRoomKit.sign(pip, "Name", "PIP-POP", Vector3(0, 1.3, 0), SuccessCast.SIGN_PIXEL)
	add_spot_target("rival", rival_shop, Vector3(0, 1.2, 0.3), 0.6)


func _people() -> void:
	customer = SuccessCast.person(str(vars.get("one", "lina")), CUSTOMER_AT)
	customer.visible = false
	add_child(customer)
	add_target("customer", customer.hips, 0.35)
	mo = SuccessCast.person("mo", CUSTOMER_AT + Vector3(0.05, 0, 0))
	mo.visible = false
	add_child(mo)
	if vars.has("two") and str(vars.two) != "mo":
		waiting = SuccessCast.person(str(vars.two), CUSTOMER_AT + Vector3(0.9, 0, -0.5), -0.3)
		waiting.visible = false
		add_child(waiting)


## The person at the counter now (the customer's target follows them).
func _at_counter(who: LifeBuddy) -> void:
	for b: LifeBuddy in [customer, mo, waiting]:
		if b != null:
			b.visible = b == who
	if who != null:
		who.position = CUSTOMER_AT
		who.rotation.y = 0.0
		add_target("customer", who.hips, 0.35)


func _person_at_counter(id: String) -> void:
	if id == "mo":
		_at_counter(mo)
		return
	if waiting != null and str(vars.get("two", "")) == id:
		_at_counter(waiting)
		return
	var b := SuccessCast.person(id, CUSTOMER_AT)
	add_child(b)
	LifeRoomPeople.merge_person(b, true)   # the Quest's draws: a head and a body
	if customer != null and customer != b:
		customer.queue_free()
	customer = b
	_at_counter(customer)


func on_event(event: String) -> void:
	match event:
		"sign_up":
			if sign_label:
				sign_label.text = "BREAD AND CAKES" if track == "little" else "FRESH BREAD, CAKES AND HONEY BUNS"
		"customer_1":
			_person_at_counter(str(vars.get("one", "lina")))
			LifeRoomPeople.feel(customer, str(vars.get("one_face", "happy")))
			_reset_goods()
		"customer_2":
			_person_at_counter(str(vars.get("two", "mo")))
			_reset_goods()
		"waiting":
			if waiting:
				waiting.visible = true
		"pay_10":
			till.clear_pile("hand")
		"thank_c1", "thank_c2", "thank_order":
			var b := mo if event == "thank_c2" else customer
			if b:
				LifeRoomPeople.feel(b, "happy")
				b.nod()
			_hand_over()
			_add_review(5)
		"prices_up", "prices_up_dear":   # the Middle Expert try's flour costs more: its loaf is 4
			_price_tags(4 if event == "prices_up_dear" else -1)
		"bake":
			if oven_light:
				oven_light.material_override = LifeRoomKit.material(Color("ff9a3c"))
			if tray_out:
				tray_out.visible = true
			if bobo:
				bobo.position = Vector3(-0.4, 0, 1.0)
				bobo.rotation.y = PI
		"complaint":
			if bobo:
				bobo.position = BOBO_AT
				bobo.rotation.y = PI
			_at_counter(mo)
			LifeRoomPeople.feel(mo, "cross")
			_reset_goods()
		"fixed":
			LifeRoomPeople.feel(mo, "happy")
			mo.nod()
			_hand_over()
			_add_review(5)
		"ledger":
			_show_ledger()
		"rival", "price_war":
			if pip:
				pip.visible = true
			if rival_sign:
				rival_sign.text = "PIP-POP'S BAKERY" if event == "rival" else "PIP-POP'S BAKERY: BREAD 1 COIN!"
		"rain":
			_rain(true)
		"order":
			_rain(false)
			_person_at_counter("okafor")
			LifeRoomPeople.feel(customer, "happy")
		"saturday":
			if order_box == null:
				order_box = LifeRoomKit.box(self, "OrderBox", Vector3(0.36, 0.14, 0.26), Vector3(0.0, 0.97, -1.0), Color("f3d2a8"))
				LifeRoomKit.sign(order_box, "Words", "ORDER", Vector3(0, 0.12, 0.1), 0.0026, Color("1f2a4a"))
			_person_at_counter("okafor")
		"unfair_review":
			_unfair_review()


func _reset_goods() -> void:
	for id: String in goods:
		var m: MeshInstance3D = goods[id]
		m.visible = true
		m.position = goods_home[id]
	till.clear_pile("hand")


## The good taken from the shelf is held out over the counter, then given (hidden) when the customer is thanked.
func _hand_over() -> void:
	for id: String in goods:
		var m: MeshInstance3D = goods[id]
		if m.position != goods_home[id]:
			m.visible = false
			m.position = goods_home[id]
	if order_box:
		order_box.visible = false


func step_started(step: Dictionary) -> void:
	if str(step.get("kind", "")) == "coins":
		till.clear_pile(str(step.get("target", "")))
	if str(step.get("view", "")) == "bake" and step.get("kind", "") == "pour" and scales_label:
		scales_label.text = "0 g"


func step_done(step: Dictionary) -> void:
	var t := str(step.get("target", ""))
	if str(step.get("kind", "")) == "touch" and goods.has(t):
		var m: MeshInstance3D = goods[t]
		m.position = Vector3(m.position.x * 0.3, 1.0, -1.05)   # held out to the customer
		m.visible = true


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"coins":
			till.show_pile(str(step.target), state.get("given", []))
		"find":
			for t: Variant in state.get("found", []):
				var m := goods.get(str(t)) as MeshInstance3D
				if m != null:
					m.position = goods_home[str(t)] + Vector3(0, 0.02, -0.08)
		"pour":
			if scales_label:
				scales_label.text = "%d g" % roundi(float(state.get("level", 0.0)))


## The goods' price tags: their fair prices (a loaf's is Big's new price, or `bread` when given).
func _price_tags(bread: int = -1) -> void:
	if not price_tags.is_empty():
		return
	for id: String in goods:
		var good := SuccessShop.good(id.trim_prefix("good_"))
		var price := int(good.get("price", 2))
		if id == "good_bread":
			price = bread if bread > 0 else int(vars.get("new_price", price))
		price_tags.append(LifeRoomKit.sign(self, "Price_" + id, str(price), (goods_home[id] as Vector3) + Vector3(0, 0.14, 0.08),
			0.0026, GOLD))


func _add_review(n: int) -> void:
	stars += n
	if stars_label:
		stars_label.text = "%d STARS" % stars
	for c in review_cards:
		if c.text == "":
			c.text = "5 STARS: \"Thank you!\""
			return


func _unfair_review() -> void:
	if review_cards.is_empty():
		return
	var c: Label3D = review_cards.back()
	c.text = "\"Not a nice bakery\" (never came in?)"
	c.modulate = Color("c9ced6")


## The ledger's bars: money in, money out, profit (this try's), and the week's seven bars (some under the line: a loss).
func _show_ledger() -> void:
	var vin := int(vars.get("money_in", 0))
	var vout := int(vars.get("money_out", 0))
	var top := maxf(float(maxi(vin, vout)), 1.0)
	for k: String in ["in", "out", "profit"]:
		var v := vin if k == "in" else (vout if k == "out" else vin - vout)
		var h := clampf(absf(float(v)) / top * 0.4, 0.02, 0.4)
		var bar: MeshInstance3D = ledger_bars[k][0]
		bar.scale = Vector3(1, h / 0.05, 1)
		bar.position.y = LEDGER_AT.y - 0.15 + h * 0.5
		(ledger_bars[k][1] as Label3D).text = "%s %d" % [k.to_upper(), v]
	var week: Array = vars.get("week", [])
	var most := 1.0
	for v: Variant in week:
		most = maxf(most, absf(float(v)))
	for i in mini(week.size(), week_bars.size()):
		var v := float(week[i])
		var h := clampf(absf(v) / most * 0.35, 0.02, 0.35)
		var b := week_bars[i]
		b.visible = true
		b.scale = Vector3(1, h / 0.05, 1)
		b.position.y = LEDGER_AT.y - 0.15 + (h * 0.5 if v >= 0.0 else -h * 0.5)
		b.material_override = LifeRoomKit.material(Color("3a7be8") if v >= 0.0 else OUT_RED)
		if b.get_child_count() == 0:
			var labels: Array = vars.get("week_labels", [])
			LifeRoomKit.sign(b, "Day", str(labels[i]) if i < labels.size() else "", Vector3(-0.02, -0.25, 0), 0.0016,
				Color("1f2a4a"))


func _rain(on: bool) -> void:
	if on and rain == null:
		rain = Node3D.new()
		rain.name = "Rain"
		add_child(rain)
		var d := LifeRoomDecor.new()   # the drops in one see-through mesh (the Quest's draws)
		for i in 14:
			d.glass("Drop", Vector3(0.015, 0.35, 0.015), Vector3(-2.0 + (i % 7) * 0.65, 1.2 + (i / 7) * 0.9, -2.6 - (i % 3) * 0.6),
				Color(0.55, 0.75, 1.0, 0.6))
		d.commit(rain, "")
	if rain:
		rain.visible = on


func review_count() -> int:
	var n := 0
	for c in review_cards:
		if c.text != "":
			n += 1
	return n


# --- The rooms' look (2026-10-17, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## The market square round the stand or the bakery: paving slabs, little houses with their doors and windows, flags, lamps,
## planters and trees, a sunny sky.
func _square() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Grass", Vector3(70, 0.1, 70), Vector3(0, -0.14, -4.0), Color("8cc56a"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Square", LifeRoomDecor.SLABS, Vector3(20, 0.1, 20), Vector3(0, -0.06, -4.0), Color("f2e4c9"), 1.25)
	var fronts := [Color("f3e1c0"), Color("f6c9b4"), Color("cfe9d6"), Color("d6e4f6"), Color("f6e7a8"), Color("e8d6f2")]
	var roofs := [Color("c8553d"), Color("b5583f"), Color("8f5a4a")]
	var i := 0
	for x: float in [-7.4, -2.6, 2.6, 7.4]:
		if track != "little" and absf(x - RIVAL_AT.x) < 2.0:
			i += 1
			continue   # Pip-pop's bakery stands there
		d.house("House", Vector3(x, 0, -13.0), Vector3(4.2, 2.8 + 0.5 * (i % 2), 2.6), 0.0, fronts[i % 6], roofs[i % 3])
		i += 1
	for z: float in [-9.0, -4.0, 1.5]:
		d.house("House", Vector3(-10.7, 0, z), Vector3(4.2, 3.0, 2.6), PI / 2, fronts[i % 6], roofs[i % 3])
		i += 1
		d.house("House", Vector3(10.7, 0, z), Vector3(4.2, 3.2, 2.6), -PI / 2, fronts[i % 6], roofs[i % 3])
		i += 1
	d.bunting("Flags", Vector3(-9.3, 3.3, -10.5), Vector3(9.3, 3.3, -10.5), 0.5)
	d.bunting("Flags", Vector3(-9.3, 3.3, -4.6), Vector3(9.3, 3.3, -4.6), 0.45)
	for at: Vector3 in [Vector3(-5.5, 0, -3.4), Vector3(5.5, 0, -3.4), Vector3(-5.5, 0, -10.0), Vector3(6.4, 0, -10.0)]:
		d.street_lamp("Lamp", at)
	d.planter("Planter", Vector3(-3.6, 0, -2.8), Vector2(1.0, 0.5), Color("e85a9a"))
	d.planter("Planter", Vector3(-8.6, 0, -11.3), Vector2(0.9, 0.5), Color("ffc93c"))
	d.bench("Bench", Vector3(-8.8, 0, -6.4), PI / 2)
	d.tree("Tree", Vector3(-7.6, 0, 4.6), 1.1)
	d.tree("Tree", Vector3(7.6, 0, 4.6), 1.0, Color("5aa548"))
	if track == "little":
		d.planter("Planter", Vector3(3.6, 0, -2.8), Vector2(1.0, 0.5), Color("ffc93c"))
		d.tree("Tree", Vector3(0.8, 0, 5.8), 1.2, Color("5aa548"))


## The bakery inside: a plank floor, walls of brick below and warm plaster above with a skirting, a ceiling with its
## lights, windows at the back of the side walls, a shelf of loaves over the baking table.
func _bakery_look() -> void:
	var d := decor()
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(4.8, 0.04, 4.2), Vector3(0, -0.01, 0.0), Color("f8e6cf"), 0.8)
	for w: Array in [[Vector3(0.1, 0, 4.2), Vector3(-2.45, 0, 0.0)], [Vector3(0.1, 0, 4.2), Vector3(2.45, 0, 0.0)],
			[Vector3(4.8, 0, 0.1), Vector3(0, 0, 2.1)]]:
		var size: Vector3 = w[0]
		var at: Vector3 = w[1]
		d.tiled("WallBrick", LifeRoomDecor.BRICK, Vector3(size.x, 1.0, size.z), at + Vector3(0, 0.5, 0), Color("e9cdbd"), 0.6)
		d.box("WallPlaster", Vector3(size.x, 1.6, size.z), at + Vector3(0, 1.8, 0), WALL, 0.0, LifeRoomDecor.SHELL)
		d.box("Rail", Vector3(size.x + 0.04, 0.05, size.z + 0.04), at + Vector3(0, 1.02, 0), Color("b98450"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Ceiling", LifeRoomDecor.PLANKS, Vector3(4.9, 0.08, 4.3), Vector3(0, 2.64, 0.0), Color("ffe9cc"), 1.0)
	d.ceiling_light("CeilingLight", Vector3(0, 2.58, -0.2))
	d.ceiling_light("CeilingLight", Vector3(0, 2.58, 1.3))
	d.window("Window", Vector3(-2.39, 1.6, 1.3), 0.8, 0.8, PI / 2)
	d.window("Window", Vector3(2.39, 1.7, 1.45), 0.7, 0.7, -PI / 2)
	d.shelf("BreadShelf", Vector3(0.55, 1.25, 2.0), 1.1, 0.75, PI, Color("b98450"), 2)
	for k in 6:
		d.box("Loaf", Vector3(0.16, 0.08, 0.1), Vector3(0.12 + (k % 3) * 0.3, 1.33 + (k / 3) * 0.36, 1.92), Color("d99a4e"))


## The shop's people drawn in few meshes (the Quest's draws): none of them changes pose; faces through feel.
func _people_look() -> void:
	for b: LifeBuddy in [customer, mo, waiting, bobo, pip]:
		if b != null:
			LifeRoomPeople.merge_person(b, true)
